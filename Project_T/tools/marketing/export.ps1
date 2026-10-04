# Exports a captured short (marketing.md §3–4) with ffmpeg: captions, a music bed from the game's stems, the
# "Wishlist on Steam" end card, one file per platform.
#   powershell -File tools\marketing\export.ps1 short_01
# Reads capture\<name>.json ("captions": [[from, to, "Text"], …] in seconds of the clip, "music": stem names such as
# "base", "dread1", "heartbeat", "boss_stag"; "music_db", "end_card" seconds) and <Raw>\<name>.avi (capture.ps1).
# Writes <Final>\<name>\:
#   <name>_youtube.mp4    9:16, captions in Title Case (as written in the scene)
#   <name>_tiktok.mp4     9:16, captions lowercase
#   <name>_x.mp4          16:9 (X / Bluesky): the vertical frame on a darkened backdrop, captions as YouTube
#   <name>_voiceover.mp4  9:16, no captions, music at -18 dB (room for a voice), same length and end card
#   <name>_music.wav      the music bed alone, full length, for mixing in an editor
param(
	[Parameter(Mandatory = $true)][string]$Name,
	[string]$Project = "",
	[string]$Raw = "",
	[string]$Final = "",
	[string]$Ffmpeg = "D:\Projects\ffmpeg\ffmpeg-9.0.2-essentials_build\bin\ffmpeg.exe"
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path  # tools\marketing ($PSScriptRoot is empty in param defaults on 5.1)
if ($Project -eq "") { $Project = (Resolve-Path (Join-Path $here "..\..")).Path }
$marketing = Join-Path (Resolve-Path (Join-Path $here "..\..\..")).Path "marketing"
if ($Raw -eq "") { $Raw = Join-Path $marketing "raw" }
if ($Final -eq "") { $Final = Join-Path $marketing "shorts" }
$scene = Get-Content (Join-Path $Project "capture\$Name.json") -Raw | ConvertFrom-Json
$inv = [Globalization.CultureInfo]::InvariantCulture

$movie = Join-Path $Raw "$Name.avi"
# A cut list ("cuts": [{"clip": "<capture name>", "from": s, "to": s}, …], optional "crossfade_frames"): the clips'
# raw captures (same size) are trimmed and joined into one timeline first; captions, music and the end card then run
# over the whole of it (caption times are on the joined timeline).
if ($null -ne $scene.cuts) {
	$parts = @($scene.cuts)
	$fade = 0.0; if ($null -ne $scene.crossfade_frames) { $fade = [double]$scene.crossfade_frames / 60.0 }
	$cutArgs = @("-v", "error", "-y")
	$graph = ""; $lengths = @()
	for ($i = 0; $i -lt $parts.Count; $i++) {
		$src = Join-Path $Raw "$($parts[$i].clip).avi"
		if (-not (Test-Path $src)) { throw "No capture $src for cut $i (run capture.ps1 $($parts[$i].clip) first)" }
		$cutArgs += @("-i", $src)
		$from = [double]$parts[$i].from; $to = [double]$parts[$i].to
		$lengths += ($to - $from)
		$graph += "[${i}:v]trim=start=$($from.ToString($inv)):end=$($to.ToString($inv)),setpts=PTS-STARTPTS,fps=60,format=yuv420p[v$i];" +
			"[${i}:a]atrim=start=$($from.ToString($inv)):end=$($to.ToString($inv)),asetpts=PTS-STARTPTS,aresample=48000[a$i];"
	}
	if ($fade -le 0.0 -or $parts.Count -lt 2) {
		for ($i = 0; $i -lt $parts.Count; $i++) { $graph += "[v$i][a$i]" }
		$graph += "concat=n=$($parts.Count):v=1:a=1[v][a]"
	} else {
		$vPrev = "v0"; $aPrev = "a0"; $offset = 0.0
		for ($i = 1; $i -lt $parts.Count; $i++) {
			$offset += $lengths[$i - 1] - $fade
			$vOut = if ($i -eq $parts.Count - 1) { "v" } else { "vx$i" }
			$aOut = if ($i -eq $parts.Count - 1) { "a" } else { "ax$i" }
			$graph += "[$vPrev][v$i]xfade=transition=fade:duration=$($fade.ToString($inv)):offset=$($offset.ToString($inv))[$vOut];" +
				"[$aPrev][a$i]acrossfade=d=$($fade.ToString($inv))[$aOut];"
			$vPrev = $vOut; $aPrev = $aOut
		}
		$graph = $graph.TrimEnd(";")
	}
	$movie = Join-Path $Raw "${Name}_cut.mkv"
	$cutArgs += @("-filter_complex", $graph, "-map", "[v]", "-map", "[a]", "-c:v", "libx264", "-preset", "fast", "-crf", "12",
		"-c:a", "pcm_s16le", $movie)
	& $Ffmpeg @cutArgs
	if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed joining the cuts" }
	Write-Host "Joined $($parts.Count) cuts into $movie"
}
if (-not (Test-Path $movie)) { throw "No capture $movie (run capture.ps1 first)" }
$probe = & ($Ffmpeg -replace "ffmpeg.exe$", "ffprobe.exe") -v error -show_entries format=duration -of csv=p=0 $movie
$clip = [double]::Parse($probe.Trim(), [Globalization.CultureInfo]::InvariantCulture)
$endCard = 1.5; if ($null -ne $scene.end_card) { $endCard = [double]$scene.end_card }
$total = $clip + $endCard

function F([double]$x) { return $x.ToString("0.###", $inv) }

# Work in a temp folder with plain relative file names: no drive colons to escape inside filtergraphs.
$work = Join-Path $env:TEMP "heartwood_export_$Name"
Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
New-Item -ItemType Directory $work | Out-Null
Copy-Item (Join-Path $Project "assets\ui\fonts\AlegreyaSans-Medium.ttf") (Join-Path $work "body.ttf")
Copy-Item (Join-Path $Project "assets\ui\fonts\CormorantSC-Medium.ttf") (Join-Path $work "title.ttf")
Copy-Item (Join-Path $Project "assets\ui\title\title_background.png") (Join-Path $work "backdrop.png")
$stems = @("base", "dread1"); if ($null -ne $scene.music) { $stems = @($scene.music) }
$stemFiles = @()
foreach ($stem in $stems) {
	$file = "stem_$stem.wav"
	Copy-Item (Join-Path $Project "assets\audio\music\mus_act1_$stem.wav") (Join-Path $work $file)
	$stemFiles += $file
}
function Wrap([string]$text, [int]$width = 24) {
	$lines = @(); $line = ""
	foreach ($word in $text -split " ") {
		if ($line.Length -gt 0 -and ($line.Length + 1 + $word.Length) -gt $width) { $lines += $line; $line = $word }
		elseif ($line.Length -gt 0) { $line += " " + $word } else { $line = $word }
	}
	if ($line.Length -gt 0) { $lines += $line }
	return ($lines -join "`n")
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Text([string]$file, [string]$text) { [IO.File]::WriteAllText((Join-Path $work $file), $text, $utf8) }
Text "card_title.txt" "Heartwood TD"
Text "card_wish.txt" "Wishlist on Steam"
Text "card_link.txt" "link in the description"

# Captions: one drawtext per beat, in the top band (the map sits in the middle of the frame).
function Captions([string]$style) {
	$filters = @(); $i = 0
	foreach ($cap in @($scene.captions)) {
		if ($null -eq $cap) { continue }
		$text = [string]$cap[2]
		if ($style -eq "lower") { $text = $text.ToLower() }
		Text "cap_${style}_$i.txt" (Wrap $text)
		$filters += "drawtext=fontfile=body.ttf:textfile=cap_${style}_$i.txt:fontsize=64:fontcolor=0xfff4dc:line_spacing=12:text_align=C:" +
			"box=1:boxcolor=0x05050d@0.6:boxborderw=28:x=(w-text_w)/2:y=h*0.11:enable='between(t,$(F $cap[0]),$(F $cap[1]))'"
		$i++
	}
	if ($filters.Count -eq 0) { return "null" }
	return ($filters -join ",")
}

# The end card: the title art, darkened, with the name and the call to action.
$card = "[1:v]scale=iw*6:ih*6:flags=neighbor,crop=1080:1920,eq=brightness=-0.18:saturation=0.85," +
	"drawtext=fontfile=title.ttf:textfile=card_title.txt:fontsize=118:fontcolor=0xe9a83c:x=(w-text_w)/2:y=h*0.36," +
	"drawtext=fontfile=body.ttf:textfile=card_wish.txt:fontsize=74:fontcolor=0xfff4dc:x=(w-text_w)/2:y=h*0.36+170," +
	"drawtext=fontfile=body.ttf:textfile=card_link.txt:fontsize=42:fontcolor=0xfff4dc@0.75:x=(w-text_w)/2:y=h*0.36+270," +
	"fps=60,trim=duration=$(F $endCard),setpts=PTS-STARTPTS,format=yuv420p,fade=t=in:st=0:d=0.25[card]"

function Music([double]$db, [string]$label) {
	$n = $stemFiles.Count
	$ins = ""; for ($k = 0; $k -lt $n; $k++) { $ins += "[$($k + 2):a]" }
	return "${ins}amix=inputs=${n}:normalize=0,atrim=0:$(F $total),asetpts=PTS-STARTPTS,aresample=48000,pan=stereo|c0=c0|c1=c0," +
		"volume=${db}dB,afade=t=in:st=0:d=0.6,afade=t=out:st=$(F ($total - 1.2)):d=1.2[$label]"
}

function Render([string]$out, [string]$captionStyle, [double]$musicDb, [double]$gameDb, [bool]$wide) {
	$caps = if ($captionStyle -eq "") { "null" } else { Captions $captionStyle }
	# Platform cuts are levelled to -14 LUFS (Shorts / TikTok); the voiceover cut keeps its quiet bed for the voice.
	$loud = if ($captionStyle -eq "") { "" } else { ",loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000" }
	$graph = "[0:v]fps=60,format=yuv420p,$caps[body];$card;[body][card]concat=n=2:v=1:a=0[tall];" +
		"[0:a]aresample=48000,volume=${gameDb}dB,apad=whole_dur=$(F $total)[game];" + (Music $musicDb "mus") + ";" +
		"[game][mus]amix=inputs=2:normalize=0,atrim=0:$(F $total)$loud[a]"
	if ($wide) {
		$graph += ";[tall]split[t1][t2];[t1]scale=1920:-2,crop=1920:1080,boxblur=24:2,eq=brightness=-0.25[bg];" +
			"[t2]scale=-2:1080:flags=lanczos[fg];[bg][fg]overlay=(W-w)/2:0[v]"
	} else {
		$graph += ";[tall]null[v]"
	}
	$graphFile = "graph_" + [IO.Path]::GetFileNameWithoutExtension($out) + ".txt"
	Text $graphFile $graph
	$args = @("-v", "error", "-y", "-i", $movie, "-loop", "1", "-framerate", "60", "-i", "backdrop.png")
	foreach ($f in $stemFiles) { $args += @("-stream_loop", "-1", "-i", $f) }
	$args += @("-/filter_complex", $graphFile, "-map", "[v]", "-map", "[a]", "-t", (F $total),
		"-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
		"-movflags", "+faststart", $out)
	Push-Location $work
	try { & $Ffmpeg @args; if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on $out" } } finally { Pop-Location }
	Write-Host "Wrote $out"
}

$dest = Join-Path $Final $Name
New-Item -ItemType Directory -Force $dest | Out-Null
$musicDb = -9.0; if ($null -ne $scene.music_db) { $musicDb = [double]$scene.music_db }
Render (Join-Path $dest "${Name}_youtube.mp4") "title" $musicDb 0.0 $false
Render (Join-Path $dest "${Name}_tiktok.mp4") "lower" $musicDb 0.0 $false
Render (Join-Path $dest "${Name}_x.mp4") "title" $musicDb 0.0 $true
Render (Join-Path $dest "${Name}_voiceover.mp4") "" -18.0 -8.0 $false
# The music bed alone (0 dB trim of the stems, faded like the videos).
$graph = (Music 0.0 "mus")
Text "graph_music.txt" $graph
$margs = @("-v", "error", "-y", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo")
foreach ($f in $stemFiles) { $margs += @("-stream_loop", "-1", "-i", $f) }
$margs += @("-/filter_complex", "graph_music.txt", "-map", "[mus]", "-t", (F $total), "-c:a", "pcm_s16le", (Join-Path $dest "${Name}_music.wav"))
Push-Location $work
try { & $Ffmpeg @margs; if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on the music bed" } } finally { Pop-Location }
Write-Host "Wrote $(Join-Path $dest "${Name}_music.wav")"
Remove-Item -Recurse -Force $work
