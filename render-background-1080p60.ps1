param(
  [int]$Port = 8765
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
  if (-not $pythonCandidates) { throw '未找到 Python，无法启动本地 HTTP 服务。' }
  Start-Process -WindowStyle Hidden -FilePath $pythonCandidates[0] -ArgumentList @('-m','http.server',"$Port",'--bind','127.0.0.1','--directory',$projectRoot) | Out-Null
  Start-Sleep -Milliseconds 500
}

$chromeCandidates = @(
  (Get-Command chrome.exe -ErrorAction SilentlyContinue).Source,
  'C:\Program Files\Google\Chrome\Application\chrome.exe',
  'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
if (-not $chromeCandidates) { throw '未找到 Chrome。' }

$url = "http://127.0.0.1:$Port/index.html?render=1080p60&autoRecord=1"
$chromeArgs = @(
  "--user-data-dir=$profileDir",
  '--disable-background-timer-throttling',
  '--disable-backgrounding-occluded-windows',
  '--disable-renderer-backgrounding',
  '--disable-features=CalculateNativeWinOcclusion',
  '--autoplay-policy=no-user-gesture-required',
  '--start-minimized',
  '--new-window',
  $url
)
Start-Process -WindowStyle Hidden -FilePath $chromeCandidates[0] -ArgumentList $chromeArgs | Out-Null
Write-Host "已启动 1× 后台 1080p60 录制。视频将在 $renderDir 自动下载。"
