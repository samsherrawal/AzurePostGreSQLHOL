[< Previous Module](./how-to-migrate-using-dump-and-restore.md) - **[Home](../../README.md)** - [Next Module >](../module02a/secureAzurePG.md)

# Module 03b - Migrate your PostgreSQL database using export and import

You can use [pg_dump](https://www.postgresql.org/docs/current/static/app-pgdump.html) to extract a PostgreSQL database into a script file and [psql](https://www.postgresql.org/docs/current/static/app-psql.html) to import the data into the target database from that file.

## Prerequisites
To step through this how-to guide, you need:
- An [Azure Database for PostgreSQL server](../single-server/quickstart-create-server-database-portal.md) with firewall rules to allow access and database under it.
- [pg_dump](https://www.postgresql.org/docs/current/static/app-pgdump.html) command-line utility installed
- [psql](https://www.postgresql.org/docs/current/static/app-psql.html) command-line utility installed

Follow these steps to export and import your PostgreSQL database.

## Create a script file using pg_dump that contains the data to be loaded
To export your existing PostgreSQL database on-premises or in a VM to a sql script file, run the following command in your existing environment:

```bash
pg_dump --host=<host> --username=<name> --dbname=<database name> --file=<database>.sql
```
For example, if you have a local server and a database called **dvdrental** in it:
```bash
pg_dump --host=localhost --username=masterlogin --dbname=dvdrental --file=dvdrental.sql
```

## Import the data on target Azure Database for PostgreSQL
You can use the psql command line and the --dbname parameter (-d) to import the data into the Azure Database for PostgreSQL server and load data from the sql file.

```bash
psql --file=<database>.sql --host=<server name> --port=5432 --username=<user> --dbname=<target database name>
```
This example uses psql utility and a script file named **testdb.sql** from previous step to import data into the database **dvdrental** on the target server **mydemoserver.postgres.database.azure.com**.

For **Flexible Server**, use this command  
```bash
psql --file=dvdrental.sql --host=mydemoserver.database.windows.net --port=5432 --username=myadmin --dbname=dvdrental
```



## Next steps
[Continue >](../module02a/secureAzurePG.md)


## Skip to Home
**[Home](../../README.md)**

