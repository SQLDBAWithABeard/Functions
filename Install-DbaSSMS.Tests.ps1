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

        It "Should run the install fiile"{
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
                'Scope' = 'It'
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
}
