#
# PostDeployment.ps1
#
$ResourceGroupName = "01-pci-paas-automation" # Provide Resource Group Name Created through ARM template
$ServerName = "sqlserver-taer4k4qg5zfa" # Provide only Server name not full name
$userId = "testuser" # Provide user id of sql server
$sqlPassword = "PartnerSolutions123" # Provide password of sql server
$cmkName = "CMK1" # Provide Any Name
$cekName = "CEK1" # Provide Any Name
$keyName = "CMK1" # Provide Any Name
$ClientIPAddress = "168.62.48.129"  # Provide Client IP address
$ASEOutboundAddress = "13.90.43.202" # Provide ASE Outbound address, we will get it ASE properties in Azure portal
$ADAdministrator = "globaladmin@sunilklive.onmicrosoft.com" # Pass AD Administrator, same we used for ARM Deployment
$subscriptionName = 'Visual Studio Enterprise' # Pass Subscription Name we used to create ARM Deployment
$ArtifactssubscriptionName = 'Cloudly Dev Visual Studio' # Pass Artifacts Subscription Name
$KeyVaultName= 'kv-pcisamples-taer4k4q' # Pass Key Vault Created through ARM template

$cloudwiseAppServiceURL = ""          # this is the Unique URL of the Cloudwise App Service deployed by the ARM script. e.g. "http://localcloudniti.sunilklive.onmicrosoft.com"
$suffix =               ""     #-- Name of the company/deployment. This is used to create a unique website name in your organization. e.g. "MSFT - "
# ==========================================================================
$DatabaseName = "ContosoClinicDB"
$StorageName = "stgpcipaasreleases"
$StorageKeyType = "StorageAccessKey"
$SQLContainerName = "pci-paas-sql-container"
$SQLBackupName = "pcidb.bacpac"
$StorageUri = "http://$StorageName.blob.core.windows.net/$SQLContainerName/$SQLBackupName"

# Check if there is already a login session in Azure Powershell, if not, sign in to Azure  
Try  
{  
    Get-AzureRmContext  -ErrorAction Continue  
	$subscriptionId = (Get-AzureRmSubscription -SubscriptionName $ArtifactssubscriptionName).SubscriptionId
	Set-AzureRmContext -SubscriptionId $subscriptionId
}  
Catch [System.Management.Automation.PSInvalidOperationException]  
{  
    Login-AzureRmAccount  -SubscriptionName $ArtifactssubscriptionName
} 

$storageAccount = Get-AzureRmStorageAccount -ErrorAction Stop | where-object {$_.StorageAccountName -eq $StorageName} 
$StorageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -name $storageAccount.StorageAccountName -ErrorAction Stop)[0].value 
$credential = Get-Credential #Pass SQL Server Credentials to connect ContosoClinicDB 

$subscriptionId = (Get-AzureRmSubscription -SubscriptionName $subscriptionName).SubscriptionId
Set-AzureRmContext -SubscriptionId $subscriptionId
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -FirewallRuleName "ClientIpRule" -StartIpAddress $ClientIPAddress -EndIpAddress $ClientIPAddress
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -FirewallRuleName "AseOutboundRule" -StartIpAddress $ASEOutboundAddress -EndIpAddress $ASEOutboundAddress
$importRequest = New-AzureRmSqlDatabaseImport –ResourceGroupName $ResourceGroupName –ServerName $ServerName –DatabaseName $DatabaseName –StorageKeytype $StorageKeyType –StorageKey $StorageKey -StorageUri $StorageUri –AdministratorLogin $credential.UserName –AdministratorLoginPassword $credential.Password –Edition Standard –ServiceObjectiveName S0 -DatabaseMaxSizeBytes 50000
Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
Start-Sleep -s 100
# Start Dynamic Data Masking
Get-AzureRmSqlDatabaseDataMaskingPolicy -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
Set-AzureRmSqlDatabaseDataMaskingPolicy -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -DataMaskingState Enabled
Get-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Patients" -ColumnName "FirstName" -MaskingFunction Default
New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Patients" -ColumnName "LastName" -MaskingFunction Default
# End Dynamic Data Masking



# Start Encryption Columns
Import-Module "SqlServer"

# Connect to your database.
$connStr = "Server=tcp:" + $ServerName + ".database.windows.net,1433;Initial Catalog=" + $DatabaseName + ";Persist Security Info=False;User ID=" + $userId + ";Password=" + $sqlPassword + ";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$connection.ConnectionString = $connStr
$connection.Connect()
$server = New-Object Microsoft.SqlServer.Management.Smo.Server($connection)
$database = $server.Databases[$databaseName]

$key = (Add-AzureKeyVaultKey -VaultName $KeyVaultName -Name $keyName -Destination 'Software').ID
$cmkSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyURL $key

New-SqlColumnMasterKey -Name $cmkName -InputObject $database -ColumnMasterKeySettings $cmkSettings
Add-SqlAzureAuthenticationContext -Interactive
New-SqlColumnEncryptionKey -Name $cekName -InputObject $database -ColumnMasterKey $cmkName

# Encrypt the selected columns (or re-encrypt, if they are already encrypted using keys/encrypt types, different than the specified keys/types.
$ces = @()
$ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Patients.SSN" -EncryptionType "Deterministic" -EncryptionKey $cekName
$ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Patients.BirthDate" -EncryptionType "Randomized" -EncryptionKey $cekName
Set-SqlColumnEncryption -InputObject $database -ColumnEncryptionSettings $ces
# End Encryption Columns

# Create an Azure Active Directory administrator for SQL
Set-AzureRmSqlServerActiveDirectoryAdministrator -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DisplayName $ADAdministrator

# Start OMS Diagnostics
$omsWS = Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName

$resourceTypes = @( "Microsoft.Network/applicationGateways",
                    "Microsoft.Network/NetworkSecurityGroups",
                    "Microsoft.Web/serverFarms",
                    "Microsoft.Sql/servers/databases",
                    "Microsoft.Compute/virtualMachines",
                    "Microsoft.Web/sites",
                    "Microsoft.KeyVault/Vaults" )

Install-Module -Name Enable-AzureRMDiagnostics -Force
Install-Module -Name AzureDiagnosticsAndLogAnalytics -Force

foreach($resourceType in $resourceTypes)
{
    Enable-AzureRMDiagnostics -ResourceGroupName $ResourceGroupName -SubscriptionId $subscriptionId -WSID $omsWS.ResourceId -Force -Update `
    -ResourceType $resourceType -ErrorAction SilentlyContinue
}

$workspace = Find-AzureRmResource -ResourceType "Microsoft.OperationalInsights/workspaces" -ResourceNameContains $omsWS.Name

foreach($resourceType in $resourceTypes)
{
    $resource = Find-AzureRmResource -ResourceType $resourceType 
    Add-AzureDiagnosticsToLogAnalytics $resource $workspace -ErrorAction SilentlyContinue
}

# End OMS Diagnostics



# Start AD App Service Principle

	Set-Location ".\"
	# ************************** HOW TO USE THIS SCRIPT ********************************

##### Why do you need this script?#######
## Refer article - https://azure.microsoft.com/en-us/documentation/articles/resource-group-authenticate-service-principal/ 

# STEPS TO MAKE THIS SCRIPT WORK FOR YOU
# 1) Ensure you pass the right subscription name. Parameter $subscriptionName
# 2) Run the ARM deployment and capture the Cloudwise App Service URL. 
# 3) When prompted, signin with a Service Admin user for the subscription
# 4) Usually that's all you have to do
#****************************************************************************



$tenantID=              ""

$passwordADApp =        "Password@123" 

$Web1SiteName =         ("cloudwise" + $suffix)
$displayName1 =         ($suffix + "Azure PCI PAAS Sample")
$servicePrincipalPath=  (".\" + $subscriptionName + ".json" )

### 0. Validate Parameters.
#############################################################################################
if (($subscriptionName -eq "") -or ($cloudwiseAppServiceURL -eq ""))
{
    Write-Host "Please ensure parameters SubscriptionName and cloudwiseAppServiceURL are not empty" -foreground Red
    return
}

### 1. Login to Azure Resource Manager and save the profile locally to avoid relogins (used primarily for debugging purposes)
#############################################################################################
Write-Host ("Step 1: Logging in to Azure Subscription"+ $subscriptionName) -ForegroundColor Gray

# To login to Azure Resource Manager
if(![System.IO.File]::Exists($servicePrincipalPath)){
    # file with path $path doesn't exist

    #Add-AzureRmAccount 
    Login-AzureRmAccount -SubscriptionName $subscriptionName
    
    #Save-AzureRmProfile -Path $servicePrincipalPath
}

Select-AzureRmProfile -Path $servicePrincipalPath




# To select a default subscription for your current session
#Get-AzureRmSubscription –SubscriptionName “Cloudly Dev (Visual Studio Ultimate)” | Select-AzureRmSubscription

$sub = Get-AzureRmSubscription –SubscriptionName $subscriptionName | Select-AzureRmSubscription 


### 2. Create Azure Active Directory apps in default directory
#############################################################################################
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
#############################################################################################

    Write-Host ("Step 3: Attempting to create Service Principal") -ForegroundColor Gray
    $principal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication1.ApplicationId
    Start-Sleep -s 30 # Wait till the ServicePrincipal is completely created. Usually takes 20+secs. Needed as Role assignment needs a fully deployed servicePrincipal

    Write-Host ("Step 3.1: Service Principal creation successful - " + $principal.DisplayName) -ForegroundColor Gray

    $scopedSubs = ("/subscriptions/" + $sub.Subscription)

    Write-Host ("Step 3.2: Attempting Reader Role assignment" ) -ForegroundColor Gray

    New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $azureAdApplication1.ApplicationId.Guid -Scope $scopedSubs

    Write-Host ("Step 3.2: Reader Role assignment successful" ) -ForegroundColor Gray




### 4. Verify the AD principal is working
####### Login with the newly created principal. Refer link https://zimmergren.net/developing-with-azure-creating-a-service-principal-for-your-azure-active-directory-aad-using-powershell-2/
############################################################################################
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

# End AD App Service Principle





