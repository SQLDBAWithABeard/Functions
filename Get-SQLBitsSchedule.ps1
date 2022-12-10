function Get-SQLBitsSchedule {
    [CmdletBinding()]
    param (
        # [Parameter()]
        # [ValidateSet('All', 'Schedule', 'Sessions', 'Speakers')]
        # $filter = 'Schedule',
        # # How do you want it?
        [Parameter()]
        [ValidateSet('Raw', 'Excel')]
        $Output = 'Raw'
    )

    $BaseUri = 'https://sessionize.com/api/v2/u1qovn3p/view'
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

    switch ($output) {
        'Raw' { 
            $Data
        }
        'Excel' { 
            if (Get-Module -Name ImportExcel -ErrorAction SilentlyContinue -ListAvailable) {
                if ($filter -eq 'Schedule') {
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
                                        (($Psitem.Group | Where-Object { $PSItem.roomID -eq $room.id }).Speakers.ForEach{ $Speakers | Where-Object id -eq $_ }.FullName -join ' ')
                                    )
                    
                                 }.GetNewClosure()
                             }
                         }
                    )
                   $Date = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'
                   $FilePath = '{0}\SQLBitsSchedule{1}_{2}.xlsx' -f $env:TEMP, $filter, $Date
  
                 $sessions = $Data.sessions | Group-Object -Property StartsAt | Select-Object $props 

                 $sessions | Group-Object Day | ForEach-Object{
                   
                        $worksheetName = $_.Name
                        $excel = $_.Group | Export-Excel -Path $FilePath -WorksheetName $worksheetName -AutoSize  -FreezePane 2,5 -PassThru
                         1..15 | ForEach-Object {
                             Set-ExcelRow -ExcelPackage $excel -WorksheetName $worksheetName -Row $_ -Height 30 -WrapText
                         }
                        
                    
                        $rulesparam = @{
                            Address   = $excel.Workbook.Worksheets[$WorkSheetName].Dimension.Address
                            WorkSheet = $excel.Workbook.Worksheets[$WorkSheetName] 
                            RuleType  = 'Expression'      
                        }
                    
                        Add-ConditionalFormatting @rulesparam -ConditionValue '"Break",$E1)))' -BackgroundColor PaleGreen -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -ConditionValue 'NOT(ISERROR(FIND("Keynote",$E1)))' -BackgroundColor BlueViolet -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -ConditionValue 'NOT(ISERROR(FIND("Lunch",$E1)))' -BackgroundColor Chocolate 
                        Add-ConditionalFormatting @rulesparam -ConditionValue 'NOT(ISERROR(FIND("Prize",$E1)))' -BackgroundColor PowderBlue 
                        Add-ConditionalFormatting @rulesparam -ConditionValue 'NOT(ISERROR(FIND("Free",$E1)))' -BackgroundColor GoldenRod 
                        Add-ConditionalFormatting @rulesparam -ConditionValue 'NOT(ISERROR(FIND("Registration",$E1)))' -BackgroundColor DarkOrange 
                    
                        Close-ExcelPackage $excel 
                 }
                 Invoke-Item $filepath
                }
                
            } else {
                Write-Warning 'You need to install ImportExcel to use this option but here is a CSV instead'
                $Data | Export-Csv -Path .\SQLBitsSchedule.csv -NoTypeInformation
            }

        }
        Default {

        }
    }
}
Get-SQLBitsSchedule  -Output Excel 
<#
foreach ($day in $data[2]){
$Date = '{0} {1}' -f  $day.date.DayOfWeek, $day.date.ToLongDateString()
$Schedule = ''

}

($data.sessions | Group-Object startsat)[0]
v


    $SortedSessions = foreach ($time in ($data.sessions | Group-Object startsat).Group){
    $room = $data.rooms.where{$PsItem.id -eq $time.roomid}.name
    [PSCustomObject]@{
        startsat = $time.startsat
        endsat = $time.endsat
        
        $room = $time.title
    }
}
$SortedSessions | Export-Excel -Path c:\temp\sess.xlsx -Show
#>