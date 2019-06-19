@ECHO OFF

SETLOCAL

REM Set here yuour favourite editor
SET EDITOR=notepad.exe

python.exe patroni\patronictl.py -c postgres-win0.yml %*