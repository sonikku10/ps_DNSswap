# For PowerShell Core on Linux
# Important to Keep Your Sites Sorted: If Primary is first in your nested arrays, make sure it is first everywhere else.

#for your log file
$OutputPath = <local file/directory>
$OutputFile = "$OutputPath/dir/file.log"

$time = Get-Date

$dnsServer = ""
$targetServerAlias = @() #Optional: Use if servers have use an additional host record under an alternate name
$targetServersFQDN = @()
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
update add $($targetServersFQDN[$i] 600 A $($serverIPs[$j])
send
"@
  $nsupdateCommand | nsupdate
  "$time $($targetServersFQDN[$i] -> $($serverIPs[$j]) DNS A Record Added." | Out-File -FilePath $OutputFile -Append
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

function AddDNSRecords {
    #Ping IP to determine where server is located
    Write-Output "Checking for server location..." | Out-File -FilePath $OutputFile -Append
    $serverPING = @($serverIps[0] | ForEach-Object -Process { (Test-Connection $_).Status })
    if ($serverPING -contains "Success") {
        Write-Output "$time Servers Pingable at Primary Site. Adding DNS Entries..."  | Out-File -FilePath $OutputFile -Append
        $serverIps = $serverIPs[0]
        $reverseZone = $reverseZone[0]
        for ($($i=0; $j=0); $i -lt $tmsWebservers.length; $($i++;$j++)) {
            forwardRecords
        }
        for ($($i=0; $j=0); $i -lt $lastOctets.length; $($i++;$j++)) {
            reverseRecords
        }
        Write-Output "$time DNS Records Updated! Restore to PRIMARY SITE completed." | Out-File -FilePath $OutputFile -Append
        Write-Output "$time Site/Application no longer in failover status." | Out-File -FilePath $OutputFile -Append
    } else {
        $serverPING = @($serverIps[1] | ForEach-Object -Process { (Test-Connection $_).Status })
        if ($serverPING -contains "Success") {
            Write-Output "$time Servers Pingable at Secondary Site. Adding DNS Entries..." | Out-File -FilePath $OutputFile -Append
            $serverIps = $serverIps[1]
            $reverseZone = $reverseZone[1]
            for ($($i=0; $j=0); $i -lt $tmsWebservers.length; $($i++;$j++)) {
                forwardRecords
            }
            for ($($i=0; $j=0); $i -lt $lastOctets.length) {
                reverseRecords
            }
            Write-Output "$time DNS Records Updated! Recovery to SECONDARY completed." | Out-File -FilePath $OutputFile -Append
            Write-Output "$time Site/Application failover completed." | Out-File -FilePath $OutputFile -Append
        }
    }
}
