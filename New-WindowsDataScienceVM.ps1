<#PSScriptInfo

.VERSION 1.3

.GUID 1e639a45-89fa-4cd3-8956-15495357edad

.AUTHOR Rob Sewell

.COMPANYNAME Sewells Consulting

.COPYRIGHT Rob Sewell - please credit Rob Sewell - https://sqldbawithbeard.com if used

.DESCRIPTION This function will create a Windows Data Science Virtual Machine in Azure using an ARM template 
   deployment, Creating a Resource Group, storage account, virtual network, public ip address and 
   a windows data science virtual machine in Azure. The simple switch will require only the admin 
   credentials for the virtual machine to be added and will create the following with RANDOM being 
   a randomly generated 5 character string. Note the virtual machine size is set to Standard_DS1_v2
   and the location to ukwest

    resourcegroupname = DS-RANDOM
    location = ukwest
    virtualMachineName = DSVMRANDOM
    virtualMachineSize = Standard_DS1_v2
    storageAccountName = dsstorageRANDOM in lowercase
    virtualNetworkName = dsnetRANDOM in lowercase
    networkInterfaceName = dsinterRANDOM in lowercase
    networkSecurityGroupName = dssecgrpRANDOM in lowercase
    storageAccountType = Standard_LRS 
    diagnosticsStorageAccountName = diagdsRANDOM in lowercase
    diagnosticsStorageAccountType = Standard_LRS
    publicIpAddressName = dspubipRANDOM
    publicIpAddressType = Dynamic

    If the simple switch is not used every parameter above is configurable
    
.TAGS Azure,Virtual Machine, Data Science

.LICENSEURI 

.PROJECTURI

.ICONURI 

.EXTERNALMODULEDEPENDENCIES sqlserver

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES Initial
#>
function New-WindowsDataScienceVM
{
    <#
.Synopsis
   This function will create a Windows Data Science Virtual Machine in Azure with all the relevant 
   infrastructure with a simple switch to remove all the hassle
.DESCRIPTION
   This function will create a Windows Data Science Virtual Machine in Azure using an ARM template 
   deployment, Creating a Resource Group, storage account, virtual network, public ip address and 
   a windows data science virtual machine in Azure. The simple switch will require only the admin 
   credentials for the virtual machine to be added and will create the following with RANDOM being 
   a randomly generated 5 character string. Note the virtual machine size is set to Standard_DS1_v2
   and the location to ukwest

    resourcegroupname = DS-RANDOM
    location = ukwest
    virtualMachineName = DSVMRANDOM
    virtualMachineSize = Standard_DS1_v2
    storageAccountName = dsstorageRANDOM in lowercase
    virtualNetworkName = dsnetRANDOM in lowercase
    networkInterfaceName = dsinterRANDOM in lowercase
    networkSecurityGroupName = dssecgrpRANDOM in lowercase
    storageAccountType = Standard_LRS 
    diagnosticsStorageAccountName = diagdsRANDOM in lowercase
    diagnosticsStorageAccountType = Standard_LRS
    publicIpAddressName = dspubipRANDOM
    publicIpAddressType = Dynamic

    If the simple switch is not used every parameter above is configurable

.PARAMETER Simple
   Enables Simple Mode - As little as possible is asked and everything is created with random names
   The simple switch will require only the admin credentials for the virtual machine to be added and 
   will create the resources required with RANDOM being a randomly generated 5 character string. Note 
   the virtual machine size is set to Standard_DS1_v2 and the location to ukwest

.PARAMETER resourcegroupname
    The name of the Resource Group - Not required for Simple mode

.PARAMETER location
    The location - Run (Get-AzureRmLocation).Location for values Not required for Simple mode

.PARAMETER virtualmachinename
    The name of the Virtual Machine - Not required for Simple mode

.PARAMETER virtualmachinesize
    The size of the Virtual Machine - Run (Get-AzureRmVmSize -Location location).Name for values - Not 
    required for Simple mode

.PARAMETER storageaccountname
    The name of the Storage Account - Unique across Azure - Check if Name already exists with 
    Test-AzureName -Storage -Name NAME -  Not required for Simple mode

.PARAMETER virtualNetworkName
    The name of the Virtual Network- Not required for Simple mode

.PARAMETER networkInterfaceName
    The name of the Network Interface - Not required for Simple mode

.PARAMETER networkSecurityGroupName
    The name of the Network Security Group - Not required for Simple mode

.PARAMETER storageAccountType 
    The Storage Account type valid values are Standard_LRS,Standard_ZRS,Standard_GRS,Standard_RAGRS,
    Premium_LRS - Not required for Simple mode

.PARAMETER diagnosticstorageaccountname
    The name of the diagnostic storage account - Unique across Azure - Check if Name already exists 
    with Test-AzureName -Storage -Name NAME - Not required for Simple mode

.PARAMETER diagnosticsStorageAccountType
    The diagnostic Storage Account type valid values are Standard_LRS,Standard_ZRS,Standard_GRS,
    Standard_RAGRS,Premium_LRS - Not required for Simple mode 

.PARAMETER addressPrefix
    The network address prefix - defaults to 10.0.0.0/24  - Not required for Simple mode

.PARAMETER subnetPrefix 
    The subnet prefix - defaults to 10.0.0.0/24 - Not required for Simple mode

.PARAMETER publicIpAddressName
    The Public IP Address name - Not required for Simple mode

.PARAMETER TemplateJsonFilePath
    The path to the template JSON file - defaults to users document folder - Not required for Simple mode

.PARAMETER ParameterJsonFilePath
    The path to the parameter JSON file - defaults to users document folder  - Not required for Simple mode

.PARAMETER credential
    The credential for the admin user for the Virtual Machine - not reuired for simple mode

.PARAMETER WhatIf 
Shows what would happen if the command were to run. No actions are actually performed. 

.PARAMETER Confirm 
Prompts you for confirmation before executing any changing operations within the command. 

.EXAMPLE
    Login-AzureRmAccount
    New-WindowsDataScienceVM -Simple

    Logs into Azure and enables Simple Mode which will pop-up a request for an admin username and password and
    then create a Windows Data Science Virtual machine and resources as shown and named as below with RANDOM
    being a randomly generated 5 character string. Note the virtual machine size is set to Standard_DS1_v2 and 
    the location to ukwest

    resourcegroupname = DS-RANDOM
    location = ukwest
    virtualMachineName = DSVMRANDOM
    virtualMachineSize = Standard_DS1_v2
    storageAccountName = dsstorageRANDOM in lowercase
    virtualNetworkName = dsnetRANDOM in lowercase
    networkInterfaceName = dsinterRANDOM in lowercase
    networkSecurityGroupName = dssecgrpRANDOM in lowercase
    storageAccountType = Standard_LRS 
    diagnosticsStorageAccountName = diagdsRANDOM in lowercase
    diagnosticsStorageAccountType = Standard_LRS
    publicIpAddressName = dspubipRANDOM
    publicIpAddressType = Dynamic
.EXAMPLE
   Login-AzureRmAccount
   $cred = Get-Credential
    New-WindowsDataScienceVM -resourcegroupname $resourcegroupname -location $location -virtualmachinename $virtualmachinename `
-virtualmachinesize $virtualmachinesize -storageaccountname $storageaccountname -virtualNetworkName $virtualNetworkName `
-networkInterfaceName $networkInterfaceName -networkSecurityGroupName $networkSecurityGroupName `
-storageAccountType $storageAccountType -diagnosticstorageaccountname $diagnosticsStorageAccountName `
-diagnosticsStorageAccountType $diagnosticsStorageAccountType -publicIpAddressName $publicIpAddressName `
-TemplateJsonFilePath $TemplateJsonFilePath -ParameterJsonFilePath $ParameterJsonFilePath -credential $cred

Creates a Windows Data Science Virtual Machine in Azure using the values for each variable

.NOTES
   AUTHOR - Rob Sewell 14/12/2016 sqldbawithabeard.com @sqldbawithbeard
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param 
(
[Parameter(Mandatory=$false, Position=0, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Enables Simple Mode - As little as possible is asked and everything is created with random names")]  
[switch]$Simple,
[Parameter(mandatory=$false, Position=0, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Resource Group Name")]        
[ValidatePattern("^[a-zA-Z0-9_-]{1,64}$")] ## 1-64 characters Alphanumeric, underscore and dash
[string]$resourcegroupname,
[Parameter(mandatory=$false, Position=0, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Location for VM - Run (Get-AzureRmLocation).Location for values")]
[ValidateScript({(Get-AzureRmLocation).Location -contains $_})]
[string]$location,
[pscredential][System.Management.Automation.Credential()]$credential,
[Parameter(mandatory=$false, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Virtual Machine Name")]
[ValidatePattern("^[a-zA-Z0-9_-]{0,15}$")] ## 1-15 characters Alphanumeric, underscore and dash
[ValidateScript({if($resourcegroupname){(Get-AzureRmVM -ResourceGroupName $resourcegroupname).Name -notcontains $_} else {$true}})]
[string]$virtualmachinename,
[Parameter(mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Virtual Machine Size - Run (Get-AzureRmVmSize -Location DataCentre).Name for values")]
[ValidatePattern("^[a-zA-Z0-9_-]{0,15}$")] ## 1-15 characters Alphanumeric, underscore and dash
[ValidateScript({if($location){(Get-AzureRmVMSize -Location $location).Name -contains $_}else {$true}})]
[string]$virtualmachinesize,
[Parameter(mandatory=$false, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Storage Account Name must be unique across Azure")]
[ValidatePattern("^[a-z0-9]{3,24}$")] ## 3-24 Alphanumeric, underscore and dash
[ValidateScript({(Test-AzureName -Storage -Name $_) -ne $true})]
[string]$storageaccountname,
[Parameter(mandatory=$false, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Virtual Network Name - must be unique in Resource Group")]
[ValidatePattern("^[a-zA-Z0-9 _-]{2,64}$")] ## 2-64 characters Alphanumeric, underscore, space and dash
[ValidateScript({if($resourcegroupname){(Get-AzureRmVirtualNetwork -ResourceGroupName $resourcegroupname).Name -notcontains $_}else {$true}})]
[string]$virtualNetworkName,
[Parameter(mandatory=$false, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Virtual Network Interface Name - must be unique in Resource Group")]
[ValidatePattern("^[a-zA-Z0-9 _-]{1,80}$")] ## 1-80 characters Alphanumeric, underscore, space and dash
[ValidateScript({if($resourcegroupname){(Get-AzureRmNetworkInterface -ResourceGroupName $resourcegroupname).Name -notcontains $_}else {$true}})]
[string]$networkInterfaceName,
[Parameter(mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Network Security Group Name - must be unique in Resource Group")]
[ValidatePattern("^[a-zA-Z0-9 _-]{1,80}$")] ## 1-80 characters Alphanumeric, underscore, space and dash
[ValidateScript({if($resourcegroupname){(Get-AzureRmNetworkSecurityGroup -ResourceGroupName $resourcegroupname).Name -notcontains $_}else {$true}})]
[string]$networkSecurityGroupName,
[Parameter(mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Storage Account Type - 'Standard_LRS','Standard_ZRS','Standard_GRS','Standard_RAGRS','Premium_LRS'")]
[ValidateSet('Standard_LRS','Standard_ZRS','Standard_GRS','Standard_RAGRS','Premium_LRS')]
[string]$storageAccountType,
[Parameter(mandatory=$false, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Diagnostic Storage Account Name must be unique across Azure")]
[ValidatePattern("^[a-z0-9]{3,24}$")] ## 3-24 Alphanumeric, underscore and dash
[ValidateScript({(Test-AzureName -Storage -Name $_) -ne $true})]
[string]$diagnosticstorageaccountname,
[Parameter(mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Diagnostic Storage Account Type - 'Standard_LRS','Standard_ZRS','Standard_GRS','Standard_RAGRS','Premium_LRS'")]
[ValidateSet('Standard_LRS','Standard_ZRS','Standard_GRS','Standard_RAGRS','Premium_LRS')]
[string]$diagnosticsStorageAccountType,
[Parameter(Mandatory=$false,  
                   ValueFromPipeline=$false, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Address Prefix - normally leave to default")]
[string]$addressPrefix = "10.0.0.0/24", ## I'm not working out the regex for this, sorry :-)
[Parameter(Mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Subnet Name - normally leave to default")]
                   [ValidatePattern("^[a-zA-Z0-9 _-]{2,80}$")] ## 2-80 characters Alphanumeric, underscore, space and dash

[string]$subnetName ='default',
[Parameter(Mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Subnet Prefix - normally leave to default")]
[string]$subnetPrefix = "10.0.0.0/24", ## nor this
[Parameter(Mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Public IP Address Name - unique accross Resource Group")]
                   [ValidatePattern("^[a-zA-Z0-9 _-]{2,80}$")] ## 2-80 characters Alphanumeric, underscore, space and dash
[ValidateScript({if($resourcegroupname){(Get-AzureRmPublicIpAddress -ResourceGroupName $resourcegroupname).ResourceGroupName -notcontains $_}else {$true}})]
[string]$publicIpAddressName,
[Parameter(Mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Template Json file path")]
[string]$TemplateJsonFilePath,
[Parameter(Mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Parameter Json file path")]
[string]$ParameterJsonFilePath
)

if ($simple)
{
$rand = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
$resourcegroupname = 'DS-' + $rand
$docs = [Environment]::GetFolderPath("mydocuments")
$ParameterJsonFilePath = "$docs\newparameter.json"
$TemplateJsonFilePath = "$docs\newtemplate.json"
$cred = Get-Credential -Message 'Enter Local Admin Credentials for the VM - Password must have 3 of the following 1 Upper case, 1 lower case, I special character and 1 number'
$location = 'ukwest'
$virtualMachineName = 'DSVM' + $rand
$virtualMachineSize = 'Standard_DS1_v2'
$adminUsername = $adminusername
$storageAccountName = 'dsstorage' + $rand.ToLower()
$virtualNetworkName = 'dsnet' + $rand.ToLower()
$networkInterfaceName = 'dsinter' + $rand.ToLower()
$networkSecurityGroupName = 'dssecgrp' + $rand.ToLower()
$storageAccountType = 'Standard_LRS' 
$diagnosticsStorageAccountName = 'diagds' + $rand.ToLower()
$diagnosticsStorageAccountType = 'Standard_LRS'
$publicIpAddressName = 'dspubip' + $rand

}
Function Set-ParameterJson
{
    [CmdletBinding(SupportsShouldProcess=$true)]
param 
(
[Parameter(Mandatory=$true, Position=0, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Resource Group Name")]        
[ValidatePattern("^[a-zA-Z0-9_-]{1,64}$")] ## 1-64 characters Alphanumeric, underscore and dash
[string]$resourcegroupname,
[Parameter(Mandatory=$true, Position=0, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Location for VM - Run (Get-AzureRmLocation).Location for values")]
[ValidateScript({(Get-AzureRmLocation).Location -contains $_})]
[string]$location,
[pscredential][System.Management.Automation.Credential()]$credential,
[Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Virtual Machine Name")]
[ValidatePattern("^[a-zA-Z0-9_-]{0,15}$")] ## 1-15 characters Alphanumeric, underscore and dash
[ValidateScript({(Get-AzureRmVM -ResourceGroupName $resourcegroupname).Name -notcontains $_})]
[string]$virtualmachinename,
[Parameter(Mandatory=$true,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Virtual Machine Size - Run (Get-AzureRmVmSize -Location DataCentre).Name for values")]
[ValidatePattern("^[a-zA-Z0-9_-]{0,15}$")] ## 1-15 characters Alphanumeric, underscore and dash
[ValidateScript({(Get-AzureRmVMSize -Location $location).Name -contains $_})]
[string]$virtualmachinesize,
[Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Storage Account Name must be unique across Azure")]
[ValidatePattern("^[a-z0-9]{3,24}$")] ## 3-24 Alphanumeric, underscore and dash
[ValidateScript({(Test-AzureName -Storage -Name $storageaccountname) -ne $true})]
[string]$storageaccountname,
[Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Virtual Network Name - must be unique in Resource Group")]
[ValidatePattern("^[a-zA-Z0-9 _-]{2,64}$")] ## 2-64 characters Alphanumeric, underscore, space and dash
[ValidateScript({(Get-AzureRmVirtualNetwork -ResourceGroupName $resourcegroupname).Name -notcontains $_})]
[string]$virtualNetworkName,
[Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Virtual Network Interface Name - must be unique in Resource Group")]
[ValidatePattern("^[a-zA-Z0-9 _-]{1,80}$")] ## 1-80 characters Alphanumeric, underscore, space and dash
[ValidateScript({(Get-AzureRmNetworkInterface -ResourceGroupName $resourcegroupname).Name -notcontains $_})]
[string]$networkInterfaceName,
[Parameter(Mandatory=$true,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Network Security Group Name - must be unique in Resource Group")]
[ValidatePattern("^[a-zA-Z0-9 _-]{1,80}$")] ## 1-80 characters Alphanumeric, underscore, space and dash
[ValidateScript({(Get-AzureRmNetworkSecurityGroup -ResourceGroupName $resourcegroupname).Name -notcontains $_})]
[string]$networkSecurityGroupName,
[Parameter(Mandatory=$true,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Storage Account Type - 'Standard_LRS','Standard_ZRS','Standard_GRS','Standard_RAGRS','Premium_LRS'")]
[ValidateSet('Standard_LRS','Standard_ZRS','Standard_GRS','Standard_RAGRS','Premium_LRS')]
[string]$storageAccountType,
[Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Diagnostic Storage Account Name must be unique across Azure")]
[ValidatePattern("^[a-z0-9]{3,24}$")] ## 3-24 Alphanumeric, underscore and dash
[ValidateScript({(Test-AzureName -Storage -Name $_) -ne $true})]
[string]$diagnosticstorageaccountname,
[Parameter(Mandatory=$true,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Diagnostic Storage Account Type - 'Standard_LRS','Standard_ZRS','Standard_GRS','Standard_RAGRS','Premium_LRS'")]
[ValidateSet('Standard_LRS','Standard_ZRS','Standard_GRS','Standard_RAGRS','Premium_LRS')]
[string]$diagnosticsStorageAccountType,
[Parameter(Mandatory=$false,  
                   ValueFromPipeline=$false, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Address Prefix - normally leave to default")]
[string]$addressPrefix = "10.0.0.0/24", ## I'm not working out the regex for this, sorry :-)
[Parameter(Mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Subnet Name - normally leave to default")]
                   [ValidatePattern("^[a-zA-Z0-9 _-]{2,80}$")] ## 2-80 characters Alphanumeric, underscore, space and dash

[string]$subnetName ='default',
[Parameter(Mandatory=$false,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Subnet Prefix - normally leave to default")]
[string]$subnetPrefix = "10.0.0.0/24", ## nor this
[Parameter(Mandatory=$true,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Public IP Address Name - unique accross Resource Group")]
                   [ValidatePattern("^[a-zA-Z0-9 _-]{2,80}$")] ## 2-80 characters Alphanumeric, underscore, space and dash
                   [ValidateScript({(Get-AzureRmPublicIpAddress -ResourceGroupName $resourcegroupname).ResourceGroupName -notcontains $_})]
[string]$publicIpAddressName,
[Parameter(Mandatory=$true,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Template Json file path")]
[string]$TemplateJsonFilePath,
[Parameter(Mandatory=$true,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Parameter Json file path")]
[string]$ParameterJsonFilePath
)

    $ParameterJson = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/SQLDBAWithABeard/DataScienceVM/master/parameters.json').Content | ConvertFrom-Json 
    $adminusername =$credential.UserName
    $adminuserpassword = $credential.GetNetworkCredential().SecurePassword
    
    $ParameterJson.parameters.location.value = $location
    $ParameterJson.parameters.virtualMachineName.value = $virtualmachinename
    $ParameterJson.parameters.virtualMachineSize.value = $virtualmachinesize
    $ParameterJson.parameters.adminUsername.value = $adminusername
    $ParameterJson.parameters.adminPassword.value = $adminuserpassword
    $ParameterJson.parameters.storageAccountName.value = $storageaccountname
    $ParameterJson.parameters.virtualNetworkName.value = $virtualNetworkName
    $ParameterJson.parameters.networkInterfaceName.value = $networkInterfaceName
    $ParameterJson.parameters.networkSecurityGroupName.value = $networkSecurityGroupName
    $ParameterJson.parameters.storageAccountType.value = $storageAccountType 
    $ParameterJson.parameters.diagnosticsStorageAccountName.value = $diagnosticsStorageAccountName
    $ParameterJson.parameters.diagnosticsStorageAccountType.value = $diagnosticsStorageAccountType
    $ParameterJson.parameters.diagnosticsStorageAccountId.value = "Microsoft.Storage/storageAccounts/$diagnosticsStorageAccountName"
    $ParameterJson.parameters.addressPrefix.value = $addressPrefix 
    $ParameterJson.parameters.subnetName.value = $subnetName
    $ParameterJson.parameters.subnetPrefix.value = $subnetPrefix
    $ParameterJson.parameters.publicIpAddressName.value = $publicIpAddressName
    $ParameterJson.parameters.publicIpAddressType.value = 'Dynamic'
  
    
    If ($Pscmdlet.ShouldProcess($ParameterJsonFilePath, "Creating Parameter File"))
    {
        $ParameterJson | ConvertTo-Json | Set-Content -Path $ParameterJsonFilePath
    }
    If ($Pscmdlet.ShouldProcess("https://raw.githubusercontent.com/SQLDBAWithABeard/DataScienceVM/master/template.json", "Saving Template json file to $TemplateJsonFilePath"))
    {
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/SQLDBAWithABeard/DataScienceVM/master/template.json' -OutFile $TemplateJsonFilePath
    }

    (Get-Content $TemplateJsonFilePath).Replace("parameters('resourcegroupname')","'$resourcegroupname'")|Out-File $TemplateJsonFilePath
}

# Register RPs
$resourceProviders = @("microsoft.compute","microsoft.storage","microsoft.network");
if($resourceProviders.length) {
    foreach($resourceProvider in $resourceProviders) {
        $null = Register-AzureRmResourceProvider -ProviderNamespace $resourceProvider;
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
   try
   {
        If ($Pscmdlet.ShouldProcess($resourceGroupName, "Creating Resource group $resourcegroupname in $location"))
        {
            New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location -erroraction stop
        }
    }
    catch
    {
        Write-warning -message "Something Went wrong- Run `$Error[0] | fl -force to get more information"
    }
}

Set-ParameterJson -resourcegroupname $resourcegroupname -location $location -virtualmachinename $virtualmachinename `
-virtualmachinesize $virtualmachinesize -storageaccountname $storageaccountname -virtualNetworkName $virtualNetworkName `
-networkInterfaceName $networkInterfaceName -networkSecurityGroupName $networkSecurityGroupName `
-storageAccountType $storageAccountType -diagnosticstorageaccountname $diagnosticsStorageAccountName `
-diagnosticsStorageAccountType $diagnosticsStorageAccountType -publicIpAddressName $publicIpAddressName `
-TemplateJsonFilePath $TemplateJsonFilePath -ParameterJsonFilePath $ParameterJsonFilePath -credential $cred

# Start the deployment

if((Test-Path $ParameterJsonFilePath) -and (Test-Path $TemplateJsonFilePath )) 
{
    try
    {
        If ($Pscmdlet.ShouldProcess($resourceGroupName, "Deploying using $TemplateJsonFilePath and $ParameterJsonFilePath"))
        {
            New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $TemplateJsonFilePath -TemplateParameterFile $ParameterJsonFilePath -Verbose -erroraction stop;
        }
    }
    catch
    {
        Write-warning -message "Something Went wrong- Run `$Error[0] | fl -force to get more information"
    } 
}
 else 
 {
    Write-Warning -Message "Something went wrong the files were not available"
 }

 }
