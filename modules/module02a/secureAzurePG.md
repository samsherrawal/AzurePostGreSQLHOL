[< Previous Module](../module02/how-to-migrate-using-export-and-import.md) - **[Home](../../README.md)** - [Next Module >](../module03/concepts-backup-restore.md)


# Introduction

Azure Database for PostgreSQL uses multiple layers of security to protect data. In this module we will learn about the Azure Database for PostgreSQL security module, the built-in server roles, and how to grant permissions to database users. We will also learn about how encryption protects data at rest, and in transit.

In this module, we will learn how to:

* Describe Azure Database for PostgreSQL security.
* Describe built-in Azure Database for PostgreSQL server roles.
* Grant permissions in Azure Database for PostgreSQL.
* Understand encryption in Azure Database for PostgreSQL.

# Describe Azure Database for PostgreSQL security

Azure Database for PostgreSQL uses multiple layers of security to protect data. These include:

* Data encryption
* Network security
* Access management

# Data encryption
Azure Database for PostgreSQL encrypts data in transit and at rest. This is discussed in Understand encryption in Azure Database for PostgreSQL.

# Network security

Azure Database for PostgreSQL flexible server provides two networking options:

* Private access. You create your server in an Azure virtual network with private network communication and using private IP addresses. Security rules in network security groups enable you to filter the type of network traffic that can flow in and out of virtual network subnets and network interfaces.

* Public access. The server can be accessed through a public endpoint with a publicly resolvable DNS address. A firewall blocks all access by default. You can create IP firewall rules to grant access to servers based on the originating IP address of each request.

Please Note: When you create an Azure Database for PostgreSQL flexible server you select either Private access or Public access. Once your server has been created, you cannot change your network option.

Both options control access at the server level, not at the database or table level. Use PostgreSQL roles to grant or deny access to database, table, and other objects.

You also manage access to the server by creating firewall rules to allow connections only from known IP address ranges.

# Access management

When you create an Azure Database for PostgreSQL server, you also create an admin account. This administrator account can be used to create more [PostgreSQL roles](https://www.postgresql.org/docs/current/user-manag.html). A role is a database user or group of users. Access to an Azure Database for PostgreSQL server is authenticated with a username, password and the permissions granted or denied to the role.

# SCRAM authentication

Most access to an Azure Database for PostgreSQL server relies on passwords. However, it is possible to use SCRAM authentication, a secure password authentication protocol that can authenticate the client without revealing the user's cleartext password to the server. Salted Challenge Response Authentication Mechanism (SCRAM) is designed to make man-in-the-middle attacks more difficult. To enable SCRAM authentication:

* In the Azure portal, navigate to your Azure Database for PostgreSQL flexible server, and under Settings, select Server parameters.
* In the search bar, enter password_encryption. The two parameters listed both default to MD5. If you want to use SCRAM, change both parameters to SCRAM-SHA-256:
    - password_encryption
    - azure.accepted_password_auth_method

Save changes.

# Built-in Azure Database for PostgreSQL server roles

PostgreSQL manages database access using roles. A role can be a database user or a group of users. Roles can:

* Own database objects such as tables or functions.
* Assign privileges on those objects to other roles.
* Grant membership to another role, allowing the member role to have their privileges.

Your Azure Database for PostgreSQL server is created with three default roles:

* azure_pg_admin
* azuresu
* server admin user - part of the azure_pg_admin role

View all the server roles by executing the following query:

SELECT * FROM pg_roles;

Please Note Azure Database for PostgreSQL is a managed PaaS service and only Microsoft users have the azuresu (super user) role.

When you created your server, a server admin user was also created. This user automatically became a member of the azure_pg_admin role. The Azure Database for PostgreSQL server admin user has the following privileges: LOGIN, NOSUPERUSER, INHERIT, CREATEDB, CREATEROLE, REPLICATION

Now, the server admin user account that you created when the server was created, can:

* Create more users and grant those users into the azure_pg_admin role.
* Create less privileged users and roles that have access to individual databases and schemas.

PostgreSQL includes some default roles that can be assigned to users. These include commonly needed privileges for access:

* pg_read_all_settings
* pg_signal_backend
* pg_read_server_files
* pg_write_server_files
* pg_execute_server_program


There are also more specialist roles:

* pg_monitor
* pg_read_all_stats
* pg_stat_scan_tables
* replication

# Create admin users in Azure Database for PostgreSQL

* In Azure Data Studio (or your preferred client tool), connect to your Azure Database for PostgreSQL server with the admin sign-in credentials.
* Edit the following SQL code by replacing the placeholders with your username and password:


CREATE ROLE <new_user> WITH LOGIN NOSUPERUSER INHERIT CREATEDB CREATEROLE NOREPLICATION PASSWORD '<StrongPassword!>';
GRANT azure_pg_admin TO <new_user>;

# Grant permissions in Azure SQL Database for PostgreSQL

To allow users access to databases hosted on your Azure Database for PostgreSQL server, you must create roles (users) and grant or deny privileges to database objects.

# Create database users in Azure Database for PostgreSQL

* In Azure Data Studio (or your preferred client tool), connect to your Azure Database for PostgreSQL server with the admin sign-in credentials.

* With the relevant database as the current database, use CREATE ROLE with the relevant options to create a new role (user).

As an example, the following query:

* Creates a new database named Mydb.
* Creates a new user with a strong password.
* Grants connect privileges to the Mydb database.

CREATE DATABASE Mydb;
CREATE ROLE <db_user> WITH LOGIN NOSUPERUSER INHERIT CREATEDB NOCREATEROLE NOREPLICATION PASSWORD '<StrongPassword!>';
GRANT CONNECT ON DATABASE Mydb TO <db_user>;

To try the query, you can replace the placeholders with your user information.

* You can then grant additional privileges to objects within the database. For example:

GRANT SELECT ON ALL TABLES IN SCHEMA <schema_name> TO <db_user>;

The syntax for CREATE ROLE is:

CREATE ROLE name [ [ WITH ] option [ ... ] ]

where option can be:

SUPERUSER | NOSUPERUSER
| CREATEDB | NOCREATEDB
| CREATEROLE | NOCREATEROLE
| INHERIT | NOINHERIT
| LOGIN | NOLOGIN
| REPLICATION | NOREPLICATION
| BYPASSRLS | NOBYPASSRLS
| CONNECTION LIMIT connlimit
| [ ENCRYPTED ] PASSWORD 'password' | PASSWORD NULL
| VALID UNTIL 'timestamp'
| IN ROLE role_name [, ...]
| ROLE role_name [, ...]
| ADMIN role_name [, ...]

# Understand encryption in Azure Database for PostgreSQL

Azure Database for PostgreSQL automatically encrypts data both in transit, and at rest. You don't need to do anything, encryption's enabled by default.

# Data at rest

Azure Database for PostgreSQL flexible server supports encryption for data at rest by using Azure storage encryption. Encryption's always on and uses Microsoft's managed keys. The encryption uses FIPS 140-2 validated cryptographic module and an AES 256-bit cipher.

# Data in transit

Azure Database for PostgreSQL secures data in transit with Transport Layer Security (TLS) and SSL by default.

Flexible server supports TLS 1.2 and 1.3 and can't be disabled.

In the Azure portal, navigate to your Azure Database for PostgreSQL server. Under Settings, select Server Parameters. In the Search bar, enter TLS.

* ssl_min_protocol_version - allows you to set the minimus SSL/TLS version to use. This parameter is set to TLS V1.2 by default.
* ssl_max_protocol_version - allows you to set the maximum SSL/TLS version to use.

# Exercise: Create a new user account in Azure Active Directory

1. In the Azure portal, sign in using an Owner account and navigate to your Azure Active Directory.

2. Under Manage, select Users.

3. At the top-left, select New user and then select Create new user.

4. In the New user page, enter these details and then select Create:

* Username: John
* Name: John Doe
* Password: Select Let me create password and then type Welcome2023.

Please Note When the user is created, make a note of the full User principal name so that you can use it later to log in.

# Assign the Reader role

1. In the Azure portal, select All resources and then select your Azure Database for PostgreSQL resource.
2. Select Access control (IAM) and then select Role assignments. Holly Rees doesn't appear in the list.
3. Select + Add and then select Add role assignment.
4. Select the Reader role, and then select Next.
5. Add John Doe to the list of members and then select Next.
6. Select Review + Assign.

# Test the Reader role
1. In the top-right of the Azure portal, select your user account and then select Sign out.
2. Sign in as the new user, with the user principal name that you noted and the password Welcome2023. Replace the default password if you're prompted to and make a note of the new one.
3. In the portal home page, select All resources and then select your Azure Database for PostgreSQL resource.
4. Select Stop. An error is displayed, because the Reader role enables you to see the resource but not change it.

# Assign the Contributor role
1. In the top-right of the Azure portal, select John's user account and then select Sign out.
2. Sign in using your original Owner account.
3. Navigate to your Azure Database for PostgreSQL resource, and then select Access Control (IAM).
4. Select + Add and then select Add role assignment.
5. Select the Contributor role, and then select Next.
6. Add John Doe to the list of members and then select Next.
7. Select Review + Assign.
8. Select Role Assignments. John Doe now has assignments for both Reader and Contributor roles.

# Test the Contributor role
1. In the top-right of the Azure portal, select your user account and then select Sign out.
2. Sign in as the John Doe, with the user principal name and password that you noted.
3. In the portal home page, select All resources and then select your Azure Database for PostgreSQL resource.
4. Select Stop and then select Yes. This time, the server stops without errors because Holly has the necessary role assigned.
5. Select Start to ensure that the PostgreSQL resource is ready for the next steps.
6. In the top-right of the Azure portal, select John's user account and then select Sign out.
7. Sign in using your original Owner account.

# GRANT access to Azure Database for PostgreSQL

1. Open Azure Data Studio and connect to your Azure Database for PostgreSQL server.

2. In the query pane, execute this code. Twelve user roles should be returned, including the demo role that you're using to connect:

SELECT rolame FROM pg_catalog.pg_role;

3. To create a new role, execute this code

CREATE ROLE dbuser WITH LOGIN NOSUPERUSER INHERIT CREATEDB NOCREATEROLE NOREPLICATION PASSWORD 'Welcome2023';
GRANT CONNECT ON DATABASE mydb TO dbuser;

4. To list the new role, execute the above SELECT query again. You should see the dbuser role listed.

5. To enable the new role to query and modify data in the customer table in the mydb database, execute this code:

GRANT SELECT, INSERT, UPDATE, DELETE ON customer TO dbuser;

# Test the new role
1. In Azure Data Studio, in the list of CONNECTIONS select the new connection button.

2. In the Connection type list, select PostgreSQL.

3. In the Server name textbox, type the fully qualified server name for your Azure Database for PostgreSQL resource. You can copy it from the Azure portal.

4. In the Authentication type list, select Password.

5. In the Username textbox, type dbuser and in the Password textbox type Welcome2023.

6. Select the Remember password checkbox and then select Connect.

7. Select New query and then execute this code:

SELECT * FROM customer;

8. To test whether you have the UPDATE privilege, execute this code:

UPDATE customer SET name = 'Jane Doe' WHERE cust_id = 7;
 SELECT * FROM cusotmer;

 9. To test whether you have the DROP privilege, execute this code. If there's an error, examine the error code:

 DROP TABLE cusotmer;

 10. To test whether you have the GRANT privilege, execute this code:

 GRANT ALL PRIVILEGES ON customer TO dbuser;

 These tests demonstrate that the new user can execute Data Manipulation Language (DML) commands to query and modify data but can't use Data Definition Language (DDL) commands to change the schema. Also, the new user can't GRANT any new privileges to circumvent the permissions.

 # Summary

 In this module, you've learned about the multiple layers of security that Azure Database for PostgreSQL uses to protect data. You've learned about the built-in server roles created when you create an Azure Database for PostgreSQL server. You've also learned how to create and grant permissions to database users and how Azure Database for PostgreSQL encrypts your data at rest, and in transit.

Now that you've completed this module, you're able to:

* Describe Azure Database for PostgreSQL security.
* Describe built-in Azure Database for PostgreSQL server roles.
* Grant permissions in Azure Database for PostgreSQL.
* Understand encryption in Azure Database for PostgreSQL.




# Next Module
[Backup & Restore in Azure PostGreSQL](../module03/concepts-backup-restore.md)




