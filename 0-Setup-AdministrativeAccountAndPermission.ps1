	

<#
 Modules NEEDED FOR this script - * AzureRM   * AzureAD    * AzureDiagnosticsAndLogAnalytics   * SqlServer   * Enable-AzureRMDiagnostics (Script)
 Note: This script requires you to run script in an elevated mode i.e -Run As Administrator-
  
This script imports and Install required powershell modules and creates Global AD Admin account.

    This script will import or installs (if not available) required powershell modules to run this deployment. It also creates Global Administrator account 
        and assigns Owner permission on a given subscription.
		
    If you already have Azure AD Global Administrator account with Subscription Owner permission, You can execute this script without any parameters.  
        Example - .\0-Setup-AdministrativeAccountAndPermission.ps1
    If you are deploying the solution on a -new subscription- you will need to run script with 'configureGlobalAdmin' switch  - otherwise script will throw a validation error.provide parameters 
	    Example - .\0-Setup-AdministrativeAccountAndPermission.ps1 -azureADDomainName contoso.com -tenantId xxxxxx-9c8f-4e1e-941b-xxxxxx -subscriptionId xxxxx-f760-4a7e-bd98-xxxxxxxx 
        -configureGlobalAdmin
       
    This script auto generates Global Admin as 'admin+(2 length random number between 10-99)@azureADDomainName' and 15 length strong password for the account 
        For example - Username - admin45@contoso.com ; Password 
    
  
#>
	

[CmdletBinding()]
Param(

    # Provide registered Azure AD Domain Name for Global Administrator Account.
    [string]$azureADDomainName,
	
    # Provide Directory / Tenant ID of an Azure Active Directory.
    [string]$tenantId,

    # Provide Subscription ID on which you want to grant Global Administrator account with an Owner permission.
    [string]$subscriptionId,

    # Use this switch to create Global Adiministrator account.
    [ValidateScript({
        if(
            (Get-Variable azureADDomainName) -and 
            (Get-Variable tenantId) -and
            (Get-Variable subscriptionId)
        ){$true}
        Else {Throw "Please make sure you have provided azureADDomainName, tenantId, subscriptionId before using configureGlobalAdmin switch"}
    })] 
    [switch]$configureGlobalAdmin,

    # Use this switch to Install Modules, if does not exist.
    [switch]$installModules
)
	
	

Begin{
    
    $ErrorActionPreference = 'stop'

    # Functions

    # Function to create a strong 15 length Strong & Random password for Azure AD Gobal Admin Account.
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
    $globalADAdminUserName = "admin"+(Get-Random -Maximum 99) +"@"+$azureADDomainName # e.g. admin45@contoso.com

    # Azure AD Global Admin Password & Profile
    $globalADAdminPassword = New-RandomPassword
    $newUserPasswordProfile = "" | Select-Object password, forceChangePasswordNextLogin
    $newUserPasswordProfile.password = $globalADAdminPassword
    $newUserPasswordProfile.forceChangePasswordNextLogin = $false

    # Hashtable for output table
    $outputTable = New-Object -TypeName Hashtable

    Write-Host -ForegroundColor Green "`nStep 1: Establishing connection to Azure AD & Subscription"
    # Login to Azure Subscrition & Azure AD 
    if($configureGlobalAdmin){
       try {
            # Login to Azure Subscription
            Write-Host -ForegroundColor Yellow "`t* Connecting to Azure Subscription - $subscriptionId." #The -Credential parameter cannot be used with Microsoft Accounts. 
            if (Login-AzureRmAccount -subscriptionId $subscriptionId){      #
                Write-Host "`t* Connection was successful" -ForegroundColor Yellow
            }

            Start-Sleep -Seconds 10
            
            # Connecting to Azure AD
            Write-Host -ForegroundColor Yellow "`t* Connecting to Azure Active Directory." #The -Credential parameter cannot be used with Microsoft Accounts. 
            Connect-AzureAD -TenantId $tenantId
            if(Get-AzureADDomain -Name $azureADDomainName){
                Write-Host -ForegroundColor Yellow "`t* Successfully connected to Azure Active Directory."
            }
       }
       catch {
           Throw $_
       }

    }
}
Process
{
    # Importing / Installing Powershell Modules
    Write-Host -ForegroundColor Green "`nStep 2: Importing / Installing Powershell Modules"
    try {
        # Azure Resource Manager Powershell Modules
        Write-Host -ForegroundColor Yellow "`t* Checking if AzureRM module already exist."
        If (Get-Module -ListAvailable -Name AzureRM*) 
        {   
            Write-Host -ForegroundColor Yellow "`t* Module has been found. Trying to import module."
            Get-Module -ListAvailable -Name AzureRM* | Import-Module -NoClobber -Force
            if(Get-Module -Name AzureRM) {Write-Host -ForegroundColor Yellow "`t* AzureRM Module imported successfully."}
        }
        Else
        {
            if (installModules) {
                # Installing Azure AD Module
                Install-Module AzureRM -AllowClobber; 
                if(Get-Module AzureRM | Out-Null){
                    Write-Host -ForegroundColor Yellow "`t* AzureRM Module successfully installed and imported in to the session"
                }                
            }else {
                Write-Host -ForegroundColor Red "`t* AzureRM module does not exist. "
				Write-Host -ForegroundColor Yellow " Please run script with -installModules switch to install modules."
            }
        }

        # Azure Active Directory Powershell Modules
        Write-Host -ForegroundColor Yellow "`t* Checking if AzureAD module already exist."
        If (Get-Module -ListAvailable -Name AzureAD) 
        {   
            Write-Host -ForegroundColor Yellow "`t* Module has been found. Trying to import module."
            Import-Module -Name AzureAD -NoClobber -Force
            if(Get-Module -Name AzureAD) {Write-Host -ForegroundColor Yellow "`t* AzureAD Module imported successfully."}             
        }
        Else
        { 
            if (installModules) {
                # Installing AzureAD Module
                Install-Module AzureAD -AllowClobber;
                if(Get-Module AzureAD | Out-Null){
                    Write-Host -ForegroundColor Yellow "`t* AzureAD Module successfully installed and imported in to the session"
                }                
            }else {
                Write-Host -ForegroundColor Red "`t* AzureAD module does not exist. "
				Write-Host -ForegroundColor Yellow "Please run script with -installModules switch to install modules."
            }
        }

        <# This script takes a SubscriptionID, ResourceType, ResourceGroup and a workspace ID as parameters, analyzes the subscription or
            specific ResourceGroup defined for the resources specified in $Resources, and enables those resources for diagnostic metrics
            also enabling the workspace ID for the OMS workspace to receive these metrics.#>
            
        Write-Host -ForegroundColor Yellow "`t* Checking if Enable-AzureRMDiagnostics script is installed."
        If (Get-InstalledScript -Name Enable-AzureRMDiagnostics) 
        {   
            Write-Host -ForegroundColor Yellow "`t* Enable-AzureRMDiagnostics script is already installed."
        }else {
            if (installModules) {
                Install-Script -Name Enable-AzureRMDiagnostics -Force
                if(Get-InstalledScript -Name Enable-AzureRMDiagnostics | Out-Null){
                    Write-Host "`t* Script installed successfully"
                }
            }else {
                Write-Host -ForegroundColor Red "`t* Enable-AzureRMDiagnostics script does not exist. "
				Write-Host -ForegroundColor Yellow "Please run script with -installModules switch to install modules."
            }            
        }

        #Enable Log Analytics to collect logs from Azure Diagnostics
        Write-Host -ForegroundColor Yellow "`t* Checking if AzureDiagnosticsAndLogAnalytics module is already exist."
        If (Get-Module -ListAvailable -Name AzureDiagnosticsAndLogAnalytics) 
        {
            Write-Host -ForegroundColor Yellow "`t* Module has been found. Trying to import module."
            Import-Module AzureDiagnosticsAndLogAnalytics -NoClobber -Force 
            if(Get-Module -Name AzureDiagnosticsAndLogAnalytics) {Write-Host -ForegroundColor Yellow "`t* AzureDiagnosticsAndLogAnalytics Module imported successfully."}            
        }
        Else{
            if (installModules) {
                # Installing AzureDiagnosticsAndLogAnalytics Module
                Install-Module AzureDiagnosticsAndLogAnalytics -AllowClobber
                if (Get-Module -Name AzureDiagnosticsAndLogAnalytics | Out-Null ) {
                    Write-Host -ForegroundColor Yellow "`t* AzureDiagnosticsAndLogAnalytics Module successfully installed and imported in to the session"
                }
            }            
        }

        # This module allows SQL Server administrators and developers to automate server administration
        Write-Host -ForegroundColor Yellow "`t* Checking if SqlServer module already exist."
        If (Get-Module -ListAvailable -Name SqlServer) 
        {   
            Write-Host -ForegroundColor Yellow "`t* Module has been found. Trying to import module."
            Import-Module -Name SqlServer -NoClobber -Force
            if(Get-Module -Name SqlServer) {Write-Host -ForegroundColor Yellow "`t* SqlServer Module imported successfully."}             
        }
        Else
        { 
            if (installModules) {
                # Installing SqlServer Module
                Install-Module SqlServer -AllowClobber;
                if(Get-Module SqlServer | Out-Null){
                    Write-Host -ForegroundColor Yellow "`t* SqlServer Module successfully installed and imported in to the session"
                }
            }else {
                Write-Host -ForegroundColor Red "`t* SqlServer Module does not exist. "
				Write-Host -ForegroundColor Yellow " run script with -installModules switch to install modules."
            }             
        }
    }
    catch {
        Throw $_
    }

    # Creating and Configuring Azure Global AD Admin account.
    if ($configureGlobalAdmin)
    {   
        # Creating Global Administrator Account & Making it Company Administrator in Azure Active Directory
        Write-Host -ForegroundColor Green "`nStep 3: Creating Azure AD Global Admin - $globalADAdminUserName"
        try {
            # Creating Azure Global Admin Account
            $adAdmin = New-AzureADUser -DisplayName "Global Admin Azure PCI Samples" -PasswordProfile $newUserPasswordProfile -AccountEnabled $true `
            -MailNickName "PCIAdmin" -UserPrincipalName $globalADAdminUserName
            Start-Sleep -Seconds 10
            if (Get-AzureADUser -ObjectId "$globalADAdminUserName"| Out-Null){
                Write-Host -ForegroundColor Yellow "`t* Azure AD Global Admin - $globalADAdminUserName created successfully."
            }
            #Get the Compay AD Admin ObjectID
            $companyAdminObjectId = Get-AzureADDirectoryRole | Where-Object {$_."DisplayName" -eq "Company Administrator"} | Select-Object ObjectId

            #Make the new user the company admin aka Global AD administrator
            Add-AzureADDirectoryRoleMember -ObjectId $companyAdminObjectId.ObjectId -RefObjectId $adAdmin.ObjectId
            Write-Host "`t* Successfully granted Global AD permissions to $globalADAdminUserName" -ForegroundColor Yellow
        }
        catch {
            Throw $_
        }

        # Assigning Owner permission to Global Administrator Account on a Subscription
        Write-Host -ForegroundColor Green "`nStep 4: Configuring subscription - $subscriptionId"        
        try {
            # Assigning Owner Permission
			Write-Host "`t* Assigning Subscription Owner permission to $globalADAdminUserName" -ForegroundColor Yellow
			New-AzureRmRoleAssignment -ObjectId $adAdmin.ObjectId -RoleDefinitionName Owner -Scope "/Subscriptions/$subscriptionId" 
			Write-Host "`t* Successfully granted Owner permissions to $globalADAdminUserName" -ForegroundColor Yellow
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
        Write-Host -ForegroundColor Yellow "Script complete"
        $outputTable.Add('globalADAdminUserName',$globalADAdminUserName)
        $outputTable.Add('globalADAdminPassword',$globalADAdminPassword)
        $outputTable | Sort-Object Name | Format-Table -AutoSize -Wrap -Expand EnumOnly
        Write-Host -ForegroundColor Green "`n######################################################################`n"
    }
}