@ECHO OFF

SETLOCAL

REM Set here your console [sic!] favorite editor
SET EDITOR=micro\micro.exe

python.exe patroni\patronictl.py -c postgres-win0.yml %*