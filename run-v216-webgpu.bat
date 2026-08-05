@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "ROOT=%~dp0"
set "HTML=index.html"
set "HOST=127.0.0.1"
set "PORT=8766"
set "QUERY="
if /i "%~1"=="perf" set "QUERY=?perf=1"
set "PATH_URL=/%HTML%%QUERY%"

if not exist "%ROOT%%HTML%" (
  echo HTML file not found: "%ROOT%%HTML%"
  pause
  exit /b 1
)

set "PYTHON="
for /f "delims=" %%P in ('where py.exe 2^>nul') do if not defined PYTHON set "PYTHON=%%P"
if not defined PYTHON for /f "delims=" %%P in ('where python.exe 2^>nul') do if not defined PYTHON set "PYTHON=%%P"

if not defined PYTHON (
  echo Python 3 was not found. Install Python, or serve this folder through another HTTP server.
  pause
  exit /b 1
)

rem Reuse an existing server, or select the first free port in the local range.
for /l %%N in (8766,1,8785) do (
  set "PORT=%%N"
  call :set_urls
  call :is_ready
  if not errorlevel 1 goto :open
  call :is_port_free
  if not errorlevel 1 goto :port_selected
)

echo No free local port was found in 8766-8785.
pause
exit /b 1

:port_selected

rem Start a detached, hidden server rooted at this package directory.
powershell.exe -NoProfile -Command "$p=Start-Process -FilePath '%PYTHON%' -ArgumentList @('-m','http.server','%PORT%','--bind','%HOST%','--directory','%ROOT%') -WorkingDirectory '%ROOT%' -WindowStyle Hidden -PassThru; if (-not $p) { exit 1 }" >nul 2>&1
if errorlevel 1 (
  echo Could not start the local HTTP server.
  pause
  exit /b 1
)

rem Wait until the HTML endpoint is actually responding instead of guessing with a fixed delay.
for /l %%N in (1,1,15) do (
  call :is_ready
  if not errorlevel 1 goto :open
  timeout /t 1 /nobreak >nul
)

echo The local HTTP server did not become ready: %OPEN_URL%
pause
exit /b 1

:set_urls
set "OPEN_URL=http://localhost:%PORT%%PATH_URL%"
set "CHECK_URL=http://127.0.0.1:%PORT%%PATH_URL%"
exit /b 0

:is_ready
powershell.exe -NoProfile -Command "try { $r=Invoke-WebRequest -UseBasicParsing -Uri '%CHECK_URL%' -TimeoutSec 2; if ($r.StatusCode -eq 200 -and $r.Content -match 'Pixel Territory War') { exit 0 } } catch {} exit 1" >nul 2>&1
exit /b %errorlevel%

:is_port_free
powershell.exe -NoProfile -Command "if (Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue) { exit 1 } else { exit 0 }" >nul 2>&1
exit /b %errorlevel%

:open
start "" "%OPEN_URL%"
endlocal
exit /b 0
