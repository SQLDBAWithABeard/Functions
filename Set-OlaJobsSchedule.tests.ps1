$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".tests.", ".")
. "$here\$sut"
"$here\$sut"
$Rules = Get-ScriptAnalyzerRule

    Describe ‘Script Analyzer Tests’ {
            Context “Testing $sut for Standard Processing” {
                foreach ($rule in $rules) { 
                    It “passes the PSScriptAnalyzer Rule $rule“ {
                        (Invoke-ScriptAnalyzer -Path "$here\$sut" -IncludeRule $rule.RuleName ).Count | Should Be 0 
                    }
                }
            }
        }
 Describe 'Describe Block'{
              Context 'First Context' {}
    }
