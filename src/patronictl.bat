@ECHO OFF

SETLOCAL

SET PYTHONPATH=venv\Scripts

REM Set here yuour favourite editor
SET EDITOR=notepad.exe

%PYTHONPATH%\python.exe patroni\patronictl.py -c postgres-win0.yml %*