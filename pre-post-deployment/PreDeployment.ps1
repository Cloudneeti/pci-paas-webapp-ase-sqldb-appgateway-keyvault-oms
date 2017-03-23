# Purpose : 
# 1) This script is used to create additional AD users to run various scenarios and creates AD Application and creates service principle to AD Application
# 2) This script should run by Global AD Administrator, You created Global AD Admin in previous script(CreateGlobalADAdmin.ps1)
# 3) This script should run before start deployment of ARM Templates
Param(
	[string] [Parameter(Mandatory=$true)] $azureADDomainName, # Provide your Azure AD Domain Name
	[string] [Parameter(Mandatory=$true)] $subscriptionID, # Provide your Azure subscription ID
	[string] [Parameter(Mandatory=$true)] $suffix #This is used to create a unique website name in your organization. This could be your company name or business unit name
)

###
#Imp: This script needs to be run by Global AD Administrator (aka Company Administrator)
###
Write-Host ("Pre-Requisite: This script needs to be run by Global AD Administrator (aka Company Administrator)" ) -ForegroundColor Gray
#Connect to the Azure AD
Connect-MsolService
$SQLADAdminName = "sqladmin@"+$azureADDomainName
$receptionistUserName = "receptionist_EdnaB@"+$azureADDomainName
$doctorUserName = "doctor_ChrisA@"+$azureADDomainName
$SQLADAdminPassword = "!Password333!!!"
$receptionistPassword = "!Password111!!!"
$doctorPassword = "!Password222!!!"
$cloudwiseAppServiceURL = "http://localcloudneeti6i"+$azureADDomainName
Write-Host ("Step 1:Create AD Users for SQL AD Admin, Receptinist and Doctor to test various scenarios" ) -ForegroundColor Gray
$sqlADAdminObjectId = (Get-MsolUser -UserPrincipalName $SQLADAdminName -ErrorAction SilentlyContinue -ErrorVariable errorVariable).ObjectID
$sqlADAdminDetails = ""
if ($sqlADAdminObjectId -eq $null)  
{    
    $sqlADAdminDetails = New-MsolUser -UserPrincipalName $SQLADAdminName -DisplayName "SQLADAdministrator PCI Samples" -FirstName "SQL AD Administrator" -LastName "PCI Samples"
	$sqlADAdminObjectId= $sqlADAdminDetails.ObjectID
    # Make the new user a Global AD Administrator
	Add-MsolRoleMember -RoleName "Company Administrator" -RoleMemberObjectId $sqlADAdminObjectId
	Set-MsolUserPassword -userPrincipalName $SQLADAdminName -NewPassword $SQLADAdminPassword -ForceChangePassword $false
}
$receptionistUserObjectId = (Get-MsolUser -UserPrincipalName $receptionistUserName -ErrorAction SilentlyContinue -ErrorVariable errorVariable).ObjectID
$receptionistuserDetails = ""
if ($receptionistUserObjectId -eq $null)  
{    
    $receptionistuserDetails = New-MsolUser -UserPrincipalName $receptionistUserName -DisplayName "Edna Benson" -FirstName "Edna" -LastName "Benson"
    Set-MsolUserPassword -userPrincipalName $receptionistUserName -NewPassword $receptionistPassword -ForceChangePassword $false
}

$doctorUserObjectId = (Get-MsolUser -UserPrincipalName $doctorUserName -ErrorAction SilentlyContinue -ErrorVariable errorVariable).ObjectID
$doctoruserDetails = ""
if ($doctorUserObjectId -eq $null)  
{    
    $doctoruserDetails = New-MsolUser -UserPrincipalName $doctorUserName -DisplayName "Chris Aston" -FirstName "Chris" -LastName "Aston"
    Set-MsolUserPassword -userPrincipalName $doctorUserName -NewPassword $doctorPassword -ForceChangePassword $false
}
Write-Host ("Created AD Users for SQL AD Admin, Receptinist and Doctor to test various scenarios" ) -ForegroundColor Gray
#------------------------------
Write-Host ("Step 2: Login to Azure AD and Azure. Please provide Global Administrator Credentials that has Owner/Contributor rights on the Azure Subscription ") -ForegroundColor Gray
Set-Location ".\"
$AzureADApplicationClientSecret =        "Password@123" 
$WebSiteName =         ("cloudwise" + $suffix)
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

# Grant 'SQL AD Admin' access to the Azure subscription
New-AzureRmRoleAssignment -ObjectId $sqlADAdminObjectId -RoleDefinitionName Contributor -Scope ('/subscriptions/' + $subscriptionID )

# To select a default subscription for your current session

$sub = Get-AzureRmSubscription -SubscriptionId $subscriptionID | Select-AzureRmSubscription 

### 2. Create Azure Active Directory apps in default directory
Write-Host ("Step 3: Create Azure Active Directory apps in default directory") -ForegroundColor Gray
    $u = (Get-AzureRmContext).Account
    $u1 = ($u -split '@')[0]
    $u2 = ($u -split '@')[1]
    $u3 = ($u2 -split '\.')[0]
    $defaultPrincipal = ($u1 + $u3 + ".onmicrosoft.com")
    # Get tenant ID
    $tenantID = (Get-AzureRmContext).Tenant.TenantId
    $homePageURL = ("http://" + $defaultPrincipal + "azurewebsites.net" + "/" + $Web1SiteName)
    $replyURLs = @( $cloudwiseAppServiceURL, "http://*.azurewebsites.net","http://localhost:62080", "http://localhost:3026/")
    # Create Active Directory Application
    $azureAdApplication = New-AzureRmADApplication -DisplayName $displayName -HomePage $cloudwiseAppServiceURL -IdentifierUris $cloudwiseAppServiceURL -Password $AzureADApplicationClientSecret # -ReplyUrls $replyURLs
    Write-Host ("`tStep 3.1: Azure Active Directory apps creation successful. AppID is " + $azureAdApplication.ApplicationId) -ForegroundColor Gray

### 3. Create a service principal for the AD Application and add a Reader role to the principal

    Write-Host ("`tStep 3.2: Attempting to create Service Principal") -ForegroundColor Gray
    $principal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId
    Start-Sleep -s 30 # Wait till the ServicePrincipal is completely created. Usually takes 20+secs. Needed as Role assignment needs a fully deployed servicePrincipal
    Write-Host ("`tStep 3.3: Service Principal creation successful - " + $principal.DisplayName) -ForegroundColor Gray
    $scopedSubs = ("/subscriptions/" + $sub.Subscription)
    Write-Host ("`tStep 3.4: Attempting Reader Role assignment" ) -ForegroundColor Gray
    New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $azureAdApplication.ApplicationId.Guid -Scope $scopedSubs
    Write-Host ("`tStep 3.5: Reader Role assignment successful" ) -ForegroundColor Gray


### 4. Print out the required project settings parameters
#############################################################################################
$AzureADApplicationObjectID = (Get-AzureRmADServicePrincipal -ServicePrincipalName $azureAdApplication.ApplicationId).Id

Write-Host "TenantId: " -foreground Yellow –NoNewLine
Write-Host $tenantID -foreground Red 
Write-Host "SubscriptionID: " -foreground Yellow –NoNewLine
Write-Host $sub.Subscription -foreground Red 


Write-Host -Prompt "Start copy all the values from below here." -ForegroundColor Yellow

Write-Host ("Parameters to be used in the registration / configuration.") -foreground Yellow
Write-Host "_artifactsLocationSasToken: " -foreground Yellow –NoNewLine
Write-Host "" -foreground Red 
Write-Host "Cert Data: " -foreground Yellow –NoNewLine
Write-Host "Please see Deployment Guide for instructions" -foreground Red 
Write-Host "Cert Password: " -foreground Yellow –NoNewLine
Write-Host "Please see Deployment Guide for instructions" -foreground Red 
Write-Host "Bastion Host Administrator User Name: " -foreground Yellow –NoNewLine
Write-Host "Default Value is 'bastionadmin'.If needs change please do so in the next step" -foreground Red 
Write-Host "Bastion Host Administrator Password: " -foreground Yellow –NoNewLine
Write-Host "Please Provide Host Administrator Password" -foreground Red 
Write-Host "SQL Administrator Login User Name: " -foreground Yellow –NoNewLine
Write-Host "Default Value is 'sqladmin'.If needs change please do so in the next step" -foreground Red 
Write-Host "SQL Administrator Login Password: " -foreground Yellow –NoNewLine
Write-Host "Please Provide SQL Administrator Login Password" -foreground Red 
Write-Host "SQL Threat Detection Alert Email Address: " -foreground Yellow –NoNewLine
Write-Host "Please Provide Email Address to get SQL Threat Detection Alerts" -foreground Red 
Write-Host "Automation Account Name: " -foreground Yellow –NoNewLine
Write-Host "Please see Deployment Guide for instructions" -foreground Red 
Write-Host "Custom Host Name: " -foreground Yellow –NoNewLine
Write-Host "Please see Deployment Guide for instructions" -foreground Red 

Write-Host "Azure AD Application Client ID: " -foreground Yellow –NoNewLine
Write-Host $azureAdApplication.ApplicationId -foreground Red 
Write-Host "Azure AD Application Client Secret: " -foreground Yellow –NoNewLine
Write-Host $AzureADApplicationClientSecret -foreground Red 
Write-Host "Azure AD Application Object ID: " -foreground Yellow –NoNewLine
Write-Host $AzureADApplicationObjectID -foreground Red 
Write-Host "SQL AD Admin User Name: " -foreground Yellow –NoNewLine
Write-Host $SQLADAdminName -foreground Red 
Write-Host "SQL AD Admin User Password:(If user already exists then we have to get password manually) " -foreground Green –NoNewLine
Write-Host $sqlADAdminDetails.password -foreground Red 


Write-Host ("TODO - Update permissions for the AD Application  '") -foreground Yellow –NoNewLine
Write-Host $displayName1 -foreground Red –NoNewLine
Write-Host ("'.Please follow the deployment guide for the specific permissions") -foreground Yellow

Write-Host -Prompt "The following additional users have been created in domain. These users will be used for trying out various scenarios" -ForegroundColor Yellow
Write-Host ($receptionistUserName +" user is created. password is "+$receptionistPassword ) -ForegroundColor Red
Write-Host ($doctorUserName +" user is created. password is "+$doctorPassword ) -ForegroundColor Red

Write-Host -Prompt "End copy all the values from above here." -ForegroundColor Yellow

Read-Host -Prompt "The script completed execution. Press any key to exit"