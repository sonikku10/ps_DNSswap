# For PowerShell 5.1 on Windows Server

$time = Get-Date

$dnsServer = ""
$targetServers = @()
$serverIPsSecondary = @()
$serverIPsPrimary = @()

# Post-Script: After servers have been recovered back to the primary site
if ((Test-Path <path-to-text-file>) -or (Test-Path <path-to-failover-site-text-file>)) {
  for ($i=0; $i -lt $serverIPsPrimary.Length) {
    $targetServers | %{ Add-DnsServerResourceRecordA -ZoneName <forwardDnsZone> -Name $_ -IPv4Address $serverIPsPrimary[$i++] -ComputerName $dnsServer -AllowUpdateAny -CreatePtr -Confirm:$false }}
  Remove-Item -Path <path-to-text-file>
  Remove-Item -Path <path-to-failover-site-text-file>
}
else {
  # Post-Script: After servers have failed over to the secondary site
  for ($i=0; $i -lt $serverIPsSecondary.Length) {
    $targetServers | %{ Add-DnsServerResourceRecordA -ZoneName <forwardDnsZone> -Name $_ -IPv4Address $serverIPsPrimary[$i++] -ComputerName $dnsServer -AllowUpdateAny -CreatePtr -Confirm:$false }}
  Write-Output $time "Site/Application is in FAILOVER STATUS." | Out-File <path-to-text-file>
  Write-Output $time "Site/Application is in FAILOVER STATUS." | Out-File <path-to-failover-site-text-file>
