# Keep development userdata, caches and temporary files on D: for this process and its children.
function Set-HeartwoodDevEnvironment {
    param([ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$Name = 'dev')
    $storageRoot = 'D:\Projects\logs'
    $env:APPDATA = Join-Path $storageRoot "userdata\$Name"
    $env:LOCALAPPDATA = Join-Path $storageRoot "localappdata\$Name"
    $env:TEMP = Join-Path $storageRoot "temp\$Name"
    $env:TMP = $env:TEMP
    foreach ($storageDir in @($env:APPDATA, $env:LOCALAPPDATA, $env:TEMP)) {
        New-Item -ItemType Directory -Path $storageDir -Force | Out-Null
    }
}