# Purpose : 
# 1) This script is used to create additional AD users to run various scenarios and creates AD Application and creates service principle to AD Application
# 2) This script should run by Global AD Administrator, You created Global AD Admin in previous script(CreateGlobalADAdmin.ps1)
# 3) This script should run before start deployment of ARM Templates
Param(
	[string] [Parameter(Mandatory=$true)] $azureADDomainName, # Provide your Azure AD Domain Name
	[string] [Parameter(Mandatory=$true)] $subscriptionID, # Provide your Azure subscription ID
	[string] [Parameter(Mandatory=$true)] $suffix, #This is used to create a unique website name in your organization. This could be your company name or business unit name
	# [string] [Parameter(Mandatory=$true)] , # Provide an SQL AD Admin Password for the user sqladmin@$azureADDomainName that complies to your AD's password policy. 
	[string] [Parameter(Mandatory=$true)] $azureADApplicationClientSecret, #Provide a Azure Application Password for setup of the app client access.
	[string] $customHostName = "pcipaas.com", # Provide CustomHostName which will be used for creating ASE subdomain.
	[bool]   $enableSSL = $false, # Provide boolean input to enable or disable SSL on application gateway 
	[string] $certificatePath # Provide Certificate path if you want to provide your own Application gateway certificate.
)

$ErrorActionPreference = 'Stop'

function Generate-Password ()
{
    (-join ((65..90) + (97..122) | Get-Random -Count 15 | % {[char]$_})) + (Get-Random -Maximum 9999)
}

function Convert-Certificate ($certPath)
{
$fileContentBytes = get-content "$certPath" -Encoding Byte
[System.Convert]::ToBase64String($fileContentBytes)
}

$ScriptFolder = Split-Path -Parent $PSCommandPath

###
#Imp: This script needs to be run by Global AD Administrator (aka Company Administrator)
###
Write-Host ("Pre-Requisite: This script needs to be run by Global AD Administrator (aka Company Administrator)" ) -ForegroundColor Yellow
#Connect to the Azure AD
Connect-MsolService
$SQLADAdminName = "sqladmin@"+$azureADDomainName
$receptionistUserName = "receptionist_EdnaB@"+$azureADDomainName

#Generate bunch of strong passwords
$sqlADAdminPassword = Generate-Password
$receptionistPassword = Generate-Password
$bastionPassword = Generate-Password

$cloudwiseAppServiceURL = "http://localcloudneeti6i"+$azureADDomainName
Write-Host ("Step 1:Create AD Users for SQL AD Admin, Receptinist and Doctor to test various scenarios" ) -ForegroundColor Yellow
$sqlADAdminObjectId = (Get-MsolUser -UserPrincipalName $SQLADAdminName -ErrorAction SilentlyContinue -ErrorVariable errorVariable).ObjectID
$sqlADAdminDetails = ""
if ($sqlADAdminObjectId -eq $null)  
{    
    $sqlADAdminDetails = New-MsolUser -UserPrincipalName $SQLADAdminName -DisplayName "SQLADAdministrator PCI Samples" -FirstName "SQL AD Administrator" -LastName "PCI Samples"
	$sqlADAdminObjectId= $sqlADAdminDetails.ObjectID
    # Make the new user a Global AD Administrator
	Add-MsolRoleMember -RoleName "Company Administrator" -RoleMemberObjectId $sqlADAdminObjectId
}
Set-MsolUserPassword -userPrincipalName $SQLADAdminName -NewPassword $sqlADAdminPassword -ForceChangePassword $false

$receptionistUserObjectId = (Get-MsolUser -UserPrincipalName $receptionistUserName -ErrorAction SilentlyContinue -ErrorVariable errorVariable).ObjectID
$receptionistuserDetails = ""
if ($receptionistUserObjectId -eq $null)  
{    
    $receptionistuserDetails = New-MsolUser -UserPrincipalName $receptionistUserName -DisplayName "Edna Benson" -FirstName "Edna" -LastName "Benson"
}

Set-MsolUserPassword -userPrincipalName $receptionistUserName -NewPassword $receptionistPassword -ForceChangePassword $false


Write-Host ("Created AD Users for SQL AD Admin, and Receptinist user" ) -ForegroundColor Yellow
#------------------------------
Write-Host ("Step 2: Login to Azure AD and Azure. Please provide Global Administrator Credentials that has Owner/Contributor rights on the Azure Subscription ") -ForegroundColor yellow
Set-Location ".\"

$suffix = $suffix.Replace(' ', '').Trim()
$WebSiteName =         ("azurepcipaas" + $suffix)
$displayName =         ($suffix + "Azure PCI PAAS Sample")

# To login to Azure Resource Manager
	Try  
	{  
		Get-AzureRmContext -ErrorAction Continue  
	}  
	Catch [System.Management.Automation.PSInvalidOperationException]  
	{  
		 #Add-AzureRmAccount 
		Login-AzureRmAccount -SubscriptionId $subscriptionID
	} 

Start-Sleep -Seconds 10
# Grant 'SQL AD Admin' access to the Azure subscription
New-AzureRmRoleAssignment -ObjectId $sqlADAdminObjectId -RoleDefinitionName Contributor -Scope ('/subscriptions/' + $subscriptionID )

# To select a default subscription for your current session

$sub = Get-AzureRmSubscription -SubscriptionId $subscriptionID | Select-AzureRmSubscription 

### 2. Create Azure Active Directory apps in default directory
Write-Host ("Step 3: Create Azure Active Directory apps in default directory") -ForegroundColor Yellow
    $u = (Get-AzureRmContext).Account
    $u1 = ($u -split '@')[0]
    $u2 = ($u -split '@')[1]
    $u3 = ($u2 -split '\.')[0]
    $defaultPrincipal = ($u1 + $u3 + ".onmicrosoft.com")
    # Get tenant ID
    $tenantID = (Get-AzureRmContext).Tenant.TenantId
    $homePageURL = ("http://" + $defaultPrincipal + "azurewebsites.net" + "/" + $WebSiteName)
    $replyURLs = @( $cloudwiseAppServiceURL, "http://*.azurewebsites.net","http://localhost:62080", "http://localhost:3026/")
    # Create Active Directory Application
    $azureAdApplication = New-AzureRmADApplication -DisplayName $displayName -HomePage $cloudwiseAppServiceURL -IdentifierUris $cloudwiseAppServiceURL -Password $AzureADApplicationClientSecret # -ReplyUrls $replyURLs
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
		$certData = Convert-Certificate -certPath $certificatePath
		$certPassword = "Customer provided certificate."
	}
	Else{
		$fileName = "appgwfrontendssl"
		$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "www.$customHostName"
		$certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint
		$pfxpass = Generate-Password
		$password = ConvertTo-SecureString -String "$pfxpass" -Force -AsPlainText
		Export-PfxCertificate -cert $certThumbprint -FilePath "$ScriptFolder\$fileName.pfx" -Password $password
		$certData = Convert-Certificate -certPath "$ScriptFolder\$fileName.pfx"
		$certPassword = $pfxpass
	}
}
Else{
	$certData = "null"
	$certPassword = "null"
}

### Generate self-signed certificate for ASE ILB and convert into base64 string

$fileName = "aseilbcertificate"
$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "*.ase.$customHostName", "*.scm.ase.$customHostName"
$certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint
$pfxpass = Generate-Password
$password = ConvertTo-SecureString -String "$pfxpass" -Force -AsPlainText
Export-PfxCertificate -cert $certThumbprint -FilePath "$ScriptFolder\$fileName.pfx" -Password $password
Export-Certificate -Cert $certThumbprint -FilePath "$ScriptFolder\$fileName.cer"
Start-Sleep -Seconds 3
$aseCertData = Convert-Certificate -certPath "$ScriptFolder\$fileName.cer"
$asePfxBlobString = Convert-Certificate -certPath "$ScriptFolder\$fileName.pfx"
$asePfxPassword = $pfxpass
$aseCertThumbprint = $certificate.Thumbprint

### 5. Print out the required project settings parameters
#############################################################################################
$AzureADApplicationObjectID = (Get-AzureRmADServicePrincipal -ServicePrincipalName $azureAdApplication.ApplicationId).Id

Write-Host "TenantId: " -foreground Yellow -NoNewLine
Write-Host $tenantID -foreground Red 
Write-Host "SubscriptionID: " -foreground Yellow -NoNewLine
Write-Host $sub.Subscription -foreground Red 
Write-Host
Write-Host
Write-Host -Prompt "Use the following information to start Azure Resource Manager Template deloyment" -ForegroundColor Yellow
Write-Host
Write-Host "_artifactsLocationSasToken: " -foreground Yellow -NoNewline
Write-Host "Advanced use" -foreground Red 
Write-Host "Cert Data: " -foreground Yellow -NoNewLine
Write-Host "Refer to deployment Guide for correct use" -foreground Red 
Write-Host "Cert Password: " -foreground Yellow -NoNewLine
Write-Host "cert [PASSWORD]" -foreground Red 
Write-Host "Bastion Host Administrator User Name: " -foreground Yellow -NoNewLine
Write-Host "Default Value 'bastionadmin' " -foreground Red 
Write-Host "Bastion Host Administrator Password: " -foreground Yellow -NoNewLine
Write-Host $bastionPassword -foreground Red 
Write-Host "SQL Administrator Login User Name: " -foreground Yellow -NoNewLine
Write-Host "Default Value 'sqladmin' " -foreground Red 
Write-Host "SQL Administrator Login Password: " -foreground Yellow -NoNewLine
Write-Host $sqlADAdminPassword -foreground Red 
Write-Host "SQL Threat Detection Alert Email Address: " -foreground Yellow -NoNewLine
Write-Host "Email Address that will receive  SQL alerts" -foreground Red 
Write-Host "Azue Automation Account Name: " -foreground Yellow -NoNewLine
Write-Host "Provide your automation account name. Configuration provided in deployment guide" -foreground Red #### PULL THIS INFORMATION AND PROVIDE IT using 
Write-Host "Custom Domain Name: " -foreground Yellow -NoNewLine
Write-Host "Please see Deployment Guide for details" -foreground Red 
Write-Host "Azure AD Application Client ID: " -foreground Yellow -NoNewLine
Write-Host $azureAdApplication.ApplicationId -foreground Red 
Write-Host "Azure AD Application Client Secret: " -foreground Yellow -NoNewLine
Write-Host $AzureADApplicationClientSecret -foreground Red 
Write-Host "Azure AD Application Object ID: " -foreground Yellow -NoNewLine
Write-Host $AzureADApplicationObjectID -foreground Red 
Write-Host "SQL AD Admin User Name: " -foreground Yellow -NoNewLine
Write-Host $SQLADAdminName -foreground Red 
Write-Host "SQL AD Admin User Password:" -foreground Yellow -NoNewLine
Write-Host $SQLADAdminPassword -foreground Red 
Write-Host "Application Gateway HTTPS certData string :" -foreground Yellow -NoNewLine
Write-Host "$certData" -foreground Red 
Write-Host "Application Gateway HTTPS certPassword :" -foreground Yellow -NoNewLine
Write-Host $certPassword -foreground Red 
Write-Host "Application Gateway Backend Authentication aseCertData String : " -foreground Yellow -NoNewLine
Write-Host $aseCertData -foreground Red 
Write-Host "ASE ILB Certificate string asePfxBlobString : " -foreground Yellow -NoNewLine
Write-Host "$asePfxBlobString" -foreground Red 
Write-Host "ASE ILB pfx Password :" -foreground Yellow -NoNewLine
Write-Host "$asePfxPassword" -foreground Red 
Write-host "ASE ILB Certificate Thumbprint aseCertthumbPrint :" -foreground Yellow -NoNewLine
Write-Host "$aseCertThumbprint" -foreground Red 
Write-Host

Write-Host -Prompt "The following additional users have been created in domain. These users will be used for trying out various scenarios" -Foreground Yellow
Write-Host ($receptionistUserName +" user is created. password is "+$receptionistPassword ) -Foreground Yellow
Write-Host
Write-Host
Write-Host -Prompt "-- `nThe script complete." -ForegroundColor Yellow

