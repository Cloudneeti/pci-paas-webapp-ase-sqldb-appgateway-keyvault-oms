<#
.Synopsis
   Imports or Install required powershell modules and creates Global AD Admin account.
.DESCRIPTION
   This script will import or installs (if not available) various powershell modules that requires to run this deployment. It also creates Global Administrator account`
    and assigns Owner permission on a given subscription.
.EXAMPLE
    Execute script without parameters to only Import / Install modules.
    .\0-Setup-AdministrativeAccountAndPermission.ps1
.EXAMPLE
        Execute below command to Import / Install modules and also create Azure AD Global Admin Account with Subscription Owner access
    .\0-Setup-AdministrativeAccountAndPermission.ps1 -azureADDomainName contoso.com -tenantId xxxxxx-9c8f-4e1e-941b-xxxxxx -subscriptionID xxxxx-f760-4a7e-bd98-xxxxxxxx `
        -configureGlobalAdmin
#>
[CmdletBinding()]
Param(
    # Provide registered Azure AD Domain Name for Global Administrator Account.
    [string]$azureADDomainName,
	
    # Provide Directory / Tenant ID of an Azure Active Directory.
    [string]$tenantId,

    # Provide Subscription ID on which you want to grant Global Administrator account with an Owner permission.
    [string]$subscriptionID,

    # Use this switch to create Global Adiministrator account.
    [ValidateScript({
        if(
            (Get-Variable azureADDomainName) -and 
            (Get-Variable tenantId) -and
            (Get-Variable subscriptionID)
        ){$true}
        Else {Throw "Please make sure you have provided azureADDomainName, tenantId, subscriptionID before using this configureGlobalAdmin switch"}
    })] 
    [switch]$configureGlobalAdmin
)
Begin{
    
    $ErrorActionPreference = 'stop'

    # Functions
	function New-RandomPassword () 
	{
		# This function generates a strong 15 length random password using Capital & Small Aplhabets,Numbers and Special characters.
        (-join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})) + `
        ((10..99) | Get-Random -Count 1) + `
        ('@','%','!','^' | Get-Random -Count 1) +`
        (-join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})) + `
        ((10..99) | Get-Random -Count 1)
	}
    
    # Azure AD username
    $globalADAdminUserName = "admin"+(Get-Random -Maximum 99) +"@"+$azureADDomainName

    # Azure AD Global Admin password & Profile
    $globalADAdminPassword = New-RandomPassword
    $newUserPasswordProfile = "" | Select-Object password, forceChangePasswordNextLogin
    $newUserPasswordProfile.password = $globalADAdminPassword
    $newUserPasswordProfile.forceChangePasswordNextLogin = $false

    # Hashtable for output table
    $outputTable = New-Object -TypeName Hashtable

}
Process
{
    # Importing / Installing Powershell Modules
    Write-Host -ForegroundColor Yellow "`nTrying to import modules"
    try {
        # Azure Resource Manager Powershell Modules
        Write-Host -ForegroundColor Yellow "`nChecking if AzureRM module already exist."
        If (Get-Module -ListAvailable -Name AzureRM) 
        {   
            Write-Host -ForegroundColor Yellow "`nModule has been found. Trying to import module."
            Import-Module -Name AzureRM -NoClobber -Force 
            if(Get-Module -Name AzureRM) {Write-Host -ForegroundColor Yellow "`nAzureRM Module imported successfully."}
        }
        Else
        {
            # Installing Azure AD Module
            Install-Module AzureRM -AllowClobber; 
            if(Get-Module AzureRM | Out-Null){
                Write-Host -ForegroundColor Yellow "`nAzureRM Module successfully installed and imported in to the session"
            }
        }

        # Azure Active Directory Powershell Modules
        Write-Host -ForegroundColor Yellow "`nChecking if AzureAD module already exist."
        If (Get-Module -ListAvailable -Name AzureAD) 
        {   
            Write-Host -ForegroundColor Yellow "`nModule has been found. Trying to import module."
            Import-Module -Name AzureAD -NoClobber -Force
            if(Get-Module -Name AzureAD) {Write-Host -ForegroundColor Yellow "`nAzureAD Module imported successfully."}             
        }
        Else
        { 
            # Installing AzureAD Module
            Install-Module AzureAD -AllowClobber;
            if(Get-Module AzureAD | Out-Null){
                Write-Host -ForegroundColor Yellow "`nAzureAD Module successfully installed and imported in to the session"
            }
        }

        # Auditing and OMS Powershell Modules & Script
        Write-Host -ForegroundColor Yellow "`nChecking if Enable-AzureRMDiagnostics script is installed."
        If (!(Get-InstalledScript -Name Enable-AzureRMDiagnostics)) 
        {
            Write-Host "`nEnable-AzureRMDiagnostics script could not be found. Installing the script."
            Install-Script -Name Enable-AzureRMDiagnostics -Force
            if(Get-InstalledScript -Name Enable-AzureRMDiagnostics | Out-Null){
                Write-Host "`nScript installed successfully"
            }
        }
        Write-Host -ForegroundColor Yellow "`nChecking if AzureDiagnosticsAndLogAnalytics module is already exist."
        If (Get-Module -ListAvailable -Name AzureDiagnosticsAndLogAnalytics) 
        {
            Write-Host -ForegroundColor Yellow "`nModule has been found. Trying to import module."
            Import-Module AzureDiagnosticsAndLogAnalytics -NoClobber -Force 
            if(Get-Module -Name AzureDiagnosticsAndLogAnalytics) {Write-Host -ForegroundColor Yellow "`nAzureDiagnosticsAndLogAnalytics Module imported successfully."}            
        }
        Else{
            # Installing AzureDiagnosticsAndLogAnalytics Module
            Install-Module AzureDiagnosticsAndLogAnalytics -AllowClobber
            if (Get-Module -Name AzureDiagnosticsAndLogAnalytics | Out-Null ) {
                Write-Host -ForegroundColor Yellow "`nAzureDiagnosticsAndLogAnalytics Module successfully installed and imported in to the session"
            }
        }
    }
    catch {
        Throw $_
    }
    
    if ($configureGlobalAdmin)
    {   
        # Creating Global Administrator Account & Making it Company Administrator in Azure Active Directory
        try {
            Write-Host -ForegroundColor Yellow "`nConnecting to Azure Active Directory."
            Connect-AzureAD -TenantId $tenantId
            if(Get-AzureADDomain -Name $azureADDomainName | Out-Null){
                Write-Host -ForegroundColor Yellow "`nSuccessfully connected to Azure Active Directory."
            }

            # Creating Azure Global Admin Account
            Write-Host -ForegroundColor Yellow "`nCreating Azure AD Global Admin with UserName - $globalADAdminUserName."
            $adAdmin = New-AzureADUser -DisplayName "Global Admin Azure PCI Samples" -PasswordProfile $newUserPasswordProfile -AccountEnabled $true -MailNickName "PCIAdmin" -UserPrincipalName $globalADAdminUserName
            if (Get-AzureADUser -ObjectId "$globalADAdminUserName"| Out-Null){
                Write-Host -ForegroundColor Yellow "Azure AD Global Admin - $globalADAdminUserName created successfully."
            }

            #Get the Compay AD Admin ObjectID
            $companyAdminObjectId = Get-AzureADDirectoryRole | Where-Object {$_."DisplayName" -eq "Company Administrator"} | Select-Object ObjectId

            #Make the new user the company admin aka Global AD administrator
            Add-AzureADDirectoryRoleMember -ObjectId $companyAdminObjectId.ObjectId -RefObjectId $adAdmin.ObjectId
            Write-Host "`nSuccessfully granted Global AD permissions to the Admin user $globalADAdminName" -ForegroundColor Yellow
        }
        catch {
            Throw $_
        }

        # Assigning Owner permission to Global Administrator Account on a Subscription
        try {
            # Login to Azure Subscription
            Write-Host -ForegroundColor Yellow "`nConfiguring subscription - $subscriptionID with Global Administrator account."
            if (Login-AzureRmAccount -SubscriptionId $subscriptionID| Out-Null){
                Write-Host "`tLogin was successful" -ForegroundColor Yellow
            }
            # Assigning Owner Permission
			Write-Host "`nAssigning Subscription Owner permission to $globalADAdminUserName" -ForegroundColor Yellow
			New-AzureRmRoleAssignment -ObjectId $adAdmin.ObjectId -RoleDefinitionName Owner -Scope "/Subscriptions/$SubscriptionId" 
			Write-Host "`nSuccessfully granted Owner permissions to the Admin user $globalADAdminName" -ForegroundColor Yellow
        }
        catch {
            Throw $_
        }
    }
}
End
{
    if($configureGlobalAdmin){
        Write-Host -ForegroundColor Green "`n######################################################################`n"
        Write-Host -ForegroundColor Yellow "`nKindly save the below information for future reference purpose:"
        $outputTable.Add('GlobalAdminUserName',$globalADAdminUserName)
        $outputTable.Add('GlobalAdminPassword',$globalADAdminPassword)
        $outputTable | Sort-Object Name | Format-Table -AutoSize -Wrap -Expand EnumOnly
        Write-Host -ForegroundColor Green "`n######################################################################`n"
    }

}
