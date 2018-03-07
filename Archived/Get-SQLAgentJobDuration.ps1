<#PSScriptInfo

.VERSION 1.0

.GUID 5ebeb3ec-36b0-4dad-a3e3-bbff1ffcbfd7

.AUTHOR Rob Sewell

.COMPANYNAME Sewells Consulting

.COPYRIGHT Rob Sewell - please credit Rob Sewell - https://sqldbawithbeard.com if used

.DESCRIPTION Returns the Job Duration for an agent job on an instance

.TAGS SQL,SQL Agent Jobs, Duration

.LICENSEURI 

.PROJECTURI

.ICONURI 

.EXTERNALMODULEDEPENDENCIES sqlserver

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES Initial
#>
#Requires -Module sqlserver
Function Get-SQLAgentJobDuration
{
<#
.Synopsis
   Returns the Job Duration for an agent job on an instance or number of instances with the Job Names provided dynamically 
.DESCRIPTION
   This function returns the Job Duration for an agent job on an instance or number of instances with the Job Names provided dynamically
   It can also output to CSV and prompt if youwould like to open the file 
.EXAMPLE
   Get-SQLAgentJobDuration -Instances SERVER -JobName 'Job must run quickly'

   This will return the servername. jobname, rundate and duration of the 'Job must run quickly' job on the Instance SERVER
.EXAMPLE
   Get-SQLAgentJobDuration -Instances SERVER -JobName 'Job must run quickly' -CSV

   This will output the servername. jobname, rundate and duration of the 'Job must run quickly' job on the Instance SERVER into a CSV file
   located in the Users MyDocuments folder named JobName_Date_Time.csv
.EXAMPLE
   Get-SQLAgentJobDuration -Instances SERVER -JobName 'Job must run quickly' -CSV -Path c:\temp

   This will output the servername. jobname, rundate and duration of the 'Job must run quickly' job on the Instance SERVER into a CSV file
   located in C:\Temp named JobName_Date_Time.csv
.NOTES
   AUTHOR - Rob Sewell https://sqldbawithabeard.com
   DATE - 30/10/2016
#>
#Requires -Version 5
#Requires -Module sqlserver 
param
(# The Server/instance 
        [Parameter(Mandatory=$true,HelpMessage='The Instance', 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [object]$Instances,
        # CSV required
        [Parameter(Mandatory=$false,HelpMessage='Want to output to CSV')]
        [switch]$CSV,
        # Path for CSV
        [Parameter(Mandatory=$false,HelpMessage='Path for CSV')]
        [object]$Path,
        # Midnight (gets all the job history information generated after midnight) 
        # Yesterday (gets all the job history information generated in the last 24 hours) 
        # LastWeek (gets all the job history information generated in the last week) 
        # LastMonth (gets all the job history information generated in the last month)
        [Parameter(Mandatory=$false,HelpMessage='The Since Parameter')]
        [ValidateSet('Midnight', 'Yesterday', 'LastWeek' , 'LastMonth')]
        [String]$Since
        )
DynamicParam {
            # Set the dynamic parameters' name
            $ParameterName = 'JobName'
            
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
            $arrSet = (Get-SQLAgentJob -ServerInstance $Instances).Name
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
        $JobName = $PsBoundParameters[$ParameterName]
        $FormattedDuration = @{Name = 'FormattedDuration';Expression = {[timespan]$_.RunDuration.ToString().PadLeft(6,'0').insert(4,':').insert(2,':')}}
        } 
Process {
if(!$Since)
{
$JObs = (Get-SQLAgentJobHistory -ServerInstance $Instances -JobName $JobName).Where{$_.Stepid -eq 0}
}
else
{
$JObs = (Get-SQLAgentJobHistory -ServerInstance $Instances -JobName $JobName -Since $Since).Where{$_.Stepid -eq 0}
}
$Result = $Jobs | Select Server, JobName,RunDate,$FormattedDuration 
}
End {
    if($CSV)
    {
        if(!$Path)
        {
            $docs = [Environment]::GetFolderPath("mydocuments")   
            $Path = $Docs
        }

        $Date = Get-Date -Format yyyyMMdd_HHmmss
        $FilePath = $Path + '\' + $jobname + '_' + $Date + '.csv'
        $Result | Export-Csv -Path $FilePath -NoTypeInformation

        # Prompt to create and then create.  
    	$title = "Want to Open the file??" 
    	$message = "Would you like to open the CSV file now? (Y/N)" 
    	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Will continue" 
    	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Will exit" 
    	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no) 
    	$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
    	 
    	if ($result -eq 1) 
        { 
            return "OK File is located at $FilePath"
        } 
        else
        {
            Invoke-Item -Path $FilePath
        }
    }
    else
    {
        $Result
    }
}
}