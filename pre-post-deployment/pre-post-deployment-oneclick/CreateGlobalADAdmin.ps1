# Purpose : 
#  This script is used to create global AD Admin user to run Pre Deployment scripts
#
#  Should run by user who is having admin access on perticular tenant. In scenarios where a new Azure Subscription has been created using a Microsoft Account MSA (Live ID), 
#   the MSA user may not be able to run the PreDeployment script. Please use this script to create an Azure AD user using this script.
#  This script would be run before running PreDeployment.ps1.


Param(
	[string] [Parameter(Mandatory=$true)] $azureADDomainName, # Provide your Azure AD Domain Name
    [string] [Parameter(Mandatory=$true)] $tenantId, # Provide your Azure AD Tenant ID
	[string] [Parameter(Mandatory=$true)] $SubscriptionId, # Provide your Azure Subscrition ID
    [string] [Parameter(Mandatory=$true)] $globalADAdminPassword # Provide an AD Admin Password for the user admin@$azureADDomainName that complies to your AD's password policy. 
)

$ErrorActionPreference = 'Stop'

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

############################################################
# Install Azure Active Directory Powershell Modules
############################################################
    if (-not (Get-Module -ListAvailable AzureAD)) 
    { 
        Install-Module AzureAD -Force -AllowClobber;
        Write-Host "Installed AzureAD Module"
    }


Write-Host ("Step 1: Set Script Execution Policy as RemoteSigned" ) -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Write-Host ("Step 2: Install AzureADPreview Module" ) -ForegroundColor Yellow
Write-Host ("Step 3: Create Global Admin User Id" ) -ForegroundColor Yellow
$globalADAdminName = "admin@"+$azureADDomainName
Write-Host ("Step 4: Connect to Azure AD" ) -ForegroundColor Yellow
Connect-AzureAD -TenantId $tenantId
$newUserPasswordProfile = "" | Select-Object password, forceChangePasswordNextLogin
$newUserPasswordProfile.password = $globalADAdminPassword
$newUserPasswordProfile.forceChangePasswordNextLogin = $false 

#check if user exists
    try
    {
        $adAdmin = Get-AzureADUser -ObjectId $globalADAdminName -ErrorAction SilentlyContinue
		if ($adAdmin){
			Write-Host "`tUpdating $globalADAdminName with new password - $globalADAdminPassword" -ForegroundColor Yellow
			Set-AzureADUser -ObjectId $adAdmin.ObjectID -PasswordProfile $newUserPasswordProfile
		}
    }
    catch
    {
        Write-Host "`tAdmin user not $globalADAdminName found. attempting create..." -ForegroundColor Yellow
        #Create New User
        $adAdmin = New-AzureADUser -DisplayName "Admin Azure PCI Samples" -PasswordProfile $newUserPasswordProfile -AccountEnabled $true -MailNickName "admin" -UserPrincipalName $globalADAdminName
    }

#Get the Compay AD Admin ObjectID
    $companyAdminObjectId = Get-AzureADDirectoryRole | Where {$_."DisplayName" -eq "Company Administrator"} | Select ObjectId

#make the new user the company admin aka Global AD administrator
    try
    {
        if((Get-AzureADDirectoryRoleMember -ObjectId $companyAdminObjectId.ObjectId).UserPrincipalName -contains $globalADAdminName){
			Write-Host "$globalADAdminName is already granted with Global Admin Permission"
		}
		Else{
			Add-AzureADDirectoryRoleMember -ObjectId $companyAdminObjectId.ObjectId -RefObjectId $adAdmin.ObjectId -ErrorAction SilentlyContinue
			Write-Host "`tSuccessfully granted Global AD permissions to the Admin user $globalADAdminName" -ForegroundColor Yellow
        }
    } catch {$Error[0].Exception}
Write-Host ("Step 5: Assinging Owner permission on a Subscription" ) -ForegroundColor Yellow
# Assinging Owner permission on a Subscription
    try
    {
		Write-Host "`tLogin to Azure Subscription with Global Admin to assign owner permission to $globalADAdminName" -ForegroundColor Yellow
		if (Login-AzureRmAccount -SubscriptionId $SubscriptionId)
		{Write-Host "`tLogin was successful" -ForegroundColor Yellow}
		if((Get-AzureRmRoleAssignment -RoleDefinitionName Owner -Scope "/Subscriptions/$SubscriptionId").SignInName -contains "$globalADAdminName"){
			Write-Host "`tOwner permissions already granted to the Admin user $globalADAdminName" -ForegroundColor Yellow
		}
		Else{
			Write-Host "`tAssigning Subscription Owner permission to $globalADAdminName" -ForegroundColor Yellow
			New-AzureRmRoleAssignment -ObjectId $adAdmin.ObjectId -RoleDefinitionName Owner -Scope "/Subscriptions/$SubscriptionId" 
			Write-Host "`tSuccessfully granted Owner permissions to the Admin user $globalADAdminName" -ForegroundColor Yellow
		}

    } catch {
		$Error[0].Exception
	}

Write-Host ("`n`nGlobal AD Admin User created Successfully. Details are" ) -ForegroundColor Yellow
Write-Host ("`tUser Name: $globalADAdminName") -ForegroundColor Red -NoNewline
Write-Host ("`tPassword: " + $newUserPasswordProfile.password) -ForegroundColor Red

Read-Host -Prompt "The script completed execution. Press any key to exit"