@ECHO off

SET "INNOTOOL=C:\Program Files (x86)\Inno Setup 6"

IF NOT EXIST "%INNOTOOL%" (
    ECHO !INNOTOOL! does not exist
    ECHO Please install Innotool and set the INNOTOOL environment variable.
    EXIT /B 1
)

CALL "%INNOTOOL%\iscc.exe" "installer\patroni.iss" || EXIT /B 1