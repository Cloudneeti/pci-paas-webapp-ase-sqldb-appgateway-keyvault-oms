# Purpose : 
#  This script is used to create global AD Admin user to run Pre Deployment scripts
#
#  Should run by user who is having admin access on perticular tenant. In scenarios where a new Azure Subscription has been created using a Microsoft Account MSA (Live ID), 
#   the MSA user may not be able to run the PreDeployment script. Please use this script to create an Azure AD user using this script.
#  This script would be run before running PreDeployment.ps1.


Param(
	[string] [Parameter(Mandatory=$true)] $azureADDomainName, # Provide your Azure AD Domain Name
    [string] [Parameter(Mandatory=$true)] $tenantId, # Provide your Azure AD Tenant ID
    [string] [Parameter(Mandatory=$true)] $globalADAdminPassword # Provide an AD Admin Password for the user admin@$azureADDomainName that complies to your AD's password policy. 
)

#Depends on Azure AD Preview Module
if (-not (Get-Module -Name AzureADPreview)) 
{
    Write-Host "Installing ADPreview Module"
    Install-Module AzureADPreview -AllowClobber
    Import-Module AzureADPreview
}

Write-Host ("Step 1: Set Script Execution Policy as RemoteSigned" ) -ForegroundColor Gray
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Write-Host ("Step 2: Install AzureADPreview Module" ) -ForegroundColor Gray


Write-Host ("Step 3: Create Global Admin User Id" ) -ForegroundColor Gray
$globalADAdminName = "admin@"+$azureADDomainName
Write-Host ("Step 4: Connect to Azure AD" ) -ForegroundColor Gray
Connect-AzureAD -TenantId $tenantId
$newUserPasswordProfile = "" | Select-Object password, forceChangePasswordNextLogin
$newUserPasswordProfile.password = $globalADAdminPassword
$newUserPasswordProfile.forceChangePasswordNextLogin = $false 

#check if user exists
    try
    {
        $adAdmin = Get-AzureADUser -ObjectId $globalADAdminName -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Host "`tAdmin user not $globalADAdminName found. attempting create..." -ForegroundColor Gray
        #Create New User
        $adAdmin = New-AzureADUser -DisplayName "Admin Azure PCI Samples" -PasswordProfile $newUserPasswordProfile -AccountEnabled $true -MailNickName "admin" -UserPrincipalName $globalADAdminName
    }


#Get the Compay AD Admin ObjectID
    $companyAdminObjectId = Get-AzureADDirectoryRole | Where {$_."DisplayName" -eq "Company Administrator"} | Select ObjectId

#make the new user the company admin aka Global AD administrator
    try
    {
        Add-AzureADDirectoryRoleMember -ObjectId $companyAdminObjectId.ObjectId -RefObjectId $adAdmin.ObjectId -ErrorAction SilentlyContinue
        Write-Host "`tSuccessfully granted Global AD permissions to the Admin user $globalADAdminName" -ForegroundColor Gray
        
    } catch {}

Write-Host ("Global AD Admin User created Successfully. Details are" ) -ForegroundColor Gray
Write-Host ("`tUser Name: $globalADAdminName") -ForegroundColor Red -NoNewline
Write-Host ("`tPassword: " + $newUserPasswordProfile.password) -ForegroundColor Red

Read-Host -Prompt "The script completed execution. Press any key to exit"