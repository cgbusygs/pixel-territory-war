param(
  [int]$Port = 8765,
  [int]$DebugPort = 9229
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$renderDir = Join-Path $projectRoot 'renders'
$profileDir = Join-Path $renderDir 'chrome-background-profile'
New-Item -ItemType Directory -Force -Path $renderDir, (Join-Path $profileDir 'Default') | Out-Null

$preferences = @{
  download = @{
    default_directory = $renderDir
    prompt_for_download = $false
    directory_upgrade = $true
  }
} | ConvertTo-Json -Compress
Set-Content -LiteralPath (Join-Path $profileDir 'Default\Preferences') -Value $preferences -Encoding UTF8

$listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $listener) {
  $pythonCandidates = @(
    (Get-Command python.exe -ErrorAction SilentlyContinue).Source,
    'C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
  ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
  if (-not $pythonCandidates) { throw 'Python was not found; cannot start the local HTTP server.' }
  Start-Process -WindowStyle Hidden -FilePath $pythonCandidates[0] -ArgumentList @('-m','http.server',"$Port",'--bind','127.0.0.1','--directory',$projectRoot) | Out-Null
  Start-Sleep -Milliseconds 500
}

$chromeCandidates = @(
  (Get-Command chrome.exe -ErrorAction SilentlyContinue).Source,
  'C:\Program Files\Google\Chrome\Application\chrome.exe',
  'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
if (-not $chromeCandidates) { throw 'Chrome was not found.' }
$chromePath = $chromeCandidates | Select-Object -First 1

$nodeCandidates = @(
  (Get-Command node.exe -ErrorAction SilentlyContinue).Source,
  'C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe'
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
if (-not $nodeCandidates) { throw 'Node.js was not found; cannot keep the background page active.' }
$nodePath = $nodeCandidates | Select-Object -First 1

$url = "http://127.0.0.1:$Port/index.html?render=1080p60&autoRecord=1"
$chromeArgs = @(
  "--user-data-dir=$profileDir",
  '--disable-background-timer-throttling',
  '--disable-backgrounding-occluded-windows',
  '--disable-renderer-backgrounding',
  '--disable-features=CalculateNativeWinOcclusion,IntensiveWakeUpThrottling',
  '--autoplay-policy=no-user-gesture-required',
  "--remote-debugging-port=$DebugPort",
  '--new-window',
  'about:blank'
)
Start-Process -FilePath $chromePath -ArgumentList $chromeArgs | Out-Null
Start-Sleep -Milliseconds 1000
$focusHelper = Join-Path $projectRoot 'render-background-focus.mjs'
Start-Process -WindowStyle Hidden -FilePath $nodePath -ArgumentList @($focusHelper,"$DebugPort",$url) | Out-Null
Write-Host "Started 1x background 1080p60 recording. Video downloads to $renderDir."
