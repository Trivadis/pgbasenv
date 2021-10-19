# pgBasEnv - PostgreSQL Base Environment Tool

pgBasEnv is a tool to set environment for community PostgreSQL and EnterpriseDB versions 9.6+.

Check the [Change Log](CHANGELOG.md) for new features and changes introduced in new versions of the tool.

Functionality includes:

 - Discover installed homes and data directories
 - Print the information about homes and data directories
 - Set environment for selected homes or data directories
 - Export numerous variables with useful information about current entity

### Output example

      pgBasEnv v1.3 by Trivadis AG
    
    Installation homes:
    ┌─────────┬─────────┬─────────────────┬─────────────────────────────────┐
    │ALIAS    │     VER │         OPTIONS │ HOME DIR                        │
    ├─────────┼─────────┼─────────────────┼─────────────────────────────────┤
    │pgh9615  │  9.6.15 │       ssl:2G:8K │ /u01/app/postgres/product/9.6.15│
    │pgh115   │    11.5 │       ssl:2G:8K │ /u01/app/postgres/product/11.5  │
    │pgh1010  │   10.10 │       ssl:2G:8K │ /u01/app/postgres/product/10.10 │
    │pgh115A  │    11.5 │       ssl:1G:8K │ /usr/pgsql-11                   │
    │pgh1010A │   10.10 │       ssl:1G:8K │ /usr/pgsql-10                   │
    │pgh9615A │  9.6.15 │       ssl:1G:8K │ /usr/pgsql-9.6                  │
    │pgh120   │    12.0 │       ssl:1G:8K │ /usr/pgsql-12                   │
    └─────────┴─────────┴─────────────────┴─────────────────────────────────┘

    Cluster data directories:
    ┌───────┬───────┬──────┬───────┬─────────┬───────┬─────────────────────────┬──────────────────┬──────────────────────────────────┐
    │ALIAS  │   VER │ STAT │  PORT │     PID │  SIZE │ PGDATA                  │       LAST START │ LAST START HOME                  │
    ├───────┼───────┼──────┼───────┼─────────┼───────┼─────────────────────────┼──────────────────┼──────────────────────────────────┤
    │pgd96  │   9.6 │   UP │  5436 │   25107 │   39M │ /u02/pgdata/tbx06       │ 2020-02-13 16:28 │ /u01/app/postgres/product/9.6.15 │
    │pgd10  │    10 │ DOWN │       │         │   40M │ /u02/pgdata/newdb/data  │                  │                                  │
    │pgd10A │    10 │ DOWN │       │         │   40M │ /u02/pgdata/newdb/data2 │                  │                                  │
    │pgd12  │    12 │   UP │  5437 │   25309 │   41M │ /u02/pgdata/tbx07       │ 2020-02-13 16:30 │ /usr/pgsql-12                    │
    │pgd10B │    10 │   UP │  5435 │   31296 │   56M │ /u02/pgdata/tbx05       │ 2020-04-24 18:33 │ /u01/app/postgres/product/10.10  │
    │pgd96A │   9.6 │   UP │  5433 │   18854 │   39M │ /u02/pgdata/tbx03       │ 2020-04-22 12:23 │ /usr/pgsql-9.6                   │
    │pgd11  │    11 │ DOWN │       │         │  104M │ /u02/pgdata/tbx01       │ 2020-02-13 16:21 │ /usr/pgsql-11                    │
    │pgd11A │    11 │ DOWN │       │         │   40M │ /var/lib/pgsql/11/data  │ 2020-04-22 16:12 │ /u01/app/postgres/product/11.5   │
    │pgd10C │    10 │ DOWN │       │         │   40M │ /var/lib/pgsql/10/data  │ 2019-09-26 15:07 │ /usr/pgsql-10                    │
    └───────┴───────┴──────┴───────┴─────────┴───────┴─────────────────────────┴──────────────────┴──────────────────────────────────┘ 
    
    ---[pgd12]:
    
                  Cluster name: tbx07
             Installation home: /usr/pgsql-12
        Cluster data directory: /u02/pgdata/tbx07
                  Cluster port: 5437
                Cluster status: UP
               Cluster version: 12
            Cluster start time: 2020-02-13 16:30
       Size of all tablespaces: 25MB
          Cluster archive mode: off
                   Cluster age: 14
             Autovacuum status: ACTIVE
             Cluster databases: postgres,template1,template0
    
    ---[08.05.2020 13:00]


# License
The pgBasEnv is released under the APACHE LICENSE, VERSION 2.0, that allows a collaborative open source software development.


# Repository structure

There are few main folders:

    -- bin
    |
    -- etc
    |
    -- bundle
    |
    -- scripts

Folders `bin` and `etc` are relevant for developers.

Folder `bundle` includes ready to install bundle of the current tool version.

Usually bundle folder includes tar file and installer script.

If you will fork this repository to make modifications, then you should modify scripts in `bin` directory. After all modifications are done, then use `bundle.sh` script to create a new ready to install bundle in the `bundle` folder.

Folder `scripts` used to store any useful scripts. All scripts in this folder will be available from `psql` over special variables. Check the description on this page and `readme.txt` inside scripts folder.

# Installation and upgrade
There is installer script available in `bundle` directory to make installation process fast and easy. It has also silent execution mode which can be used for bulk installations.

To execute installation two files required:

 - `install_pgbasenv.sh`
 - `pgbasenv-[version].tar`

Both files must be in the same directory.

### \# install_pgbasenv.sh
Installer script, which will do the installation and upgrade.
It can be executed without arguments to do regular installation:

    $ ./install_pgbasenv.sh
If it is fresh installation for current user, then script will be executed in interactive mode.
It will ask to provide the installation location for the pgBasEnv. This directory will be the base directory for the TVD tools and will be indicated with variable `$TVDBASE`.

The value entered can also include variables, like `$MYSCRIPTS/pgs`.

Default value for `$TVDBASE` is `$HOME/tvdtoolbox`.

Inside `$TVDBASE` directory `pgbasenv` will be created. It will be the home for pgBasEnv and will be indicated with variable `$PGBASENV_BASE`.

Following two important environment files will be created in users home directory `$HOME`:

 - `.PGBASENV_HOME`
 - `.pgbasenv_profile`

File `.PGBASENV_HOME`will be used as entry point for pgBasEnv.
File `.pgbasenv_profile` can be used to source pgBasEnv global environment. It will be added by default to the users `~/.pgsql_profile` during installation. At next login pgBasEnv is sourced automatically.

> Note: The installer adds the entry to .pgsql_profile because .bash_profile is overwritten anytime when a new PostgreSQL binary is installed (e.g. with yum install) and pgBasEnv would not be sourced automatically at login.

To prevent the filesystem scan on each login, you can update `.pgbasenv_profile` file and add `--noscan` option to the `pgsetenv.sh` call.

Installer will ask for the following parameters which can affect the discovery process:
| Parameter | Default value |Description|
|--|--|--|
|`PGBASENV_EXCLUDE_DIRS`|`"tmp proc sys"`|The list of root level directories to skip during the discovery process.|
|`PGBASENV_EXCLUDE_FILESYSTEMS`|`"nfs tmpfs"`|The list of filesystem types to skip during the discovery process.|
|`PGBASENV_SEARCH_MAXDEPTH`|`7`|Maximum directory search depth during the discovery process.|

After providing values for these variables or accepting defaults, installer will discover all PostgreSQL or EnterproseDB installations and cluster data directories.

Each home and data directory will be assigned an alias name.

The list of all found homes and data directories will be printed, then user can choose the default alias name to set default environment. This environment will be set by default when you first log in.

The variable name is `PGBASENV_INITIAL_ALIAS`, if it will be left null, which is default, then pgBasEnv will set default alias automatically. Default alias will be identified according to next steps:

 1. Alias of the data directory with latest version of the up and running clusters.
 2. Alias of the data directory with latest version of the not running clusters.
 3. Alias of the installation home with latest version.

### Upgrade
If it is not the fresh installation, then script will use the already configured `$TVDBASE/pgbasenv` location and will updated scripts to the new versions. User specific config files will not be updated or modified.

Just execute `./install_pgbasenv.sh` from bundle direcotry. Latest version tar file will be installed by default.

### Force mode
To overwrite upgrade mode force option can be used. Then, installation script will behave like in fresh installation mode.

    $ ./install_pgbasenv.sh --force

### Silent mode
Silent mode can be used in scripts.

With silent mode all the parameters can be provided on command line, if some will be omitted then defaults will be used.

Example:

    $ ./install_pgbasenv.sh --silent TVDBASE=/u01/pgsql PGBASENV_EXCLUDE_DIRS="proc u04" PGBASENV_SEARCH_MAXDEPTH=10

*Silent option will be executed in **force** mode*.
 
 

# Directory structure

    $TVDBASE --
               |
               |-- pgbasenv --
                              |
                              |-- bin --
                              |         |
                              |         |-- pgbasenv.sh
                              |         |-- pgsetenv.sh
                              |         |-- pgup.sh
                              |         |-- pgstatus.sh
                              |         |-- scriptmgr.sh
                              |
                              |-- etc --
                                        |-- pgbasenv.conf
                                        |-- pgbasenv_standard.conf
                                        |-- pgclustertab
                                        |-- pghometab
                                        |-- *.env
Description of the scripts:

|Script|Func|Alias|Description|
|--|--|--|--|
|`pgbasenv.sh`|`pgbasenv`||Will do discovery and create/update pghometab and pgclustertab files.|
|`pgup.sh`|`pgup`|`u`|Will print the information from tab files and add runtime information to it.|
|`pgsetenv.sh`|`pgsetenv`||Sourcing script, it will set the global and object level environment.|
|`pgstatus.sh`|`pgstatus`|`sta`|Will print the information about currently set environment.|
|`scriptmgr.sh`|||Will be used to expose $PGBASENV_BASE/scripts contents to psql. Not for explicit execution.|

Each script will be exported to the current shell over the functions (Func column), it will make it possible to access them fast and from any location.

Like:

    $ pgbasenv --force
Because they are exported as a functions they will be also accessible from sub-shells. Generally it is recommended to use functions inside the scripts and aliases on the terminal.

Some of the mostly executed scripts has also shortcuts in form of aliases, like `u` and `sta`, to list all resources and print the current object status.

Folder `./etc` includes configuration files and tab files.

|File|Description  |
|--|--|
|`pgbasenv.conf` |File to set user specific variables. It can be modified by the user. It will be sourced to the environment after the pgbasenv_standard.conf. Will not be modified during upgrade mode.  |
|`pgbasenv_standard.conf`|Variables and aliases delivered by developer. Must not be modified, will be overwritten during upgrade mode. |
|`pghometab`|File which includes the list of all found installation homes and their properties including alias. Will not be modified during upgrade.|
|`pgclustertab`|List of all found cluster data directories and their properties including aliases. Will not be modified during upgrade.|
|`*.env`|Environment file for the alias. User can create [alias].env file to set alias specific environment |

# Tab files
Two tab files will be generated in the `$PGBASENV_BASE/etc` :

 - `pghometab`
 - `pgclustertab`


### pghometab

Has the following format:

    HOME;VERSION;[OPTIONS WITH_SSL:SEGMENT_SIZE:BLOCK_SIZE];ALIAS
It is the information, discovered by `pgbasenv`. Main field separator is `;`, the third column is composite column and includes three sub-columns delimited with `:`, these are: `WITH_SSL` indicated if home was with SSL support built, `SEGMENT_SIZE` second sub-column indicates the segment size set during the build and last third one `BLOCK_SIZE` indicates block size.

Column `ALIAS` will include the automatically generated alias name for the home.

The alias format is `pgh[VERSION]`, for example if there is home version 11.5 then alias will be `pgh115`, if there are two 11.5 homes installed, then second one will be `pgh115A`, and so on.

User can set its own alias for the homes. `pgbasenv` will not overwrite the aliases.

### pgclustertab

Has the following format:

    PGDATA;VERSION;HOME;PORT;ALIAS
Alias naming here is similar to the home alias naming, but with prefix `pgd`, like for data directory version 11 it will be `pgd11` and if the will be another one then `pgd11A` and so on.

In `pgclustertab` there are three columns which can be modified by the user: `HOME`, `PORT` and `ALIAS`.

All three will not be overwritten by `pgbasenv`.

The `pgup` will list the **pgclustertab** contents and will merge it with the runtime information.
If, for example, pgd11 alias has port defined as 5433 in the tab file but cluster is up and running from this data directory and actually has port 5445 then, `pgup` will show actual port 5445.

# Discovery
To discover the current installations and data directories `pgbasenv` can be used.

First discovery will be executed during installation.

To execute discovery again, in case if some new home was installed or new cluster was created, then `pgbasenv` can be manually executed.

By default it will updated existing **pghometab** and **pgclustertab** files.

There is option to forcefully re-create both tab files from scratch with `--force` option.

    $ pgbasenv --force

Discovery script will check the current user, if it will be `enterprisedb` then pgBasEnv will consider current environment as EnterpriseDB installation, in all other cases it will be treated as community version PostgreSQL.

To change this behaviour, user can export `PGBASENV_VENDOR` variable before installation or discovery process. Like this:

    $ export PGBASENV_VENDOR=enterprisedb
    $ pgbasenv
The value of the `PGBASENV_VENDOR` can be `enterprisedb` or `postgres`.

# Listing current homes and data directories
To list current installation homes and data directories use `pgup` function or `u` alias.

It will print out the user friendly tables, see example on top of this document.

It is possible to get the output in script fredly format, just add `--list` argument:

    $ pgup --list
    pgd96;9.6;UP;5436;25107;39M;/u02/pgdata/tbx06;2020-02-13 16:28;/u01/app/postgres/product/9.6.15
    pgd10;10;DOWN;;;40M;/u02/pgdata/newdb/data;;
    pgd12;12;UP;5437;25309;41M;/u02/pgdata/tbx07;2020-02-13 16:30;/usr/pgsql-12
    pgd10B;10;UP;5435;31296;56M;/u02/pgdata/tbx05;2020-04-24 18:33;/u01/app/postgres/product/10.10

The output is only for data directories and includes also runtime information.

# Setting environment
To set environment from the terminal special aliases can be used.

Each alias in the `pgup` output has associated shell alias.

For example:

        Cluster data directories:
    ===============================================================================================================================
    ALIAS  |   VER | STAT |  PORT |     PID |  SIZE | PGDATA                  |       LAST START | LAST START HOME
    ===============================================================================================================================
    pgd96  |   9.6 |   UP |  5436 |   25107 |   39M | /u02/pgdata/tbx06       | 2020-02-13 16:28 | /u01/app/postgres/product/9.6.15
    pgd10  |    10 | DOWN |       |         |   40M | /u02/pgdata/newdb/data  |                  |
    pgd10A |    10 | DOWN |       |         |   40M | /u02/pgdata/newdb/data2 |                  |
    pgd12  |    12 |   UP |  5437 |   25309 |   41M | /u02/pgdata/tbx07       | 2020-02-13 16:30 | /usr/pgsql-12
    pgd10B |    10 |   UP |  5435 |   31296 |   56M | /u02/pgdata/tbx05       | 2020-04-24 18:33 | /u01/app/postgres/product/10.10
    pgd96A |   9.6 |   UP |  5433 |   18854 |   39M | /u02/pgdata/tbx03       | 2020-04-22 12:23 | /usr/pgsql-9.6

You can set environment for the `/u02/pgdata/tbx07` directory, just enter its alias on the shell prompt `pgd12`:

    node1:/usr/home/pg $ pgd12
    
    ---[pgd12]:
    
                  Cluster name: tbx07
             Installation home: /usr/pgsql-12
        Cluster data directory: /u02/pgdata/tbx07
                  Cluster port: 5437
                Cluster status: UP
               Cluster version: 12
            Cluster start time: 2020-02-13 16:30
       Size of all tablespaces: 25MB
          Cluster archive mode: off
                   Cluster age: 14
             Autovacuum status: ACTIVE
             Cluster databases: postgres,template1,template0
    
    ---[08.05.2020 17:04]
    
    node1:/usr/home/pg [pgd12]$ _


> Note: If cluster is not running from the data directory at the moment of environment sourcing and PORT was not explicitly defined in  `pgclustertab` then *PGPORT* will be set to *1*. We are doing it because if it will be set to null then libpq will use default port 5432 (or whatever configured during build). In this case, there can be some other cluster which is already running on this port. That means all database tools will connect to the incorrect cluster. By setting it to 1 we prevent such dangerous behavior. After you will start the cluster you must source environment for the database cluster to actualize its status and port information.
But the best way to prevent such situations is to define the port explicitly in *pgclustertab* file.

Environment will be set and the output from `pgstatus` will be printed out.

Each time when environment set for the specific alias, `pgsetenv` will check `$PGBASENV_BASE/etc` folder for the env file named after alias.
When we set environment for `pgd12` then file `$PGBASENV_BASE/etc/pgd12.env` will be also sourced. When you will switch environment to some other alias, then `pgd12.env` will be unset from the environment.

After setting data directory alias, alias per database will be also created. Database aliases has format db.(db name), like db.salesdb.

Database aliases will export PGDATABASE with appropriate value and call psql.

Bash prompt will also set to include current alias name.

It is possible to combine data directory alias with installation home alias.

On example above **pgd10**, has no installation home associated, most probably that it was never started. To start using particular installation home, for example home **pgh1010**,  you can combine both of them like this:

    $ pgd10 pgh1010

Then you can manipulate your cluster using binaries from **pgh1010** home.


### pgsetenv
The script responsible for setting environment is `pgsetenv`.

It stays behind the above described aliases.

It is possible to directly execute `pgsetenv` function from the shell or inside the scripts.

Examples:

    $ pgsetenv pgd10
    $ pgsetenv pgd10 pgh1010
 It is also possible to set environment by data directory, like this:
 

    $ pgsetenv /u02/pgdata/tbx05
Can be used inside the scripts, eliminates lookup for the alias name.

Another option for `pgsetenv` is the argument `--default`. When executed with this argument, the environment for default alias will be set. It will identified based on variable `PGBASENV_INITIAL_ALIAS` in the `$PGBASENV_BASE/etc/pgbasenv.conf` file.

By default `pgsetenv` will scan the filesystem to find any new installations and data directories. Sometimes it is better to source without scanning, in this case use `--noscan` option.


`pgsetenv` will source following resources to the current shell: 
 
|Name|Type|Description|
|--|--|--|
|`TVDBASE`|Variable|Base directory for TVD Tools.|
|`PGBASENV_BASE`|Variable|Base directory for pgBasEnv|
|`TVDPGOPERATE_BASE`|Variable|Base directory for TVD-PgOperate|
|`pglogfile`|function|Will print the current logfile of the Logging Collector|
|`pgunsetenv`|function|To unset global environment|
|`pgunsetclsenv`|function|To unset alias specific environment|


If `pgsetenv` will be executed without any arguments then it will set the global environment. Which includes:

 - The variables and aliases from **pgbasenv_standard.conf**
 - The variables and aliases from **pgbasenv.conf**
 - `TVD_PGUP_CLUSTERS` variable, the list of aliases of the UP clusters

If `pgsetenv` will be executed for specific home alias, then following variables will be set:
|Name|Description  |
|--|--|
|`PGBASENV_ALIAS`|Current alias name|
|`TVD_PGHOME`|Installation home directory|
|`PGLOCALEDIR`|Will be set to `$TVD_PGHOME/share/locale`|
|`EDBHOME`|In case of EnterpriseDB will be set to installation home directory|

Variable `$MANPATH` will be updated to include `$TVD_PGHOME/share/man`.
Variable `$PATH` will be updated to include `$TVD_PGHOME/bin`.

For the data directory alias the following variables will be set:

> If data directory has associated home directory, then all variables
> for the home will be set. As mentioned above.

Variables will be set, if it will be possible to discover them, if not, they will not be set.

|Variable|Description  |
|--|--|
|`TVD_PGCLUSTER_NAME` | Cluster name |
|`PGDATA`|Data directory|
|`PGPORT`|Current port|
|`PGSQL_BASE`|PgOperate related. If parameters_<alias>.conf file exists, then PGSQL_BASE from it will be sourced|
|`PGBASENV_ALIAS`|Current alias name|
|`TVD_PGSTATUS`|The status, UP or DOWN|
|`TVD_PGVERSION`|Data directory version|
|`TVD_PGSTART_TIME`|Last time cluster was started|
|`TVD_PGIS_STANDBY`|Is standby or not, YES or NO|
|`TVD_PGIS_INRECOVERY`|Is standby in recovery or note, YES or NO|
|`TVD_PGMASTER_HOST`|Master host name|
|`TVD_PGMASTER_PORT`|Master port|
|`TVD_PGSTANDBY_STATUS`|Status of the wal reveiver process from pg_stat_wal_receiver.|
|`TVD_PGCLUSTER_SIZE`|The size of all tablespaces in human readable format|
|`TVD_PGCLUSTER_DATABASES`|List of all databases in cluster|
|`TVD_PGUSER_DATABASES`|List of all user created database in cluster|
|`TVD_PGAUTOVACUUM_STATUS`|Status of the autovacuum, ACTIVE or NOTACTIVE|
|`TVD_PGCLUSTER_AGE`|The transaction age of the cluster|
|`TVD_PGLOG_COLLECTOR`|Is Logging Collector enabled or nor, on or off|
|`TVD_PGLOG_DIR`|Log directory|
|`TVD_PGLOG_FILE`|The logfile pattern|
|`TVD_PGCONF`|The config file of the cluster. postgresql.conf.|
|`TVD_PGHBA`|The hba conf file pg_hba.conf|
|`TVD_PGARCHIVE_MODE`|Is cluster in archive log mode, on or off|

To get the current logfile name, use function `pglogfile`, if logging collector is enabled then it will return the name of the logfile:

    $ cat $(pglogfile)

Use `sta` alias or `pgstatus` function to print the values of the some this variables on the screen. The values of some variables will be printed in red or green depending on the value. For example if autovacuum is not active then it will be red, if active then green.

There are also some very useful aliases, like `vic` which will open *postgresql.conf* with vi for you.
Check the `$PGBASENV_BASE/etc/pgbasenv_standard.conf` for the predefined variables and aliases.

You can define you own or overwrite defaults one in `$PGBASENV_BASE/etc/pgbasenv.conf` file.


# Custom scripts in $PGBASENV_BASE/scripts folder

Each script in this directory will be available in the `psql` under special variables.

Copy any script into this directory, then call `psql` from any location.

Enter the variable "`:scripts`" in `psql` prompt. It will list you all the scripts available for current PostgreSQL version.

```
postgres=# :scripts

 pgBaseEnv scripts:
┌───────────────────────────────┬─────────────┬──────────────────────────────────────────────────────────────────────────┐
│ Name (Variable)               │ Min. Version│ Description                                                              │
├───────────────────────────────┼─────────────┼──────────────────────────────────────────────────────────────────────────┤
│ :myscript1                    │ *           │ Script description here                                                  │
│ :myscript2                    │ 12          │ Second script description                                                │
└───────────────────────────────┴─────────────┴──────────────────────────────────────────────────────────────────────────┘
 Count: 2
```
It will be enough to enter "`:myscript1`" to execute the script.

```
postgres=# :myscript1
```

You can put special descriptors in your scripts:
```
-- NAME: <script_name_without_space> (Max length 30 characters)
-- VERSION: <minimum major PostgreSQL version supported for this script> (Must be a number)
-- DESCRIPTION: <description of the script> (Max length 73 characters)
```

Example:
```
-- NAME: index_stats
-- VERSION: 12
-- DESCRIPTION: Collect postgres index stats.

select ....
  from ....
  where ....;
```

This script will not be listed in psql version 11, but will be available in version 12 and later.

If `NAME` descriptor will not be found or null, then script name, without ".sql" part will be used.

If `VERSIONS` descriptor will not be found or null, then script will be available on all versions.

If `DESCRIPTION` descriptor will not be found or null, then no description will be displayed.

To execute from command line use pipe, `-c` will not work:
```
$ echo ":myscript1" | psql
```


# Using pgBasEnv in scripts

All of the listed above variables can be accessed from the scripts also.

If you write the script which will be executed in some other shell and not in the current one, the you will need first source pgbasenv.

Then you can set environment based on alias or data directory.

For example you want to start backup on standby site only, then your script will look like this:

    # Source pgbasenv
    source $HOME/.pgbasenv_profile

    # Call pgsetenv to set environment for your data directory
    # You can use data directory itself
    pgsetenv /u02/pgdata/tbx05
    
    # or its alias
    pgsetenv pg12
    
    # Now all the variables, functions and aliases are available for you

    if [[ $TVD_PGIS_STANDBY == "YES" ]]; then
      pg_basebackup -D /u01/backup
    fi

