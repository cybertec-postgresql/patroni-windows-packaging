# patroni-windows-packaging
Automate installing and launching of Patroni under Windows

## Install
There are two ways to set up patroni cluster:
1. For manual one, please, check the [Setup Guide](doc/setup.md);
2. You may use [PES](https://github.com/cybertec-postgresql/PES) Graphical User Interface (included in the package) for automated setup.

## Build
1. Run `make.bat`
2. Deploy `PES.zip` or `Patroni-Env-Setup.exe` installer

**Dependencies**:
* `curl`
* `PowerShell`
* [Inno Setup](https://github.com/jrsoftware/issrc)

`curl` and `powershell` both present in Windows 10 build 17063 and later. However, one may install them on earlier OSes and get the same result.

## Authors
[Pavlo Golub](https://github.com/pashagolub) and [Julian Markwort](https://github.com/markwort)
