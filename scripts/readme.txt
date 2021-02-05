
Each script in this directory will be available in the psql under special variables.

Copy the script into this directory, then call psql from any location.

Enter the ":scripts" in psql prompt. It will list you all the scripts available for current PostgreSQL version.

postgres=# :scripts

 pgBaseEnv scripts:
┌───────────────────────────────┬─────────────┬──────────────────────────────────────────────────────────────────────────┐
│ Name (Variable)               │ Min. Version│ Description                                                              │
├───────────────────────────────┼─────────────┼──────────────────────────────────────────────────────────────────────────┤
│ :myscript1                    │ *           │ Script description here                                                  │
│ :myscript2                    │ 12          │ Second script description                                                │
└───────────────────────────────┴─────────────┴──────────────────────────────────────────────────────────────────────────┘
 Count: 2

It will be enough to enter ":myscript1" to execute the script.

postgres=# :myscript1

You can put special descriptors in your scripts:

-- NAME: <script_name_without_space> (Max length 30 characters)
-- VERSION: <minimum major PostgreSQL version supported for this script> (Must be a number)
-- DESCRIPTION: <description of the script> (Max length 73 characters)

Example:

-- NAME: index_stats
-- VERSION: 12
-- DESCRIPTION: Collect postgres index stats.

This script will not be listed in psql version 11, but will be available in version 12 and later.

If NAME descriptor will not be found or null, then script name, without ".sql" part will be used.
If VERSION descriptor will not be found or null, then script will be available on all versions.
If DESCRIPTION descriptor will not be found or null, then no description.

To execute from command line use pipe, -c will not work:
$ echo ":myscript1" | psql


