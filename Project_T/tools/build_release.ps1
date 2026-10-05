# One-click release build (export_presets.cfg): exports the game from a clean checkout of a commit, then zips it.
#   powershell -File tools\build_release.ps1                      the full game, from HEAD of this checkout
#   powershell -File tools\build_release.ps1 -Preset demo         the demo preset (game/demo on via the demo_build feature)
#   powershell -File tools\build_release.ps1 -Commit a8c4fd8c     a given commit (built in a temporary worktree)
# Output: D:\Projects\Game\builds\<yyyy-MM-dd>_<hash>[_demo]\HeartwoodTD.exe (+ .pck) and a zip beside it.
# Needs the Godot 4.7.2 export templates in the self-contained editor's folder:
# D:\Program Files\Godot\editor_data\export_templates\4.7.2.stable (Editor > Manage Export Templates puts them there).
param(
	[ValidateSet("full", "demo")] [string]$Preset = "full",
	[string]$Commit = ""
)
$ErrorActionPreference = "Stop"  # Until the native tools run: they write progress and notices to stderr
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$project = Split-Path -Parent $here
$repo = Split-Path -Parent $project
$git = "D:\Program Files\Git\cmd\git.exe"
$godot = "D:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe"
$presetName = if ($Preset -eq "demo") { "Windows Desktop (demo)" } else { "Windows Desktop (full game)" }
$exeName = if ($Preset -eq "demo") { "HeartwoodTD_Demo.exe" } else { "HeartwoodTD.exe" }

if (-not (Test-Path "D:\Program Files\Godot\editor_data\export_templates\4.7.2.stable\windows_release_x86_64.exe")) {  # Self-contained Godot
	throw "No Godot 4.7.2 export templates: install them (Editor > Manage Export Templates > Download)."
}

# Build from a clean temporary worktree of the commit, so nobody's uncommitted work goes into the game.
if ($Commit -eq "") { $Commit = (& $git -C $repo rev-parse --short HEAD).Trim() }
$hash = (& $git -C $repo rev-parse --short $Commit).Trim()
$stamp = Get-Date -Format "yyyy-MM-dd"
$tag = "${stamp}_$hash" + $(if ($Preset -eq "demo") { "_demo" } else { "" })
$builds = Join-Path $repo "builds"
$out = Join-Path $builds $tag
$work = Join-Path $env:TEMP "heartwood_build_$hash"
$ErrorActionPreference = "Continue"
New-Item -ItemType Directory -Force $out | Out-Null
if (Test-Path $work) { & $git -C $repo worktree remove --force $work 2>$null }
& $git -C $repo worktree add --detach $work $hash | Out-Null
try {
	$src = Join-Path $work "Project_T"
	if (-not (Test-Path (Join-Path $src "export_presets.cfg"))) { throw "Commit $hash has no export_presets.cfg." }
	Write-Host "Importing $hash ..."
	for ($pass = 0; $pass -lt 2; $pass++) {  # A fresh checkout: the first pass builds the class cache
		& $godot --headless --path $src --import 2>&1 | Out-Null
	}
	Write-Host "Exporting '$presetName' to $out ..."
	& $godot --headless --path $src --export-release $presetName (Join-Path $out $exeName) 2>&1 | Tee-Object -FilePath (Join-Path $out "export.log") | Out-Null
	if (-not (Test-Path (Join-Path $out $exeName))) { throw "Export failed: see $out\export.log" }
	Remove-Item (Join-Path $out "export.log")
} finally {
	& $git -C $repo worktree remove --force $work 2>$null
}
$zip = Join-Path $builds "HeartwoodTD_$tag.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path (Join-Path $out "*") -DestinationPath $zip
$size = "{0:N1} MB" -f ((Get-Item $zip).Length / 1MB)
Write-Host "Built $zip ($size)"
