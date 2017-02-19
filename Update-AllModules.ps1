## from @jeffhicks https://gist.github.com/jdhitsolutions/8a49a59c5dd19da9dde6051b3e58d2d0#file-check-moduleupdate-ps1

## 
function Update-AllModules
{
[cmdletbinding()]
Param()
function Check-AllModules
{
[cmdletbinding()]
Param()
Write-Verbose "Getting installed modules" 
$modules = Get-Module -ListAvailable

#group to identify modules with multiple versions installed
$g = $modules | group name -NoElement | where count -gt 1

Write-Verbose "Filter to modules from the PSGallery"
$gallery = $modules.where({$_.repositorysourcelocation})

Write-Verbose "Comparing to online versions" 
foreach ($module in $gallery) {

     #find the current version in the gallery
     Try {
        $online = Find-Module -Name $module.name -Repository PSGallery -ErrorAction Stop
     }
     Catch {
        Write-Warning "Module $($module.name) was not found in the PSGallery"
     }

     #compare versions
     if ($online.version -gt $module.version) {
        $UpdateAvailable = $True
     }
     else {
        $UpdateAvailable = $False
     }

     #write a custom object to the pipeline
     [pscustomobject]@{
        Name = $module.name
        MultipleVersions = ($g.name -contains $module.name)
        InstalledVersion = $module.version
        OnlineVersion = $online.version
        Update = $UpdateAvailable
        Path = $module.modulebase
     }
 
} #foreach


Write-Verbose "Check complete"

}
Check-AllModules| Out-Gridview -title "Select modules to update" -PassThru | foreach { 
    Write-Host "Updating $($_.name)"
    ## update-module $_.name -force 
}
}
