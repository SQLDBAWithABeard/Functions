$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"
"$here\$sut"
Import-Module PSScriptAnalyzer
$Rules = Get-ScriptAnalyzerRule
$Name = $sut.Split('.')[0]

Describe 'Script Analyzer Tests' -Tag Invoke-SqlFailOverDetection {
    Context 'Testing $sut for Standard Processing' {
        foreach ($rule in $rules.Where{$_.RuleName -ne 'PSAvoidUsingWMICmdlet'}) { 
            $i = $rules.IndexOf($rule)
            It "passes the PSScriptAnalyzer Rule number $i - $rule  " {
                (Invoke-ScriptAnalyzer -Path "$here\$sut" -IncludeRule $rule.RuleName ).Count | Should Be 0 
            }
        }
    }
}
Describe 'Tests For Help' -Tag Invoke-SqlFailOverDetection {
    # The module-qualified command fails on Microsoft.PowerShell.Archive cmdlets 
    $Help = Get-Help $Name -ErrorAction SilentlyContinue 

    # Should be a description for every function 
    It "gets description for $Name" { 
        $Help.Description | Should Not BeNullOrEmpty 
    } 
 
    # Should be at least one example 
    It "gets example code from $Name" { 
        ($Help.Examples.Example | Select-Object -First 1).Code | Should Not BeNullOrEmpty 
    } 
 
    # Should be at least one example description 
    It "gets example help from $Name" { 
        ($Help.Examples.Example.Remarks | Select-Object -First 1).Text | Should Not BeNullOrEmpty 
    } 
 
    Context "Test parameter help for $Name" { 
	 
        $Common = 'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable', 'OutBuffer', 'OutVariable', 
        'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable' , 'Confirm', 'WhatIf'
        $command = Get-Command $name
        $parameters = $command.ParameterSets.Parameters | Sort-Object -Property Name -Unique | Where-Object { $_.Name -notin $common } 
        $parameterNames = $parameters.Name 
        $HelpParameterNames = $Help.Parameters.Parameter.Name| Where-Object { $_ -notin $common }  | Sort-Object -Unique 
	 
        foreach ($parameter in $parameters) { 
            $parameterName = $parameter.Name 
            $parameterHelp = $Help.parameters.parameter | Where-Object Name -EQ $parameterName 
		 
            # Should be a description for every parameter 
            It "gets help for parameter: $parameterName : in $Name" { 
                $parameterHelp.Description.Text | Should Not BeNullOrEmpty 
            } 
		 
            # Required value in Help should match IsMandatory property of parameter 
            It "help for $parameterName parameter in $Name has correct Mandatory value" { 
                $codeMandatory = $parameter.IsMandatory.toString() 
                $parameterHelp.Required | Should Be $codeMandatory 
            } 
			 
            # Parameter type in Help should match code 
            It "help for $Name has correct parameter type for $parameterName" { 
                $codeType = $parameter.ParameterType.Name 
                # To avoid calling Trim method on a null object. 
                $helpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() } 
                $helpType | Should be $codeType 
            } 
        } 
		 
        foreach ($helpParm in $HelpParameterNames) { 
            # Shouldn't find extra parameters in help. 
            It "finds help parameter in code: $helpParm" { 
                $helpParm -in $parameterNames | Should Be $true 
            } 
        } 
    } 
} 
Describe "$Name Tests" -Tag Invoke-SqlFailOverDetection {
    Context 'Function' {
        $MadatoryParams = 'InstallationFolder', 'DownloadFolder', 'DataFolder', 'SQLInstance'
        It 'Has Cmdlet Binding set to true' {
            (Get-Command $Name).CmdletBinding | Should -BeTrue
        }
        $MadatoryParams.ForEach{
            It "$Name Should have a mandatory parameter $PsItem" {
                (Get-Command $Name).Parameters[$PsItem].Attributes.Mandatory | Should -BeTrue -Because "The Parameter $Psitem should be mandatory for $Name"
            }
        }
        $Params = 'AvailabilityGroup', 'AlreadyDownloaded', 'Analyze', 'Show'
        $Params.ForEach{
            It "$Name Should have a parameter $PSItem" {
                (Get-Command $Name).Parameters[$PSItem].Count | Should -Be 1 -Because "We need to have the Parameter $PSItem for $Name"
            }
        }
    }
    Context 'Execution without folders existing and no switches' {
        Mock Write-Verbose {}
        Mock Write-Warning {}
        Mock New-Item {}
        function DownloadFile {}
        Mock DownloadFile {}
        Mock Expand-Archive {}

        Mock Get-DbaAvailabilityGroup {
            @{
                Name                 = 'DummyAgName'
                AvailabilityReplicas = @(
                    @{
                        Name = 'Dummy1'
                    },
                    @{
                        Name = 'Dummy2'
                    },
                    @{
                        Name = 'Dummy3'
                    },
                    @{
                        Name = 'Dummy4'
                    }
                )
            }
        }

        function Get-DbaErrorLogConfig {}
        Mock Get-DbaErrorLogConfig {
            @{
                LogPath = 'C:\Summat\Summat'
            }
        }
        Mock Copy-Item {}
        Mock Get-ChildItem {'Summat'} # because otherwise nothing passes down the pipeline to copy-item
        Mock Get-ClusterLog {}
        Mock Get-Eventlog {'Summat'} # because otherwise nothing passes down the pipeline to copy-item
        Mock Out-File {}
        Mock Set-Location {}
        Mock Export-Csv {}
        function RunFailOverDetection {}
        Mock RunFailOverDetection {}

        Mock Test-Path {$false}
        Mock Test-Path {$true} -ParameterFilter {$Path -and $path -like '*Download\FailoverDetector.zip'}

        $InstallationFolder = 'C:\temp\'
        $DownloadFolder = 'C:\temp\Download'
        $DataFolder = 'C:\temp\'
        $SQLInstance = 'Dummy'

        $invokeSqlFailOverDetectionSplat = @{
            DownloadFolder     = $DownloadFolder
            SQLInstance        = $SQLInstance
            DataFolder         = $DataFolder
            InstallationFolder = $InstallationFolder
        }
        Invoke-SqlFailOverDetection @invokeSqlFailOverDetectionSplat
        It 'Should Create the Required Folders' {
            $assertMockParams = @{
                'CommandName' = 'New-Item'
                'Times'       = 8
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "The New-item function is called whenver we create folders" 
        }
        It 'Should Downlaod the file' {
            $assertMockParams = @{
                'CommandName' = 'DownloadFile'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We want to download the files otherwise how can we extract them" 
        }
        It 'Should Extract the file' {
            $assertMockParams = @{
                'CommandName' = 'Expand-Archive'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to extract the zipped files otherwise how can we run them?" 
        }
        It 'Should get the Availability Group Information' {
            $assertMockParams = @{
                'CommandName' = 'Get-DbaAvailabilityGroup'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the replica names from the Availablity Group" 
        }
        It 'Should get the location of the Error Log once per replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-DbaErrorLogConfig'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the error log locatio for each replica" 
        }
        It 'Should get the cluster log once per replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-ClusterLog'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the cluster log from each replica to perform the analysis" 
        }
        It 'Should get the system event log once per replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-Eventlog'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the system event log from each replica to perform the analysis" 
            $assertMockParams = @{
                'CommandName' = 'Export-Csv'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the system event log from each replica to perform the analysis" 
        }
        It 'Should copy the files to the Data Folder' {
            $assertMockParams = @{
                'CommandName' = 'Copy-Item'
                'Times'       = 21
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "How else will we ge thte files ready fo rth eapplication?" 
        }
        It 'Should create the JSON file' {
            $assertMockParams = @{
                'CommandName' = 'Out-File'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "The configuration JSON is needed" 
        }
        It 'Should create the Executable' {
            $assertMockParams = @{
                'CommandName' = 'RunFailOverDetection'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "The configuration JSON is needed" 
        }

    }
    Context 'Execution with folders existing and no switches' {
        Mock Write-Verbose {}
        Mock Write-Warning {}
        Mock New-Item {}
        function DownloadFile {}
        Mock DownloadFile {}
        Mock Expand-Archive {}

        Mock Get-DbaAvailabilityGroup {
            @{
                Name                 = 'DummyAgName'
                AvailabilityReplicas = @(
                    @{
                        Name = 'Dummy1'
                    },
                    @{
                        Name = 'Dummy2'
                    },
                    @{
                        Name = 'Dummy3'
                    },
                    @{
                        Name = 'Dummy4'
                    }
                )
            }
        }

        function Get-DbaErrorLogConfig {}
        Mock Get-DbaErrorLogConfig {
            @{
                LogPath = 'C:\Summat\Summat'
            }
        }
        Mock Copy-Item {}
        Mock Get-ChildItem {'Summat'} # because otherwise nothing passes down the pipeline to copy-item
        Mock Get-ClusterLog {}
        Mock Get-Eventlog {'Summat'} # because otherwise nothing passes down the pipeline to copy-item
        Mock Out-File {}
        Mock Set-Location {}
        Mock Export-Csv {}
        function RunFailOverDetection {}
        Mock RunFailOverDetection {}

        Mock Test-Path {$true}

        $InstallationFolder = 'C:\temp\'
        $DownloadFolder = 'C:\temp\Download'
        $DataFolder = 'C:\temp\'
        $SQLInstance = 'Dummy'

        $invokeSqlFailOverDetectionSplat = @{
            DownloadFolder     = $DownloadFolder
            SQLInstance        = $SQLInstance
            DataFolder         = $DataFolder
            InstallationFolder = $InstallationFolder
        }
        Invoke-SqlFailOverDetection @invokeSqlFailOverDetectionSplat
        It 'Should Not Create the Required Folders' {
            $assertMockParams = @{
                'CommandName' = 'New-Item'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "Dont create folders if they already exist" 
        }
        It 'Should Downlaod the file' {
            $assertMockParams = @{
                'CommandName' = 'DownloadFile'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We want to download the files otherwise how can we extract them" 
        }
        It 'Should Extract the file' {
            $assertMockParams = @{
                'CommandName' = 'Expand-Archive'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to extract the zipped files otherwise how can we run them?" 
        }
        It 'Should get the Availability Group Information' {
            $assertMockParams = @{
                'CommandName' = 'Get-DbaAvailabilityGroup'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the replica names from the Availablity Group" 
        }
        It 'Should get the location of the Error Log once per replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-DbaErrorLogConfig'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the error log locatio for each replica" 
        }
        It 'Should get the cluster log once per replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-ClusterLog'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the cluster log from each replica to perform the analysis" 
        }
        It 'Should get the system event log once per replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-Eventlog'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the system event log from each replica to perform the analysis" 
            $assertMockParams = @{
                'CommandName' = 'Export-Csv'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the system event log from each replica to perform the analysis" 
        }
        It 'Should copy the files to the Data Folder' {
            $assertMockParams = @{
                'CommandName' = 'Copy-Item'
                'Times'       = 21
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "How else will we ge thte files ready fo rth eapplication?" 
        }
        It 'Should create the JSON file' {
            $assertMockParams = @{
                'CommandName' = 'Out-File'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "The configuration JSON is needed" 
        }
        It 'Should create the Executable' {
            $assertMockParams = @{
                'CommandName' = 'RunFailOverDetection'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "The configuration JSON is needed" 
        }

    }
    Context 'Execution with folders existing and AlreadyDownloaded switch' {
        Mock Write-Verbose {}
        Mock Write-Warning {}
        Mock New-Item {}
        function DownloadFile {}
        Mock DownloadFile {}
        Mock Expand-Archive {}

        Mock Get-DbaAvailabilityGroup {
            @{
                Name                 = 'DummyAgName'
                AvailabilityReplicas = @(
                    @{
                        Name = 'Dummy1'
                    },
                    @{
                        Name = 'Dummy2'
                    },
                    @{
                        Name = 'Dummy3'
                    },
                    @{
                        Name = 'Dummy4'
                    }
                )
            }
        }

        function Get-DbaErrorLogConfig {}
        Mock Get-DbaErrorLogConfig {
            @{
                LogPath = 'C:\Summat\Summat'
            }
        }
        Mock Copy-Item {}
        Mock Get-ChildItem {'Summat'} # because otherwise nothing passes down the pipeline to copy-item
        Mock Get-ClusterLog {}
        Mock Get-Eventlog {'Summat'} # because otherwise nothing passes down the pipeline to copy-item
        Mock Out-File {}
        Mock Set-Location {}
        Mock Export-Csv {}
        function RunFailOverDetection {}
        Mock RunFailOverDetection {}

        Mock Test-Path {$true}

        $InstallationFolder = 'C:\temp\'
        $DownloadFolder = 'C:\temp\Download'
        $DataFolder = 'C:\temp\'
        $SQLInstance = 'Dummy'

        $invokeSqlFailOverDetectionSplat = @{
            DownloadFolder     = $DownloadFolder
            SQLInstance        = $SQLInstance
            DataFolder         = $DataFolder
            InstallationFolder = $InstallationFolder
            AlreadyDownloaded  = $true
        }
        Invoke-SqlFailOverDetection @invokeSqlFailOverDetectionSplat
        It 'Should Create the Required Folders' {
            $assertMockParams = @{
                'CommandName' = 'New-Item'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "Dont create folders if they already exist" 
        }
        It 'Should Not Downlaod the file' {
            $assertMockParams = @{
                'CommandName' = 'DownloadFile'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "Thats the point of the AlreadyDownloaded switch!" 
        }
        It 'Should Not Extract the file' {
            $assertMockParams = @{
                'CommandName' = 'Expand-Archive'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We dont need to extraxct it if it has already been downloaded" 
        }
        It 'Should get the Availability Group Information' {
            $assertMockParams = @{
                'CommandName' = 'Get-DbaAvailabilityGroup'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the replica names from the Availablity Group" 
        }
        It 'Should get the location of the Error Log once per replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-DbaErrorLogConfig'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the error log locatio for each replica" 
        }
        It 'Should get the cluster log once per replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-ClusterLog'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the cluster log from each replica to perform the analysis" 
        }
        It 'Should get the system event log once per replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-Eventlog'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the system event log from each replica to perform the analysis" 
            $assertMockParams = @{
                'CommandName' = 'Export-Csv'
                'Times'       = 4
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the system event log from each replica to perform the analysis" 
        }
        It 'Should copy the files to the Data Folder' {
            $assertMockParams = @{
                'CommandName' = 'Copy-Item'
                'Times'       = 21
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "How else will we ge thte files ready fo rth eapplication?" 
        }
        It 'Should create the JSON file' {
            $assertMockParams = @{
                'CommandName' = 'Out-File'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "The configuration JSON is needed" 
        }
        It 'Should create the Executable' {
            $assertMockParams = @{
                'CommandName' = 'RunFailOverDetection'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "The configuration JSON is needed" 
        }

    }
    Context 'Execution with folders existing and Analyze switch' {
        Mock Write-Verbose {}
        Mock Write-Warning {}
        Mock New-Item {}
        function DownloadFile {}
        Mock DownloadFile {}
        Mock Expand-Archive {}

        Mock Get-DbaAvailabilityGroup {
            @{
                Name                 = 'DummyAgName'
                AvailabilityReplicas = @(
                    @{
                        Name = 'Dummy1'
                    },
                    @{
                        Name = 'Dummy2'
                    },
                    @{
                        Name = 'Dummy3'
                    },
                    @{
                        Name = 'Dummy4'
                    }
                )
            }
        }

        function Get-DbaErrorLogConfig {}
        Mock Get-DbaErrorLogConfig {
            @{
                LogPath = 'C:\Summat\Summat'
            }
        }
        Mock Copy-Item {}
        Mock Get-ChildItem {'Summat'} # because otherwise nothing passes down the pipeline to copy-item
        Mock Get-ClusterLog {}
        Mock Get-Eventlog {'Summat'} # because otherwise nothing passes down the pipeline to copy-item
        Mock Out-File {}
        Mock Set-Location {}
        Mock Export-Csv {}
        function RunFailOverDetection {}
        Mock RunFailOverDetection {}

        Mock Test-Path {$true}

        $InstallationFolder = 'C:\temp\'
        $DownloadFolder = 'C:\temp\Download'
        $DataFolder = 'C:\temp\'
        $SQLInstance = 'Dummy'

        $invokeSqlFailOverDetectionSplat = @{
            DownloadFolder     = $DownloadFolder
            SQLInstance        = $SQLInstance
            DataFolder         = $DataFolder
            InstallationFolder = $InstallationFolder
            Analyze = $true
        }
        Invoke-SqlFailOverDetection @invokeSqlFailOverDetectionSplats
        It 'Should Create the Required Folders' {
            $assertMockParams = @{
                'CommandName' = 'New-Item'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "Dont create folders if they already exist" 
        }
        It 'Should Not Downlaod the file' {
            $assertMockParams = @{
                'CommandName' = 'DownloadFile'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "Thats the point of the AlreadyDownloaded switch!" 
        }
        It 'Should Not Extract the file' {
            $assertMockParams = @{
                'CommandName' = 'Expand-Archive'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We dont need to extraxct it if it has already been downloaded" 
        }
        It 'Should get the Availability Group Information' {
            $assertMockParams = @{
                'CommandName' = 'Get-DbaAvailabilityGroup'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "We need to get the replica names from the Availablity Group" 
        }
        It 'Should Not get the location of the Error Log on any replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-DbaErrorLogConfig'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "Analyze means the data is there" 
        }
        It 'Should get Not the cluster log on any replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-ClusterLog'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "Analyze means the data is there"
        }
        It 'Should Not get the system event log on any replica' {
            $assertMockParams = @{
                'CommandName' = 'Get-Eventlog'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "Analyze means the data is there"
            $assertMockParams = @{
                'CommandName' = 'Export-Csv'
                'Times'       = 0
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "Analyze means the data is there"
        }
        It 'Should copy the files to the Data Folder' {
            $assertMockParams = @{
                'CommandName' = 'Copy-Item'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "Analyze means the data is there"
        }
        It 'Should create the JSON file' {
            $assertMockParams = @{
                'CommandName' = 'Out-File'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "The configuration JSON is needed" 
        }
        It 'Should create the Executable' {
            $assertMockParams = @{
                'CommandName' = 'RunFailOverDetection'
                'Times'       = 1
                'Exactly'     = $true
            }
         {Assert-MockCalled @assertMockParams} | Should -Not -Throw -Because "The configuration JSON is needed" 
        }

    }

}
