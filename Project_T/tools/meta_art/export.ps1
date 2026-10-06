# Regenerates every sheet in assets/meta/ from grove_gen.html (built from the grove_*.js sources in this folder
# plus the shared pixel helpers). Needs Chrome. Run from the project folder:  powershell -File tools/meta_art/export.ps1
# To edit: change a grove_*.js file, then rebuild grove_gen.html with -Rebuild (helpers are kept inside grove_gen.html).
param([switch]$Rebuild)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$gen = Join-Path $here "grove_gen.html"
if ($Rebuild) {
	$old = Get-Content -Raw -Encoding UTF8 $gen
	$s = $old.IndexOf('"use strict";'); $e = $old.IndexOf('const HW32 ='); if ($e -lt 0) { $e = $old.IndexOf('// ================= Memory Grove') }
	$helpers = $old.Substring($s, $e - $s).TrimEnd()  # TrimEnd: no extra newline per rebuild
	$parts = ("grove_tree.js","grove_parts.js","grove_icons.js","grove_memories.js","grove_starlit.js","grove_sixth.js","grove_memory_wardens.js","grove_blooms.js","grove_export.js" | ForEach-Object { Get-Content -Raw -Encoding UTF8 (Join-Path $here $_) }) -join ""
	$palette = Get-Content -Raw -Encoding UTF8 (Join-Path (Split-Path -Parent (Split-Path -Parent $here)) "assets/palette/heartwood32.json")
	# Each node's icon (limb, frame) from resource/meta/grove/*.tres, for the per-node blooms.
	$proj = Split-Path -Parent (Split-Path -Parent $here)
	$icons = Get-ChildItem (Join-Path $proj "resource/meta/grove") -Filter *.tres | ForEach-Object {
		$t = Get-Content -Raw -Encoding UTF8 $_.FullName
		'"{0}":[{1},{2}]' -f [regex]::Match($t, '(?m)^id = "([^"]+)"').Groups[1].Value, [regex]::Match($t, '(?m)^root = (\d)').Groups[1].Value, $(if ($t -match '(?m)^icon = (-?\d+)') { $Matches[1] } else { -1 })
	}
	# The Ascended Wardens' first idle frame (160x160), as data URLs, for the Ascension blooms.
	Add-Type -AssemblyName System.Drawing
	$asc = @{ sporeling = "sporemother"; firefly_jar = "stormheart"; dewdrop = "tidecaller"; pebbling = "old_mountain"; rootling = "world_root"; bellflower = "the_great_bell"; acorn = "grandmother_oak"; nestling = "dawnwing"; whirligig = "the_tempest" }
	$ascArt = $asc.Keys | Sort-Object | ForEach-Object {
		$src = [Drawing.Bitmap]::FromFile((Join-Path $proj "assets/towers/ascended/$($asc[$_]).png"))
		$frame = $src.Clone((New-Object Drawing.Rectangle 0, 0, $src.Height, $src.Height), [Drawing.Imaging.PixelFormat]::Format32bppArgb); $src.Dispose()
		$ms = New-Object IO.MemoryStream; $frame.Save($ms, [Drawing.Imaging.ImageFormat]::Png); $frame.Dispose()
		'"{0}":"data:image/png;base64,{1}"' -f $_, [Convert]::ToBase64String($ms.ToArray())
	}
	$parts = "const HW32 = $palette;`nconst NODE_ICON = {$($icons -join ',')};`nconst ASCENDED_ART = {$($ascArt -join ',')};`n" + $parts
	$html = "<!doctype html><meta charset=`"utf-8`"><body><script>window.addEventListener('error',ev=>{const p=document.createElement('p');p.id='jserr';p.textContent=ev.message+' @'+ev.lineno;document.body.appendChild(p)});</script><script>(() => {`n$helpers`n$parts`n})();</script></body>"
	[IO.File]::WriteAllText($gen, $html, (New-Object Text.UTF8Encoding $false))
}
$profileDir = "D:/Projects/logs/chrome/meta_art"  # nothing temporary on C: (user, 2026-10-05)
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
