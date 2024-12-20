# Stop execution on any error
$ErrorActionPreference = "Stop"

# Set the environment variables
. .\env.ps1

function Extract-ZipFile {
    param (
        [string]$zipFilePath,
        [string]$destinationPath
    )
    if (Test-Path $SEVENZIP) {
        & $SEVENZIP x "$zipFilePath" -o"$destinationPath"
        Start-Sleep -Seconds 5
    } else {
        Expand-Archive -Path "$zipFilePath" -DestinationPath "$destinationPath"
    }
    Remove-Item -Force "$zipFilePath" -ErrorAction Ignore
}

function Compress-ToZipFile {
    param (
        [string]$sourcePath,
        [string]$destinationPath
    )
    if (Test-Path $SEVENZIP) {
        & $SEVENZIP a "$destinationPath" -y "$sourcePath"
    } else {
        Compress-Archive -Path "$sourcePath" -DestinationPath "$destinationPath"
    }
}

function Start-Bootstrapping {
    Write-Host "`n--- Start bootstrapping ---" -ForegroundColor blue
    & ./clean.ps1
    New-Item -ItemType Directory -Path $MD
    Copy-Item "src\*.bat" $MD
    Copy-Item "src\*.ps1" $MD
    Copy-Item "doc" "$MD\doc" -Recurse
    Write-Host "`n--- End bootstrapping ---" -ForegroundColor green
}

function Get-VCRedist {
    Write-Host "`n--- Download VCREDIST ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $VCREDIST_REF -OutFile "$MD\vc_redist.x64.exe"
    Write-Host "`n--- VCREDIST downloaded ---" -ForegroundColor green
}

function Get-ETCD {
    Write-Host "`n--- Download ETCD ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $ETCD_REF -OutFile "$env:TEMP\etcd.zip"
    Extract-ZipFile "$env:TEMP\etcd.zip" "$MD"
    Rename-Item "$MD\etcd-*" "etcd"
    Copy-Item "src\etcd.yaml" "$MD\etcd"
    Write-Host "`n--- ETCD downloaded ---" -ForegroundColor green
}

function Get-Micro {
    Write-Host "`n--- Download MICRO ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $MICRO_REF -OutFile "$env:TEMP\micro.zip"
    Extract-ZipFile "$env:TEMP\micro.zip" "$MD"
    Rename-Item "$MD\micro-*" "micro"
    Write-Host "`n--- MICRO downloaded ---" -ForegroundColor green
}

function Get-VIPManager {
    Write-Host "`n--- Download VIP-MANAGER ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $VIP_REF -OutFile "$env:TEMP\vip.zip"
    Extract-ZipFile "$env:TEMP\vip.zip" "$MD"
    Rename-Item "$MD\vip-manager*" "vip-manager"
    Remove-Item "$MD\vip-manager\*.yml" -ErrorAction Ignore
    Copy-Item "src\vip.yaml" "$MD\vip-manager"
    Write-Host "`n--- VIP-MANAGER downloaded ---" -ForegroundColor green
}

function Get-PostgreSQL {
    Write-Host "`n--- Download POSTGRESQL ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $PGSQL_REF -OutFile "$env:TEMP\pgsql.zip"
    Extract-ZipFile "$env:TEMP\pgsql.zip" "$MD"
    Remove-Item -Recurse -Force "$MD\pgsql\pgAdmin 4", "$MD\pgsql\symbols" -ErrorAction Ignore
    Write-Host "`n--- POSTGRESQL downloaded ---" -ForegroundColor green
}

function Get-Patroni {
    Write-Host "`n--- Download PATRONI ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $PATRONI_REF -OutFile "$env:TEMP\patroni.zip"
    Extract-ZipFile "$env:TEMP\patroni.zip" "$MD"
    Rename-Item "$MD\patroni-*" "patroni"
    Remove-Item "$MD\patroni\postgres?.yml" -ErrorAction Ignore
    Copy-Item "src\patroni.yaml" "$MD\patroni"
    Write-Host "`n--- PATRONI downloaded ---" -ForegroundColor green
}

function Update-PythonAndPIP {
    Write-Host "`n--- Update Python and PIP installation ---" -ForegroundColor blue
    & "./install-python.ps1"
    Move-Item "python-install.exe" "$MD"
    Write-Host "`n--- Python and PIP installation updated ---" -ForegroundColor green
}

function Get-PatroniPackages {
    Write-Host "`n--- Download PATRONI packages ---" -ForegroundColor blue
    Set-Location "$MD\patroni"
    & $PIP download -r requirements.txt -d .patroni-packages
    & $PIP download pip pip_install setuptools wheel cdiff psycopg2-binary -d .patroni-packages
    Set-Location -Path "..\.."
    Write-Host "`n--- PATRONI packages downloaded ---" -ForegroundColor green
}

function Get-WinSW {
    Write-Host "`n--- Download WINSW ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $WINSW_REF -OutFile "$MD\patroni\patroni_service.exe"
    Copy-Item "src\patroni_service.xml" "$MD\patroni"
    Copy-Item "$MD\patroni\patroni_service.exe" "$MD\etcd\etcd_service.exe" -Force
    Copy-Item "src\etcd_service.xml" "$MD\etcd"
    Copy-Item "$MD\patroni\patroni_service.exe" "$MD\vip-manager\vip_service.exe" -Force
    Copy-Item "src\vip_service.xml" "$MD\vip-manager"
    Write-Host "`n--- WINSW downloaded ---" -ForegroundColor green
}

function Export-Assets {
    Write-Host "`n--- Creating windows installer ---" -ForegroundColor blue
    if (-Not (Test-Path $INNOTOOL)) {
        Write-Host "$INNOTOOL does not exist" -ForegroundColor Red
        Write-Host "Please install Innotool and set the INNOTOOL environment variable." -ForegroundColor Red
        exit 1
    }
    & $ISCC $ISSFile
    Write-Host "`n--- Installer generated successfully ---" -ForegroundColor green

    Write-Host "`n--- Prepare archive ---" -ForegroundColor blue
    Compress-ToZipFile "$MD" "$MD.zip" 
    Write-Host "`n--- Archive compressed ---" -ForegroundColor green
}

Start-Bootstrapping
Get-VCRedist
Get-ETCD
Get-Micro
Get-VIPManager
Get-PostgreSQL
Get-Patroni
Update-PythonAndPIP
Get-PatroniPackages
Get-WinSW
Export-Assets
Write-Host "`n--- PACKAGING FINISHED ---" -ForegroundColor green