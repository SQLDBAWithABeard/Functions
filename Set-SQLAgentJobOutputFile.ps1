Function Set-SQLAgentJobOutPutFile
{
<#
.Synopsis
   Sets the OutPut File for a step of an agent job with the Job Names and steps provided dynamically 
.DESCRIPTION
   Sets the OutPut File for a step of an agent job with the Job Names and steps provided dynamically  
.EXAMPLE
   Set-SQLAgentJobOutPutFile -instance SERVERNAME -JobName 'The Agent Job' -JobStep

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
        [string]$Instance,
                [Parameter(Mandatory=$true,HelpMessage='The Full Output File Path', 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFile,
        [Parameter(Mandatory=$false,HelpMessage='The Job Step name', 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [object]$JobStep)
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

    begin 
    {
            # Bind the parameter to a friendly variable
            $JobName = $PsBoundParameters[$ParameterName]
    }
    process
    {
        $Job = Get-SQLAgentJob -ServerInstance $Instance -Name $JobName
        If(!$Jobstep)
        {
            if( ($Job|Get-SqlAgentJobStep).Name.Count -gt 1)
            {
                Write-output "Which Job Step do you wish to add output file to?"
                $JobStep = $Job |Get-SqlAgentJobStep| Out-GridView -Title "Choose the Job Steps to add an output file to" -PassThru -Verbose
            }
            else
            {
                $Jobstep = $Job |Get-SqlAgentJobStep
            }
        }
#
        Write-Output "Adding $OutputFile to $($JobStep.Name)"
        Write-Output "Current Output File = $(($Jobstep).OutputFileName)"
        try
        {
           $Jobstep.OutputFileName = $OutputFile
           $Jobstep.Alter()
           Write-Output "Successfully added Output file - You can check with Get-SQLAgentJobOutputFile -Instance $Instance -JobName '$JobName'"
        }
        catch
        {
           Write-Warning "Failed to add $OutputFile to $(($JobStep).Name) for $JobName - Run `$error[0] | fl -force to find out why!"
        }
}
end{}
}
