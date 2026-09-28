# Regenerates every sheet in assets/meta/ from grove_gen.html (built from the grove_*.js sources in this folder
# plus the shared pixel helpers). Needs Chrome. Run from the project folder:  powershell -File tools/meta_art/export.ps1
# To edit: change a grove_*.js file, then rebuild grove_gen.html with -Rebuild (helpers are kept inside grove_gen.html).
param([switch]$Rebuild)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$gen = Join-Path $here "grove_gen.html"
if ($Rebuild) {
	$old = Get-Content -Raw $gen
	$s = $old.IndexOf('"use strict";'); $e = $old.IndexOf('// ================= Memory Grove')
	$helpers = $old.Substring($s, $e - $s)
	$parts = ("grove_tree.js","grove_parts.js","grove_icons.js","grove_memories.js","grove_export.js" | ForEach-Object { Get-Content -Raw (Join-Path $here $_) }) -join ""
	$html = "<!doctype html><meta charset=`"utf-8`"><body><script>window.addEventListener('error',ev=>{const p=document.createElement('p');p.id='jserr';p.textContent=ev.message+' @'+ev.lineno;document.body.appendChild(p)});</script><script>(() => {`n$helpers`n$parts`n})();</script></body>"
	[IO.File]::WriteAllText($gen, $html, (New-Object Text.UTF8Encoding $false))
}
$profileDir = Join-Path $env:TEMP "meta_art_chrome"
$dump = & "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-first-run --user-data-dir=$profileDir --virtual-time-budget=400000 --dump-dom ("file:///" + ($gen -replace '\\','/')) 2>$null | Out-String
if ($dump -match '<p id="jserr">([^<]+)') { throw "Generator error: $($Matches[1])" }
if ($dump -notmatch '<p id="done">') { throw "Generator did not finish" }
$out = Join-Path (Split-Path -Parent (Split-Path -Parent $here)) "assets\meta"
$ms = [regex]::Matches($dump, '<pre data-name="([^"]+)">([A-Za-z0-9+/=\s]+)</pre>')
foreach ($m in $ms) {
	$name = $m.Groups[1].Value
	$p = if ($name.StartsWith("_preview/")) { Join-Path $here ($name -replace '/','\') } else { Join-Path $out ($name -replace '/','\') }
	New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
	[IO.File]::WriteAllBytes($p, [Convert]::FromBase64String(($m.Groups[2].Value -replace '\s','')))
}
"$($ms.Count) files written. Run Godot --import next."
