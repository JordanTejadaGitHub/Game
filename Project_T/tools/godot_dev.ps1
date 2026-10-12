# Launch the D: Godot installation with development output on D:.
# Example: powershell -NoProfile -ExecutionPolicy Bypass -File tools/godot_dev.ps1 editor --editor --path .
param([Parameter(Mandatory = $true)][string]$Name, [Parameter(ValueFromRemainingArguments = $true)][string[]]$GodotArgs)
. (Join-Path $PSScriptRoot 'dev_environment.ps1')
Set-HeartwoodDevEnvironment -Name $Name
& 'D:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe' @GodotArgs
exit $LASTEXITCODE