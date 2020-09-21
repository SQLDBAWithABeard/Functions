<#

This rough and ready script will change the scene in Streamlabs 
when the PowerPoint Slide changes
AND
the first line of the notes on the slide 
is

OBS:NAMEOFSCENE

It will only work on Windows PowerShell unless someone knows how
to get PowerPoint com objects with events in PowerShell core.

#>
#region Setup Slobs
function Add-BeardSlobsConnection {
    $npipeClient = New-Object System.IO.Pipes.NamedPipeClientStream($Env:ComputerName, 'slobs', [System.IO.Pipes.PipeDirection]::InOut, [System.IO.Pipes.PipeOptions]::None, [System.Security.Principal.TokenImpersonationLevel]::Impersonation)
    $npipeClient.Connect()
    $npipeClient
}

function New-BeardSlobsReader {
    param($pipeClient)
    New-Object System.IO.StreamReader($pipeClient)
}

function New-BeardSlobsWriter {
    param($pipeClient)
    New-Object System.IO.StreamWriter($pipeClient)
}



function  Get-BeardSlobsScene {
    $scenesMessage = '{"jsonrpc": "2.0","id": 6,"method": "getScenes","params": {"resource": "ScenesService"}}'
    $pipeWriter.WriteLine($scenesMessage)
    ($pipeReader.ReadLine() | ConvertFrom-Json).result | Select Name, id
}



function Set-BeardSlobsObsScene {
    Param($SceneName)
    $SceneId = ($scenes | Where Name -eq $SceneName).id
    $MakeSceneActiveMessage = '{    "jsonrpc": "2.0",    "id": 1,    "method": "makeSceneActive",    "params": {        "resource": "ScenesService","args": ["' + $SceneId + '"]}}'  
    $pipeWriter.WriteLine($MakeSceneActiveMessage)
    $switchResults = $pipeReader.ReadLine() | ConvertFrom-Json
}

#endregion

#region Setup PowerPoint

function New-BeardSlobsPowerPoint {
    $Application = New-Object -ComObject PowerPoint.Application
    $Application.Visible = 'MsoTrue'
    $Application
}


function Set-BeardSlobsNextSlide {
    $slideNumber = $PowerPoint.SlideShowWindows[1].view.Slide.SlideIndex
    Write-Host " I went to slide $slideNumber"
    $notes = $PowerPoint.SlideShowWindows[1].View.Slide.NotesPage.Shapes[2].TextFrame.TextRange.Text
    if ($Notes) {
        Write-Host "The notes are $notes"
        $SceneName = ($notes -split "`r")[0] -replace 'OBS:', ''
        Write-Host "The scene name is $SceneName"
        Set-BeardSlobsObsScene -SceneName $SceneName
    }
    else {
        Write-Host "There are no notes"
    }
}


    $Client = Add-BeardSlobsConnection
    $pipeReader = New-BeardSlobsReader -pipeClient $Client
    $pipeWriter = New-BeardSlobsWriter -pipeClient $Client
    $pipeWriter.AutoFlush = $true
    $scenes = Get-BeardSlobsScene
    $PowerPoint = New-BeardSlobsPowerPoint

    $action = { Set-BeardSlobsNextSlide }
    #subscribe to the event generated when the refresh action is completed so we know when to move on to trying to save
    $subscriber = Register-ObjectEvent -InputObject $PowerPoint -EventName SlideShowNextSlide -Action $action 



#endregion

$PowerPoint.SlideShowWindows[1].View.Slide.NotesPage.Shapes[2].TextFrame.TextRange.Text 