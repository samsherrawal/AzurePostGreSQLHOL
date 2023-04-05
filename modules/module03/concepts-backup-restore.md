
[< Previous Module](../modules/module02.md) - **[Home](../../README.md)** - [Next Module >](./ConnectPGSql.md)

# Backup and restore in Azure Database for PostgreSQL - Flexible Server



Backups form an essential part of any business continuity strategy. They help protect data from accidental corruption or deletion. 

Azure Database for PostgreSQL - Flexible Server automatically performs regular backups of your server. You can then do a point-in-time recovery (PITR) within a retention period that you specify. The overall time to restore and recovery typically depends on the size of data and the amount of recovery to be performed. 

## Backup overview

Flexible Server takes snapshot backups of data files and stores them securely in zone-redundant storage or locally redundant storage, depending on the region. The server also backs up transaction logs when the write-ahead log (WAL) file is ready to be archived. You can use these backups to restore a server to any point in time within your configured backup retention period. 

The default backup retention period is 7 days, but you can extend the period to a maximum of 35 days. All backups are encrypted through AES 256-bit encryption for data stored at rest.

These backup files can't be exported or used to create servers outside Azure Database for PostgreSQL - Flexible Server. For that purpose, you can use the PostgreSQL tools pg_dump and pg_restore/psql.

## Backup frequency

Backups on flexible servers are snapshot based. The first snapshot backup is scheduled immediately after a server is created. Snapshot backups are currently taken once daily. **The first snapshot is a full backup and consecutive snapshots are differential backups.**

Transaction log backups happen at varied frequencies, depending on the workload and when the WAL file is filled and ready to be archived. In general, the delay (recovery point objective, or RPO) can be up to 15 minutes.

## Backup redundancy options

Flexible Server stores multiple copies of your backups to help protect your data from planned and unplanned events. These events can include transient hardware failures, network or power outages, and natural disasters. Backup redundancy helps ensure that your database meets its availability and durability targets, even if failures happen. 

Flexible Server offers three options: 

- **Zone-redundant backup storage**: This option is automatically chosen for regions that support availability zones. When the backups are stored in zone-redundant backup storage, multiple copies are not only stored within the availability zone in which your server is hosted, but also replicated to another availability zone in the same region. 

  This option provides backup data availability across availability zones and restricts replication of data to within a country/region to meet data residency requirements. This option provides at least 99.9999999999 percent (12 nines) durability of backup objects over a year.  

- **Locally redundant backup storage**: This option is automatically chosen for regions that don't support availability zones yet. When the backups are stored in locally redundant backup storage, multiple copies of backups are stored in the same datacenter. 

  This option helps protect your data against server rack and drive failures. It provides at least 99.999999999 percent (11 nines) durability of backup objects over a year. 
  
  By default, backup storage for servers with same-zone high availability (HA) or no high-availability configuration is set to locally redundant. 

- **Geo-redundant backup storage**: You can choose this option at the time of server creation. When the backups are stored in geo-redundant backup storage, in addition to three copies of data stored within the region where your server is hosted, the data is replicated to a geo-paired region. 

  This option provides the ability to restore your server in a different region in the event of a disaster. It also provides at least 99.99999999999999 percent (16 nines) durability of backup objects over a year. 
  
  Geo-redundancy is supported for servers hosted in any of the Azure paired regions. 

## Moving from other backup storage options to geo-redundant backup storage 

You can configure geo-redundant storage for backup only during server creation. After a server is provisioned, you can't change the backup storage redundancy option.  

### Backup retention

Backups are retained based on the retention period that you set for the server. You can select a retention period between 7 (default) and 35 days. You can set the retention period during server creation or change it at a later time. Backups are retained even for stopped servers.

The backup retention period governs how far back in time a PITR can be retrieved, because it's based on available backups. You can also treat the backup retention period as a recovery window from a restore perspective. 

All backups required to perform a PITR within the backup retention period are retained in the backup storage. For example, if the backup retention period is set to 7 days, the recovery window is the last 7 days. In this scenario, all the data and logs that are required to restore and recover the server in the last 7 days are retained. 

### Backup storage cost

Flexible Server provides up to 100 percent of your provisioned server storage as backup storage at no additional cost. Any additional backup storage that you use is charged in gigabytes per month. 

For example, if you have provisioned a server with 250 gibibytes (GiB) of storage, then you have 250 GiB of backup storage capacity at no additional charge. If the daily backup usage is 25 GiB, then you can have up to 10 days of free backup storage. Backup storage consumption that exceeds 250 GiB is charged as defined in the [pricing model](https://azure.microsoft.com/pricing/details/postgresql/flexible-server/).

If you configured your server with geo-redundant backup, the backup data is also copied to the Azure paired region. So, your backup size will be two times the local backup copy. Billing is computed as *( (2 x local backup size) - provisioned storage size ) x price @ gigabytes per month*. 

You can use the [Backup Storage Used](../concepts-monitoring.md) metric in the Azure portal to monitor the backup storage that a server consumes. The Backup Storage Used metric represents the sum of storage consumed by all the retained database backups and log backups, based on the backup retention period set for the server. 


Please Note Irrespective of the database size, heavy transactional activity on the server generates more WAL files. The increase in files in turn increases the backup storage.

## Point-in-time recovery

In Flexible Server, performing a PITR creates a new server in the same region as your source server, but you can choose the availability zone. It's created with the source server's configuration for the pricing tier, compute generation, number of virtual cores, storage size, backup retention period, and backup redundancy option. Also, tags and settings such as virtual networks and firewall settings are inherited from the source server.

The physical database files are first restored from the snapshot backups to the server's data location. The appropriate backup that was taken earlier than the desired point in time is automatically chosen and restored. A recovery process then starts by using WAL files to bring the database to a consistent state. 

For example, assume that the backups are performed at 11:00 PM every night. If the restore point is for August 15 at 10:00 AM, the daily backup of August 14 is restored. The database will be recovered until 10:00 AM of August 15 by using the transaction log backup from August 14, 11:00 PM, to August 15, 10:00 AM. 

To restore your database server, see [these steps](./how-to-restore-server-portal.md).

Please Note A restore operation in Flexible Server always creates a new database server with the name that you provide. It doesn't overwrite the existing database server.

PITR is useful in scenarios like these:

- A user accidentally deletes data, a table, or a database.
- An application accidentally overwrites good data with bad data because of an application defect. 
- You want to clone your server for test, development, or for data verification.

With continuous backup of transaction logs, you'll be able to restore to the last transaction. You can choose between the following restore options:

-   **Latest restore point (now)**: This is the default option. It allows you to restore the server to the latest point in time. 

-   **Custom restore point**: This option allows you to choose any point in time within the retention period defined for this flexible server. By default, the latest time in UTC is automatically selected. Automatic selection is useful if you want to restore to the last committed transaction for test purposes. You can optionally choose other days and times. 

-   **Fast restore point**: This option allows users to restore the server in the fastest time possible within the retention period defined for their flexible server. Fastest restore is possible by directly choosing the timestamp from the list of backups. This restore operation provisions a server and simply restores the full snapshot backup and doesn't require any recovery of logs which makes it fast. We recommend you select a backup timestamp which is greater than the earliest restore point in time for a successful restore operation.

For latest and custom restore point options, the estimated time to recover depends on several factors, including the volume of transaction logs to process after the previous backup time, and the total number of databases recovering in the same region at the same time. The overall recovery time usually takes from few minutes up to a few hours.

If you've configured your server within a virtual network, you can restore to the same virtual network or to a different virtual network. However, you can't restore to public access. Similarly, if you configured your server with public access, you can't restore to private virtual network access.

Please Note A user can't restore deleted servers. If you delete a server, all databases that belong to the server are also deleted and can't be recovered. To help protect server resources from accidental deletion or unexpected changes after deployment, administrators can use management locks. 

If you accidentally deleted your server, please reach out to support. In some cases, your server might be restored with or without data loss.


## Geo-redundant backup and restore

To enable geo-redundant backup from the **Compute + storage** pane in the Azure portal, see the quickstart guide. 


Please Note Geo-redundant backup can be configured only at the time of server creation. 

After you've configured your server with geo-redundant backup, you can restore it to a geo-paired region. For more information, see the supported regions for geo-redundant backup.

When the server is configured with geo-redundant backup, the backup data and transaction logs are copied to the paired region asynchronously through storage replication. After you create a server, wait at least one hour before initiating a geo-restore. That will allow the first set of backup data to be replicated to the paired region. 

Subsequently, the transaction logs and the daily backups are asynchronously copied to the paired region. There might be up to one hour of delay in data transmission. So, you can expect up to one hour of RPO when you restore. You can restore only to the last available backup data that's available at the paired region. Currently, PITR of geo-redundant backups is not available.

The estimated time to recover the server (recovery time objective, or RTO) depends on factors like the size of the database, the last database backup time, and the amount of WAL to process until the last received backup data. The overall recovery time usually takes from a few minutes up to a few hours.

During the geo-restore, the server configurations that can be changed include virtual network settings and the ability to remove geo-redundant backup from the restored server. Changing other server configurations--such as compute, storage, or pricing tier (Burstable, General Purpose, or Memory Optimized)--during geo-restore is not supported.




Please Note When the primary region is down, you can't create geo-redundant servers in the respective geo-paired region, because storage can't be provisioned in the primary region. Before you can provision geo-redundant servers in the geo-paired region, you must wait for the primary region to be up. 
>
> With the primary region down, you can still geo-restore the source server to the geo-paired region. Disable the geo-redundancy option in the **Compute + Storage** > **Configure Server** settings in the portal, and restore as a locally redundant server to help ensure business continuity.  

## Restore and networking

### Point-in-time recovery

If your source server is configured with a *public access* network, you can only restore to public access. 

If your source server is configured with a *private access* virtual network, you can restore either to the same virtual network or to a different virtual network. You can't perform PITR across public and private access.

### Geo-restore

If your source server is configured with a *public access* network, you can only restore to public access. Also, you have to apply firewall rules after the restore operation is complete. 

If your source server is configured with a *private access* virtual network, you can only restore to a different virtual network, because virtual networks can't span regions. You can't perform geo-restore across public and private access.

## Post-restore tasks

After you restore the database, you can perform the following tasks to get your users and applications back up and running:

- If the new server is meant to replace the original server, redirect clients and client applications to the new server. Change the server name of your connection string to point to the new server.

- Ensure that appropriate server-level firewall and virtual network rules are in place for user connections. These rules are not copied over from the original server.
  
- Scale up or scale down the restored server's compute as needed.

- Ensure that appropriate logins and database-level permissions are in place.

- Configure alerts as appropriate.
  
## Next steps
[PostGreSQL Security] modules/module02a/secureAzurePG.md
