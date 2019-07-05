Function Get-FunctionCalls {
    <#
    .SYNOPSIS 
    Get's the functions called in a script and the the file containing those definitions
    
    .DESCRIPTION
    
    
    .PARAMETER FunctionName
    The root function name you're wanting to process
    
    .PARAMETER FunctionPaths
    An object linking a function's name to the the file containing it's definition. 
    Is built by the first call, and then passed to later calls.
    
    .PARAMETER ModulePath
    Path to the root of the powershell module you're analyzing
    
    .PARAMETER Depth
    How deep to recurse into the function calls.
    Default is 1. This will just load the functions called within the first function. Higher numbers increase the level of recurions, increasing the number of function definitions retrieved, and slowing down the Chronometer run
    0 - Will only load the definition of the root function
    
    .EXAMPLE
    $Path = Get-FunctionCalls -FunctionName Restore-DbaDataBase -ModulePath C:\dbatools\module\ -depth 1
    $Chronometer = @{
        Path = $Path.FileName
        Script = {Restore-DbaDatabase -SqlServer localhost\sqlexpress2016 -Path C:\dbatools\backups -WithReplace -OutputScriptOnly}
    }
    $results = Get-Chronometer @Chronometer
    
    Will scan all the ps1 files in c:\dbatools\Module for function definitions, and then will scan the definition of 
    Restore-DbaDatabase for function calls. As depth is set to 1, it will then add the definitions of those called functions
    from within the module to the Chronometer path. Higher depth values will scan for the definition of functions called in
    the next tier of functions recursively.
    
    .NOTES 
    Original Author: Stuart Moore (@napalmgram), https://stuart-moore.com
    Source tracked at https://github.com/Stuart-Moore/VariousHelperFunctions/blob/master/Get-FunctionCalls.ps1
    Written as a helper function to Kevin Marquette's Chronometer module (https://github.com/KevinMarquette/Chronometer)
    
    This parses the function to be analysed for it's definition and other functions it calls, so that an entire
    stack can be monitored without needin to manually build up the path or adding every file in the module and
    killing performance
    
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
    #>
            [CmdletBinding()]
            param (
            [string[]]$FunctionName,
            [object[]]$FunctionPaths,
            [String]$ModulePath,
            [int]$depth=1
            )
            if ($FunctionPaths -eq $null)
            {
                Write-Verbose "$FunctionName - Need to populate the paths to Function calls"
                $files = Get-ChildItem $ModulePath -filter *.ps1 -recurse
                $FunctionPaths = @()
                $null = $files | ForEach{Get-Content $_.FullName | Where-Object {$_ -match 'function\s(\w+-\w+)'} | %{$FunctionPaths += [PSCustomObject]@{Function = $Matches[1]; FileName = $_.PsPath}}}
            }
            $FunctionFile = $FunctionPaths | Where-Object {$_.Function -eq $FunctionName}
            $FileContents = Get-Content ($FunctionFile.FileName)
            $funcs = $FileContents | Where-Object {$_ -match '[^\s|(]\w+-\w+'}  | ForEach{$Matches[0]} | Select-Object -Unique
            $results = @()
            if ($depth -ge 1){
                Foreach ($func in $funcs){
                    $results += $FunctionPaths | Where-Object {$_.Function -eq $func}
                }
            }else{
                $results = $FunctionFile
            }
            if ($depth -gt 1)
            {
                Foreach ($call in $results)
                {
                    $results += Get-FunctionCalls -FunctionName $call.Function -FunctionPaths $FunctionPaths -depth ($depth-1) -ModulePath $ModulePath
                }    
            }
            $results | Select-Object -Unique -property Function,FileName
    }