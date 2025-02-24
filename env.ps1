$MD = "PES"
$VCREDIST_REF = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$ETCD_REF = "https://github.com/etcd-io/etcd/releases/download/v3.5.18/etcd-v3.5.18-windows-amd64.zip"
$PATRONI_REF = "https://github.com/patroni/patroni/archive/refs/tags/v4.0.5.zip"
$MICRO_REF = "https://github.com/zyedidia/micro/releases/download/v2.0.14/micro-2.0.14-win64.zip"
$WINSW_REF = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW.NET461.exe"
$VIP_REF = "https://github.com/cybertec-postgresql/vip-manager/releases/download/v3.0.0/vip-manager_3.0.0_Windows_x86_64.zip"
$PGSQL_REF = "https://get.enterprisedb.com/postgresql/postgresql-17.4-1-windows-x64-binaries.zip"
$PYTHON_REF = "https://www.python.org/ftp/python/3.13.2/python-3.13.2-amd64.exe"
# one should change python version in github action workflows when changed here

$SEVENZIP = "C:\Program Files\7-Zip\7z.exe"

$INNOTOOL = "C:\Program Files (x86)\Inno Setup 6"
$ISCC = Join-Path $INNOTOOL "iscc.exe"
$ISSFile = "installer\patroni.iss"
