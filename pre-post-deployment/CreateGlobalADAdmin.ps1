# Purpose : 
# 1) This script is used to create global AD Admin user to run Pre Deployment scripts
# 2) This script should run by user who is having admin access on perticular tenant
# 3) This script should run before running PreDeployment.ps1 
Param(
	[string] [Parameter(Mandatory=$true)] $azureADDomainName, # Provide your Azure AD Domain Name
    [string] [Parameter(Mandatory=$true)] $tenantId # Provide your Azure AD Tenant ID
)
Write-Host ("Step 1: Set Script Execution Policy as RemoteSigned" ) -ForegroundColor Red
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Write-Host ("Step 2: Install AzureADPreview Module" ) -ForegroundColor Red
Install-Module AzureADPreview

Write-Host ("Step 3: Create Global Admin User Id" ) -ForegroundColor Red
$globalADAdminName = "admin@"+$azureADDomainName
Write-Host ("Step 4: Connect to Azure AD" ) -ForegroundColor Red
Connect-AzureAD -TenantId $tenantId
$newUserPasswordProfile = "" | Select password, forceChangePasswordNextLogin
$newUserPasswordProfile.password = "CF4!!12sdfStgb"
$newUserPasswordProfile.forceChangePasswordNextLogin = $false 
New-AzureADUser -DisplayName "Admin Azure PCI Samples" -PasswordProfile $newUserPasswordProfile -AccountEnabled $true -MailNickName "admin" -UserPrincipalName $globalADAdminName
Write-Host ("Global Admin User Created Successfully" ) -ForegroundColor Red

Read-Host -Prompt "The script completed execution. Press any key to exit"