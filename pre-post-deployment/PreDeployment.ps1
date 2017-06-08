# Purpose : 
# 1) This script is used to create additional AD users to run various scenarios and creates AD Application and creates service principle to AD Application
# 2) This script should run by Global AD Administrator, You created Global AD Admin in previous script(CreateGlobalADAdmin.ps1)
# 3) This script should run before start deployment of ARM Templates
Param(
	[string] [Parameter(Mandatory=$true)] $azureADDomainName, # Provide your Azure AD Domain Name
	[string] [Parameter(Mandatory=$true)] $subscriptionID, # Provide your Azure subscription ID
	[string] [Parameter(Mandatory=$true)] $suffix, #This is used to create a unique website name in your organization. This could be your company name or business unit name
	[string] [Parameter(Mandatory=$true)] $sqlADAdminPassword, # Provide an SQL AD Admin Password for the user sqladmin@$azureADDomainName that complies to your AD's password policy. 
	[string] [Parameter(Mandatory=$true)] $azureADApplicationClientSecret, #Provide a Azure Application Password for setup of the app client access.
	[string] $customHostName, # Provide CustomHostName which will be used for creating ASE subdomain.
	[bool]   $enableSSL, # Provide boolean input to enable or disable SSL on application gateway 
	[string] $certificatePath, # Provide Certificate path if you want to provide your own Application gateway certificate.
)

$ErrorActionPreference = 'Stop'
function Convert-Certificate ($certPath)
{
$fileContentBytes = get-content "$certPath" -Encoding Byte
[System.Convert]::ToBase64String($fileContentBytes)
}
$ScriptFolder = Split-Path -Parent $PSCommandPath
#Imp: This script needs to be run by Global AD Administrator (aka Company Administrator)
<#
$mycreds = Get-Credential
$Login = Login-AzureRmAccount -SubscriptionId $SubscriptionID -Credential $mycreds
Connect-MsolService -Credential $mycreds
#>
Try  
{  
    Get-AzureRmContext  -ErrorAction Continue  
}  
Catch [System.Management.Automation.PSInvalidOperationException]  
{  
    Login-AzureRmAccount  -SubscriptionId $subscriptionId
} 

### Set password policy
Write "Setting up password policy for $azureADDomainName domain"
Set-MsolPasswordPolicy -ValidityPeriod 60 -NotificationDays 14 -DomainName "$azureADDomainName"

$Global:SQLADAdminName = "sqladmin@"+$azureADDomainName
$receptionistUserName = "receptionist_EdnaB@"+$azureADDomainName
$receptionistPassword = "$sqlADAdminPassword"

$cloudwiseAppServiceURL = "http://pcisolution"+(Get-Random -Maximum 999)+'.'+$azureADDomainName
Write-Host ("Step 1:Create AD Users for SQL AD Admin, Receptinist and Doctor to test various scenarios" ) -ForegroundColor Gray
$sqlADAdminObjectId = (Get-MsolUser -UserPrincipalName $SQLADAdminName -ErrorAction SilentlyContinue -ErrorVariable errorVariable).ObjectID
$sqlADAdminDetails = ""
if ($sqlADAdminObjectId -eq $null)  
{    
    $sqlADAdminDetails = New-MsolUser -UserPrincipalName $SQLADAdminName -DisplayName "SQLADAdministrator PCI Samples" -FirstName "SQL AD Administrator" -LastName "PCI Samples" -PasswordNeverExpires $false -StrongPasswordRequired $true
	$sqlADAdminObjectId= $sqlADAdminDetails.ObjectID
    # Make the new user a Global AD Administrator
	Add-MsolRoleMember -RoleName "Company Administrator" -RoleMemberObjectId $sqlADAdminObjectId
}

Set-MsolUserPassword -userPrincipalName $SQLADAdminName -NewPassword $sqlADAdminPassword -ForceChangePassword $false

$receptionistUserObjectId = (Get-MsolUser -UserPrincipalName $receptionistUserName -ErrorAction SilentlyContinue -ErrorVariable errorVariable).ObjectID
$receptionistuserDetails = ""
if ($receptionistUserObjectId -eq $null)  
{    
    $receptionistuserDetails = New-MsolUser -UserPrincipalName $receptionistUserName -DisplayName "Edna Benson" -FirstName "Edna" -LastName "Benson" -PasswordNeverExpires $false -StrongPasswordRequired $true
}

Set-MsolUserPassword -userPrincipalName $receptionistUserName -NewPassword $receptionistPassword -ForceChangePassword $false


Write-Host ("`nCreated AD Users for SQL AD Admin, and Receptinist user" ) -ForegroundColor Yellow
#------------------------------
Write-Host ("`nStep 2: Login to Azure AD and Azure. Please provide Global Administrator Credentials that has Owner/Contributor rights on the Azure Subscription ") -ForegroundColor yellow
Set-Location ".\"

$suffix = $suffix.Replace(' ', '').Trim()
$displayName = ($suffix + " Azure PCI PAAS Sample")

Start-Sleep -Seconds 10

# Grant 'SQL AD Admin' access to the Azure subscription
$RoleAssignment = Get-AzureRmRoleAssignment -ObjectId $sqlADAdminObjectId -RoleDefinitionName Contributor -Scope ('/subscriptions/'+ $subscriptionID) -ErrorAction Continue
if ($RoleAssignment -eq $null){New-AzureRmRoleAssignment -ObjectId $sqlADAdminObjectId -RoleDefinitionName Contributor -Scope ('/subscriptions/' + $subscriptionID )}
Else{ Write-Output "$($sqlADAdminDetails.SignInName) has already been assigned with Contributor permission on Subscription."}

# To select a default subscription for your current session
$sub = Get-AzureRmSubscription -SubscriptionId $subscriptionID | Select-AzureRmSubscription 

### 2. Create Azure Active Directory apps in default directory
Write-Host ("`nStep 3: Create Azure Active Directory apps in default directory") -ForegroundColor Yellow
    # Get tenant ID
    $tenantID = (Get-AzureRmContext).Tenant.TenantId
    if ($tenantID -eq $null){$tenantID = (Get-AzureRmContext).Tenant.Id}

    # Create Active Directory Application
    $Global:azureAdApplication = New-AzureRmADApplication -DisplayName $displayName -HomePage $cloudwiseAppServiceURL -IdentifierUris $cloudwiseAppServiceURL -Password $AzureADApplicationClientSecret
    
    Write-Host ("`tStep 3.1: Azure Active Directory apps creation successful. AppID is " + $azureAdApplication.ApplicationId) -ForegroundColor Yellow

### 3. Create a service principal for the AD Application and add a Reader role to the principal

    Write-Host ("`tStep 3.2: Attempting to create Service Principal") -ForegroundColor Yellow
    $principal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId
    Start-Sleep -s 30 # Wait till the ServicePrincipal is completely created. Usually takes 20+secs. Needed as Role assignment needs a fully deployed servicePrincipal
    Write-Host ("`tStep 3.3: Service Principal creation successful - " + $principal.DisplayName) -ForegroundColor Yellow
    $scopedSubs = ("/subscriptions/" + $sub.Subscription)
    Write-Host ("`tStep 3.4: Attempting Reader Role assignment" ) -ForegroundColor Yellow
    New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $azureAdApplication.ApplicationId.Guid -Scope $scopedSubs
    Write-Host ("`tStep 3.5: Reader Role assignment successful" ) -ForegroundColor Yellow

### 4. Create a Self-signed certificate for ASE ILB and Application Gateway.

### Generate App Gateway Front End SSL certificate string
if($enableSSL){
	if($certificatePath) {
		$Global:certData = Convert-Certificate -certPath $certificatePath
		$Global:certPassword = "$certificatePassword"
	}
	Else{
		$fileName = "appgwfrontendssl"
		$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "www.$customHostName"
		$certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint
		$pfxpass = $sqlADAdminPassword
		$password = ConvertTo-SecureString -String "$pfxpass" -Force -AsPlainText
		Export-PfxCertificate -cert $certThumbprint -FilePath "$ScriptFolder\Certificates\$fileName.pfx" -Password $password
		$Global:certData = Convert-Certificate -certPath "$ScriptFolder\Certificates\$fileName.pfx"
		$Global:certPassword = $pfxpass
	}
}
Else{
	$Global:certData = "null"
	$Global:certPassword = "null"
}

### Generate self-signed certificate for ASE ILB and convert into base64 string

$fileName = "aseilbcertificate"
$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "*.ase.$customHostName", "*.scm.ase.$customHostName"
$certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint
$pfxpass = $sqlADAdminPassword
$password = ConvertTo-SecureString -String "$pfxpass" -Force -AsPlainText
Export-PfxCertificate -cert $certThumbprint -FilePath "$ScriptFolder\Certificates\$fileName.pfx" -Password $password
Export-Certificate -Cert $certThumbprint -FilePath "$ScriptFolder\Certificates\$fileName.cer"
Start-Sleep -Seconds 3
$Global:aseCertData = Convert-Certificate -certPath "$ScriptFolder\Certificates\$fileName.cer"
$Global:asePfxBlobString = Convert-Certificate -certPath "$ScriptFolder\Certificates\$fileName.pfx"
$Global:asePfxPassword = $pfxpass
$Global:aseCertThumbprint = $certificate.Thumbprint



################# END ###################