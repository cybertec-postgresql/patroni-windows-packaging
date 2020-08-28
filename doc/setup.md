# PES (Patroni Environment Setup) on Windows

The package consists of:

- [patroni](https://github.com/zalando/patroni) HA
- [etcd](https://github.com/etcd-io/etcd) distributed key-value store
- [vip-manager](https://github.com/cybertec-postgresql/vip-manager) virtual IP manager
- [PostgreSQL](https://www.postgresql.org/) database itself
- [python](https://www.python.org/) runtime and packages
- [micro](https://github.com/zyedidia/micro) console editor

While the processes within `patroni` itself do not change much when running it under Windows, most challenges come from creating an environment in which patroni can run.

- `patroni` needs to be able to run PostgreSQL, this can only be done by unprivileged users.
- That unprivileged user in turn needs to be able to run Patroni, thus is needs access to Python.
- `patroni` needs to run as soon as the machine is booted up, without requiring anybody to log in and start anything.
- For that services are used under Windows. Since `etcd`, `patroni`, and `vip-manager` are not native Windows services, it is wise to use `[WinSW](https://github.com/winsw/winsw/)` wrapper for that.

# Installing all the things

You can choose two installation methods:

1. by Installer (.exe)
2. by unzipping (.zip) and running a PowerShell Script.

Both installation methods need to be run with **Administrator** privileges.

In either case, you will need to install everything into a path that can be made accessible to the unprivileged user that will later be used to run `patroni` and PostgreSQL.

This rules out any Paths that are below `C:\Users`

We recommend installing everything into a directory directly at the root of `C:\`, e.g. `C:\PES\` . The PostgreSQL data dir can still be located in another location, but this will also need to be made accessible to the user running PostgreSQL.

The PowerShell Script `install.ps1` needs to be run with special Execution Policy because it is not signed by us. You can verify the contents beforehand.
To change the Execution Policy only for the execution of the script:

```powershell
cd C:\PES
powershell.exe -ExecutionPolicy Bypass
.\install.ps1
REM waiting...
exit
```

During the installation, the script or the installer will try to create a new user `pes` and assign a randomly chosen password. This password will be printed on the screen, so make sure to note it down somewhere. Don't worry if you forget this password. You can check it in the `patroni\patroni_service.xml` file.

Afterward, the script or installer will make sure to grant access to the installation directory to the newly created user.

Should any of this user-creating or access-granting fail to work, here are the commands you can use (and adapt) yourself to fix it:

```powershell
REM add a user with a password:
net user username password /ADD

REM change the password only:
net user username newpassword
```

Even though a new user was just created, all remaining setup tasks need to be performed as an **Administrator**, primarily to register the Services.

Because PostgreSQL cannot be run by a "superuser", Patroni, and subsequently PostgreSQL is run by the `pes` user. Consequently, the user needs to be able to access the pgsql binaries, patroni configuration, patroni script and so on.

```powershell
REM grant full access to pes user:
icacls C:\PES\ /q /c /t /grant pes:F
```

Now is also a good time to add the Firewall rules that etcd, Patroni, and PostgreSQL need to function. Make sure the program paths match up with your system, especially if you're running a different Python install location.

```powershell
netsh advfirewall firewall add rule name="etcd" dir=in action=allow program="C:\PES\etcd\etcd.exe" enable=yes

netsh advfirewall firewall add rule name="postgresql" dir=in action=allow program="C:\PES\pgsql\bin\postgres.exe" enable=yes

netsh advfirewall firewall add rule name="python" dir=in action=allow program="C:\Program Files\Python38\python.exe" enable=yes
```

# Setup etcd

From the base directory `C:\PES\`, go into the `etcd` directory and create a file `etcd.conf`.

```yaml
name: 'win1'
data-dir: win1.etcd
heartbeat-interval: 100
election-timeout: 1000
listen-peer-urls: http://0.0.0.0:2380
listen-client-urls: http://0.0.0.0:2379
initial-advertise-peer-urls: http://192.168.178.88:2380
advertise-client-urls: http://192.168.178.88:2379
initial-cluster: win1=http://192.168.178.88:2380,win2=http://192.168.178.89:2380,win3=http://192.168.178.90:2380
initial-cluster-token: 'etcd-cluster'
initial-cluster-state: 'new'
enable-v2: true
```

The config file above is for three-node etcd clusters, which is the minimum recommended size.
You can go through and replace the IP-addresses in `initial-advertise-peer-urls`, `advertise-client-urls`, and `initial-cluster` to match those of your three cluster members-to-be.
The mapping `name=url` in the `initial-cluster` value needs to contain the matching `name` and `initial-advertise-peer-urls` of your cluster members.

When you're done adapting the above `etcd.conf` to your needs, copy it over to the other cluster members and change the name, and IP addresses or hostnames there accordingly.

To make sure that `etcd` can be run after boot, we need to create a Windows Service. Windows Services require the executable to behave in a particular fashion and to react to certain signals, all of which `etcd` cannot do. The simplest option is to use a wrapper that behaves in this fashion and in turn, launches `etcd` for us. One such wrapper (and the best option it seems) is [WinSW](https://github.com/winsw/winsw).

A copy of the `winsw.exe` executable is renamed `etcd_service.exe` and an accompanying `etcd_service.xml` config file is created. The config contains details on where to find the `etcd` executable, where the config file (`etcd.conf`) is located, and where the logs should go.

The next version of WinSW will allow to provide YAML configuration files.

## etcd service installation

```powershell
etcd_service.exe install
```

Will register the service that will later launch `etcd` automatically for us.

Apart from the messages on screen, you can check that the service is installed with:

```powershell
sc qc etcd
```

You should see that the start type for this service is set to auto, which means "start the service automatically after booting up".

Now that the service is installed, we need to create 

## etcd service running

Having installed the service, you can start it manually:

```powershell
> etcd_service.exe start
or
> net start etcd
or
> sc start etcd
```

You will need to go through the etcd Setup on all three hosts in order to successfully bootstrap the etcd cluster. Only after that you will be able to continue with the setup of Patroni.

## etcd checking

You can first take a look at `C:\PES\etcd\log\etcd_service.err.log`. If something went wrong during the installing or starting of the service already, the messages about that will be in `C:\PES\etcd\log\etcd_service.wrapper.log`.

If there are no critical errors in those files, you can check if the etcd cluster is working allright, assuming that you've started all other etcd cluster members:

```powershell
 C:\PES\etcd\etcdctl cluster-health
```

```powershell
PS C:\PES\etcd> .\etcdctl cluster-health
member 21f8508fe1bed56a is healthy: got healthy result from http://192.168.178.96:2379
member 381962e0d76a93eb is healthy: got healthy result from http://192.168.178.97:2379
member 49a65bc5e0e3e0ea is healthy: got healthy result from http://192.168.178.98:2379
cluster is healthy
```

This should list all of your etcd cluster members and indicate that they are all working.

If you receive any timeout errors or similar, something during the bootstrap went wrong.

If you figured out the error that was preventing successful bootstrap of the cluster, it is best practice to 1. stop all etcd members 2. remove all etcd data directories 3. fix the error 4. start all etcd members.

Some changes to the config (mainly those involving the initial cluster members and cluster name) will be ignored if the data dir has already been initialized.

# Setup Patroni

Warning: Do not begin setting up Patroni if your etcd cluster does not yet contain all cluster members, check `C:\PES\etcd\etcdctl cluster-health` to make sure. Otherwise you will have multiple Patroni instances who are not aware of their peers and will bootstrap on their own.

From the base directory `C:\PES\`, go into the `patroni` directory and create (or edit) a file `patroni.yml`.

```yaml
scope: pgcluster
namespace: /service/
name: win1

restapi:
  listen: 0.0.0.0:8008
  connect_address: 192.168.178.88:8008

etcd:
  hosts:
  - 192.168.178.88:2379
  - 192.168.178.89:2379
  - 192.168.178.90:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048906
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        logging_collector: true
        log_directory: log
        log_filename: postgresql.log
        wal_keep_segments: 50
      pg_hba:
      - host replication replicator 0.0.0.0/0 md5
      - host all all 0.0.0.0/0 md5

  initdb: 
  - encoding: UTF8
  - data-checksums

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 192.168.178.88:5432
  data_dir: C:/PES/pgsql/pgcluster_data
  bin_dir: C:/PES/pgsql
  authentication:
    replication:
      username: replicator
      password: reptilefluid
    superuser:
      username: postgres
      password: snakeoil

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
```

Under Windows one should double backslash path delimiter when used in patroni configuration, since it used as an escape character. To resolve the ambiguity we highly recommend to replace all backslashes with slashes in a folder names, e.g.
`data_dir: C:/PES/pgsql/pgcluster_data`

If you're running different Patroni clusters on top of the same etcd cluster, make sure to set a different `scope` (often reffered to as cluster name) for the different Patroni clusters.

Change the `name` (this is the name of a member within the cluster `scope` ) to your liking; This name needs to be different for each cluster member.
Setting the `name` to the hostname is often a good starting point.

Replace the IP address in `restapi.connect_address` with the host's own IP address or hostname. This address will be used for communication from other Patroni members to this one.

Replace the IP addresses in the `etcd.hosts` list to match the IP addresses or hostnames of your etcd cluster.

Change the IP address in the `postgresql.listen` section to the host's own IP address or hostname. This address will be used when Patroni needs to pull a backup from the primary or to create the Streaming Replication connections. If Streaming Replication and backups should use a dedicated NIC put the IP address registered on that NIC here.

If you intend to create a Patroni cluster from a preexisting PostgreSQL cluster, stop that cluster and put the location of that cluster's data directory into the `postgresql.data_dir` variable. If the PostgreSQL version of the preexisting cluster is different, change the `postgresql.bin_dir` accordingly. Make sure that the `pes` user can access both of those directories.

For a full list of configuration items and their description, please refer to the Patroni [Documentation](https://patroni.readthedocs.io/en/latest/SETTINGS.html).

When you're done adapting the above `patroni.yml` to your needs, copy it over to the other cluster members and change the name, and IP addresses or hostnames there accordingly.

The creation of the Patroni Service and start is similar to the procedure for `etcd`.
The major difference is that Patroni needs to be run as the `pes` user. For this reason, the `patroni_service.xml` contains the user name and password.

## patroni service installation

Create the service:

```powershell
C:\PES\patroni\patroni_service.exe install
```

Check the service:

```powershell
sc qc patroni
```

You should see that the start type for this service is set to auto, which means "start the service automatically after booting up".

## patroni service running

Start the service:

```powershell
> etcd_service.exe start
or
> net start etcd
or
> sc start etcd
```

It is recommended to start Patroni on one host first and check that it bootstrapped as expected, before starting the remaining cluster members. This is not to avoid race conditions, because Patroni can handle those fine. This recommendation is given mainly to make it easier to troubleshoot problems as soon as they arise.

## Check Patroni

You can first take a look at `C:\PES\patroni\log\patroni_service.err.log`. If something went wrong during the installing or starting of the service already, the messages about that will be in `C:\PES\patroni\log\patroni_service.wrapper.log`.

If the `patroni_service.err.log` contains messages like "starting PostgreSQL failed" or similar, check the PostgreSQL log as well, which should be located in `C:\PES\pgsql\pgcluster_data\log\`.

If there are no critical errors in those files, you can check if the Patroni cluster is working allright:

```powershell
 C:\PES\patronictl list
```

```powershell
PS C:\PES\patroni> python patronictl.py -c patroni.yml list
+ Cluster: pgcluster (6865748196457585920) --+----+-----------+
| Member |      Host      |  Role  |  State  | TL | Lag in MB |
+--------+----------------+--------+---------+----+-----------+
|  win1  | 192.168.178.96 |        | running |  2 |         0 |
|  win2  | 192.168.178.97 |        | running |  2 |         0 |
|  win3  | 192.168.178.98 | Leader | running |  2 |           |
+--------+----------------+--------+---------+----+-----------+
```

This should list all of your Patroni cluster members and indicate that they are all working.

If you are bootstrapping the cluster for the first time and the first cluster member did not yet show up, check the logs.

If there are cluster members that display "Start failed" in their status field, you need to examine the logs on those machines first.

# Setup vip-manager

From the base directory `C:\PES\`, go into the `vip-manager` directory and create a file `vip-manager.yml`.

```powershell
# time (in milliseconds) after which vip-manager wakes up and checks if it needs to register or release ip addresses.
interval: 1000

# the etcd or consul key which vip-manager will regularly poll.
key: "/service/pgcluster/leader"
# if the value of the above key matches the trigger-value (often the hostname of this host), vip-manager will try to add the virtual ip address to the interface specified in Iface
nodename: "win2"

ip: 192.168.178.123 # the virtual ip address to manage
mask: 24 # netmask for the virtual ip
iface: "Ethernet 2" #interface to which the virtual ip will be added

endpoint_type: etcd # etcd or consul
# a list that contains all DCS endpoints to which vip-manager could talk. 
endpoints:
  - http://192.168.178.96:2379
  - http://192.168.178.97:2379
  - http://192.168.178.98:2379

# how often things should be retried and how long to wait between retries. (currently only affects arpClient)
retry_num: 2
retry_after: 250  #in milliseconds
```

Change the `trigger-key` to match what the concatenation of these values from the patroni.yml gives: `<namespace> + "/" + <scope> + "/leader"` . Patroni store the current leader name in this key.

Change the `trigger-value` to the `name` in the `patroni.yml` of this host.

Change `ip`, `netmask`, `interface` to the virtual IP that will be managed and the appropriate netmask, as well as the networking interface on which the virtual IP should be registered.

Change the `endpoints` list to the list of all your etcd cluster members. Do not forget the protocol prefrix: `http://` here.

## vip-manager service installation

The creation of the vip-manager Service and start is similar to the procedure for etcd.
Create the service:

```powershell
C:\PES\vip-manager\vip-manager_service install
```

Check the service:

```powershell
sc qc vip-manager
```

You should see that the start type for this service is set to auto, which means "start the service automatically after booting up".

## vip-manager service running

Start the service:

```powershell
> vip-manager_service.exe start
or
> net start vip-manager
or
> sc start vip-manager
```

## Check vip-manager

You can first take a look at `C:\PES\vip-manager\log\vip-manager_service.err.log`. If something went wrong during the installing or starting of the service already, the messages about that will be in `C:\PES\vip-manager\log\vip-manager_service.wrapper.log`.

When vip-manager is working as expected, it should log messages like ...

```powershell
2020/08/28 01:24:36 reading config from C:\PES\vip-manager\vip-manager.yml
2020/08/28 01:24:36 IP address 192.168.178.123/24 state is false, desired false
2020/08/28 01:24:36 IP address 192.168.178.123/24 state is false, desired true
2020/08/28 01:24:36 Configuring address 192.168.178.123/24 on Ethernet 2
2020/08/28 01:24:36 IP address 192.168.178.123/24 state is true, desired true
2020/08/28 01:24:46 IP address 192.168.178.123/24 state is true, desired true
2020/08/28 01:24:56 IP address 192.168.178.123/24 state is true, desired true
2020/08/28 01:25:06 IP address 192.168.178.123/24 state is true, desired true
2020/08/28 01:25:16 IP address 192.168.178.123/24 state is true, desired true
2020/08/28 01:25:26 IP address 192.168.178.123/24 state is true, desired true
2020/08/28 01:25:36 IP address 192.168.178.123/24 state is true, desired true
```

# Check Patroni cluster is working as expected

- Trigger a couple of switchovers (`patronictl switchover <clustername>`) and observe (using `patronictl -w` that the demoted primary comes back up as a replica and clears its rewind state (i.e. switches to the new primary's timeline). Observe vip-manager log to make sure it is succesfully dropping the VIP on the old primary and registering it on the new primary.
- Trigger a reinit of a replica (`patronictl reinit <clustername> <membername>`).
- Reboot your machines at least once to check if all the services are starting as expected.
