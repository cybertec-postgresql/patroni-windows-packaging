@ECHO off
SET MD=patroni-win-x64
SET ETCD_REF=https://github.com/etcd-io/etcd/releases/download/v3.3.13/etcd-v3.3.13-windows-amd64.zip
SET PATRONI_REF=https://github.com/zalando/patroni/archive/v1.5.6.zip


ECHO --- Start bootstrapping ---

RMDIR /Q /S %MD% patroni > nul
MKDIR %MD%
COPY src\*.* %MD%\

@ECHO on

@ECHO --- Download ETCD ---
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; ((new-object net.webclient).DownloadFile('%ETCD_REF%', '%TEMP%\etcd.zip'))"
powershell -Command "$shell = New-Object -ComObject Shell.Application; 	$zip_src = $shell.NameSpace('%TEMP%\etcd.zip'); $zip_dest = $shell.NameSpace((Resolve-Path '%CD%').Path); $zip_dest.CopyHere($zip_src.Items(), 1044)"
MOVE etcd-* %MD%\etcd

@ECHO --- Download PATRONI ---
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; ((new-object net.webclient).DownloadFile('%PATRONI_REF%', '%TEMP%\patroni.zip'))"
powershell -Command "$shell = New-Object -ComObject Shell.Application; 	$zip_src = $shell.NameSpace('%TEMP%\patroni.zip'); $zip_dest = $shell.NameSpace((Resolve-Path '%CD%').Path); $zip_dest.CopyHere($zip_src.Items(), 1044)"
MOVE patroni-* patroni

CD patroni
virtualenv.exe venv
CALL venv\Scripts\activate || EXIT /B 1
pip install -r requirements.txt || EXIT /B 1
pip install psycopg2-binary || EXIT /B 1
CALL venv\Scripts\deactivate || EXIT /B 1

MOVE venv ..\%MD%\venv
CD ..
MOVE patroni %MD%\patroni