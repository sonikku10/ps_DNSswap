#For PowerShell 5.1 on Windows Server

$time = Get-Date

$dnsServer = ""
$targetServers = @()
$lastOctets = @()

if((Test-Path <path-to-text-file>) -or (Test-Path <path-to-failover-site-text-file>)) {
  Write-Host "Site/Application in FAILOVER STATUS."

  #Pre-Script: Restore to Primary Site
  $targetServers | %{ Remove-DnsServerResourceRecord -ComputerName $dnsServer -ZoneName <forward_dnsZone> -RRType "A" -Name "$_" -Confirm:$false -Force }
  $lastOctets | %{ Remove-DnsServerResourceRecord -ComputerName $dnsServer -ZoneName <secondary_reverse_dnsZone> -RRType "PTR" -Name "$_" -Confirm:$false -Force }
} 
else {
  #Pre-Script: Recover to Secondary Site
  Write-Host "Site/Application is not yet in Failover Status."
  $targetServers | %{ Remove-DnsServerResourceRecord -ComputerName $dnsServer -ZoneName <forward_dnsZone> -RRType "A" -Name "$_" -Confirm:$false -Force }
  $lastOctets | %{ Remove-DnsServerResourceRecord -ComputerName $dnsServer -ZoneName <primary_reverse_dnsZone> -RRType "PTR" -Name "$_" -Confirm:$false -Force }
}
