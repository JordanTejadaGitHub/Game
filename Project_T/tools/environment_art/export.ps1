# Regenerates every sheet in assets/environment/ (documentation/environment_assets.md).
#   powershell -File tools/environment_art/export.ps1        (from the Project_T folder)
# 1. heartwood_grounds.html is the generator (also the concept page). export_tail.js is appended to
#    its drawing code and run in headless Chrome, which dumps each raw sheet as base64.
# 2. process_environment.gd runs every raw sheet through DetailPass + the Heartwood 32 palette
#    (tools/art/) and writes the PNGs into assets/environment/.
# Then run Godot once with --import. Only PNGs are written, so .import files and UIDs don't change.
# Note: PowerShell variable names are case-insensitive; keep them distinct.
param(
	[string]$Chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe",
	[string]$Godot = "D:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe"
)
# Not "Stop": PowerShell 5 turns Chrome's harmless stderr lines into errors. Failures are checked explicitly.
$ErrorActionPreference = "Continue"
$toolDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent (Split-Path -Parent $toolDir)
$workDir = Join-Path $env:TEMP "environment_art_export"
$rawDir = Join-Path $workDir "raw"
if (Test-Path $rawDir) { Remove-Item $rawDir -Recurse -Force }
New-Item -ItemType Directory -Force $rawDir | Out-Null

# 1. Build the export page from the generator's drawing code and run it.
$page = Get-Content -Raw (Join-Path $toolDir "heartwood_grounds.html")
$codeStart = $page.IndexOf('"use strict";')
$codeEnd = $page.IndexOf('// ---------- scene ----------')
if ($codeStart -lt 0 -or $codeEnd -lt 0) { throw "heartwood_grounds.html: drawing-code markers not found" }
$drawing = $page.Substring($codeStart, $codeEnd - $codeStart)
$tailJs = Get-Content -Raw (Join-Path $toolDir "export_tail.js")
$errHook = "<script>window.addEventListener('error',ev=>{const p=document.createElement('p');p.id='jserr';p.textContent=ev.message+' @'+ev.lineno;document.body.appendChild(p)});</script>"
$exportPage = Join-Path $workDir "export.html"
[IO.File]::WriteAllText($exportPage, "<!doctype html><meta charset=`"utf-8`"><body>$errHook<script>(() => {`n$drawing`n$tailJs`n})();</script></body>", (New-Object Text.UTF8Encoding $false))
$dump = & $Chrome --headless=new --disable-gpu --no-first-run "--user-data-dir=$workDir\chrome" --virtual-time-budget=180000 --dump-dom ("file:///" + ($exportPage -replace '\\', '/')) 2>$null | Out-String
if ($dump -match '<p id="jserr">([^<]+)') { throw "Generator error: $($Matches[1])" }
if ($dump -notmatch 'id="done"') { throw "The generator did not finish" }
$sheets = [regex]::Matches($dump, '<pre data-name="([^"]+)">([A-Za-z0-9+/=\s]+)</pre>')
foreach ($m in $sheets) {
	$target = Join-Path $rawDir ($m.Groups[1].Value -replace '/', '\')
	New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
	[IO.File]::WriteAllBytes($target, [Convert]::FromBase64String(($m.Groups[2].Value -replace '\s', '')))
}
"$($sheets.Count) raw sheets exported"

# 2. Detail pass + palette into assets/environment/.
& $Godot --headless --path $projectDir --script res://tools/environment_art/process_environment.gd -- "--raw=$rawDir"
if ($LASTEXITCODE -ne 0) { throw "process_environment.gd reported $LASTEXITCODE problem(s)" }
"Done. Now run: Godot --headless --path . --import"
