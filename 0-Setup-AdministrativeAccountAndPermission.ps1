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
    Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy UnRestricted -Force

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
    Function Get-StringHash([String]$String, $HashName = "MD5") {
        $StringBuilder = New-Object System.Text.StringBuilder
        [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))| 
            ForEach-Object { [Void]$StringBuilder.Append($_.ToString("x2"))
        }
        $StringBuilder.ToString().Substring(0, 24)
    }
    function Install-RequiredModules {
        param
        (
            # <!Provide modules name(s).!>
            [Parameter(Mandatory=$true, 
                ValueFromPipelineByPropertyName=$true,
                Position=0)]
            [ValidateNotNullOrEmpty()]
            [hashtable]
            $moduleNames
        )
        Process
            {
                try {
                    $modules = $moduleNames.Keys
                    foreach ($module in $modules){
                        Write-Host "Verifying module $module." -ForegroundColor Yellow
                        if (!(Get-InstalledModule $module -ErrorAction SilentlyContinue)){
                            Write-Host "Module $module does not exist. Attempting to install the module." -ForegroundColor Yellow
                            Install-Module $module -RequiredVersion $moduleNames[$module] -Force -AllowClobber
                            Write-Host "Module $module installed successfully." -ForegroundColor Yellow
                        }
                        elseif((Get-InstalledModule $module).Version.ToString() -ne $moduleNames[$module]){
                            Write-Host "Other version of Module found. Installing required version of module." -ForegroundColor Yellow
                            if (Install-Module $module -RequiredVersion $moduleNames[$module] -Force -AllowClobber){
                                Write-Host "Module $module installed successfully." -ForegroundColor Yellow
                            }
                        }
                        else {
                            Write-Host "Module $module with required version is already installed." -ForegroundColor Yellow
                        }
                    }
                }
                catch {
                    Throw $_
                    Break
                }
            }
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

}
Process
{
    # Importing / Installing Powershell Modules
    Write-Host -ForegroundColor Green "`nStep 1: Importing / Installing Powershell Modules"
    try{
          ### Install required powershell modules
            $requiredModules=@{
                'AzureRM' = '4.4.0';
                'AzureAD' = '2.0.0.131';
                'SqlServer' = '21.0.17178';
                'MSOnline' = '1.1.166.0';
                'AzureDiagnosticsAndLogAnalytics' = '0.1'
            }
        if ($installModules) {
              Write-Host "Trying to install listed modules.." -ForegroundColor Yellow
        $requiredModules
        Install-RequiredModules -moduleNames $requiredModules
        Write-Host "All the required modules are now installed. You can now re-run the script without 'installModules' switch." -ForegroundColor Yellow
        }

        <# This script takes a SubscriptionID, ResourceType, ResourceGroup and a workspace ID as parameters, analyzes the subscription or
        specific ResourceGroup defined for the resources specified in $Resources, and enables those resources for diagnostic metrics
        also enabling the workspace ID for the OMS workspace to receive these metrics.#>        
        Write-Host -ForegroundColor Yellow "Checking if Enable-AzureRMDiagnostics script is installed."
        If (Get-InstalledScript -Name Enable-AzureRMDiagnostics -ErrorAction SilentlyContinue) 
        {   
            Write-Host -ForegroundColor Yellow "Enable-AzureRMDiagnostics script is already installed."
        }else {
            if ($installModules) {
                Install-Script -Name Enable-AzureRMDiagnostics -Force
                Start-Sleep -Seconds 10
                if(Get-InstalledScript -Name Enable-AzureRMDiagnostics ){
                    Write-Host -ForegroundColor Yellow "Script installed successfully"
                }
            }else {
                Write-Host -ForegroundColor Red "Enable-AzureRMDiagnostics script does not exist. "
                Write-Host -ForegroundColor Red "Please run script with -installModules switch to install modules."
            }            
        }

        #Following script Removes the existing Module.
        $modules = $requiredModules.Keys
        foreach ($module in $modules){
            Remove-Module -Name $module -ErrorAction SilentlyContinue
        }
        
        #Following script Imports the Required Module into powershell.
        Start-Sleep 5
    	Write-Host "Trying to import listed modules.." -ForegroundColor Cyan
        foreach ($module in $modules){
            Write-Host "Importing module - $module with required version $($requiredModules[$module])." -ForegroundColor Yellow 
            Import-Module -Name $module -RequiredVersion $requiredModules[$module]
            if (Get-Module -Name $module) {
                Write-Host "Module - $module imported successfully." -ForegroundColor Yellow
            }
        }        
        If (Get-InstalledScript -Name Enable-AzureRMDiagnostics -ErrorAction SilentlyContinue)
        {
            Write-Host "All the required modules are now installed and imported successfully." -ForegroundColor Green
        }          
    }
    catch {
        Throw $_
    }

    # Creating and Configuring Azure Global AD Admin account.
    if ($configureGlobalAdmin)
    {   
        # Creating Global Administrator Account & Making it Company Administrator in Azure Active Directory
        Write-Host -ForegroundColor Green "`nStep 2: Creating Azure AD Global Admin - $globalADAdminUserName"
        try {
             # Connecting to Azure AD
             Write-Host -ForegroundColor Yellow "`t* Connecting to Azure Active Directory. Enter username and password when prompted." #The -Credential parameter cannot be used with Microsoft Accounts. 
             Connect-AzureAD -TenantId $tenantId
             if(Get-AzureADDomain -Name $azureADDomainName){
                 Write-Host -ForegroundColor Yellow "`t* Successfully connected to Azure Active Directory."
             }

            # Creating Azure Global Admin Account
            $adAdmin = New-AzureADUser -DisplayName "Global Admin Azure PCI Samples" -PasswordProfile $newUserPasswordProfile -AccountEnabled $true `
            -MailNickName "PCIAdmin" -UserPrincipalName $globalADAdminUserName
            Start-Sleep -Seconds 10
            if (Get-AzureADUser -ObjectId "$globalADAdminUserName"){
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
        Write-Host -ForegroundColor Green "`nStep 3: Configuring subscription - $subscriptionId"        
        try {
             # Login to Azure Subscription
             Write-Host -ForegroundColor Yellow "`t* Connecting to Azure Subscription - $subscriptionId. Enter username and password when prompted. " #The -Credential parameter cannot be used with Microsoft Accounts. 
             if (Login-AzureRmAccount -subscriptionId $subscriptionId){      #
                 Write-Host "`t* Connection was successful" -ForegroundColor Yellow
             }
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