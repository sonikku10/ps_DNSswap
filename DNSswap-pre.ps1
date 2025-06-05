# For PowerShell Core on Linux
# Important to Keep Your Sites Sorted: If Primary is first in your nested arrays, make sure it is first everywhere else.

#for your log file
$OutputPath = <local file/directory>
$OutputFile = "$OutputPath/dir/file.log>

$time = Get-Date

$dnsServer = ""
$targetServerAlias = @() #Optional: Use if servers have use an additional host record under an alternate name
$targetServersFQDN = @()
$lastOctets = @()
$reverseZone = @("0.0.10.in-addr.arpa","0.1.10.in-addr.arpa")  #Primary First here as well

#Use dig to pull list of PTR records
$PTRRecordsPrimary = dig AXFR $reverseZone[0] @$dnsServer +short
$PTRRecordsSecondary = dig AXFR $reverseZone[1] @$dnsServer +short

# Functions to remove current records using nsupdate command
function forwardRecords {
  #Here-string requires that no extra spaces/tabs are present
  $nsupdateCommand = @"
server $dnsServer
zone <forwardDnsZone>
update delete $_
send
"@
  $nsupdateCommand | nsupdate
}

function reverseRecords {
  $nsupdateCommand = @"
server $dnsServer
update delete $_.$reverseZone
send
"@
  $nsupdateCommand | nsupdate
}

#The ACTUAL Failover/Failback Functions
#Pre-Script: Recover to Secondary Site
function RemovePrimarySiteDnsEntries {
  "$time Site/Application is not yet in Failover Status. Removing DNS Entries..." | Out-File -FilePath $OutputFile -Append
  $targetServersFQDN | ForEach-Object -Process {
    forwardRecords
    "$time $_ DNS A Record Deleted." | Out-File -FilePath $OutputFile -Append
  }
  $LastOctets | ForEach-Object -Process {
    reverseRecords
    "$time $reverseZone $_ DNS PTR Record Deleted." | Out-File -FilePath $OutputFile -Append
  }
}

#Pre-Script: Restore to Primary Site
function RemoveSecondarySiteDnsEntries {
  "$time Site/Application is in FAILOVER STATUS. Removing DNS Entries..." | Out-File -FilePath $OutputFile -Append
  $targetServersFQDN | ForEach-Object -Process {
    forwardRecords
    "$time $_ DNS A Record Deleted." | Out-File -FilePath $OutputFile -Append
  }
  $LastOctets | ForEach-Object -Process {
    reverseRecords
    "$time $reverseZone $_ DNS PTR Record Deleted." | Out-File -FilePath $OutputFile -Append
  }
}

#Running the Functions
if ($targetServersFQDN | ForEach-Object -Process { $PTRRecordsPrimary -match $_ }) {
  $reverseZone = $reverseZone[0]
  RemovePrimarySiteDnsEntries
}
if ($targetServersFQDN | ForEach-Object -Process { $PTRRecordsSecondary -match _ }) {
  $reverseZone = $reverseZone[1]
  RemoveSecondarySiteDnsEntries
}
