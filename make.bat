@ECHO off
SET MD=output
SET ETCD_REF=https://github.com/etcd-io/etcd/releases/download/v3.3.13/etcd-v3.3.13-windows-amd64.zip
SET PATRONI_REF=https://github.com/zalando/patroni/archive/v1.5.6.zip


ECHO --- Start bootstrapping ---

RMDIR /Q /S %MD% patroni
MKDIR %MD%
copy src\*.* %MD%\

@ECHO on


rem @ECHO --- Download ETCD ---
rem powershell -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; ((new-object net.webclient).DownloadFile('%ETCD_REF%', '%TEMP%\etcd.zip'))"
rem powershell -Command "$shell = New-Object -ComObject Shell.Application; 	$zip_src = $shell.NameSpace('%TEMP%\etcd.zip'); $zip_dest = $shell.NameSpace((Resolve-Path '%CD%').Path); $zip_dest.CopyHere($zip_src.Items(), 1044)"
rem MOVE etcd-* output\etcd

@ECHO --- Download PATRONI ---
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; ((new-object net.webclient).DownloadFile('%PATRONI_REF%', '%TEMP%\patroni.zip'))"
powershell -Command "$shell = New-Object -ComObject Shell.Application; 	$zip_src = $shell.NameSpace('%TEMP%\patroni.zip'); $zip_dest = $shell.NameSpace((Resolve-Path '%CD%').Path); $zip_dest.CopyHere($zip_src.Items(), 1044)"
MOVE patroni-* patroni

rem CD patroni
rem virtualenv.exe venv || EXIT /B 1
rem CALL venv\Scripts\activate || EXIT /B 1
rem pip install -r requirements.txt || EXIT /B 1
rem pip install psycopg2-binary || EXIT /B 1
rem CALL venv\Scripts\deactivate || EXIT /B 1