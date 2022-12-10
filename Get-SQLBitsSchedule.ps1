<#
.SYNOPSIS
Gets the SQLBits Schedule from the Sessionize API

.DESCRIPTION
Gets the SQLBits Schedule from the Sessionize API and outputs to json, excel, psobject, html or csv

.PARAMETER Output
The type of output required. Valid values are json, excel, psobject, html or csv

.PARAMETER fileDirectory
The directory to save the output file to - defaults to Env:Temp

.PARAMETER Show
Whether to open the output file after it has been created

.EXAMPLE
Get-SQLBitsSchedule  -Output Excel -Show

Gets the SQLBits Schedule from the Sessionize API and outputs to excel, opens the file and saves it to the default temp directory

.EXAMPLE
Get-SQLBitsSchedule  -Output Raw

Gets the SQLBits Schedule from the Sessionize API and outputs as json on the screen

.EXAMPLE
Get-SQLBitsSchedule  -Output csv -Show

Gets the SQLBits Schedule from the Sessionize API and outputs to csv, opens the file and saves it to the default temp directory

.EXAMPLE
Get-SQLBitsSchedule  -Output object

Gets the SQLBits Schedule from the Sessionize API and outputs as a psobject on the screen

.EXAMPLE
Get-SQLBitsSchedule  -Output html -Show

Gets the SQLBits Schedule from the Sessionize API and outputs to html, opens the file and saves it to the default temp directory

.NOTES
Author: Rob Sewell
December 2022
#>
function Get-SQLBitsSchedule {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('raw', 'excel', 'object', 'csv', 'html')]
        $Output = 'excel',
        [string]
        $fileDirectory = $env:TEMP,
        [switch]
        $Show
    )

    $BaseUri = 'https://sessionize.com/api/v2/u1qovn3p/view'
    $Date = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'

    #TODO Add other opttions
    $filter = 'Schedule'
    switch ($filter) {
        'All' { 
            $uri = '{0}/All' -f $BaseUri
        }
        'Schedule' { 
            $uri = '{0}/All' -f $BaseUri
        }
        'Sessions' { 
            $uri = '{0}/sessions' -f $BaseUri
        }
        'Speakers' { 
            $uri = '{0}/speakers' -f $BaseUri
        }
        Default {
            $uri = '{0}/All' -f $BaseUri
        }
    }

    $Data = Invoke-RestMethod -Uri $uri
    $rooms = ($data.rooms | Sort-Object name)
    $Speakers = $data.speakers
    # Thank you Shane - https://nocolumnname.blog/2020/10/29/pivot-in-powershell/
    $props = @(
        @{ Name = 'Day' ; Expression = { $Psitem.Group[0].startsAt.DayOfWeek } }
        @{ Name = 'Date' ; Expression = { $Psitem.Group[0].startsAt.tolongdatestring() } }
        @{ Name = 'StartTime' ; Expression = { $Psitem.Group[0].startsAt.ToShortTimeString() } }
        @{ Name = 'EndTime' ; Expression = { $Psitem.Group[0].EndsAt.ToShortTimeString() } }
        foreach ($room in $rooms) {
            $rn = $room.Name
            @{ 
                Name       = $rn
                Expression = { 
                    '{0}
{1}'  -f @(
                        ($Psitem.Group | Where-Object { $PSItem.roomID -eq $room.id }).title,
                        (($Psitem.Group | Where-Object { $PSItem.roomID -eq $room.id }).Speakers.ForEach{ $Speakers | Where-Object id -EQ $_ }.FullName -join ' ')
                    )

                }.GetNewClosure()
            }
        }
    )

    $sessions = $Data.sessions | Group-Object -Property StartsAt | Select-Object $props 

    switch ($output) {
        'Raw' {
            $Data
        }
        'object' {
            $sessions
        }
        'Excel' {
            if (Get-Module -Name ImportExcel -ErrorAction SilentlyContinue -ListAvailable) {
                if ($filter -eq 'Schedule') {

                    $FilePath = '{0}\SQLBitsSchedule{1}_{2}.xlsx' -f $fileDirectory, $filter, $Date

                    $sessions | Group-Object Day | ForEach-Object {

                        $worksheetName = $_.Name
                        $excel = $_.Group | Export-Excel -Path $FilePath -WorksheetName $worksheetName -AutoSize  -FreezePane 2, 5 -PassThru
                        1..15 | ForEach-Object {
                            Set-ExcelRow -ExcelPackage $excel -WorksheetName $worksheetName -Row $_ -Height 30 -WrapText
                        }

                        $rulesparam = @{
                            Address   = $excel.Workbook.Worksheets[$WorkSheetName].Dimension.Address
                            WorkSheet = $excel.Workbook.Worksheets[$WorkSheetName]
                        }

                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Coffee Break",$E1)))' -BackgroundColor GoldenRod -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Quick Break",$E1)))' -BackgroundColor GoldenRod -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Keynote",$E1)))' -BackgroundColor BlueViolet -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Lunch",$E1)))' -BackgroundColor Chocolate  -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Prize",$E1)))' -BackgroundColor PowderBlue  -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Free Time",$E1)))' -BackgroundColor GoldenRod  -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Registration",$E1)))' -BackgroundColor DarkOrange  -ForegroundColor White -StopIfTrue
                    
                        Close-ExcelPackage $excel
                    }
                    if ($Show) {
                        Invoke-Item $filepath
                    }
                }
            } else {
                Write-Warning 'You need to install ImportExcel to use this option but here is a CSV instead'
                $FilePath = '{0}\SQLBits_{1}_{2}.csv' -f $fileDirectory, $filter, $Date
                $sessions | Sort-Object Day, StartsAt | Export-Csv -Path $FilePath -NoTypeInformation
                if ($Show) {
                    Invoke-Item $filepath
                }
            }

        }
        'CSv' {
            $FilePath = '{0}\SQLBits_{1}_{2}.csv' -f $fileDirectory, $filter, $Date
            $sessions | Sort-Object Day, StartsAt | Export-Csv -Path $FilePath -NoTypeInformation
            if ($Show) {
                Invoke-Item $filepath
            }
        }
        'html' {
            $FilePath = '{0}\SQLBits_{1}_{2}.html' -f $fileDirectory, $filter, $Date
            $sessions | ConvertTo-Html | out-file $FilePath
                if ($Show) {
                    Invoke-Item $filepath
                }
        }
        Default {

        }
    }
}
# Get-SQLBitsSchedule  -Output Excel -Show
# Get-SQLBitsSchedule  -Output Raw 
# Get-SQLBitsSchedule  -Output csv -Show
# Get-SQLBitsSchedule  -Output object
# Get-SQLBitsSchedule  -Output html -Show
