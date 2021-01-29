
Each script in this directory will be available in the psql under special variable.

Copy the script into this directory, then call psql from any location.

Enter the ":scripts" in psql prompt. It will list you all the scripts available for current PostgreSQL version.

postgres=# :scripts

 Name (Variable)               | Versions       | Description
======================================================================================================================
 :myscript1                    | *              | Script description here
 :myscript2                    | 12,13          | Second script description
======================================================================================================================
Count: 2

It will be enough to enter ":myscript1" to execute the script.

postgres=# :myscript1

You can put special descriptors in your scripts:

-- NAME: <script_name_without_space>
-- VERSIONS: <comma separated major versions on which this script can run>
-- DESCRIPTION: <description of the script>

Example:

-- NAME: index_stats
-- VERSIONS: 12,13
-- DESCRIPTION: Collect postgres index stats.


If NAME descriptor will not be found or null, then script name, without ".sql" part will used.
If VERSIONS descriptor will not be found or null, then script will be available on all versions.
If DESCRIPTION descriptor will not be found or null, then no description.

To execute from command line use pipe, -c will not work:
$ echo ":myscript1" | psql


