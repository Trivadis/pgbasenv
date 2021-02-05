

### v1.3

* `$PGBASENV_BASE/scripts` was introduced to store the user scripts and inject them into psql. The list of the scripts will be available in psql under `:scripts` variable. Each script can be executed by enetering its own variable name. It is possible to define on which PostgreSQL version the particular script will be visible. Check corresponding section in main README.md file for details.
* To prevent *pgclustertab* and *pghometab* corruption during simultaneous execution, operations will be executed over `flock` utility. It will guarantee a sequential access to those files and  `pgbasenv.sh` execution.
* New styling was added to the output of the `u` alias (`pgup.sh`).
* Other minor changes.

