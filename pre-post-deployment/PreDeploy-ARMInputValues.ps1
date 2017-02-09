<<<<<<< HEAD
Param(
    [string] [Parameter(Mandatory=$true)] $DoaminName,# Provide your azuure Domain Name
	[string] [Parameter(Mandatory=$true)] $subscriptionName, # Provide your Azure subscription
	[string] [Parameter(Mandatory=$true)] $suffix #This is used to create a unique website name in your organization
)

###
#Imp: This script need to run by Global Administror 
###
Connect-MsolService
$cloudwiseAppServiceURL = "http://localcloudnit6i.$DoaminName"
$AdUserExists = Get-MsolUser -UserPrincipalName "adadmin@$DoaminName" -ErrorAction SilentlyContinue -ErrorVariable errorVariable
if ($AdUserExists -eq $null)  
{    
    $AdUserdetails=New-MsolUser -UserPrincipalName "adadmin@$DoaminName" -DisplayName "Administror" -FirstName "PCI" -LastName "Samples"
	$AdUserdetails
}
$SQLUserExists = Get-MsolUser -UserPrincipalName "sqladmin@$DoaminName" -ErrorAction SilentlyContinue -ErrorVariable errorVariable
if ($SQLUserExists -eq $null)  
{    
    New-MsolUser -UserPrincipalName "sqladmin@$DoaminName" -DisplayName "SQLAdmin" -FirstName "PCI" -LastName "Samples"
}
$AdminUserExists = Get-MsolUser -UserPrincipalName "user1@$DoaminName" -ErrorAction SilentlyContinue -ErrorVariable errorVariable
if ($AdminUserExists -eq $null)  
{    
    New-MsolUser -UserPrincipalName "user1@$DoaminName" -DisplayName "User" -FirstName "PCI" -LastName "Samples"
}
=======
$DoaminName = "@avyanconsulting.onmicrosoft.com" # Provide Domain Name
>>>>>>> origin/master

$subscriptionName = 'Cloudly Dev Visual Studio'# name of the Azure subscription
$cloudwiseAppServiceURL = "http://localcloudniti.sunilklive.onmicrosoft.com" # this is the Unique URL of the Cloudwise App Service deployed by the ARM script. e.g. "http://localcloudniti.sunilklive.onmicrosoft.com"
$suffix = "MSFT-Laxmi" #-- Name of the company/deployment. This is used to create a unique website name in your organization. e.g. "MSFT - "
#------------------------------
<<<<<<< HEAD
=======
###
#Imp: This script need to run by Global Administror 
###
Connect-MsolService

# Create User Object ID and use same in ARM deployment

$AdUserExists = Get-MsolUser -UserPrincipalName "adadmin$DoaminName" -ErrorAction SilentlyContinue -ErrorVariable errorVariable
if ($AdUserExists -eq $null)  
{    
    $AdUserdetails=New-MsolUser -UserPrincipalName "adadmin$DoaminName" -DisplayName "Administror" -FirstName "PCI" -LastName "Samples"
	$AdUserdetails
}
$SQLUserExists = Get-MsolUser -UserPrincipalName "sqladmin$DoaminName" -ErrorAction SilentlyContinue -ErrorVariable errorVariable
if ($SQLUserExists -eq $null)  
{    
    New-MsolUser -UserPrincipalName "sqladmin$DoaminName" -DisplayName "SQLAdmin" -FirstName "PCI" -LastName "Samples"
}
$AdminUserExists = Get-MsolUser -UserPrincipalName "user1$DoaminName" -ErrorAction SilentlyContinue -ErrorVariable errorVariable
if ($AdminUserExists -eq $null)  
{    
    New-MsolUser -UserPrincipalName "user1$DoaminName" -DisplayName "User" -FirstName "PCI" -LastName "Samples"
}


# /*****   ***** ******  *************
# /*****   ***** ******  *************
# /*****   ***** ******  *************


#------------------------------
>>>>>>> origin/master
Set-Location ".\"
$passwordADApp =        "Password@123" 
$Web1SiteName =         ("cloudwise" + $suffix)
$displayName1 =         ($suffix + "Azure PCI PAAS Sample")
# To login to Azure Resource Manager
	Try  
	{  
		Get-AzureRmContext -ErrorAction Continue  
	}  
	Catch [System.Management.Automation.PSInvalidOperationException]  
	{  
		 #Add-AzureRmAccount 
		Login-AzureRmAccount -SubscriptionName $subscriptionName
	} 

# To select a default subscription for your current session

$sub = Get-AzureRmSubscription –SubscriptionName $subscriptionName | Select-AzureRmSubscription 

### 2. Create Azure Active Directory apps in default directory
Write-Host ("Step 2: Create Azure Active Directory apps in default directory") -ForegroundColor Gray
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
    $azureAdApplication1 = New-AzureRmADApplication -DisplayName $displayName1 -HomePage $cloudwiseAppServiceURL -IdentifierUris $cloudwiseAppServiceURL -Password $passwordADApp -ReplyUrls $replyURLs
    Write-Host ("Step 2.1: Azure Active Directory apps creation successful. AppID is " + $azureAdApplication1.ApplicationId) -ForegroundColor Gray

### 3. Create a service principal for the AD Application and add a Reader role to the principal

    Write-Host ("Step 3: Attempting to create Service Principal") -ForegroundColor Gray
    $principal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication1.ApplicationId
    Start-Sleep -s 30 # Wait till the ServicePrincipal is completely created. Usually takes 20+secs. Needed as Role assignment needs a fully deployed servicePrincipal
    Write-Host ("Step 3.1: Service Principal creation successful - " + $principal.DisplayName) -ForegroundColor Gray
    $scopedSubs = ("/subscriptions/" + $sub.Subscription)
    Write-Host ("Step 3.2: Attempting Reader Role assignment" ) -ForegroundColor Gray
    New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $azureAdApplication1.ApplicationId.Guid -Scope $scopedSubs
    Write-Host ("Step 3.2: Reader Role assignment successful" ) -ForegroundColor Gray

<<<<<<< HEAD

### 4. Print out the required project settings parameters
#############################################################################################
$ADAdminObjectId = (Get-AzureRmADUser -UserPrincipalName "adadmin@$DoaminName").id
$SQLAdminObjectId = (Get-AzureRmADUser -UserPrincipalName "sqladmin@$DoaminName").id
$UserObjectId = (Get-AzureRmADUser -UserPrincipalName "user1@$DoaminName").id
$ApplicationObjectId = (Get-AzureRmADServicePrincipal -ServicePrincipalName $azureAdApplication1.ApplicationId) 

Write-Host ("AD Application Details:") -foreground Green
$azureAdApplication1
Write-Host ("Parameters to be used in the registration / configuration.") -foreground Green
Write-Host "SubscriptionID: " -foreground Green –NoNewLine
Write-Host $sub.Subscription -foreground Red 
Write-Host "Application Client ID: " -foreground Green –NoNewLine
Write-Host $azureAdApplication1.ApplicationId -foreground Red 
Write-Host "Application Client Password: " -foreground Green –NoNewLine
Write-Host $passwordADApp -foreground Red 
Write-Host "PostLogoutRedirectUri: " -foreground Green –NoNewLine
Write-Host $cloudwiseAppServiceURL -foreground Red 
Write-Host "TenantId: " -foreground Green –NoNewLine
Write-Host $tenantID -foreground Red 
Write-Host "AD Admin Object Id: " -foreground Green –NoNewLine
Write-Host $ADAdminObjectId -foreground Red 
Write-Host "SQL Admin Object Id: " -foreground Green –NoNewLine
Write-Host $SQLAdminObjectId -foreground Red 
Write-Host "Application Object ID: " -foreground Green –NoNewLine
Write-Host $ApplicationObjectId.Id -foreground Red 
Write-Host "AD Admin User: " -foreground Green –NoNewLine
Write-Host adadmin@$DoaminName -foreground Red 
Write-Host "AD Admin Password: " -foreground Green –NoNewLine
Write-Host $AdUserdetails.password -foreground Red 

Write-Host ("TODO - Update permissions for the AD Application  '") -foreground Yellow –NoNewLine
Write-Host $displayName1 -foreground Red –NoNewLine
Write-Host ("'. Cloudwise would atleast need 2 apps") -foreground Yellow
Write-Host ("`t 1) Windows Azure Active Directory ") -foreground Yellow
Write-Host ("`t 2) Windows Azure Service Management API ") -foreground Yellow
Write-Host ("see README.md for details") -foreground Yellow

Read-Host -Prompt "The script executed. Press Copy required values."
=======
### 4. Verify the AD principal is working
####### Login with the newly created principal. Refer link https://zimmergren.net/developing-with-azure-creating-a-service-principal-for-your-azure-active-directory-aad-using-powershell-2/
$svcPrincipalCredentials = Get-Credential ## -Credential ## $azureAdApplication1.ApplicationId
Login-AzureRmAccount  `
    -Credential $svcPrincipalCredentials `
    -ServicePrincipal `
    -TenantId $tenantID 

### 5. Print out the required project settings parameters
#############################################################################################

Write-Host ("AD Application Details:") -foreground Green
$azureAdApplication1
Write-Host ("Parameters to be used in the registration / configuration.") -foreground Green
Write-Host "SubscriptionID: " -foreground Green –NoNewLine
Write-Host $sub.Subscription -foreground Red 
Write-Host "Domain: " -foreground Green –NoNewLine
Write-Host ($u3 + ".onmicrosoft.com") -foreground Red –NoNewLine
Write-Host "- Please verify the domain with the management portal. For debugging purposes we have used the domain of the user signing in. You might have Custom / Organization domains" -foreground Yellow
Write-Host "Application Client ID: " -foreground Green –NoNewLine
Write-Host $azureAdApplication1.ApplicationId -foreground Red 
Write-Host "Application Client Password: " -foreground Green –NoNewLine
Write-Host $passwordADApp -foreground Red 
Write-Host "PostLogoutRedirectUri: " -foreground Green –NoNewLine
Write-Host $cloudwiseAppServiceURL -foreground Red 
Write-Host "TenantId: " -foreground Green –NoNewLine
Write-Host $tenantID -foreground Red 
Write-Host ("TODO - Update permissions for the AD Application  '") -foreground Yellow –NoNewLine
Write-Host $displayName1 -foreground Red –NoNewLine
Write-Host ("'. Cloudwise would atleast need 2 apps") -foreground Yellow
Write-Host ("`t 1) Windows Azure Active Directory ") -foreground Yellow
Write-Host ("`t 2) Windows Azure Service Management API ") -foreground Yellow
Write-Host ("see README.md for details") -foreground Yellow


# /*****   ***** ******  *************
# /*****   ***** ******  *************
# /*****   ***** ******  *************

# Out put values to use in ARM Templates

$ADAdminObjectId = (Get-AzureRmADUser -UserPrincipalName "adadmin$DoaminName").id
$SQLAdminObjectId = (Get-AzureRmADUser -UserPrincipalName "sqladmin$DoaminName").id
$UserObjectId = (Get-AzureRmADUser -UserPrincipalName "user1$DoaminName").id
$ApplicationObjectId = (Get-AzureRmADServicePrincipal -ServicePrincipalName $azureAdApplication1.ApplicationId) 
Write-Host 'AD Admin Object Id = '$ADAdminObjectId -foreground Red 
Write-Host 'SQL Admin Object Id = '$SQLAdminObjectId -foreground Red 
Write-Host 'User Object ID = '$UserObjectId -foreground Red 
Write-Host 'Application Object ID = '$ApplicationObjectId.Id -foreground Red 
Write-Host 'Application Client ID = '$azureAdApplication1.ApplicationId -foreground Red 
Write-Host 'Application Client Secret = '$passwordADApp -foreground Red 
Write-Host 'AD Admin User = 'adadmin$DoaminName -foreground Red
Write-Host 'AD Admin Password = '$AdUserdetails.password -foreground Red

>>>>>>> origin/master
