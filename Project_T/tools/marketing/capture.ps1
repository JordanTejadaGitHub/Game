# Renders a capture scene (res://capture/<name>.json, marketing.md §3) with Godot's Movie Maker.
#   powershell -File tools\marketing\capture.ps1 short_01
#   powershell -File tools\marketing\capture.ps1 short_01 -Project D:\Projects\wt_movie\Project_T -Out D:\Projects\Game\marketing\raw
# The frame size is the scene's "size" (default 1080x1920). It goes into an override.cfg in the project for the run
# (stretch mode "viewport", so it renders whole on a smaller screen) and is removed afterwards. Other sessions
# running Godot from the same folder see it meanwhile, so render from a separate worktree when others are working.
# Debug builds only (run from the editor binary). Writes only the capture profile (user://capture_*.json).
param(
	[Parameter(Mandatory = $true)][string]$Name,
	[string]$Project = (Resolve-Path "$PSScriptRoot\..\..").Path,
	[string]$Out = (Join-Path (Resolve-Path "$PSScriptRoot\..\..\..").Path "marketing\raw"),
	[string]$Godot = "D:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe"
)
$ErrorActionPreference = "Stop"
$scenePath = Join-Path $Project "capture\$Name.json"
if (-not (Test-Path $scenePath)) { throw "No capture scene $scenePath" }
$scene = Get-Content $scenePath -Raw | ConvertFrom-Json
$size = @(1080, 1920)
if ($null -ne $scene.size) { $size = @([int]$scene.size[0], [int]$scene.size[1]) }
# A window that fits the screen; the video is the viewport size either way.
$shrink = [Math]::Max(1, [Math]::Ceiling([Math]::Max($size[0] / 960.0, $size[1] / 700.0)))
$override = Join-Path $Project "override.cfg"
if (Test-Path $override) { throw "$override already exists (another capture running?)" }
@"
[display]

window/size/viewport_width=$($size[0])
window/size/viewport_height=$($size[1])
window/size/window_width_override=$([int]($size[0] / $shrink))
window/size/window_height_override=$([int]($size[1] / $shrink))
window/stretch/mode="viewport"
"@ | Out-File -Encoding ascii $override
New-Item -ItemType Directory -Force $Out | Out-Null
$movie = Join-Path $Out "$Name.avi"
try {
	& $Godot --path $Project --write-movie $movie --fixed-fps 60 -- "--capture=res://capture/$Name.json" | Out-Host
} finally {
	Remove-Item $override -Force
}
if (-not (Test-Path $movie)) { throw "No movie written: $movie" }
Write-Host "Captured $movie"
