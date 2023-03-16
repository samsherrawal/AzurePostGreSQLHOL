

# What is Azure Database for PostgreSQL?

Azure Database for PostgreSQL is a managed database solution that provides highly available, massively scalable PostgreSQL in the cloud. The solution is made up of two tightly integrated layers: PostgreSQL, and specialized Azure services. You’re provided with all the features of the community edition of PostgreSQL [PostgreSQL open source relational database](https://www.postgresql.org/), with the security, reliability, and performance you expect from Azure.

Azure Database for PostgreSQL delivers:

- Built-in high availability.
- Data protection using automatic backups and point-in-time-restore for up to 35 days.
- Automated maintenance for underlying hardware, operating system and database engine to keep the service secure and up to date.
- Predictable performance, using inclusive pay-as-you-go pricing.
- Elastic scaling within seconds.
- Enterprise grade security and industry-leading compliance to protect sensitive data at-rest and in-motion.
- Monitoring and automation to simplify management and monitoring for large-scale deployments.
- Industry-leading support experience.

# The Azure layer

PostgreSQL in Azure has two services, Azure Database for PostgreSQL and Azure Cosmos DB for PostgreSQL.

Azure Database for PostgreSQL is available in two deployment modes, with each deployment mode allowing different levels of customization and scale.

Flexible server is suitable for production workloads that require zone resilient HA, predictable performance, maximum control, custom maintenance window, cost optimization controls and simplified developer experience. Ideal for workloads that don't need full compute capacity continuously.

# Data protection and security benefits

Data is automatically encrypted and backed up. Options such as Advanced Threat Protection make it simple to address potential threats without the need to be a security expert or manage advanced security monitoring systems.

The example of a contactless payment app having a simple and reliable way to back up your database means you can focus on developing your app. Also, Advanced Threat Protection means it will be easier for you to mitigate threats if they arise during a trial, without having to rely on expert security personnel.

# Lower administrative complexity and cost

For many businesses, the decision to transition to a cloud service is as much about offloading the complexity of administration as it is about cost. Azure helps to lower administrative costs in three key ways.

Azure automates maintenance and updates for the underlying hardware, operating system, and the database engine (minor versions).
Azure provides automated management and analytics for monitoring of large-scale deployments.
Together these capabilities can allow for significant cost savings, especially when many databases need to be supported.

## Deployment models

Azure Database for PostgreSQL powered by the PostgreSQL community edition is available in three deployment modes,
However, we will be focusing Flexible Server.

### Azure Database for PostgreSQL - Flexible Server

Azure Database for PostgreSQL Flexible Server is a fully managed database service designed to provide more granular control and flexibility over database management functions and configuration settings. In general, the service provides more flexibility and customizations based on the user requirements. The flexible server architecture allows users to opt for high availability within single availability zone and across multiple availability zones. Flexible Server provides better cost optimization controls with the ability to stop/start server and burstable compute tier, ideal for workloads that don’t need full-compute capacity continuously. The service currently supports community version of PostgreSQL 11, 12, 13 and 14, with plans to add newer versions soon. The service is generally available today in wide variety of Azure regions.

Flexible servers are best suited for

- Application developments requiring better control and customizations
- Cost optimization controls with ability to stop/start server
- Zone redundant high availability
- Managed maintenance windows

## Overview

Azure Database for PostgreSQL - Flexible Server is a fully managed database service designed to provide more granular control and flexibility over database management functions and configuration settings. In general, the service provides more flexibility and server configuration customizations based on the user requirements. The flexible server architecture allows users to collocate database engine with the client-tier for lower latency,  choose high availability within a single availability zone and across multiple availability zones. Flexible servers also provide better cost optimization controls with ability to stop/start your server and burstable compute tier that is ideal for workloads that do not need full compute capacity continuously. The service currently supports community version of [PostgreSQL 11, 12, 13, and 14](./concepts-supported-versions.md). The service is currently available in wide variety of  [Azure regions](https://azure.microsoft.com/global-infrastructure/services/).

![Flexible Server - Overview](./overview-flexible-server.png)

Flexible servers are best suited for

- Application developments requiring better control and customizations.
- Zone redundant high availability
- Managed maintenance windows
  
## Architecture and high availability

The flexible server deployment model is designed to support high availability within a single availability zone and across multiple availability zones. The architecture separates compute and storage. The database engine runs on a container inside a Linux virtual machine, while data files reside on Azure storage. The storage maintains three locally redundant synchronous copies of the database files ensuring data durability.

If zone redundant high availability is configured, the service provisions and maintains a warm standby server across availability zone within the same Azure region. The data changes on the source server are synchronously replicated to the standby server to ensure zero data loss. With zone redundant high availability, once the planned or unplanned failover event is triggered, the standby server comes online immediately and is available to process incoming transactions. This allows the service resiliency from availability zone failure within an Azure region that supports multiple availability zones as shown in the picture below.

![high-availability-architecture](./concepts-zone-redundant-high-availability-architecture.png)

