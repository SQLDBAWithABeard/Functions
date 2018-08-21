
<#PSScriptInfo

.VERSION 1.0.0.2

.GUID 0b89f8fb-6de5-4f1b-8a0d-6172a89d4743

.AUTHOR Rob Sewell @sqldbawithbeard

.COMPANYNAME Sewells Consulting

.COPYRIGHT Rob Sewell @sqldbawithbeard

.TAGS Power Bi SSRS SQL Server Reporting Services PBIX deployment

.LICENSEURI https://github.com/SQLDBAWithABeard/Functions/blob/master/LICENSE

.PROJECTURI https://github.com/SQLDBAWithABeard/Functions

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

#Requires -Module ReportingServicesTools

<# 

.DESCRIPTION 
 Uploads PBIX files to a PowerBi report server and sets the data source 

#> 

Param()

<#
.SYNOPSIS
Publishes a Power Bi File to a PowerBi Report Server. It will overwrite existing
files.

.DESCRIPTION
Publishes a Power Bi File to a Power Bi report Server and sets the credential for
the datasources

.PARAMETER FolderName
The Name of the folder the report is to be placed. Will be created if it doesnt 
exist - IE dbachecks-weekly or Finance

.PARAMETER ReportServerURI
The URI of the Report Server like http://Server01/ReportS

.PARAMETER FolderLocation
The Path to the folder - If it is in the root directory then / otherwise 
/dbachecks

.PARAMETER PBIXFile
The full path to the pbix file 

.PARAMETER Description
The Description of the report

.PARAMETER AuthenticationType
The type of Authentication for the user for the datasource - SQL or Windows

.PARAMETER ConnectionUserName
The User name for the credential for the datasource if required - Use a 
creential object if possible

.PARAMETER Secret
The password for the user for the datasource - Use a credential object if 
possible

.PARAMETER Credential
A credential object for the user for the data source

.EXAMPLE

$FolderName = 'TestFolder'
$ReportServerURI = 'http://localhost/Reports'
$FolderLocation = '/'
$PBIXFile = 'C:\Temp\test.pbix'
$Description = "Descriptions"

    $publishPBIXFileSplat = @{
        ReportServerURI = $ReportServerURI
        FolderLocation = $FolderLocation
        Description = $Description
        PBIXFile = $PBIXFile
        FolderName = $FolderName
        AuthenticationType = 'Windows'
      ConnectionUserName = $UserName1
      Secret = $Password1
      
    }
    Publish-PBIXFile @publishPBIXFileSplat

    Deploys a report from the PBIX file C:\Temp\test.pbix  to the report server 
    on the localhost into a  folder called TestFolder located at the root of the
    server (which it will create if it doesnt exist) and sets the connection 
    string to use a Windows user name and password stored in the variables

    
.EXAMPLE

$FolderName = 'TestFolder'
$ReportServerURI = 'http://localhost/Reports'
$FolderLocation = '/'
$PBIXFile = 'C:\Temp\test.pbix'
$Description = "Descriptions"

    $publishPBIXFileSplat = @{
        ReportServerURI = $ReportServerURI
        FolderLocation = $FolderLocation
        Description = $Description
        PBIXFile = $PBIXFile
        FolderName = $FolderName
        AuthenticationType = 'SQL'
      ConnectionUserName = $UserName1
      Secret = $Password1
      
    }
    Publish-PBIXFile @publishPBIXFileSplat

    Deploys a report from the PBIX file C:\Temp\test.pbix  to the report server 
    on the localhost into a  folder called TestFolder located at the root of the
    server (which it will create if it doesnt exist) and sets the connection 
    string to use a SQL user name and password stored in the variables

.NOTES
Rob Sewell 20/08/2018
#>
function Publish-PBIXFile {
    [CmdletBinding(DefaultParameterSetName = 'ByUserName', SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$FolderName,
        [Parameter(Mandatory = $true)]
        [string]$ReportServerURI,
        [Parameter(Mandatory = $true)]
        [string]$FolderLocation,
        [Parameter(Mandatory = $true)]
        [string]$PBIXFile,
        [Parameter()]
        [string]$Description = "Description of Your report Should go here",
        [Parameter()]
        [ValidateSet('Windows','SQL')]
        [string]$AuthenticationType,
        [Parameter(ParameterSetName = 'ByUserName')]
        [string]$ConnectionUserName, 
        [Parameter(ParameterSetName = 'ByUserName')]
        [string]$Secret,
        [Parameter(Mandatory = $true, ParameterSetName = 'ByCred')]
        [pscredential]$Credential
    )

    $FolderPath = $FolderLocation + $FolderName
    $PBIXName = $PBIXFile.Split('\')[-1].Replace('.pbix', '')

    try {
        Write-Verbose "Creating a session to the Report Server $ReportServerURI"
        # establish session w/ Report Server
        $session = New-RsRestSession -ReportPortalUri $ReportServerURI
        Write-Verbose "Created a session to the Report Server $ReportServerURI"
    }
    catch {
        Write-Warning "Failed to create a session to the report server $reportserveruri"
        Return
    }

    # create folder (optional)
    try {
        if ($PSCmdlet.ShouldProcess("$ReportServerURI", "Creating a folder called $FolderName at $FolderLocation")) {
            $Null = New-RsRestFolder -WebSession $session -RsFolder $FolderLocation  -FolderName $FolderName -ErrorAction Stop
        }
    }
    catch [System.Exception] {
        If ($_.Exception.InnerException.Message -eq 'The remote server returned an error: (409) Conflict.') {
            Write-Warning "The folder already exists - moving on"
        }
    }
    catch {
        Write-Warning "Failed to create a folder called $FolderName at $FolderLocation report server $ReportServerURI but not because it already exists"
        Return
    }

    try {
        if ($PSCmdlet.ShouldProcess("$ReportServerURI", "Uploading the pbix from $PBIXFile to the report server ")) {
            # upload copy of PBIX to new folder
            Write-RsRestCatalogItem -WebSession $session -Path $PBIXFile -RsFolder $folderPath -Description $Description -Overwrite
        }
    }
    catch {
        Write-Warning "Failed to upload the file $PBIXFile to report server $ReportServerURI"
        Return
    }

    try {
        Write-Verbose "Getting the datasources from the pbix file for updating"
        # get data source object
        $datasources = Get-RsRestItemDataSource -WebSession $session -RsItem "$FolderPath/$PBIXName"
        Write-Verbose "Got the datasources for updating"
    }
    catch {
        Write-Warning "Failed to get the datasources"
        Return
    }


    try {
        Write-Verbose "Updating Datasource"

       
        foreach ($dataSource in $datasources) {
            if ($AuthenticationType -eq 'SQL') {
                $dataSource.DataModelDataSource.AuthType = 'UsernamePassword'
            }
            else{
                $dataSource.DataModelDataSource.AuthType = 'Windows'
            }
            if ($Credential -or $UserName) {
                if ($Credential) {
                    $UserName = $Credential.UserName
                    $Password = $Credential.GetNetworkCredential().Password
                }
                else {
                    $UserName = $ConnectionUserName
                    $Password = $Secret
                }
                $dataSource.CredentialRetrieval = 'Store'
                $dataSource.DataModelDataSource.Username = $UserName 
                $dataSource.DataModelDataSource.Secret = $Password 
            }
            if ($PSCmdlet.ShouldProcess("$ReportServerURI", "Updating the data source for the report $PBIXName")) {
                # update data source object on server
                Set-RsRestItemDataSource -WebSession $session -RsItem "$folderPath/$PBIXName" -RsItemType PowerBIReport -DataSources $datasource
            }
        }
    }
    catch {
        Write-Warning "Failed to set the datasource"
        Return
    }
    Write-Verbose "Completed Successfully"
}
