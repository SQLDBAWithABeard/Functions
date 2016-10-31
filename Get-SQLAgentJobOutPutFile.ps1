Function Get-SQLAgentJobOutPutFile
{
<#
.Synopsis
   Returns the OutPut File for each step of an agent job with the Job Names provided dynamically 
.DESCRIPTION
   This function returns the output file value for each step in an agent job with the Job Names provided dynamically 
.EXAMPLE
   Get-SQLAgentJobOutPutFile -instance SERVERNAME -JobName 'The Agent Job' 

   This will return the paths to the output files foreach job step of the The Agent Job Job on the SERVERNAME instance    
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
        [string]$Instance)
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
            $arrSet = (Get-SQLAgentJob -ServerInstance $Instance).Name
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
    }
    process
    {
    $Job = Get-SQLAgentJob -ServerInstance $Instance -Name $JobName
    if($Instance.Contains('\'))
    {
        $Server = $Instance.Split('\')[0]
    }
    else
    {
        $Server = $Instance
    }
    foreach($Step in $Job.JobSteps)
    {
    $fileName = $Step.OutputFileName
    $Name = '\\' + $Server + '\' + $Filename.Replace(':','$')
    Write-Output $Name
    }
}
end{}
}

