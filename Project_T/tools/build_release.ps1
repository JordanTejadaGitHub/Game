# One-click test build (export_presets.cfg): exports the game from a clean checkout of a commit, numbers it, and
# deletes the previous builds (user, 2026-10-07: "start creating versioning numbers for builds and always delete the
# old build").
#   powershell -File tools\build_release.ps1                      Windows zip + Android APK of the full game, from HEAD
#   powershell -File tools\build_release.ps1 -Platform windows    one platform (windows / android / all)
#   powershell -File tools\build_release.ps1 -Preset demo         the demo presets (game/demo on via the demo_build feature)
#   powershell -File tools\build_release.ps1 -Commit a8c4fd8c     a given commit (built in a temporary worktree)
#   powershell -File tools\build_release.ps1 -KeepOld             keep the previous builds this once
# Versions: VERSION_BASE + a build number that goes up by one with every successful build (0.1.1, 0.1.2, …), kept in
# builds\build_number.txt; builds\versions.log lists every version with its commit. The version is the game's
# application/config/version (the title shows "v0.1.2" in exported builds), the exe's file version and the APK's
# version name / code. Bump VERSION_BASE for a milestone (0.2, 1.0); the build number keeps counting.
# Output: D:\Projects\Game\builds\v<version>[_demo]\ holding HeartwoodTD_v<version>.zip (Windows) and
# HeartwoodTD_v<version>.apk (Android, signed with the editor's debug key: fine for test phones, not for a store).
# Needs the Godot 4.7.2 export templates in the self-contained editor's folder:
# D:\Program Files\Godot\editor_data\export_templates\4.7.2.stable (Editor > Manage Export Templates puts them there).
param(
	[ValidateSet("all", "windows", "android")] [string]$Platform = "all",
	[ValidateSet("full", "demo")] [string]$Preset = "full",
	[string]$Commit = "",
	[switch]$KeepOld
)
$VERSION_BASE = "0.1"
. (Join-Path $PSScriptRoot 'dev_environment.ps1')
Set-HeartwoodDevEnvironment -Name 'build'
$ErrorActionPreference = "Stop"  # Until the native tools run: they write progress and notices to stderr
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$project = Split-Path -Parent $here
$repo = Split-Path -Parent $project
$git = "D:\Program Files\Git\cmd\git.exe"
$godot = "D:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe"
$demo = $Preset -eq "demo"
$windowsPreset = if ($demo) { "Windows Desktop (demo)" } else { "Windows Desktop (full game)" }
$androidPreset = if ($demo) { "Android (demo)" } else { "Android (full game)" }
$exeName = if ($demo) { "HeartwoodTD_Demo.exe" } else { "HeartwoodTD.exe" }
$product = if ($demo) { "Heartwood TD Demo" } else { "Heartwood TD" }
$env:APPDATA = "D:\Projects\logs\userdata\build"  # Nothing project-related on C: (Godot's editor settings stay in its own folder)
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null

$rcedit = "D:\Projects\archive\tools\rcedit-x64.exe"  # electron/rcedit: the exe's icon and version strings

# A multi-size .ico from PNGs (PNG-compressed entries, which Windows reads at every size): 16, 32, 48, 256 px.
function New-Ico([string[]]$pngs, [string]$ico) {
	$images = $pngs | ForEach-Object { ,[System.IO.File]::ReadAllBytes($_) }
	$stream = New-Object System.IO.MemoryStream
	$w = New-Object System.IO.BinaryWriter($stream)
	$w.Write([UInt16]0); $w.Write([UInt16]1); $w.Write([UInt16]$images.Count)
	$offset = 6 + 16 * $images.Count
	foreach ($bytes in $images) {
		$side = [BitConverter]::ToUInt32(@($bytes[19], $bytes[18], $bytes[17], $bytes[16]), 0)  # The PNG's width (big-endian)
		$w.Write([byte]($(if ($side -ge 256) { 0 } else { $side }))); $w.Write([byte]($(if ($side -ge 256) { 0 } else { $side })))
		$w.Write([byte]0); $w.Write([byte]0); $w.Write([UInt16]1); $w.Write([UInt16]32)
		$w.Write([UInt32]$bytes.Length); $w.Write([UInt32]$offset)
		$offset += $bytes.Length
	}
	foreach ($bytes in $images) { $w.Write($bytes) }
	$w.Flush()
	[System.IO.File]::WriteAllBytes($ico, $stream.ToArray())
}

# The exe's own icon (assets/app_icon/, when the commit has it) and its version strings, via rcedit.
function Set-ExeIdentity([string]$exe, [string]$src, [string]$product, [string]$version, [string]$scratch) {
	if (-not (Test-Path $rcedit)) { Write-Host "No rcedit at ${rcedit}: the exe keeps Godot's icon"; return }
	$rcArgs = @($exe, "--set-version-string", "CompanyName", "TopBunk Studios", "--set-version-string", "ProductName", $product,
		"--set-version-string", "FileDescription", $product, "--set-file-version", $version, "--set-product-version", $version)
	$iconDir = Join-Path $src "assets\app_icon"
	$sizes = @("app_icon_16.png", "app_icon_32.png", "app_icon_48.png", "app_icon.png") | ForEach-Object { Join-Path $iconDir $_ } | Where-Object { Test-Path $_ }
	if ($sizes.Count -gt 0) {
		$ico = Join-Path $scratch "heartwood_app_icon.ico"
		New-Ico $sizes $ico
		$rcArgs += @("--set-icon", $ico)
	} else {
		Write-Host "No assets/app_icon in this commit: the exe keeps Godot's icon"
	}
	& $rcedit @rcArgs
}

# Stamps the version into the checkout: application/config/version in project.godot, and every preset's Android
# version code (the build number: phones only install an update with a higher one) and version name.
function Set-Version([string]$src, [string]$version, [int]$number) {
	$godotFile = Join-Path $src "project.godot"
	$lines = [System.Collections.Generic.List[string]](Get-Content $godotFile -Encoding UTF8)
	$lines.RemoveAll({ param($l) $l -match '^config/version=' }) | Out-Null
	$at = $lines.IndexOf("[application]")
	if ($at -lt 0) { throw "project.godot has no [application] section." }
	$lines.Insert($at + 1, "config/version=`"$version`"")
	$utf8 = New-Object System.Text.UTF8Encoding($false)  # No BOM (PowerShell 5.1's UTF8 writes one)
	[System.IO.File]::WriteAllLines($godotFile, $lines, $utf8)
	$presets = Join-Path $src "export_presets.cfg"
	$text = [System.IO.File]::ReadAllText($presets)
	$text = $text -replace '(?m)^version/code=\d+', "version/code=$number" -replace '(?m)^version/name="[^"]*"', "version/name=`"$version`""
	[System.IO.File]::WriteAllText($presets, $text, $utf8)
}

if (-not (Test-Path "D:\Program Files\Godot\editor_data\export_templates\4.7.2.stable\windows_release_x86_64.exe")) {  # Self-contained Godot
	throw "No Godot 4.7.2 export templates: install them (Editor > Manage Export Templates > Download)."
}

# The next version: the last successful build's number + 1 (written only once this build has succeeded).
$builds = Join-Path $repo "builds"
New-Item -ItemType Directory -Force $builds | Out-Null
$counter = Join-Path $builds "build_number.txt"
$number = 1 + $(if (Test-Path $counter) { [int](Get-Content $counter -Raw).Trim() } else { 0 })
$version = "$VERSION_BASE.$number"

# Build from a clean temporary worktree of the commit, so nobody's uncommitted work goes into the game.
if ($Commit -eq "") { $Commit = (& $git -C $repo rev-parse --short HEAD).Trim() }
$hash = (& $git -C $repo rev-parse --short $Commit).Trim()
$tag = "v$version" + $(if ($demo) { "_demo" } else { "" })
$out = Join-Path $builds $tag
$work = "D:\Projects\worktrees\build_$hash"
$scratch = "D:\Projects\logs\build"
Write-Host "Building $tag from $hash ($Platform) ..."
$ErrorActionPreference = "Continue"
New-Item -ItemType Directory -Force $out, $scratch | Out-Null
if (Test-Path $work) { & $git -C $repo worktree remove --force $work 2>$null }
& $git -C $repo worktree add --detach $work $hash 2>$null | Out-Null
$made = @()
try {
	$src = Join-Path $work "Project_T"
	if (-not (Test-Path (Join-Path $src "export_presets.cfg"))) { throw "Commit $hash has no export_presets.cfg." }
	Set-Version $src $version $number
	Write-Host "Importing $hash ..."
	for ($pass = 0; $pass -lt 2; $pass++) {  # A fresh checkout: the first pass builds the class cache
		& $godot --headless --path $src --import 2>&1 | Out-Null
	}
	if ($Platform -ne "android") {
		$winDir = Join-Path $scratch "windows_$tag"
		if (Test-Path $winDir) { Remove-Item -Recurse -Force $winDir }
		New-Item -ItemType Directory -Force $winDir | Out-Null
		Write-Host "Exporting '$windowsPreset' ..."
		& $godot --headless --path $src --export-release $windowsPreset (Join-Path $winDir $exeName) 2>&1 | Tee-Object -FilePath (Join-Path $out "export_windows.log") | Out-Null
		if (-not (Test-Path (Join-Path $winDir $exeName))) { throw "Windows export failed: see $out\export_windows.log" }
		Set-ExeIdentity (Join-Path $winDir $exeName) $src $product $version $scratch
		$zip = Join-Path $out "HeartwoodTD_$tag.zip"
		Compress-Archive -Path (Join-Path $winDir "*") -DestinationPath $zip
		Remove-Item -Recurse -Force $winDir
		$made += $zip
	}
	if ($Platform -ne "windows") {
		$apk = Join-Path $out "HeartwoodTD_$tag.apk"
		Write-Host "Exporting '$androidPreset' ..."
		# Debug-signed (the editor's debug keystore): no release keystore exists yet.
		& $godot --headless --path $src --export-debug $androidPreset $apk 2>&1 | Tee-Object -FilePath (Join-Path $out "export_android.log") | Out-Null
		if (-not (Test-Path $apk)) { throw "Android export failed: see $out\export_android.log" }
		Remove-Item -ErrorAction SilentlyContinue "$apk.idsig"
		$made += $apk
	}
} finally {
	& $git -C $repo worktree remove --force $work 2>$null
}
Remove-Item -ErrorAction SilentlyContinue (Join-Path $out "export_*.log")

# Success: count it, log it, and clear out every older build (only the counter and the log stay).
Set-Content $counter $number
Add-Content (Join-Path $builds "versions.log") ("{0}  {1}  {2}  {3}" -f $tag, $hash, (Get-Date -Format "yyyy-MM-dd HH:mm"), $Platform)
if (-not $KeepOld) {
	Get-ChildItem $builds | Where-Object { $_.FullName -ne $out -and $_.Name -ne "build_number.txt" -and $_.Name -ne "versions.log" } |
		ForEach-Object { Remove-Item -Recurse -Force $_.FullName }
}
foreach ($file in $made) { Write-Host ("Built {0} ({1:N1} MB)" -f $file, ((Get-Item $file).Length / 1MB)) }
