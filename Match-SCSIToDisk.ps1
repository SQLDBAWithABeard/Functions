function Match-SCSIToDisk {

<#
.Synopsis
   Matches a VMWare SCSI Disk ID to a VM Disk Letter in a HARDCODED VCenter Server
.DESCRIPTION
   Matches a VMWare SCSI Disk ID to a VM Disk Letter
.EXAMPLE
   $Cred = Get-Crendetial
   Match-SCSIToDisk -vm VMName -cred $cred

   Stores a credential for accessing VCenter and gets the details for the VMName server out of VCenter and matches the SCSID to the drive
#>

# Massively Altered by Rob!!!!

# This script requires PowerCLI 4.0 U1
#
# Create Disk Mapping Table
# Created by Arnim van Lieshout
# Http://www.van-lieshout.com
Param(
[string]$VM,
[pscredential]$cred
)

# Initialize variables
# $VCServerList is a comma-separated list of vCenter servers
$VCServerList = ''
$DiskInfo= @()

# Set Default Server Mode to Multiple
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false | Out-Null
# Connect to vCenter Server(s)
foreach ($VCServer in $VCServerList) 
{
if(!$cred)
{
$cred = Get-Credential -Message $vcServerName -UserName 'UKHO\arobz'
}
Connect-VIServer -Server "$VCServer" -Credential $cred| Out-Null
}

if (($VmView = Get-View -ViewType VirtualMachine -Filter @{"Name" = $Vm})) {
    $WinDisks = Get-WmiObject -Class Win32_DiskDrive -ComputerName $Vm
  $Object = @()
  foreach ($DiskDrive in $WinDisks) {
                    $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='" + $DiskDrive.DeviceID + "'} where AssocClass = Win32_DiskDriveToDiskPartition"
                    $DiskPartitions = Get-WmiObject -Query $Query -Computername $VM

                    foreach ($DiskPartition in $DiskPartitions) {
                        $Query = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='" + $DiskPartition.DeviceID + "'} where AssocClass = Win32_LogicalDiskToPartition"
                        $LogicalDisks = Get-WmiObject -Query $Query -Computername $VM

                        foreach ($LogicalDisk in $LogicalDisks) {                         
                                $Object += New-Object PSObject -Property @{
                                    Caption = $DiskDrive.Caption
                                    DeviceID = $DiskDrive.DeviceID
                                    DiskPartition = $DiskPartition.DeviceID
                                    DriveLetter = $LogicalDisk.DeviceID
                                    InterfaceType = $DiskDrive.InterfaceType
                                    Firmware = $DiskDrive.FirmwareRevision
                                }
                        }
                    }
                    }

    foreach ($VirtualSCSIController in ($VMView.Config.Hardware.Device | where {$_.DeviceInfo.Label -match "SCSI Controller*"})) {
        foreach ($VirtualDiskDevice in ($VMView.Config.Hardware.Device | where {$_.ControllerKey -eq $VirtualSCSIController.Key})) {
            $VirtualDisk = "" | Select SCSIController, DiskName, SCSI_Id, DiskFile,  DiskSize, WindowsDisk,DriveLetter 
            $VirtualDisk.SCSIController = $VirtualSCSIController.DeviceInfo.Label
            $VirtualDisk.DiskName = $VirtualDiskDevice.DeviceInfo.Label
            $VirtualDisk.SCSI_Id = "$($VirtualSCSIController.BusNumber) : $($VirtualDiskDevice.UnitNumber)"
            $VirtualDisk.DiskFile = $VirtualDiskDevice.Backing.FileName
            $VirtualDisk.DiskSize = $VirtualDiskDevice.CapacityInKB * 1KB / 1GB

            # Match disks based on SCSI ID
            $DiskMatch = $WinDisks | ?{($_.SCSIBus -eq $VirtualSCSIController.BusNumber) -and $_.SCSITargetID -eq $VirtualDiskDevice.UnitNumber}
            if ($DiskMatch){
                $DriveLetter = $Object.Where{$_.DeviceID -eq $DiskMatch.DeviceID}.DriveLetter          
                $VirtualDisk.WindowsDisk = "Disk $($DiskMatch.Index)"
                $VirtualDisk.DriveLetter = $DriveLetter
            
            }
            else {Write-Warning "No matching Windows disk found for SCSI id $($VirtualDisk.SCSI_Id)"}
            $DiskInfo += $VirtualDisk
        }
    }
    $DiskInfo | Out-GridView
}
else {Write-Warning "VM $Vm Not Found"}

Disconnect-VIServer * -Confirm:$false
}