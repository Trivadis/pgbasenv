### v1.5

* Additional information about standby status and incoming data stream will be reported. Now status of the wal receiver and master node:port will be reported. Standby status string: `Cluster role: STANDBY [ Status: streaming Master: masternode:5435 In recovery: YES ]`. As usual all these information will be available from the evn variables `TVD_PGMASTER_HOST`, `TVD_PGMASTER_PORT` and `TVD_PGSTANDBY_STATUS`.
* Timeouts was added to find commands to prevent hangs. Parameter `PGBASENV_SEARCH_TIMEOUT` can be set in pgbasenv.conf to control this timout. By default it is 5 sec.

### v1.4

* Added support of SUSE Linux.
* Other minor changes.

### v1.3

* `$PGBASENV_BASE/scripts` was introduced to store the user scripts and inject them into psql. The list of the scripts will be available in psql under `:scripts` variable. Each script can be executed by enetering its own variable name. It is possible to define on which PostgreSQL version the particular script will be visible. Check corresponding section in main README.md file for details.
* To prevent *pgclustertab* and *pghometab* corruption during simultaneous execution, operations will be executed over `flock` utility. It will guarantee a sequential access to those files and  `pgbasenv.sh` execution.
* New styling was added to the output of the `u` alias (`pgup.sh`).
* Other minor changes.

### v1.9
* `pgsetenv.sh` now accepts `--noscan` option. It will source the *pgBaseEnv* without scanning the filesystem. This argument can be used also in `$HOME/.pgbasenv_profile` to prevent filesystem scan every time on login.