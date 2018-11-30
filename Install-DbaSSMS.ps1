<#
.SYNOPSIS
Uses the Microsoft website to get the latest download link for SSMS full install or SSMS upgrade and 
silently installs it. It WILL KILL SSMS is it is already running

.DESCRIPTION
Uses the Microsoft website and gets the download link for SSMS full install or SSMS upgrade and 
silently installs it. It WILL KILL SSMS is it is already running

.PARAMETER URL
Defaults to the correct Microsoft page. This the URL to check for a download link 

.PARAMETER DownloadPath
The directory to download the file to. Defaults to the User Profile Downloads folder. But can be defined to use a different directory if required

.PARAMETER Upgrade
Switch to choose the upgrade link instead of the full install (for online installs only)

.PARAMETER Offline
Switch to choose an offline installer method

.PARAMETER FilePath
Path to the file for the offline installation

.EXAMPLE
Install-DbaSSMS 

Contacts the Microsoft website and installs the latest SSMS using the full installer
It WILL KILL SSMS is it is already running

.EXAMPLE
Install-DbaSSMS -Upgrade

Contacts the Microsoft website and upgrades SSMS
It WILL KILL SSMS is it is already running

.EXAMPLE
Install-DbaSSMS -DownloadPath T:\WhereIStoreMySSMSDownload

Contacts the Microsoft website downloads the latest full installer to the T:\WhereIStoreMySSMSDownload directory
 and installs it.
 It WILL KILL SSMS is it is already running

.EXAMPLE
Install-DbaSSMS -Offline -FilePath T:\WhereIStoreMySSMSDownload\SSMS-Setup-ENU.exe

Uses the file T:\WhereIStoreMySSMSDownload\SSMS-Setup-ENU.exe to install SSMS. 
It WILL KILL SSMS is it is already running

.EXAMPLE
Install-DbaSSMS -Offline -FilePath T:\WhereIStoreMySSMSDownload\SSMS-Setup-ENU-Upgrade.exe

Uses the file T:\WhereIStoreMySSMSDownload\SSMS-Setup-ENU-Upgrade.exe to upgrade SSMS 
(assuming the upgrade file is named SSMS-Setup-ENU-Upgrade.exe). 
It WILL KILL SSMS is it is already running

.NOTES

It WILL KILL SSMS is it is already running

Written by Rob Sewell @sqldbawithabeard
Initial Help - RMS - 28/03/2018
#>
function Install-DbaSSMS {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Online')]
    Param(
        [Parameter(Mandatory = $false, ParameterSetName = 'Online')]
        [ValidateNotNullOrEmpty()]
        [string] $URL = "https://msdn.microsoft.com/en-us/library/mt238290.aspx",
        [Parameter(Mandatory = $false, ParameterSetName = 'Online')]
        [ValidateScript( {Test-Path $_})]
        [ValidateNotNullOrEmpty()]
        [string] $DownloadPath = "$ENV:USERPROFILE\Downloads",
        [Parameter(Mandatory = $false, ParameterSetName = 'Online')]
        [switch]$Upgrade,
        [Parameter(Mandatory = $false, ParameterSetName = 'Offline')]
        [switch]$Offline,
        [Parameter(Mandatory = $false, ParameterSetName = 'Offline')]
        [string]$FilePath
    )

    if ( -not $Offline) {
        $pscmdlet.WriteVerbose("Installing from the web")
        #region SanityCheck
        if ( -not (Test-Path $DownloadPath)) {
            Write-Warning "I can't access $DownloadPath -  won't be able to continue. Please specify a directory this account has access to"
            Return
        }
        #endregion
        function Start-DbaFileDownload {
            [CmdletBinding(SupportsShouldProcess = $true)]
            Param(
                $url,
                $OutputFile
            )
            if ($PSCmdlet.ShouldProcess("$ENV:COMPUTERNAME", "Downloading file from $url to $outputFile ")) {
                try {
                    (New-Object System.Net.WebClient).DownloadFile($url, $outputFile)
                }
                Catch {
                    $pscmdlet.WriteVerbose("Probably using a proxy for internet access, trying default proxy settings")
                    $wc = (New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
                    $wc.DownloadFile($url, $outputFile)
                }
            }
        }

        #region Get the download link
        # Go to the Microsoft Site and grab the download link

        try {
            $pscmdlet.WriteVerbose("Getting the download link from $url")
            $webpage = Invoke-WebRequest -Uri $url -UseBasicParsing 
            ## Choose the link depending on if it is an ugrade or a full install
            if ($Upgrade) {
                $pscmdlet.WriteVerbose("Getting the download link for upgrade")
                $Downloadlink = $webpage.Links.Where{$_.OuterHtml -match 'Download SQL Server Management'}[1].href
                $InstallFile = "$DownloadPath\Autoinstall-SSMS-Setup-ENU-Upgrade.exe"
            }
            else {
                $pscmdlet.WriteVerbose("Getting the download link for full install")
                $Downloadlink = $webpage.Links.Where{$_.OuterHtml -match 'Download SQL Server Management'}[0].href
                $InstallFile = "$DownloadPath\Autoinstall-SSMS-Setup-ENU.exe"
            }
            $pscmdlet.WriteVerbose("Got the download link $Downloadlink")
        }
        Catch {
            Write-Warning "Failed To Get Download link from $url"
            Return
        }
        #endregion

        #region Download the file
        try {
            $pscmdlet.WriteVerbose("Starting Downloading the file from $DownloadLink to $InstallFile")
            Start-DbaFileDownload -Url $DownloadLink -OutputFile $InstallFile 
            $pscmdlet.WriteVerbose("Downloaded the file to $InstallFile ")
        }
        catch {
            Write-Warning "Failed To Get Download link from $url"
            Return
        }
        #endregion
    }
    else {
        $pscmdlet.WriteVerbose("Installing from Off-Line file $FilePath")
        #region SanityCheck
        if ( -not (Test-Path $FilePath)) {
            Write-Warning "I can't access $FilePath -  won't be able to continue. Please specify a directory this account has access to"
            Return
        }
        #endregion
        $pscmdlet.WriteVerbose("Using the Offline file $FilePath for installation")
        $InstallFile = $FilePath
    }

    #region Stop SSMS if it is running

    if (Get-Process SSMS -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess("$ENV:COMPUTERNAME", "Stopping SSMS process on ")) {
            try {
                Stop-Process -Name SSMS
                $pscmdlet.WriteVerbose("Stopped SSMS with a big bang - hope nothing was running")
            }
            catch {
                Write-Warning "Failed To stop SSMS - Need to bomb out as it wont install with SSMS running"
                Return
            }
        }
    }
    else {
        $pscmdlet.WriteVerbose("SSMS Not Running - Carry On")
    }
    #endregion

    #region Install SSMS

    if ($PSCmdlet.ShouldProcess("$ENV:COMPUTERNAME", "Installing SSMS on ")) {
        try {
            Start-Process -FilePath $InstallFile -ArgumentList "/install /quiet /norestart" -Wait -Verb RunAs
            $pscmdlet.WriteVerbose("SSMS installed or upgraded")
        }
        catch {
            Write-Warning "Failed to install or upgrade SSMS"
        }
    }
    #endregion
}



