SETLOCAL

SET PYTHONPATH=venv\Scripts

START etcd\etcd.exe --data-dir=data\etcd

%PYTHONPATH%\python.exe patroni\patroni.py %*