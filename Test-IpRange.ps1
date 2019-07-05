function Test-IpRange {
    Param(
        $FirstThreeOctets,
        $Start,
        $End,
        $Throttle = 10
    )
    Write-PSFMessage "Removing Jobs" -Level Host
    Get-RSJob -Name "ResolveIP" | Remove-RSJob
    $ScriptBlock = {
        Param (
            $EndOctet
        )
        $IP = $Using:FirstThreeOctets + '.' + $EndOctet
        [string]$DNSServer = (Get-DnsClientServerAddress)[0].Serveraddresses[0]
        $DNSARecords = Get-DnsServerResourceRecord -ZoneName $env:USERDNSDOMAIN -ComputerName $DNSServer -RRType "A" | Where-Object {$_.RecordData.Ipv4Address -eq $Ip}
        [PSCustomObject]@{
            IPAddress = $IP
            HostName = $DNSARecords.HostName
        }
    }
    Write-PSFMessage "Starting Jobs" -Level Host
    $Start..$End | Start-RSJob -Name "ResolveIP" -ScriptBlock $ScriptBlock -Throttle $Throttle |Out-Null
    Write-PSFMessage "Waiting for Jobs" -Level Host
    While ((Get-RSJob -Name "ResolveIP").State -contains 'Running') {}
    Write-PSFMessage "Geetting Jobs" -Level Host
    Get-RSJob -Name "ResolveIP" | Receive-RSJob 
    Write-PSFMessage "End" -Level Host
}

Test-IpRange -FirstThreeOctets 10.202.100 -Start 110 -End 209 |Format-Table
