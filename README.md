# ps_DNSswap
Clean version of PowerShell pre/post scripts to modify DNS record.

### About

Due to Zerto migrating from a Windows-based installation to using a Linux-based ZVM appliance template (version 9.7+), this script was re-written for use on PowerShell Core for Linux. As it turns out, the DnsServer PowerShell module that we'd normally use to update DNS entries only exists in the Windows version. We don't have that same luxury for Linux. Hence, the extensive refactoring. Some here-string fuckery was required to pass commands into nsupdate. As always, please refer to the Zerto documentation at https://help.zerto.com for details on how to implement pre- and post-recovery PowerShell scripts to assist you in your disaster recovery plan.

### Overview

This script was originally written to take advantage of the pre-/post- script feature built into Zerto, a software solution that provides continuous data protection and replication across on-premises data centers and/or cloud environments. In many cases, network blocks at your production site may not match exactly with what you have in DR. While Zerto has the ability to change the network block and IP address on your compute resource, DNS, in many cases, can lag behind. A site failover that takes 5 minutes to execute in Zerto may take upwards of 15-30 minutes just because DNS entries haven't updated across your environment yet. You're either waiting, or frantically updating the records manually and initiating zone transfers.

That's where this script comes in. It speeds up the process by deleting the old record in the pre-recovery script (before Zerto fails over your replication group), then upon completion, re-adds the updated DNS entries at your primary DNS server/zone, to be picked up immediately by whatever application or system that needs to access it.

### Refactoring for the Zerto Linux Appliance

Because Zerto as a Linux Appliance, I had to account for some changes:
1. Zerto scripts are now uploaded via the Dashboard Web GUI (at both the primary site and DR site), versus on the servers directly.
2. Can't domain-join the appliances ☹️.
3. Could continue using a text file as a flag, but writing to the remote appliance would involve an authenticated SSH session, and .env files to store my domain admin credentials might go beyond what the appliance is capable of, and just isn't great practice if other admins have access.
4. Linux.... just..... Linux.

### What the scripts do
Prior to migration, the pre-script will ping scan the current DNS record to determine the location of the servers. Upon locating the records, the script will delete the records, and log the output to file.
After the server migration, Zerto will run the post-script file. The script will ping for the servers, attempting at each site until a successful ping is returned. A successful ping will determine the post-migration location of the servers, and the appropriate A/PTR DNS records will be added.
