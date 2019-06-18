@ECHO on

@ECHO --- Installing Python runtime ---
python-install.exe /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
@ECHO --- Python runtime installed ---

@ECHO --- Installing Patroni packages ---
python -m pip install --upgrade pip
CD patroni
pip install --no-index --find-links .patroni-packages -r requirements.txt
pip install --no-index --find-links .patroni-packages psycopg2-binary
@ECHO --- Patroni packages installed ---
