@ECHO off

SET PIP=pip3.exe

@ECHO --- Installing Patroni packages ---
CD patroni
%PIP% install --no-index --find-links .patroni-packages -r requirements.txt
%PIP% install --no-index --find-links .patroni-packages psycopg2-binary
@ECHO --- Patroni packages installed ---

@ECHO --- You may close this terminal window ---