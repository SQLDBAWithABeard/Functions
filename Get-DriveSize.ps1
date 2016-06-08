<#
    .Synopsis
    Function to return space details for drives and mount points on local and remote servers
    .DESCRIPTION
    Returns Drive or volume name, Label, Size in GB, Free Space in Gb and Percentage of Free Space
    for Drives and Mount points for local and remote servers
    .EXAMPLE
    Get-DriveSize

    This will return the details of the drives on the local machine
    .EXAMPLE
    Get-DriveSize -Server SQLServer1

    This will return the details of the drives on the Server SQLServer1
    .EXAMPLE
    Get-DriveSize -Server SQLServer1 -Credential $Credential

    This will return the details of the drives on the Server SQLServer1 using the credential stored in the $Credential Variable
    .EXAMPLE
    Get-DriveSize -Server SQLServer1 -PromptForCredential

    This will return the details of the drives on the Server SQLServer1 and prompt for a credential
    .NOTES
    AUTHOR : Rob Sewell http://sqldbawithabeard.com
    Initial Release 06/03/2014
    Aliased for Show-DriveSizes 25/10/2014
    Updated with remoting capabilities 10/05/2015
#>
#requires -Version 3 -Modules CimCmdlets
function Get-DriveSize 
{
  [CmdletBinding()]
  [Alias('Show-DrivesSizes')] # For Rob who still uses the old function name!
  param (
    # Server Name - Defaults to $ENV:COMPUTERNAME
    [Parameter(Mandatory = $false, 
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true, 
    Position = 0)]
    [string]$Server = $Env:COMPUTERNAME,
    # Credential for connecting to server
    [Parameter(Mandatory = $false, 
        ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true)]
    [System.Management.Automation.PSCredential]$Credential,
    # Prompts for credential
    [switch]$PromptForCredential
  )
  if($PromptForCredential)
  {
    $Credential = Get-Credential -Message "Credential with Permissions to $Server"
  }
  $Date = Get-Date
  ## Get the operating system version to decide win32_volume or win32_logicaldisk
  if($Credential)
  {
    try 
    {
        $version = [int](Get-WMIObject -ClassName Win32_OperatingSystem -Credential $Credential).Version.split('.')[0]
    }
    catch 
    {
      Write-Error -Message 'Failed to get Operating System'
      $_
      break
    }        
  }
  else
  {
    try 
    {
      $version = [int](Get-WMIObject -ClassName Win32_OperatingSystem -ComputerName $Server -ErrorAction Stop).Version.split('.')[0]
    }
    catch 
    {
      Write-Error -Message 'Failed to get Operating System'
      $_
      break
    }
  }

  If($version -ge 6)
  {
    $FreeGb = @{
      Name       = 'FreeGB'
      Expression = {
        '{0:N2}' -f ($_.Freespace/1GB)
      }
    }
    $TotalGB = @{
      Name       = 'SizeGB'
      expression = {
        [math]::round(($_.Capacity/1Gb),2)
      }
    }
    $FreePercent = @{
      Name       = 'Free %'
      expression = {
        [math]::round(((($_.FreeSpace /1Gb)/($_.Capacity /1Gb)) * 100),0)
      }
    }
    if($Credential)
    {
      try 
      {
        $ScriptBlock = {
          $disks = (Get-CimInstance -ClassName win32_volume -ComputerName $Server -ErrorAction Stop ).Where{
            $_.DriveLetter -ne $null
          }
          $Return = $disks |
          Select-Object -Property PSComputerName, Name, Label , $TotalGB , $FreeGb , $FreePercent |
          Sort-Object -Property Name |
          Format-Table -AutoSize |
          Out-String
          return $Return
        }
        Invoke-Command -ComputerName $Server -ScriptBlock $ScriptBlock -Credential $Credential -ErrorAction Stop
      }
      catch 
      {
        Write-Error -Message 'Failed to get Disks'
        $_
        break
      }
    }
    else
    {
      try 
      {
        $disks = (Get-CimInstance -ClassName win32_volume -ComputerName $Server -ErrorAction Stop).Where{
          $_.DriveType -eq 3 -and $_.DriveLetter -ne $null
        }
        $Return = $disks |
        Select-Object -Property PSComputerName, Name, Label , $TotalGB , $FreeGb , $FreePercent |
        Sort-Object -Property Name |
        Format-Table -AutoSize |
        Out-String
        return $Return 
      }
      catch 
      {
        Write-Error -Message 'Failed to get Disks'
        $_
        break
      }
    }
  }
  else
  {
    $TotalGB = @{
      Name       = 'Size GB'
      expression = {
        [math]::round(($_.Size/ 1Gb),2)
      }
    }
    $FreePerc = @{
      Name       = 'Free %'
      expression = {
        [math]::round(((($_.FreeSpace / 1Gb)/($_.Size / 1Gb)) * 100),0)
      }
      }
    $FreeGb = @{
      Name       = 'FreeGB'
      Expression = {
        '{0:N2}' -f ($_.Freespace/1GB)
      }
    }
    
    if($Credential)
    {
      Try 
      {
         $Return = Get-WmiObject -Class win32_logicaldisk -ComputerName $Server -Credential $Credential -ErrorAction Stop|
          Where-Object -FilterScript {
            $_.drivetype -eq 3
          }|
          Select-Object -Property Name, Label, $TotalGB, $FreeGb, $FreePerc |
          Sort-Object -Property Name |
          Format-Table -AutoSize  |
          Out-String
          return $Return
      }
      Catch 
      {
        Write-Error -Message 'Failed to get Disks'
        $_    
        break
      }
    }
    else 
    {
      Try 
      {
        $Return = Get-WmiObject -Class win32_logicaldisk -ComputerName $Server -ErrorAction Stop|
        Where-Object -FilterScript {
          $_.drivetype -eq 3
        }|
        Select-Object -Property Name, Label, $TotalGB, $FreeGb, $FreePerc |
        Sort-Object -Property Name |
        Format-Table -AutoSize  |
        Out-String
        return $Return
      }
      Catch 
      {
        Write-Error -Message 'Failed to get Disks'
        $_  
        break        
      }
    }
  }
  return $Return
}
