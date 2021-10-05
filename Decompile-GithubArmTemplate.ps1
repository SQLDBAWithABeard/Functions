function Decompile-GithubArmTemplate {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $GithubPath,
        
        [Parameter()]
        [string]
        $Path,
        
        [Parameter()]
        [string]
        $FileName
    )

    if($GithubPath.StartsWith('https://raw.githubusercontent.com')){
        Write-Verbose "Well it looks like raw content URL"
    } elseif ($GithubPath.StartsWith('https://github.com')) {
        Write-Verbose "Well it looks like a base Github URL"
        $GithubPath = $GithubPath -replace 'github', 'raw.githubusercontent' -replace '/blob',''
        $Name = $GithubPath.Split('/')[-2] 

    }else{
        Write-Warning "Use the right path and start with https://"
        Return
    }

    $DownloadFile = "$env:TEMP\{0}.{1}" -f $Name, 'json'

    ($Path) ? ($outputPath = $Path) : ($outputPath = $Pwd.Path)
    ($FileName) ? ($FileName) : ($FileName = "$Name.{0}" -f 'bicep')
 
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($GithubPath, $DownloadFile)

    bicep decompile $DownloadFile --outfile "$outputPath\$FileName"

    Write-Output "Decompiled $GithubPath to $outputPath\$FileName" 
}