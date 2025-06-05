# For PowerShell Core on Linux
# Important to Keep Your Sites Sorted: If Primary is first in your nested arrays, make sure it is first everywhere else.

# For your log file
$OutputPath = <local file/directory>
$OutputFile = "$OutputPath/dir/file.log"

$time = Get-Date

$dnsServer = ""
$targetServerAlias = @() #Optional: Use if servers have use an additional host record under an alternate name
$targetServersFQDN = @() #The ACTUAL server hostnames
# Nested array to sort primary/secondary site IP addresses. Remember to keep your primary/secondary groups ordered properly!
$serverIPs = @( @("primaryIP1", "primaryIP2", "etc"), @("secondaryIP1", "secondaryIP2", "etc")
              
$lastOctets = @()
$reverseZone = @("0.0.10.in-addr.arpa","0.1.10.in-addr.arpa")  #Primary First here as well

# Functions to update records using nsupdate command
function forwardRecords {
  #Here-string requires that no extra spaces/tabs are present
  $nsupdateCommand = @"
server $dnsServer
zone <forwardDnsZone>
update add $($targetServersAlias[$i]).contoso 600 A $($serverIPs[$j])
send
"@
  $nsupdateCommand | nsupdate
  "$time $($targetServersAlias[$i]).contoso -> $($serverIPs[$j]) DNS A Record Added." | Out-File -FilePath $OutputFile -Append
}

function reverseRecords {
  $nsupdateCommand = @"
server $dnsServer
update add $($lastOctets[$i]).$($reverseZone) 600 PTR $($targetServersFQDN[$j])
send
"@
  $nsupdateCommand | nsupdate
  "$time $(lastOctets[$i]).$($reverseZone) -> $(targetServerFQDN[$j]) DNS PTR Record Added." | Out-File -FilePath $OutputFile -Append
}

#The actual failover/restore functions
function AddDNSRecordsPrimary {
  for ($($i=0; $j=0); $i -lt $targetServersAlias.length; $($i++;$j++)) {
    forwardRecords
  }
  for ($($i=0; $j=0); $i -lt $lastOctets.length; $($i++;$j++)) {
    reverseRecords
  }
  "$time DNS Records Updated! Restore to PRIMARY SITE completed." | Out-File -FilePath $OutputFile -Append
  "$time Site/Application no longer in failover status." | Out-File -FilePath $OutputFile -Append
}

function AddDNSRecordsSecondary {
  for ($($i=0; $j=0); $i -lt $targetServersAlias.length; $($i++;$j++)) {
    forwardRecords
  }
  for ($($i=0; $j=0); $i -lt $lastOctets.length; $($i++;$j++)) {
    reverseRecords
  }
  "$time DNS Records Updated! Recovery to SECONDARY SITE completed." | Out-File -FilePath $OutputFile -Append
  "$time Site/Application in FAILOVER STATUS." | Out-File -FilePath $OutputFile -Append
}

# Running the functions
# Ping IP to determine where server is located
"$time Checking for server location..." | Out-File -FilePath $OutputFile -Append
$serverPING = @($serverIPs[0] | ForEach-Object -Process { (Test-Connection $_).Status }) #Because no Test-NetConnection in Linux PWSH
if ($serverPING -contains "Success") {
  "$time Servers Pingable at PRIMARY SITE. Adding DNS Entries..." | Out-File -FilePath $OutputFile -Append
  $serverIPs = $serverIPs[0]
  $reverseZone = $reverseZone[0]
  AddDnsRecordsPrimary
}
else {
  $serverPing = @($serverIPs[1] | ForEach-Object -Process { (Test-Connection $_).Status })
  if ($serverPING -contains "Success") {
    "$time Servers Pingable at SECONDARY SITE. Adding DNS Entries..." | Out-File -FilePath $OutputFile -Append
    $serverIPs = $serverIPs[1]
    $reverseZone = $reverseZone[1]
    AddDnsRecordsSecondary
  }
}
