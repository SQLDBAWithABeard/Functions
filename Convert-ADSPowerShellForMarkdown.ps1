
function Convert-ADSPowerShellForMarkdown {
    <#
    .SYNOPSIS
    Converts PowerShell code into valid Markdown URI Link text
    
    .DESCRIPTION
    Converts PowerShell code into valid Markdown URI Link Text
    
    .PARAMETER inputstring
    The endoded URL from the website

    .PARAMETER LinkText
    The text to show for the link
    
    .PARAMETER ToClipBoard
    Will not output to screen but instead will set the clipboard
    
    .EXAMPLE
    Convert-ADSPowerShellForMarkdown if+%28-not+%28%24IsLinux+-or+%24IsMacOS%29+%29+%7B%0D%0A++++if+%28-not%28Test-Path+C%3A%5C%5CMSSQL%5C%5CBACKUP%29%29+%7B%0D%0A++++++++Write-Output+%22I%27m+going+to+create+C%3A%5C%5CMSSQL%5C%5CBACKUPS+so+that+the+docker-compose+will+work%22%0D%0A++++++++New-Item+C%3A%5CMSSQL1%5CBACKUP1+-ItemType+Directory%0D%0A++++%7D%0D%0A++++else+%7B%0D%0A++++++++Write-Output+%22C%3A%5C%5CMSSQL%5C%5CBACKUPS+already+exists%22%0D%0A++++%7D%0D%0A%7D%0D%0Aelse+%7B%0D%0A++++Write-Warning+%22Sorry+This+code+won%27t+run+on+Linux+-+You+will+have+to+do+it+manually+and+edit+the+docker+compose+file%22%0D%0A%7D -ToClipBoard

    Converts the encoded URL so that it works with MarkDown and sets it to the clipboard
    
    .NOTES
    June 2019 - Rob Sewell @SQLDbaWithBeard
    SQLDBAWithABeard.Com
    #>
    
    Param(
        [Parameter(Mandatory = $true)]
        [string]$inputstring,
        [string]$linktext = " LINK TEXT HERE ",
        [switch]$ToClipBoard
    )
    clear
    [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
    $encodedstring = [System.Web.HttpUtility]::UrlEncode($inputstring) 
    $linkage = $encodedstring.Replace('+', ' ').Replace('%3a', ':').Replace('%5c', '%5c%5c').Replace('%22', '\u0022').Replace('%27', '\u0027').Replace('%0D%0A', '').Replace('%3b%0a','\u0028 ')
    
    $outputstring = @"
<a href="command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%22 $linkage \u000D %22%7D">$linktext</a>
"@
    if ($ToClipBoard) {
        if (-not ($IsLinux -or $IsMacOS) ) {
            $outputstring | Set-Clipboard
        }
        else {
            Write-Warning "Set-Clipboard - Doesnt work on Linux - Outputting to screen" 
            $outputstring
        }
    }
    else {
        $outputstring
    }
}
