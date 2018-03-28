$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Install-DbaSSMS" {
    Mock Invoke-WebRequest {}
    Mock Write-Warning {}
    Mock Test-Path {$true}
    function Start-DbaFileDownload {}
    Mock Start-DbaFileDownload {}
    Mock Get-Process {}
    Mock Stop-Process {}
    Mock Start-Process {}
    Context "Input" {
        It "Should have a parameter of URL" {
            (Get-Command Install-DbaSSMS).Parameters['URL'].Count | Should -Be 1 -Because "We may want to change it"
        }
        It "URL Parameter should not be mandatory" {
            (Get-Command Install-DbaSSMS).Parameters['URL'].Attributes.Mandatory | Should -BeFalse -Because "We generally want to use the default value"
        }
        It "URL Parameter should be of type string" {
            (Get-Command Install-DbaSSMS).Parameters['URL'].ParameterType.Name | Should -Be 'String' -Because "What else would an URL be?"
        }
        It "Should have a parameter of DownloadPath" {
            (Get-Command Install-DbaSSMS).Parameters['DownloadPath'].Count | Should -Be 1 -Because "We may need to set a folder we want to download"
        }
        It "DownloadPath Parameter should not be mandatory" {
            (Get-Command Install-DbaSSMS).Parameters['DownloadPath'].Attributes.Mandatory | Should -BeFalse -Because "We generally want to use the default value"
        }
        It "DownloadPath Parameter should be of type string" {
            (Get-Command Install-DbaSSMS).Parameters['DownloadPath'].ParameterType.Name | Should -Be 'String' -Because "What else would an URL be?"
        }
        It "Should throw if no access to Download Path if it is specified" {
            Mock Test-Path {$false}

            { Install-DbaSSMS -DownloadPath 'madeup'} | Should -Throw -Because "We need to be able to access the path"

            $assertMockParams = @{
                'CommandName' = 'Test-Path'
                'Times'       = 1
                'Exactly'     = $true
            }
            Assert-MockCalled @assertMockParams
        }
        It "Should write a warning if no access to default Download Path" {
            Mock Test-Path {$false}

            Install-DbaSSMS 

            $assertMockParams = @{
                'CommandName' = 'Test-Path'
                'Times'       = 1
                'Exactly'     = $true
                'Scope'       = 'It'
            }
            Assert-MockCalled @assertMockParams

            $assertMockParams = @{
                'CommandName' = 'Write-Warning'
                'Times'       = 1
                'Exactly'     = $true
                'Scope'       = 'It'
            }
            Assert-MockCalled @assertMockParams
        }
        It "Should have a parameter of Upgrade" {
            (Get-Command Install-DbaSSMS).Parameters['Upgrade'].Count | Should -Be 1 -Because "We want to enable upgrades"
        }
        It "Upgrade Parameter should not be mandatory" {
            (Get-Command Install-DbaSSMS).Parameters['Upgrade'].Attributes.Mandatory | Should -BeFalse -Because "The default should be full install"
        }
        It "Upgrade Parameter should be of type Switch" {
            (Get-Command Install-DbaSSMS).Parameters['Upgrade'].ParameterType.Name | Should -Be 'SwitchParameter' -Because "It only needs to be a switch"
        }
        It "Should have a parameter of OffLine" {
            (Get-Command Install-DbaSSMS).Parameters['OffLine'].Count | Should -Be 1 -Because "We want to enable offline installation"
        }
        It "OffLine Parameter should not be mandatory" {
            (Get-Command Install-DbaSSMS).Parameters['OffLine'].Attributes.Mandatory | Should -BeFalse -Because "The default should be online"
        }
        It "OffLine Parameter should be of type Switch" {
            (Get-Command Install-DbaSSMS).Parameters['OffLine'].ParameterType.Name | Should -Be 'SwitchParameter' -Because "It only needs to be a switch"
        }
        It "Should have a parameter of FilePath" {
            (Get-Command Install-DbaSSMS).Parameters['FilePath'].Count | Should -Be 1 -Because "We want to enable offline installation"
        }
        It "FilePath Parameter should not be mandatory" {
            (Get-Command Install-DbaSSMS).Parameters['FilePath'].Attributes.Mandatory | Should -BeFalse -Because "The default should be online"
        }
        It "FilePath Parameter should be of type String" {
            (Get-Command Install-DbaSSMS).Parameters['FilePath'].ParameterType.Name | Should -Be 'String' -Because "What else would a filepath be?"
        }
    }
    Context "Execution" {
        It "Should Not Throw" {
            { Install-dbassms }| Should -Not -Throw
        }

        Install-DbaSSMS

        It "Should get the download link from the web-site" {
            $assertMockParams = @{
                'CommandName' = 'Invoke-WebRequest'
                'Times'       = 2
                'Exactly'     = $true
            }
            Assert-MockCalled @assertMockParams
        }

        It "Should Download the file" {
            $assertMockParams = @{
                'CommandName' = 'Start-DbaFileDownload'
                'Times'       = 2
                'Exactly'     = $true
            }
            Assert-MockCalled @assertMockParams
        }

        It "Should run the install fiile" {
            $assertMockParams = @{
                'CommandName' = 'Start-Process'
                'Times'       = 2
                'Exactly'     = $true
            }
            Assert-MockCalled @assertMockParams
        }
        It "Should close SSMS if it is running" {
            # Just a thing to pass the if
            Mock Get-Process {'a thing'}
            Install-DbaSSMS
            $assertMockParams = @{
                'CommandName' = 'Stop-Process'
                'Times'       = 1
                'Exactly'     = $true
                'Scope'       = 'It'
            }
            Assert-MockCalled @assertMockParams
        }

        It "Should not contact the web if offline switch is used" {
            Install-DbaSSMS -Offline -FilePath 'DummyFile'
            $assertMockParams = @{
                'CommandName' = 'Start-DbaFileDownload'
                'Times'       = 0
                'Exactly'     = $true
                'Scope'       = 'It'
            }
            Assert-MockCalled @assertMockParams
        }

        It "Should Write a warning if it errors installing" {
            Mock Start-Process {Throw} 
            Install-DbaSSMS
            $assertMockParams = @{
                'CommandName' = 'Write-Warning'
                'Times'       = 1
                'Exactly'     = $true
                'Scope'       = 'It'
            }
            Assert-MockCalled @assertMockParams
        }

        It "Should Stop if it fails to get download link" {
            Mock Invoke-WebRequest {Throw}
            Install-DbaSSMS
            $assertMockParams = @{
                'CommandName' = 'Write-Warning'
                'Times'       = 1
                'Exactly'     = $true
                'Scope'       = 'It'
            }
            Assert-MockCalled @assertMockParams
        }
        Mock Invoke-WebRequest {}

        It "Should Write a warning if it errors downloading the file" {
            Mock Start-DbaFileDownload {Throw} 
            Install-DbaSSMS
            $assertMockParams = @{
                'CommandName' = 'Write-Warning'
                'Times'       = 1
                'Exactly'     = $true
                'Scope'       = 'It'
            }
            Assert-MockCalled @assertMockParams
        }

    }
    
    Context "Output" {

    }

    ## Add Script Analyser Rules
    Context "Testing Install-DbaSSMS for Script Analyser" {
        $Rules = Get-ScriptAnalyzerRule 
        $Name = $sut.Split('.')[0]
        foreach ($rule in $rules) { 
            $i = $rules.IndexOf($rule)
            It "passes the PSScriptAnalyzer Rule number $i - $rule  " {
                (Invoke-ScriptAnalyzer -Path "$here\$sut" -IncludeRule $rule.RuleName ).Count | Should Be 0 
            }
        }
    }

    ##            	
    ## 	.NOTES
    ## 		===========================================================================
    ## 		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.119
    ## 		Created on:   	4/12/2016 1:11 PM
    ## 		Created by:   	June Blender
    ## 		Organization: 	SAPIEN Technologies, Inc
    ## 		Filename:		*.Help.Tests.ps1
    ## 		===========================================================================
    ## 	.DESCRIPTION
    ## 	To test help for the commands in a module, place this file in the module folder.
    ## 	To test any module from any path, use https://github.com/juneb/PesterTDD/Module.Help.Tests.ps1
    ## 
    ##     ## ALTERED FOR ONE COMMAND - Rob Sewell 10/05/2017
    ## 
    $commandName = 'Install-DbaSSMS'
    Describe "Test help for $commandName" {
        # The module-qualified command fails on Microsoft.PowerShell.Archive cmdlets
        $Help = Get-Help $commandName -ErrorAction SilentlyContinue
        # If help is not found, synopsis in auto-generated help is the syntax diagram
        It "should not be auto-generated" {
            $Help.Synopsis | Should Not BeLike '*`[`<CommonParameters`>`]*'
        }
    
        # Should be a description for every function
        It "gets description for $commandName" {
            $Help.Description | Should Not BeNullOrEmpty
        }
    
        # Should be at least one example
        It "gets example code from $commandName" {
            ($Help.Examples.Example | Select-Object -First 1).Code | Should Not BeNullOrEmpty
        }
    
        # Should be at least one example description
        It "gets example help from $commandName" {
            ($Help.Examples.Example.Remarks | Select-Object -First 1).Text | Should Not BeNullOrEmpty
        }
    
        Context "Test parameter help for $commandName" {
            $command = Get-Command $CommandName
            $Common = 'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable', 'OutBuffer', 'OutVariable',
            'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable', 'Confirm', 'Whatif'
        
            $parameters = $command.ParameterSets.Parameters | Sort-Object -Property Name -Unique | Where-Object Name -notin $common
            $parameterNames = $parameters.Name
            $HelpParameterNames = $Help.Parameters.Parameter.Where{$_.Name -notin $common}.Name | Sort-Object -Unique
        
            foreach ($parameter in $parameters) {
                $parameterName = $parameter.Name
                $parameterHelp = $Help.parameters.parameter | Where-Object Name -EQ $parameterName
            
                # Should be a description for every parameter
                It "gets help for parameter: $parameterName : in $commandName" {
                    $parameterHelp.Description.Text | Should Not BeNullOrEmpty
                }
            
                # Required value in Help should match IsMandatory property of parameter
                It "help for $parameterName parameter in $commandName has correct Mandatory value" {
                    $codeMandatory = $parameter.IsMandatory.toString()
                    $parameterHelp.Required | Should Be $codeMandatory
                }
            
                # Parameter type in Help should match code
                It "help for $commandName has correct parameter type for $parameterName" {
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
}
