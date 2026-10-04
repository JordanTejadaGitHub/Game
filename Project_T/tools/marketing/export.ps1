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
	[string]$Project = (Resolve-Path "$PSScriptRoot\..\..").Path,
	[string]$Raw = (Join-Path (Resolve-Path "$PSScriptRoot\..\..\..").Path "marketing\raw"),
	[string]$Final = (Join-Path (Resolve-Path "$PSScriptRoot\..\..\..").Path "marketing\shorts"),
	[string]$Ffmpeg = "D:\Projects\ffmpeg\ffmpeg-9.0.2-essentials_build\bin\ffmpeg.exe"
)
$ErrorActionPreference = "Stop"
$scene = Get-Content (Join-Path $Project "capture\$Name.json") -Raw | ConvertFrom-Json
$movie = Join-Path $Raw "$Name.avi"
if (-not (Test-Path $movie)) { throw "No capture $movie (run capture.ps1 first)" }
$probe = & ($Ffmpeg -replace "ffmpeg.exe$", "ffprobe.exe") -v error -show_entries format=duration -of csv=p=0 $movie
$clip = [double]::Parse($probe.Trim(), [Globalization.CultureInfo]::InvariantCulture)
$endCard = 1.5; if ($null -ne $scene.end_card) { $endCard = [double]$scene.end_card }
$total = $clip + $endCard
$inv = [Globalization.CultureInfo]::InvariantCulture
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
		$filters += "drawtext=fontfile=body.ttf:textfile=cap_${style}_$i.txt:fontsize=64:fontcolor=0xfff4dc:line_spacing=12:" +
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
	$graph = "[0:v]fps=60,format=yuv420p,$caps[body];$card;[body][card]concat=n=2:v=1:a=0[tall];" +
		"[0:a]aresample=48000,volume=${gameDb}dB,apad=whole_dur=$(F $total)[game];" + (Music $musicDb "mus") + ";" +
		"[game][mus]amix=inputs=2:normalize=0,atrim=0:$(F $total)[a]"
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
