@ECHO OFF

SETLOCAL

REM Set here your console [sic!] favorite editor
SET EDITOR=micro\micro.exe
REM Pager for edit-config diffs; plain "more" fails because it is more.com, not more.exe
IF NOT DEFINED PAGER SET PAGER=more.com

python.exe patroni\patronictl.py -c patroni\patroni.yaml %*
