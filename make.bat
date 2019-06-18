@ECHO off
SET MD=patroni-win-x64
SET ETCD_REF=https://github.com/etcd-io/etcd/releases/download/v3.3.13/etcd-v3.3.13-windows-amd64.zip
SET PATRONI_REF=https://github.com/zalando/patroni/archive/v1.5.6.zip


ECHO --- Start bootstrapping ---

RMDIR /Q /S %MD% patroni > nul 2>&1
MKDIR %MD%
COPY src\*.* %MD%\

@ECHO --- Update Python and PIP installation ---
@CALL install-env.bat
MOVE python-install.exe %MD%\
@ECHO --- Python and PIP installation updated ---

@ECHO --- Download ETCD ---
curl %ETCD_REF% --location --output %TEMP%\etcd.zip
powershell -Command "Expand-Archive '%TEMP%\etcd.zip' '%CD%'"
MOVE etcd-* %MD%\etcd
@ECHO --- ETCD downloaded ---

@ECHO --- Download PATRONI ---
curl %PATRONI_REF% --location --output %TEMP%\patroni.zip
powershell -Command "Expand-Archive '%TEMP%\patroni.zip' '%CD%'"
MOVE patroni-* patroni
@ECHO --- PATRONI downloaded ---

@ECHO --- Download PATRONI packages ---
CD patroni
pip download -r requirements.txt -d .patroni-packages
pip download psycopg2-binary -d .patroni-packages
@ECHO --- PATRONI packages downloaded ---

CD ..
MOVE patroni %MD%\patroni

@ECHO --- Prepare archive ---
powershell -Command "Compress-Archive '%MD%' '%MD%.zip'"
@ECHO --- Archive compressed ---

@ECHO --- PACKAGING FINISHED ---