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
            Param(
                $url,
                $OutputFile
            )
            (New-Object System.Net.WebClient).DownloadFile($url, $outputFile)
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
            Start-Process -FilePath $InstallFile -ArgumentList "/install /quiet /norestart" -Wait
            $pscmdlet.WriteVerbose("SSMS installed or upgraded")
        }
        catch {
            Write-Warning "Failed to install or upgrade SSMS"
        }
    }
    #endregion
}



