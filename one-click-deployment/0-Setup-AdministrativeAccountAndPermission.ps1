<#
.Synopsis
   Imports or Install required powershell modules and creates Global AD Admin account.
.DESCRIPTION
    This script will import or installs (if not available) various powershell modules that requires to run this deployment. It also creates Global Administrator account `
        and assigns Owner permission on a given subscription.
    If you already have Azure AD Global Administrator account with Subscription Owner permission, You can only directly execute the script without any parameters. You `
        can refer Example-1 for reference.
    However, If you are deploying the solution on a new subscription you will need to provide all parameters as shown in Example-2. You also need to provide a Switch `
        'configureGlobalAdmin', otherwise script will throw a validation error.
    This script auto generates Global Admin UserPrincipal Name as 'admin+(2 length random number between 10-99)@azureADDomainName' and 15 length strong password for Global `
        Admin account and will print output at the completion of script. Please save the output for future reference purpose.
        For example - Username - admin45@contoso.com ; Password - ECUbZ30@IrSiG53
    By default, 
    
    Important Note: This script requires you to run powershell in an elevated mode i.e Run As Administrator. Otherwise you might see issues while executing the script.

.EXAMPLE
    Execute script without parameters to only Import / Install modules.
    .\0-Setup-AdministrativeAccountAndPermission.ps1
.EXAMPLE
    Execute below command to Import / Install modules and also create Azure AD Global Admin Account with Subscription Owner access
    .\0-Setup-AdministrativeAccountAndPermission.ps1 -azureADDomainName contoso.com -tenantId xxxxxx-9c8f-4e1e-941b-xxxxxx -subscriptionId xxxxx-f760-4a7e-bd98-xxxxxxxx `
        -configureGlobalAdmin
#>
[CmdletBinding()]
Param(
    # Provide Azure AD UserName with Global Administrator permission on Azure AD and Service Administrator / Co-Admin permission on Subsciption.
    [Parameter(Position=0, 
        Mandatory=$True, 
        ValueFromPipeline=$True)] 
    [string]$userName, 

    # Provide registered Azure AD Domain Name for Global Administrator Account.
    [Parameter(Position=1, 
        Mandatory=$True, 
        ValueFromPipeline=$True)] 
    [securestring]$password,

    # Provide registered Azure AD Domain Name for Global Administrator Account.
    [Parameter(Position=2,
        ParameterSetName='ConfigureGlobalADAdmin')]
    [string]$azureADDomainName,
	
    # Provide Directory / Tenant ID of an Azure Active Directory.
    [Parameter(Position=3,
        ParameterSetName='ConfigureGlobalADAdmin')]
    [string]$tenantId,

    # Provide Subscription ID on which you want to grant Global Administrator account with an Owner permission.
    [Parameter(Position=4)]
    [string]$subscriptionId,

    # Use this switch to create Global Adiministrator account.
    [Parameter(Position=5,
        ParameterSetName='ConfigureGlobalADAdmin')]
    [ValidateScript({
        if(
            (Get-Variable azureADDomainName) -and 
            (Get-Variable tenantId) -and
            (Get-Variable subscriptionId)
        ){$true}
        Else {Throw "Please make sure you have provided azureADDomainName, tenantId, subscriptionId before using this configureGlobalAdmin switch"}
    })] 
    [switch]$configureGlobalAdmin,

    # Use this switch to change password policy to 60 days on your tenant.
    [Parameter(Position=6)] 
    [ValidateScript({
        if(Get-Variable subscriptionId) {$true}
        Else {Throw "Please make sure you have provided azureADDomainName, tenantId, subscriptionId before using this configureGlobalAdmin switch"}
    })] 
    [switch]$setPasswordPolicy
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
    Write-Host -ForegroundColor Green "`nStep-1: Importing / Installing Powershell Modules"
    try {
        # Azure Resource Manager Powershell Modules
        Write-Host -ForegroundColor Yellow "`t* Checking if AzureRM module already exist."
        If (Get-Module -ListAvailable -Name AzureRM) 
        {   
            Write-Host -ForegroundColor Yellow "`t* Module has been found. Trying to import module."
            Import-Module -Name AzureRM -NoClobber -Force 
            if(Get-Module -Name AzureRM) {Write-Host -ForegroundColor Yellow "`t* AzureRM Module imported successfully."}
        }
        Else
        {
            # Installing Azure AD Module
            Install-Module AzureRM -AllowClobber; 
            if(Get-Module AzureRM | Out-Null){
                Write-Host -ForegroundColor Yellow "`t* AzureRM Module successfully installed and imported in to the session"
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
            # Installing AzureAD Module
            Install-Module AzureAD -AllowClobber;
            if(Get-Module AzureAD | Out-Null){
                Write-Host -ForegroundColor Yellow "`t* AzureAD Module successfully installed and imported in to the session"
            }
        }

        # Auditing and OMS Powershell Modules & Script
        Write-Host -ForegroundColor Yellow "`t* Checking if Enable-AzureRMDiagnostics script is installed."
        If (!(Get-InstalledScript -Name Enable-AzureRMDiagnostics)) 
        {
            Write-Host "`t* Enable-AzureRMDiagnostics script could not be found. Installing the script."
            Install-Script -Name Enable-AzureRMDiagnostics -Force
            if(Get-InstalledScript -Name Enable-AzureRMDiagnostics | Out-Null){
                Write-Host "`t* Script installed successfully"
            }
        }
        Write-Host -ForegroundColor Yellow "`t* Checking if AzureDiagnosticsAndLogAnalytics module is already exist."
        If (Get-Module -ListAvailable -Name AzureDiagnosticsAndLogAnalytics) 
        {
            Write-Host -ForegroundColor Yellow "`t* Module has been found. Trying to import module."
            Import-Module AzureDiagnosticsAndLogAnalytics -NoClobber -Force 
            if(Get-Module -Name AzureDiagnosticsAndLogAnalytics) {Write-Host -ForegroundColor Yellow "`t* AzureDiagnosticsAndLogAnalytics Module imported successfully."}            
        }
        Else{
            # Installing AzureDiagnosticsAndLogAnalytics Module
            Install-Module AzureDiagnosticsAndLogAnalytics -AllowClobber
            if (Get-Module -Name AzureDiagnosticsAndLogAnalytics | Out-Null ) {
                Write-Host -ForegroundColor Yellow "`t* AzureDiagnosticsAndLogAnalytics Module successfully installed and imported in to the session"
            }
        }
    }
    catch {
        Throw $_
    }
    
    if ($configureGlobalAdmin)
    {   
        # Creating Global Administrator Account & Making it Company Administrator in Azure Active Directory
        Write-Host -ForegroundColor Green "`nStep-2: Creating Azure AD Global Admin with UserName - $globalADAdminUserName."
        try {
            Write-Host -ForegroundColor Yellow "`t* Connecting to Azure Active Directory."
            Connect-AzureAD -TenantId $tenantId
            if(Get-AzureADDomain -Name $azureADDomainName | Out-Null){
                Write-Host -ForegroundColor Yellow "`t* Successfully connected to Azure Active Directory."
            }
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
            Write-Host "`t* Successfully granted Global AD permissions to the Admin user $globalADAdminName" -ForegroundColor Yellow
        }
        catch {
            Throw $_
        }

        # Assigning Owner permission to Global Administrator Account on a Subscription
        Write-Host -ForegroundColor Green "`nStep-3: Configuring subscription - $subscriptionId with Global Administrator account."        
        try {
            # Login to Azure Subscription
            Write-Host -ForegroundColor Yellow "`t* Connecting to Azure Subscription - $subscriptionId."
            if (Login-AzureRmAccount -subscriptionId $subscriptionId| Out-Null){
                Write-Host "`t* Connection was successful" -ForegroundColor Yellow
            }
            # Assigning Owner Permission
			Write-Host "`t* Assigning Subscription Owner permission to $globalADAdminUserName" -ForegroundColor Yellow
			New-AzureRmRoleAssignment -ObjectId $adAdmin.ObjectId -RoleDefinitionName Owner -Scope "/Subscriptions/$subscriptionId" 
			Write-Host "`t* Successfully granted Owner permissions to the Admin user $globalADAdminName" -ForegroundColor Yellow
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
        Write-Host -ForegroundColor Yellow "Kindly save the below information for future reference purpose:"
        $outputTable.Add('globalADAdminUserName',$globalADAdminUserName)
        $outputTable.Add('globalADAdminPassword',$globalADAdminPassword)
        $outputTable | Sort-Object Name | Format-Table -AutoSize -Wrap -Expand EnumOnly
        Write-Host -ForegroundColor Green "`n######################################################################`n"
    }

}


############### Improvements
# Add a switch to enable password policy at domain level.
#FIX PASSWORD NEVER EXPIRES & STRONG PASSWORD