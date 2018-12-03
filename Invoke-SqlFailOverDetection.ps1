<#
.SYNOPSIS
Downloads the Failover Detection Utility from the Tiger Team GitHub repo
 https://github.com/Microsoft/tigertoolbox/tree/master/Always-On/FailoverDetection,
 creates the configuration json and gathers all the required data and runs the executable

.DESCRIPTION
Downloads the Failover Detection Utility from the tiger teams GitHub Repo,
https://github.com/Microsoft/tigertoolbox/tree/master/Always-On/FailoverDetection
 creates the configuration json dynamically depending on the SQL Instance
 provided and gathers all of the required data and runs the utility

.PARAMETER InstallationFolder
The folder where the executable will run, it will copy the data here and create the results here

.PARAMETER DownloadFolder
The folder to hold the downloaded files or hte locatio if already downloaded

.PARAMETER DataFolder
The folder to copy all of the required data from the replicas for the utility

.PARAMETER ArchiveFolder
The folder for storing the gathered logs from earlier runs - Defaults to DataFolder\Archive if not specified

.PARAMETER SQLInstance
One SQL Instance that is a replica in the required Availability Group, the script will find all of the rest of the replicas

.PARAMETER AvailabilityGroup
The name of the Availability Group - Only required if there are multiple Availability Groups on the instance

.PARAMETER AlreadyDownloaded
A switch to avoid downloading the files if they have already been downloaded

.PARAMETER Analyze
This parameter will just run the tool without downloading or gathering any data

.PARAMETER Show
This parameter to output the results to the screen as well as to store them in the json file

.EXAMPLE
$InstallationFolder = 'C:\temp\failoverdetection\Install'
$DownloadFolder = 'C:\temp\failoverdetection\Download'
$DataFolder = 'C:\temp\failoverdetection\Data'
$SQLInstance = 'SQL0'

$invokeSqlFailOverDetectionSplat = @{
    DownloadFolder = $DownloadFolder
    SQLInstance = $SQLInstance
    DataFolder = $DataFolder
    InstallationFolder = $InstallationFolder
}
Invoke-SqlFailOverDetection @invokeSqlFailOverDetectionSplat

Downloads the required files from the GitHub repo to 'C:\temp\failoverdetection\Download'
Connects to SQL0 and finds the all of the replicas in the Availability Group and gets the
Error Logs, Extended Event files, System Event log and Cluster Log for each of the replicas amd
puts them in 'C:\temp\failoverdetection\Data'. Copies the required files to 'C:\temp\failoverdetection\Install'
and runs the utility

.EXAMPLE
$InstallationFolder = 'C:\temp\failoverdetection\Install'
$DownloadFolder = 'C:\temp\failoverdetection\Download'
$DataFolder = 'C:\temp\failoverdetection\Data'
$SQLInstance = 'SQL0'

$invokeSqlFailOverDetectionSplat = @{
    DownloadFolder = $DownloadFolder
    SQLInstance = $SQLInstance
    DataFolder = $DataFolder
    InstallationFolder = $InstallationFolder
    AlreadyDownloaded = $true
}
Invoke-SqlFailOverDetection @invokeSqlFailOverDetectionSplat

Does not download any files
Connects to SQL0 and finds the all of the replicas in the Availability Group and gets the
Error Logs, Extended Event files, System Event log and Cluster Log for each of the replicas amd
puts them in 'C:\temp\failoverdetection\Data'.
Copies the required files from 'C:\temp\failoverdetection\Download' to 'C:\temp\failoverdetection\Install'
and runs the utility

.EXAMPLE
$InstallationFolder = 'C:\temp\failoverdetection\Install'
$DownloadFolder = 'C:\temp\failoverdetection\Download'
$DataFolder = 'C:\temp\failoverdetection\Data'
$ArchiveFolder = 'C:\temp\failoverdetection\Archive'
$SQLInstance = 'SQL0'

$invokeSqlFailOverDetectionSplat = @{
    DownloadFolder = $DownloadFolder
    SQLInstance = $SQLInstance
    DataFolder = $DataFolder
    InstallationFolder = $InstallationFolder
    ArchiveFolder      = $ArchiveFolder
    AlreadyDownloaded = $true
}
Invoke-SqlFailOverDetection @invokeSqlFailOverDetectionSplat

Does not download any files
Connects to SQL0 and finds the all of the replicas in the Availability Group and gets the
Error Logs, Extended Event files, System Event log and Cluster Log for each of the replicas amd
puts them in 'C:\temp\failoverdetection\Data'.
If there has been a previous run, archives the files to C:\temp\failoverdetection\Archive'
Copies the required files from 'C:\temp\failoverdetection\Download' to 'C:\temp\failoverdetection\Install'
and runs the utility

.EXAMPLE
$InstallationFolder = 'C:\temp\failoverdetection\Install'
$DownloadFolder = 'C:\temp\failoverdetection\Download'
$DataFolder = 'C:\temp\failoverdetection\Data'
$SQLInstance = 'SQL0'

$invokeSqlFailOverDetectionSplat = @{
    DownloadFolder = $DownloadFolder
    SQLInstance = $SQLInstance
    DataFolder = $DataFolder
    InstallationFolder = $InstallationFolder
}
Invoke-SqlFailOverDetection @invokeSqlFailOverDetectionSplat -Verbose -WhatIf

Shows what would happenn if you ran the command and gives verbose output

.EXAMPLE
$InstallationFolder = 'C:\temp\failoverdetection\Install'
$DownloadFolder = 'C:\temp\failoverdetection\Download'
$DataFolder = 'C:\temp\failoverdetection\Data'
$SQLInstance = 'SQL0'

$invokeSqlFailOverDetectionSplat = @{
    DownloadFolder = $DownloadFolder
    SQLInstance = $SQLInstance
    DataFolder = $DataFolder
    InstallationFolder = $InstallationFolder
    AlreadyDownloaded = $true
    Analyze = $true
}
Invoke-SqlFailOverDetection @invokeSqlFailOverDetectionSplat

Does not download any files
Does not collect any data
Copies the required files from 'C:\temp\failoverdetection\Download' to 'C:\temp\failoverdetection\Install'
and runs the utility with the Analyze flag to use the already gathered infomration in 'C:\temp\failoverdetection\Data'

.EXAMPLE
$InstallationFolder = 'C:\temp\failoverdetection\Install'
$DownloadFolder = 'C:\temp\failoverdetection\Download'
$DataFolder = 'C:\temp\failoverdetection\Data'
$SQLInstance = 'SQL0'

$invokeSqlFailOverDetectionSplat = @{
    DownloadFolder = $DownloadFolder
    SQLInstance = $SQLInstance
    DataFolder = $DataFolder
    InstallationFolder = $InstallationFolder
    AlreadyDownloaded = $true
    Analyze = $true
    Show = $true
}
Invoke-SqlFailOverDetection @invokeSqlFailOverDetectionSplat

Does not download any files
Does not collect any data
Copies the required files from 'C:\temp\failoverdetection\Download' to 'C:\temp\failoverdetection\Install'
and runs the utility with the Analyze flag to use the already gathered infomration in 'C:\temp\failoverdetection\Data'

.NOTES
More information about the FailoverDetection Utility can be found here
https://blogs.msdn.microsoft.com/sql_server_team/failover-detection-utility-availability-group-failover-analysis-made-easy/

Created by Rob Sewell
@SQLDbaWithBeard
sqldbawithabeard.com
Blog post - https://sqldbawithabeard.com/2018/11/28/gathering-all-the-logs-and-running-the-availability-group-failover-detection-utility-with-powershell/
#>
function Invoke-SqlFailOverDetection {
    [cmdletbinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $InstallationFolder,
        [Parameter(Mandatory = $true)]
        [string] $DownloadFolder,
        [Parameter(Mandatory = $true)]
        [string] $DataFolder,
        [string] $ArchiveFolder,
        [Parameter(Mandatory = $true)]
        [string] $SQLInstance,
        [string] $AvailabilityGroup,
        [switch]$AlreadyDownloaded,
        [switch]$Analyze,
        [switch]$Show
    )
    #Requires -Modules dbatools
    #Requires -Version 5
    $msg = "Starting Invoke-SqlFailOverDetection with
InstallationFolder = $InstallationFolder
DownloadFolder = $DownloadFolder
DataFolder = $Datafolder
SQLInstance = $SQLInstance
AvailabilityGroup = $AvailabilityGroup
AlreadyDownloaded = $AlreadyDownloaded
Analyze = $Analyze
Show = $Show"
    Write-Verbose $msg

    #Region Some Folder bits
    $msg = "Ensuring folders have \ at the end because it pulls my beard so often"
    Write-Verbose $msg
    if (-not $DownloadFolder.EndsWith('\')) {
        $DownloadFolder = $DownloadFolder + '\'
    }
    if (-not $InstallationFolder.EndsWith('\')) {
        $InstallationFolder = $InstallationFolder + '\'
    }
    if (-not $DataFolder.EndsWith('\')) {
        $DataFolder = $DataFolder + '\'
    }
    if (-not $ArchiveFolder.EndsWith('\')) {
        $ArchiveFolder = $ArchiveFolder + '\'
    }
    $msg = "Creating folders as needed"
    Write-Output $msg
    if (-not (Test-Path $DownloadFolder)) {
        try {
            if ($PSCmdlet.ShouldProcess("$DownloadFolder" , "Creating Directory")) {
                $null = New-Item $DownloadFolder -ItemType Directory
            }
        }
        catch {
            Write-Warning "We aren't going to get very far without creating the $DownloadFolder"
            Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
            Return
        }
    }
    if (-not (Test-Path $InstallationFolder)) {
        try {
            if ($PSCmdlet.ShouldProcess("$InstallationFolder" , "Creating Directory")) {
                $null = New-Item $InstallationFolder -ItemType Directory
            }
        }
        catch {
            Write-Warning "We aren't going to get very far without creating the $InstallationFolder"
            Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
            Return
        }
    }
    if (-not (Test-Path $DataFolder)) {
        try {
            if ($PSCmdlet.ShouldProcess("$DataFolder" , "Creating Directory")) {
                $null = New-Item $DataFolder -ItemType Directory
            }
        }
        catch {
            Write-Warning "We aren't going to get very far without creating the $DataFolder"
            Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
        }
    }
    #endregion

    #region Avoid TLS errors
    Write-Output "Avoiding TLS Errors"
    $currentVersionTls = [Net.ServicePointManager]::SecurityProtocol
    $currentSupportableTls = [Math]::Max($currentVersionTls.value__, [Net.SecurityProtocolType]::Tls.value__)
    $availableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object {
        $_ -gt $currentSupportableTls
    }
    $availableTls | ForEach-Object {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
    }
    #endregion

    #region Download the files
    if ( -not $AlreadyDownloaded -and -not $Analyze) {
        $msg = "Downloading and extracting required files"
        Write-Output $msg
        $DownloadFile = 'https://github.com/Microsoft/tigertoolbox/raw/master/Always-On/FailoverDetection/FailoverDetector.zip'
        $FileName = $DownloadFile.Split('/')[-1]
        $FilePath = $DownloadFolder + $FileName

        try {
            if ($PSCmdlet.ShouldProcess("$FilePath" , "Downloading $DownloadFile ")) {
                (New-Object System.Net.WebClient).DownloadFile($DownloadFile, $FilePath)
            }
        }
        catch {
            try {
                Write-Output "Probably using a proxy for internet access, trying default proxy settings"
                if ($PSCmdlet.ShouldProcess("$FilePath" , "Downloading $DownloadFile with default proxy settings")) {
                    $wc = (New-Object System.Net.WebClient)
                    $wc.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
                    $wc.DownloadFile($DownloadFile, $FilePath)
                }
            }
            catch {
                Write-Warning "The Beard is sad! There was an error downloading file :( "
                Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
                return
            }
        }

        $msg = "Extracting $FileName"
        Write-Output $msg

        if ($PSCmdlet.ShouldProcess("$FileName" , "Extracting zip file ")) {
            if (Test-Path $FilePath) {
                try {
                    if (-not (Test-Path "$DownloadFolder\Extract")) {
                        if ($PSCmdlet.ShouldProcess("$DataFolder" , "Creating Directory")) {
                            $null = New-Item "$DownloadFolder\Extract" -ItemType Directory
                        }
                    }
                    Expand-Archive -Path $FilePath -DestinationPath "$DownloadFolder\Extract" -Force
                }
                catch {
                    Write-Warning "Hmm something has gone wrong with the extraction"
                    Write-Output "Hmm something has gone wrong with the extraction"
                    Return
                }
            }
            else {
                Write-Warning "Hmm something has gone wrong - where is the zip file? It should be $FilePath"
                Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
                Return
            }
        }
    }
    #endregion

    #region get all of the data
    $msg = "Getting the info about the Availability Group"
    Write-Output $msg
    try {
        $Ag = Get-DbaAvailabilityGroup -SqlInstance $SQLInstance -AvailabilityGroup $AvailabilityGroup
    }
    catch {
        Write-Warning "Failed to get the informatio about the Availability Group - Gonna have to stop"
        Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
    }

    $replicastring = ForEach ($replica in $Ag.AvailabilityReplicas.Name) {
        '"' + $replica.Split('\')[0].Replace('\', '\\') + '",'
    }
    $msg = "Getting the information from the Availability Group $($Ag.Name) replicas and putting it in the DataFolder $DataFolder"
    Write-Output $msg
    foreach ($replica in $Ag.AvailabilityReplicas.Name) {
        $replicaHostName = $replica.Split('\')[0]
        $InstanceFolder = $DataFolder + $replica.Split('\')[0]
        if (-not (Test-Path $InstanceFolder)) {
            try {
                if ($PSCmdlet.ShouldProcess("$InstanceFolder" , "Creating Directory for Data for replica $Replica ")) {
                    $null = New-Item $InstanceFolder -ItemType Directory
                }
            }
            catch {
                Write-Warning "We aren't going to get very far without creating the folder $InstanceFolder for the data for the replica $Replica"
                Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
                Return
            }
        }
        else {
            #because some people clear out there files manually :-)
            if ((Get-ChildItem $InstanceFolder).Length -ne 0) {
                ## if there are results in here already we dont want to lose them so we shall move them to a new folder
                $msg = "There is data in the data folder so we will move it"
                Write-Verbose $msg
                $clusterlog = Get-ChildItem "$InstanceFolder\*_cluster.log"
                if ($clusterlog) {
                    $FileDate = Get-Date $clusterlog.LastWriteTime -Format ddMMyyyy-HHmmss
                }
                else {
                    #if process fails and there is no cluster file to get a date it errors
                    $FileDate = (Get-Date -Format ddMMyyyy-HHmmss) + "_WhenMoved_CouldntGetAccurateDate"
                }
                if (-not $ArchiveFolder) {
                    $ArchiveFolder = "$DataFolder\Archive\"
                }

                $FolderName = $ArchiveFolder + $FileDate + '_' + $replicaHostName
                if ($PSCmdlet.ShouldProcess("$FolderName" , "Creating an archive folder ")) {
                    $null = New-Item $FolderName -ItemType Directory
                }
                if ($PSCmdlet.ShouldProcess("$InstanceFolder" , "Archiving files to $FolderName ")) {
                    $msg = "Archiving files from $InstanceFolder to $FolderName "
                    Write-Output $msg
                    Get-ChildItem "$InstanceFolder\*" -Recurse | Move-Item -Destination $FolderName
                }
            }
        }

        if ( -not $Analyze) {

            # Need to remvoe the files from here if we run this multiple times, else things get confusing
            if ((Get-ChildItem $InstallationFolder\Data\*).Length -gt 0) {
                if ($PSCmdlet.ShouldProcess("$InstallationFolder\Data" , "Removing all files from ")) {
                    Remove-Item $InstallationFolder\Data\* -Recurse -Force
                }
            }

            $msg = "Getting the error log location for the replica $replica"
            Write-Verbose $msg
            try {
                $Errorlogpath = (Get-DbaErrorLogConfig -SqlInstance $replica).LogPath
            }
            catch {
                Write-Warning "Failed to get the error log path for the replica $replica - Going to be difficult to gather all the data for $replica"
                Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
            }

            $UNCErrorLogPath = '\\' + $replicaHostName + '\' + $Errorlogpath.Replace(':', '$')
            try {
                if ($PSCmdlet.ShouldProcess("$replica" , "Copying the Error Log to $InstanceFolder from ")) {
                    $msg = "Copying the Error Log to $InstanceFolder from $replicaHostName"
                    Write-Output $msg
                    Get-ChildItem $UNCErrorLogPath -Filter '*ERRORLOG*' | Copy-Item -Destination $InstanceFolder -Force
                }
                if ($PSCmdlet.ShouldProcess("$replica" , "Copying the system health Extended Events logs to $InstanceFolder from ")) {
                    $msg = "Copying the system health Extended Events logs to $InstanceFolder from $replica"
                    Write-Output $msg
                    Get-ChildItem $UNCErrorLogPath -Filter 'system_health_*' | Copy-Item -Destination $InstanceFolder -Force
                }
                if ($PSCmdlet.ShouldProcess("$replica" , "Copying the Always On health Extended Events logs to $InstanceFolder from ")) {
                    $msg = "Copying the Always On health Extended Events logs to $InstanceFolder from $replica"
                    Write-Output $msg
                    Get-ChildItem $UNCErrorLogPath -Filter 'AlwaysOn_health_*' | Copy-Item -Destination $InstanceFolder -Force
                }
                if ($PSCmdlet.ShouldProcess("$replica" , "Copying the cluster log to $InstanceFolder from ")) {
                    $msg = "Copying the cluster log to $InstanceFolder from $replica"
                    $null = Get-ClusterLog -Node $replicaHostName -Destination $UNCErrorlogpath
                    Write-Output $msg
                    Get-ChildItem $UNCErrorLogPath -Filter '*_cluster.log' | Copy-Item -Destination $InstanceFolder -Force
                }
                if ($PSCmdlet.ShouldProcess("$replica" , "Copying the system event log to $InstanceFolder from ")) {
                    $msg = "Copying the system event log to $InstanceFolder from $replica"
                    Write-Output $msg
                    $SystemLogFilePath = $UNCErrorLogPath + '\' + $replicaHostName + '_system.csv'
                    $date = (Get-Date).AddDays(-2)
                    # Get the event log and filter by last two days The silently continue is because if the event log message contains certain characters and is filtered this way it shows errors
                    #Get-WinEvent : The description string for parameter reference (%1) could not be found
                    Get-WinEvent -FilterHashtable @{LogName = 'System'; StartTime = $date } -ComputerName $replicaHostName -ErrorAction SilentlyContinue | Export-CSV -Path  $SystemLogFilePath
                    Copy-Item -Path $SystemLogFilePath -Destination $InstanceFolder -Force
                }
            }
            catch {

                Write-Warning "Failed to get all of the information from the replica $replica - need to stop"
                Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
                Return
            }
        }
    }
    #endregion

    #region copy all to the installation folder
    $msg = "Copying the required files to the Installation folder $InstallationFolder"
    Write-Output $msg
    try {
        if ($PSCmdlet.ShouldProcess("$InstallationFolder" , "Copying the files from the Download folder $DownloadFolder to ")) {
            Get-ChildItem $DownloadFolder\Extract\* -Recurse | Copy-Item -Destination $InstallationFolder -Force
        }
    }
    catch {
        Write-Warning "Failed to copy the files to the installation folder - Cant carry on"
        Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
        return
    }

    #endregion
    #region create the JSON
    $msg = "Creating the Configuration Json file dynamically"
    Write-Verbose $msg
    $replicastring[-1] = $replicastring[-1].Replace(',', '')
    $DatafolderJson = $DataFolder.Replace('\', '\\')

    $ConfigurationJson = @"
{
    "Data Source Path": "$DatafolderJson",
    "Health Level": 3,
    "Instances": [
		$ReplicaString
    ]
}
"@

    $JsonFilePath = $InstallationFolder + 'Configuration.json'
    if ($PSCmdlet.ShouldProcess("$JsonFilePath" , "Creating the Configuration JSON File  ")) {
        try {
            $ConfigurationJson | Out-File -FilePath $JsonFilePath
        }
        catch {
            Write-Warning "Failed to create the configuration json file- cant continue"
            Write-Warning "Run `$Error[0] | Fl -Force to find out what happened"
        }
    }
    #endregion

    #region Run the EXE
    if ($Analyze) {
        if ($Show) {
            if ($PSCmdlet.ShouldProcess("$DataFolder" , "Running the Failover.exe with the Analyze and Show switches so not getting any data ")) {
                Set-Location $InstallationFolder
                & .\FailoverDetector.exe --Analyze --Show
                Return
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess("$DataFolder" , "Running the Failover.exe with the Analyze switch so not getting any data ")) {
                Set-Location $InstallationFolder
                & .\FailoverDetector.exe --Analyze
                Return
            }
        }
    }
    else {
        if ($Show) {
            if ($PSCmdlet.ShouldProcess("$InstallationFolder" , "Running the Failover.exe with the Show switch in the folder ")) {
                Set-Location $InstallationFolder
                & .\FailoverDetector.exe --Show
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess("$InstallationFolder" , "Running the Failover.exe in the folder ")) {
                Set-Location $InstallationFolder
                & .\FailoverDetector.exe
            }
        }
    }
    #endregion
}
