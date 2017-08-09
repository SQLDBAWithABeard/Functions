<#
.SYNOPSIS
Connects to the API at https://haveibeenpwned.com/ to see if a Password or Password hash has been found in a breach

.DESCRIPTION
Connects to the API at https://haveibeenpwned.com/ to see if a Password or Password hash has been found in a breach

Troy Hunt @troyhunt has created an API which allows you to query if a Password has been found in a breach. 
This is a simple function enabling you to query it

.PARAMETER Password
The password to check as a secure string. If not supplied will be prompted

.PARAMETER Hash
A SHA1 hash of the password to be checked

.EXAMPLE
$Password = Read-Host -AsSecureString
Get-PwnedPassword -Password Password

Connects to the API at https://haveibeenpwned.com/ and checks if a password has been found
in a breach.


.EXAMPLE
Get-PwnedPassword -Hash 8be3c943b1609fffbfc51aad666d0a04adf83c9d

Connects to the API at https://haveibeenpwned.com/ and checks if the SHA1 hash of 'Password' has been found
in a breach.

Don't run this. It has!!

.EXAMPLE
Get-PwnedPassword

Prompts for a Password and connects to the API at https://haveibeenpwned.com/ and checks if it has been found
in a breach.

.NOTES
    AUTHOR : Rob Sewell @sqldbawithbeard https://sqldbawithabeard.com 
    DATE : 4th August 2017

    With many many thanks to Troy Hunt for creating this service
    You can find Troy on Twitter @TroyHunt
    You can read his blog at https://troyhunt.com 
    You should defintely sign up for his service at https://haveibeenpwned.com/ 
    to be notified when your email is in a breach
.LINK
https://www.troyhunt.com/introducing-306-million-freely-downloadable-pwned-passwords/
#>
function Get-PwnedPassword {
    [CmdletBinding()] 
    Param(
        [Parameter()]
        [SecureString]$Password ,
        [Parameter()]
        [String]$Hash
    )

    if ((!$Password) -and (!$Hash)) {
        $Password = Read-Host -Prompt "Enter Password" -AsSecureString
        $Pass =  (New-Object PSCredential "user",$Password).GetNetworkCredential().Password
        $URL = 'https://haveibeenpwned.com/api/v2/pwnedpassword/' + $Pass
    }
    elseif ($hash) {
        $URL = 'https://haveibeenpwned.com/api/v2/pwnedpassword/' + $Hash
    }
    else {
        $Pass = ConvertFrom-SecureString $Password
        $URL = 'https://haveibeenpwned.com/api/v2/pwnedpassword/' + $Pass
    }
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        $Response = Invoke-WebRequest -Uri $URL -ErrorAction SilentlyContinue
    }
    catch [System.Net.WebException] {
        $400 = 'The remote server returned an error: (400) Bad Request.'
        $404 = 'The remote server returned an error: (404) Not Found.'
        $429 = 'The remote server returned an error: (429) Too Many Requests.'
        Switch ($_.Exception.Message) {
            $400 {Write-Error -Message "Bad Request - the account does not comply with an acceptable format - Did you forget the password ?"}
            $404 {Write-Output  "Hurrah! - No Password found - Congratulations this password has not been pwned. `nYou should still sign up for free at https://haveibeenpwned.com/ to be notified when your account is in a breach"}
            $429 {Write-Error -Message "Slow down! Too many requests — the rate limit has been exceeded"}
        }
        break
    }
    Switch ($Response.StatusCode) {
        200 {Write-Warning -Message "Oh No! - Password has been pwned - Change it NOW! `nYou should sign up for free at https://haveibeenpwned.com/ to be notified when your account is in a breach"}    
    }
}
<#PSScriptInfo

.VERSION 1.2

.GUID bc54fa58-2ebc-4a87-8dd7-ecdcae505288

.AUTHOR Rob Sewell @sqldbawithbeard https://sqldbawithabeard.com 

.DESCRIPTION Connects to the API at https://haveibeenpwned.com/ to see if a Password or Password hash has been found in a breach. Troy Hunt @troyhunt has created an API which allows you to query if a Password has been found in a breach. This is a simple function enabling you to query it
      
.COMPANYNAME Sewells Consulting

.COPYRIGHT 

.TAGS Pwned,Password,TroyHunt

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>