## This needs to be run as a file available to the agent service

## as a SQLCMD step

## powershell.exe 'path to file'

Write-Output "Starting Copy of XXXX database from SourceServerName to DestServerName"

try {
    $params = @{
        Source = '' 
        Destination = '' 
        Database = '' 
        BackupRestore = $true
        NetworkShare = '' 
        WithReplace = $true
        EnableException = $true
        Verbose = $true
    }
$output = Copy-DbaDatabase @Params
}
Catch
{
    $CopyError = $error[0..5] | fl -force
    $CopyError = $CopyError | OUt-String
    Write-Error $CopyError

    [System.Environment]::Exit(1)
}
if ($output.Status = 'Failed') {
$CopyError = $error[0..5] | fl -force
    $CopyError = $CopyError | OUt-String
    Write-Error $CopyError
[System.Environment]::Exit(1)
}
