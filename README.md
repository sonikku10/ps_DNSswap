# ps_DNSswap
Clean version of PowerShell pre/post scripts to modify DNS record.

### About
This PowerShell 5.1 version was written for use on Windows Server 2019+ with Zerto 9.5 installed.
Please refer to the Zerto documentation at https://help.zerto.com for details on how to implement pre- and post-recovery PowerShell scripts to assist you in your disaster recovery plan.

### Overview
This script was originally written to take advantage of the pre-/post- script feature built into Zerto, a software solution that provides continuous data protection and replication across on-premises data centers and/or cloud environments. In many cases, network blocks at your production site may not match exactly with what you have in DR. While Zerto has the ability to change the network block and IP address on your compute resource, DNS, in many cases, can lag behind. A site failover that takes 5 minutes to execute in Zerto may take upwards of 15-30 minutes just because DNS entries haven't updated across your environment yet. You're either waiting, or frantically updating the records manually and initiating zone transfers.

That's where this script comes in.
It speeds up the process by deleting the old record in the pre-recovery script (before Zerto fails over your replication group), then upon completion, re-adds the updated DNS entries at your primary DNS server/zone, to be picked up immediately by whatever application or system that needs to access it.

### What the scripts do
Because the Zerto service runs on a Windows Server, the pre-script checks for a text file to see if it's either at the primary Zerto server, or the on the Zerto server hosted at the DR site. The text file acts as a flag to determine if the application is has already been failed over or not. If it's not present, then the app is not failed over. The script will proceed to add the text file, then remove the server DNS records in prepartion for the server migration.

After the server migration, Zerto will run the post-script file. Again, the script will check for the presence of this file. If the file is present (indicating that the app should be in "failover mode"), then new DNS records will be added with the approprite records to reflect the updated IP address/subnet.

For rollback, or migrating back to the primary site, the pre-script will delete the existing text file so that the post-script sees that the application is no longer in failover status and to add in DNS records for the primary site.
