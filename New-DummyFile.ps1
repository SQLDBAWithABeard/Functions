<#
.SYNOPSIS
Creates a dummy empty file of a specified size

.DESCRIPTION
This will create one or a number of empty files of a specified size
Useful for creating demos or dummy files to delete as an emergency when
drives are full

.PARAMETER FilePath
The Directory for the files

.PARAMETER Name
The Name of the file, will have underscore integer added if more than one file requested - If you include an extension it will retained otherwise it will have a .dmp extension

.PARAMETER Size
The Size of the File(s) to be created in Mb unless the Gb switch is used

.PARAMETER Number
The number of files to create defaults to 1

.PARAMETER Gb
Switch to change Size to Gb instead of Mb

.PARAMETER Force
OverWrite Existing Files

.EXAMPLE
New-DummyFile -FilePath C:\temp -Name Jeremy -Size 10 

Will create 1 file of size 10Mb called jeremy.dmp at C:\temp

.EXAMPLE
New-DummyFile -FilePath C:\temp -Name Jeremy.txt -Size 10 -Number 10

Will create 10 files of size 10Mb called jeremy_N.txt where N is 1-10 at C:\temp

.EXAMPLE
New-DummyFile -FilePath C:\temp -Name Jeremy -Size 10 -Gb

Will create 1 file of size 10Gb called jeremy.dmp at C:\temp

.EXAMPLE
New-DummyFile -FilePath C:\temp -Name Jeremy.txt -Size 10 -Number 10 -Gb

Will create 10 files of size 10Gb called jeremy_N.txt where N is 1-10 at C:\temp

.EXAMPLE
New-DummyFile -FilePath C:\temp -Name Jeremy -Size 10 -Force

Will create 1 file of size 10Mb called jeremy.dmp at C:\temp and overwrite the exisitng file if it exists

.NOTES
SQLDBAWithABeard @SqlDbaWithABeard
#>

function New-DummyFile {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [string]$Name = 'DummyFile',
        [Parameter(Mandatory = $true)]
        [int]$Size,
        [int]$Number = 1,
        [Switch]$Gb ,
        [switch]$Force
    )
    Begin {
        if ($Gb) {
            $SizeMsg = "$Size Gb"
        }
        else {
            $SizeMsg = "$Size Mb"
        }
        Write-Verbose "Creating $Number files of $SizeMsg named $Name at $FilePath "
        $fileSize = $Size * 1024 * 1024
        if ($Gb) {
            $fileSize = $fileSize * 1024
        }
    }
    Process {
        for ($i = 1; $i -le $Number; $i++) {
            $BaseName, $extension = $Name.Split('.')
            if ($null -eq $extension) { $extension = 'dmp' }
            if($i -ne 1){
                $FileName = "$FilePath\$($BaseName)_$i.$Extension"
            } else{
                $FileName = "$FilePath\$($BaseName).$Extension"
            }

            if (-not $Force) {
                if (Test-Path $FileName) {
                    Write-Warning "Nope I am not creating the file as -Force was not specified and $FileName already exists"
                    Continue
                }
            }
            if ($PSCmdlet.ShouldProcess("$FilePath", "Creating $FileName ($i/$Number) $FilePath\$FileName")) {
                $file = [System.IO.File]::Create($FileName)
                $file.SetLength($fileSize)
                $file.Close()
            }
        }
    }
    End {
        Write-Verbose "Done!"
    }
}
