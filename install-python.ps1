# Set the environment variables
. .\env.ps1

$PYTHON = "python.exe"
$PIP = "pip3.exe"

if (-Not $env:RUNNER_TOOL_CACHE) {
    Write-Host "Running on a local machine builder" -ForegroundColor Yellow
    $PYTHON = "$env:ProgramFiles\Python313\python.exe"
    $PIP = "$env:ProgramFiles\Python313\Scripts\pip3.exe"
}

Write-Host "Loading the Python installation..." -ForegroundColor Blue
Invoke-WebRequest -Uri $PYTHON_REF -OutFile "python-install.exe"
Start-Process -FilePath "python-install.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0" -Wait

& $PYTHON -m pip install --upgrade pip

Write-Host "Python version is:" -ForegroundColor Green
& $PYTHON --version

Write-Host "PIP version is:" -ForegroundColor Green
& $PIP --version

$global:PYTHON = $PYTHON
$global:PIP = $PIP