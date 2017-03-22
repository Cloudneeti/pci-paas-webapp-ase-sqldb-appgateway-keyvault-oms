# Purpose : 
# 1) This script is used to create global AD Admin user to run Pre Deployment scripts
# 2) This script should run by user who is having admin access on perticular tenant
# 3) This script should run before running PreDeployment.ps1 
Param(
	[string] $azureADDomainName , # Provide your Azure AD Domain Name
    [string] $tenantId # Provide your Azure AD Tenant ID
)

#Depends on Azure AD Preview Module
if (-not (Get-Module -Name AzureADPreview)) 
{
    Write-Host "Installing ADPreview Module"
    Install-Module AzureADPreview -AllowClobber
    Import-Module AzureADPreview
}

Write-Host ("Step 1: Set Script Execution Policy as RemoteSigned" ) -ForegroundColor Red
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Write-Host ("Step 2: Install AzureADPreview Module" ) -ForegroundColor Red


Write-Host ("Step 3: Create Global Admin User Id" ) -ForegroundColor Red
$globalADAdminName = "admin@"+$azureADDomainName
Write-Host ("Step 4: Connect to Azure AD" ) -ForegroundColor Red
Connect-AzureAD -TenantId $tenantId
$newUserPasswordProfile = "" | Select password, forceChangePasswordNextLogin
$newUserPasswordProfile.password = "CF4!!12sdfStgb"
$newUserPasswordProfile.forceChangePasswordNextLogin = $false 

#check if user exists
try
{
    $adAdmin = Get-AzureADUser -ObjectId $globalADAdminName -ErrorAction SilentlyContinue
}
catch
{
    Write-Host "admin user not found. attempting create..."
    #Create New User
    $adAdmin = New-AzureADUser -DisplayName "Admin Azure PCI Samples" -PasswordProfile $newUserPasswordProfile -AccountEnabled $true -MailNickName "admin" -UserPrincipalName $globalADAdminName
}


#Get the Compay AD Admin ObjectID
$companyAdminObjectId = Get-AzureADDirectoryRole | Where {$_."DisplayName" -eq "Company Administrator"} | Select ObjectId

#make the new user the company admin aka Global AD administrator
try
{
    Add-AzureADDirectoryRoleMember -ObjectId $companyAdminObjectId.ObjectId -RefObjectId $adAdmin.ObjectId -ErrorAction SilentlyContinue
} catch {}

Write-Host ("Global AD Admin User " ) -ForegroundColor Cyan
Write-Host ("`tUser Name: $globalADAdminName") -ForegroundColor Red -NoNewline
Write-Host ("`tPassword: " + $newUserPasswordProfile.password) -ForegroundColor Red
Write-Host (" Created Successfully" ) -ForegroundColor Cyan

Read-Host -Prompt "The script completed execution. Press any key to exit"