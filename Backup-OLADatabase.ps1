<#PSScriptInfo

.VERSION 1.0

.GUID e690e558-357e-43fb-9bcf-5c39b33ce527

.AUTHOR Rob Sewell

.DESCRIPTION This function will perform an ad-hoc backup using OLA Hallengrens solution - It doesnot expose all of the capabilities but is useful for quick backups when needed Note the Database paramter is dynamically filled once you type it
      
.COMPANYNAME 

.COPYRIGHT 

.TAGS SQL, Ola Hallengren, Backup

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>
<#
.Synopsis
   To perform an ad-hoc backup using OLA Hallengrens solution
.DESCRIPTION
   This function will perform an ad-hoc backup using OLA Hallengrens solution - It doesnot expose all of the 
   capabilities but is useful for quick backups when needed
   Note the Database paramter is dynamically filled once you type it
.EXAMPLE
   Backup-OlaDatabase -instance SERVERNAME -Type LOG -Share \\backupshare -Database Database 

   This will perform a LOG backup of the Database database on the SERVERNAME instance to the \\backupshare Share. 
   Note the Database paramter is dynamically filled once you type it
.EXAMPLE
   Backup-OlaDatabase -instance SERVERNAME -Type FULL -Share X:\backups -Database Database 

   This will perform a FULL backup of the Database database on the SERVERNAME instance to the X:\backups Share. 
   Note the Database paramter is dynamically filled once you type it   
.EXAMPLE
   Backup-OlaDatabase -instance SERVERNAME -Type DIFF -Share \\TheShareForBackups -Database Database -OutputResults

   This will perform a DIFF backup of the Database database on the SERVERNAME instance to the \\TheShareForBackups 
   Share and output the message to the screen. 
   Note the Database paramter is dynamically filled once you type it  
.NOTES

  IF YOU HAVE THE STORED PROCEDURE IN A DIFFERENT DATABASE - You will need to alter line 130

   AUTHOR - Rob Sewell https://sqldbawithabeard.com
   DATE - 27/10/2016
#>
function Backup-OlaDatabase
{
    [CmdletBinding(  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  ConfirmImpact='Medium')]
    [Alias()]
    Param
    (
        # The Server/instance 
        [Parameter(Mandatory=$true,HelpMessage='This is the Instance that the database is on', 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Instance,
         # The Server/instance 
        [Parameter(Mandatory=$true,HelpMessage='This is the type of backup', 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('FULL', 'DIFF', 'LOG')]
        [string]$Type,
        

        # The Share
        [Parameter(Mandatory=$true,HelpMessage='This is the root of the backup directory', 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]$Share,
        
        #If you wish to see the results of the query
        [switch]$OutputResults,
        
        # Compression off ?
        [switch]$CompressionOff,
        
        # Copy Only ?
        [switch]$CopyOnly
        
    )


    DynamicParam {
            # Set the dynamic parameters' name
            $ParameterName = 'Database'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 1

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            # Load the assembly
            [void][reflection.assembly]::LoadWithPartialName( 'Microsoft.SqlServer.Smo' )

            $srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $Instance
            $arrSet = $Srv.databases.Name
            $srv.ConnectionContext.Disconnect()
            $ValidateSetAttribute = New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList ($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList ($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
    }

    begin {
        # Bind the parameter to a friendly variable
        $Database = $PsBoundParameters[$ParameterName]
        
        if($CompressionOff)
        {
          $Compression = 'N'
        }
        else
        {
          $Compression = 'Y'
        }
        if($CopyOnly)
        {
          $Co = 'Y'
        }
        else
        {
          $CO = 'N'
        }
    }
    Process
    {
  
        $Query = @"
EXECUTE [master].[dbo].[DatabaseBackup] 
@Databases = '$Database', 
@Directory = N'$Share', 
@BackupType = '$Type', 
@Verify = 'Y', 
@CheckSum = 'Y', 
@Compress= '$Compression', 
@LogToTable = 'Y',
@CopyOnly = '$CO'
"@
        
        if ($pscmdlet.ShouldProcess("$Instance" , "Back up $Database"))
        {
            try
            {
                $srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $Instance
                $SqlConnection = $srv.ConnectionContext
                if($OutputResults)
                {
                  Register-ObjectEvent -InputObject $SqlConnection -EventName InfoMessage -SupportEvent  -Action {
                    Write-Host $Event.SourceEventArgs 
                  } 
                }
                $SqlConnection.StatementTimeout = 8000
                $SqlConnection.ConnectTimeout = 10
                $SqlConnection.Connect()
                $SqlConnection.ExecuteNonQuery($Query)
                Write-Output -InputObject "$Database has been backed up to $Share"
            }
            catch
            {
                Write-Warning -Message ("Something went Wrong. Run `$Error[0] | Fl -force to work out why")
                $Query
            }
        }
    }
    End
    {
        $srv.ConnectionContext.Disconnect()
    }
}