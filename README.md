>[!IMPORTANT]
>This script will NOT work with the Zerto Linux Appliance as of version 10.0_U7 and should instead be used as guidance for similar functions/scenarios.

# ps_DNSswap
Clean version of PowerShell pre/post scripts to modify DNS record.

### About

Due to Zerto migrating from a Windows-based installation to using a Linux-based ZVM appliance template (version 9.7+), this script was re-written for use on PowerShell Core for Linux. As it turns out, the DnsServer PowerShell module that we'd normally use to update DNS entries only exists in the Windows version. We don't have that same luxury for Linux. Hence, the extensive refactoring. Some here-string fuckery was required to pass commands into nsupdate. As always, please refer to the Zerto documentation at https://help.zerto.com for details on how to implement pre- and post-recovery PowerShell scripts to assist you in your disaster recovery plan.

### Overview

This script was originally written to take advantage of the pre-/post- script feature built into Zerto, a software solution that provides continuous data protection and replication across on-premises data centers and/or cloud environments. In many cases, network blocks at your production site may not match exactly with what you have in DR. While Zerto has the ability to change the network block and IP address on your compute resource, DNS, in many cases, can lag behind. A site failover that takes 5 minutes to execute in Zerto may take upwards of 15-30 minutes just because DNS entries haven't updated across your environment yet. You're either waiting, or frantically updating the records manually and initiating zone transfers.

That's where this script comes in. It speeds up the process by deleting the old record in the pre-recovery script (before Zerto fails over your replication group), then upon completion, re-adds the updated DNS entries at your primary DNS server/zone, to be picked up immediately by whatever application or system that needs to access it.

### Refactoring for PowerShell Core for Linux

Because Zerto as a Linux Appliance, I had to account for some changes:
1. Zerto scripts are now uploaded via the Dashboard Web GUI (at both the primary site and DR site), versus on the servers directly.
2. Can't domain-join the appliances ☹️.
3. Could continue using a text file as a flag, but writing to the remote appliance would involve an authenticated SSH session, and .env files to store my domain admin credentials might go beyond what the appliance is capable of, and just isn't great practice if other admins have access.
4. PowerShell limitations in Linux.

### What the scripts (are supposed to) do
>[!NOTE]
>This script assumes that your primary/secondary sites are on different subnets, and that your servers' primary NIC relies on them. This also assumes that if the server is hosting a web application, it's on a secondary NIC on a separate DMZ subnet that otherwise won't be affected. 

- Pre-script: Uses the current reverse DNS record to determine the location of the servers. Upon locating the records, the script will delete the records, and log the output to file.
- Post-script: Pings for server location at each site. A successful ping will determine the post-migration location of the servers, and the appropriate A/PTR DNS records will be added.

### Why the script does not work in Zerto
So it took Zerto literally breaking for me to figure out why the script doesn't work correctly during migration tests. It gave me an opportunity to take a deep dive into how everything is put together (versus with the Windows-based install) while getting a bit of a Kubernetes intro crash course in the process.

Since Zerto shifted their ZVM appliance to the Linux platform, they have changed the architecture and _how_ it operates. Each function is broken into separate Kubernetes pods. From the authentication piece, to the internal database, management console, and, yes, the `script-service`. Neither the appliance nor the "application" itself runs the script. It's passed to a separate service to run from that specific k8s pod. And that's where we hit our roadblock.
```
zadmin@local.server:~$ kubectl exec -it scripts-service-85dbc9bcd4-fx5l9 -- "/bin/bash"
zerto@scripts-service-85dbc9bcd4-fx5l9:/app$ nsupdate
bash: nsupdate: command not found
zerto@scripts-service-85dbc9bcd4-fx5l9:/app$ dig
bash: dig: command not found
zerto@scripts-service-85dbc9bcd4-fx5l9:/app$ ping
bash: ping: command not found
```
The necessary utilities for this script to function do not exist in the pod. And while the PowerShell cmdlet `Test-Connection` is available to use based on the installed PS modules within this pod, it actually cannot function because it relies on the ping utility.

Without modifying the default vendor configuration, it's not a choice that I would personally make without official support/documentation.
Until Zerto adds additional functionality in their pods, we're stuck.
