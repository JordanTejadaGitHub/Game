# Balance simulation batch (documentation/balance_simulation.md "How it's used").
# Runs tools/balance_sim.gd for every seed x profile x style, a few at a time, then prints the summary
# and checks (tools/balance_summary.gd). Output goes to tools/balance_out/ (not committed).
#
#   powershell -File tools/balance_batch.ps1                      # quick batch: 3 seeds, Fresh, Balanced
#   powershell -File tools/balance_batch.ps1 -Seeds 1,2,3,4,5 -Profiles fresh,early,half,full -Styles balanced,wide,narrow,combo
#   powershell -File tools/balance_batch.ps1 -SaveBaseline         # keep this batch as tools/balance_baseline.json
param(
	[string]$Seeds = "1,2,3",  # Comma-separated (powershell -File passes arrays as one string)
	[string]$Profiles = "fresh",
	[string]$Styles = "balanced",
	[int]$Parallel = 3,
	[double]$Speed = 8,
	[switch]$SaveBaseline,
	[string]$Godot = "D:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe"
)
$project = Split-Path -Parent $PSScriptRoot
$out = Join-Path $project "tools\balance_out"
New-Item -ItemType Directory -Force $out | Out-Null
Remove-Item (Join-Path $out "runs.csv") -ErrorAction SilentlyContinue  # A batch starts a fresh table

$jobs = @()
foreach ($profile in $Profiles.Split(",")) { foreach ($style in $Styles.Split(",")) { foreach ($seed in $Seeds.Split(",")) {
	$jobs += ,@("--seed=$seed", "--profile=$profile", "--style=$style", "--speed=$Speed")
} } }
$running = @()
foreach ($job in $jobs) {
	while (($running | Where-Object { -not $_.HasExited }).Count -ge $Parallel) { Start-Sleep -Seconds 2 }
	$argList = @("--headless", "--path", $project, "--script", "res://tools/balance_sim.gd", "--fixed-fps", "60", "--") + $job
	$log = Join-Path $out ((($job -join "_") -replace "[-=]", "") + ".log")
	$running += Start-Process -FilePath $Godot -ArgumentList $argList -NoNewWindow -PassThru -RedirectStandardOutput $log
	Write-Host "started $($job -join ' ')"
}
$running | ForEach-Object { $_.WaitForExit() }
$summaryArgs = @("--headless", "--path", $project, "--script", "res://tools/balance_summary.gd", "--")
if ($SaveBaseline) { $summaryArgs += "--save-baseline" }
& $Godot @summaryArgs
