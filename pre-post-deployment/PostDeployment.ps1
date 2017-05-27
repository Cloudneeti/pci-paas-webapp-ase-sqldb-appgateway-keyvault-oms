# Refer to the README.md (located here https://github.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/) 
#   and Deployment Guide (located in the documents folder of the same github repo
#
# This is a Post-Deployment script that is to be run after a successful ARM deployment 
# Pre-Requisites to run this script
#      1) Global Azure AD admin credentials that has at least contributor access to the Azure Subscription
#      2) Should have successfully deployed pre-Deployment script and Azure ARM deployment
#
# The script does the following things 
#      1) Downloads and copies the SQL bacpac file to a new Azure storage account
#      2) Updates SQL DB firewall to allow you (your clientIp) access to manage SQL DB AND Allowing the WebApp deployed on ASE (the ASE outbound virtual IP)
#      3) Data Mask few DB columns (ensuring that only the SQL Admins be able to see the detailed info in the Database) everyone else sees them as masked .. 
#      4) Enable Always Encrypt for a few columns (e.g. Credit card)
#      5) Makes an AD User to the the SQL AD Admin [refer command Set-AzureRmSqlServerActiveDirectoryAdministrator]
#      6) Ensures Diagnotics logs are sent to OMS Workspace (script assumes that there's only one WS in the resourcegroup created by the ARM template)
#
# Enjoy the sample.

<#
# If you'd like to run this from w/i a powershell_ISE or visual studio code, you could try replacing and uncommenting this code block AND commenting out the parameters block.
$SubscriptionId = <your sub id> # Provide your Azure subscription ID
$ResourceGroupName = '001-azurepcisamples-avyan' # Provide Resource Group Name Created through ARM template
$ClientIPAddress = <your client IP address>  # Eg: 168.62.48.129 Provide Client IP address (get by running ipconfig in cmd prompt)
$ASEOutboundAddress = <virtual outbound IP address of the ASE> # Provide ASE Outbound address we will get it in ASE properties in Azure portal
$SQLServerName = <your sql server name> # Provide Sql Server name (not required full name) Created through ARM template
$SQLServerAdministratorLoginPassword = <your sqlserver admin password> # Provide admin password of sql server used for ARM template parameter "sqlAdministratorLoginPassword" 
$KeyVaultName = <your keyvault name> # Provide Key Vault Name Created through ARM template
$AzureAdApplicationClientId = <your app id> # AD Application ClientID - the same one you used in the ARM template
$AzureAdApplicationClientSecret = <your password> # AD Application ClientID - the same one you used in the ARM template
$SqlAdAdminUserName = <your sqladadmin user principal name> # Provide SQL AD Administrator Name same we used for ARM Deployment for parameter sqlAdAdminUserName
$SqlAdAdminUserPassword = <your password> # Provide SQL AD Administrator Name same we used for ARM Deployment for parameter sqlAdAdminUserPassword, available for consistency purposes only.
#>


Param(
	[string] [Parameter(Mandatory=$true)] $SubscriptionId , # Provide your Azure subscription ID
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName , # Provide Resource Group Name Created through ARM template
	[string] [Parameter(Mandatory=$true)] $ClientIPAddress , # Eg: 168.62.48.129 Provide Client IP address (get by running ipconfig in cmd prompt)
	[string] [Parameter(Mandatory=$true)] $ASEOutboundAddress , # Provide ASE Outbound address, we will get it in ASE properties in Azure portal
	[string] [Parameter(Mandatory=$true)] $SQLServerName , # Provide Sql Server name (not required full name) Created through ARM template
	[string] [Parameter(Mandatory=$true)] $SQLServerAdministratorLoginUserName, # Provide admin user name of sql server used for ARM template parameter "sqlAdministratorLoginUserName" 
	[string] [Parameter(Mandatory=$true)] $SQLServerAdministratorLoginPassword, # Provide admin password of sql server used for ARM template parameter "sqlAdministratorLoginPassword" 
	[string] [Parameter(Mandatory=$true)] $KeyVaultName , # Provide Key Vault Name Created through ARM template
	[string] [Parameter(Mandatory=$true)] $AzureAdApplicationClientId , # AD Application ClientID - the same one you used in the ARM template
    [string] [Parameter(Mandatory=$true)] $AzureAdApplicationClientSecret, # AD Application ClientID - the same one you used in the ARM template
	[string] [Parameter(Mandatory=$true)] $SqlAdAdminUserName, # Provide SQL AD Administrator Name, same we used for ARM Deployment for parameter sqlAdAdminUserName
	[string] [Parameter(Mandatory=$true)] $SqlAdAdminUserPassword # Provide SQL AD Administrator Name, same we used for ARM Deployment for parameter sqlAdAdminUserPassword, available for consistency purposes only.
)


$DatabaseName = "ContosoPayments"
$StorageName = "stgreleases"+$SQLServerName.Substring(10,5).ToLower()
$StorageKeyType = "StorageAccessKey"
$SQLContainerName = "pci-paas-sql-container"
$SQLBackupName = "ContosoPayments.bacpac"
$StorageUri = "http://$StorageName.blob.core.windows.net/$SQLContainerName/$SQLBackupName"
$cmkName = "CMK1" 
$cekName = "CEK1" 
$keyName = "CMK1" 
$location = 'East US'
$SQLBackupToUpload = (".\"+$SQLBackupName)
# Check if there is already a login session in Azure Powershell, if not, sign in to Azure  

Write-Host "Azure Subscription Login " -foreground Yellow 
Write-Host ("Step 1: Please use Contributor/Owner access to Login to Azure Subscription Id = " + $subscriptionId) -ForegroundColor Gray

Try  
{  
    Get-AzureRmContext  -ErrorAction Continue  
}  
Catch [System.Management.Automation.PSInvalidOperationException]  
{  
    Login-AzureRmAccount  -SubscriptionId $subscriptionId
} 
$PWord = ConvertTo-SecureString -String $SQLServerAdministratorLoginPassword -AsPlainText -Force
$credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $SQLServerAdministratorLoginUserName, $PWord
$subscriptionId = (Get-AzureRmSubscription -SubscriptionId $subscriptionId).SubscriptionId
$context = Set-AzureRmContext -SubscriptionId $subscriptionId
$userPrincipalName = $context.Account.Id
$downloadbacpacPath = "https://stgpcipaasreleases.blob.core.windows.net/pci-paas-sql-container/"+$SQLBackupName
Invoke-WebRequest $downloadbacpacPath -OutFile $SQLBackupToUpload


Write-Host ("Step 2: Creating storage account for SQL Artifacts") -ForegroundColor Gray
# Create a new storage account.
$StorageAccountExists = Get-AzureRmStorageAccount -Name $StorageName -ResourceGroupName $ResourceGroupName -ErrorAction Ignore
if ($StorageAccountExists -eq $null)  
{    
    New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageName -Location $Location -Type "Standard_GRS" -EnableEncryptionService "Blob,File"
}

# Set a default storage account.
Set-AzureRmCurrentStorageAccount -StorageAccountName $StorageName -ResourceGroupName $ResourceGroupName
# Create a new SQL container.
$SQLContainerNameExists = Get-AzureStorageContainer -Name $SQLContainerName -ev notPresent -ea 0
if ($SQLContainerNameExists -eq $null)  
{    
    New-AzureStorageContainer -Name $SQLContainerName -Permission Container 
}
 # Upload a blob into a sql container.
Set-AzureStorageBlobContent -Container $SQLContainerName -File $SQLBackupToUpload
$storageAccount = Get-AzureRmStorageAccount -ErrorAction Stop | where-object {$_.StorageAccountName -eq $StorageName} 
$StorageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -name $storageAccount.StorageAccountName -ErrorAction Stop)[0].value 

########################
Write-Host "SQL Server Updates" -foreground Yellow 
Write-Host ("`tStep 3: Update SQL firewall with your ClientIp = " + $ClientIPAddress + " and ASE's virtual-ip = " + $ASEOutboundAddress ) -ForegroundColor Gray
$clientIp =  Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip  
$unqiueid = Get-Random -Maximum 999
Try { New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIpRule$unqiueid" -StartIpAddress $ClientIPAddress -EndIpAddress $ClientIPAddress -ErrorAction Continue} Catch {}
Try { New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "AseOutboundRule$unqiueid" -StartIpAddress $ASEOutboundAddress -EndIpAddress $ASEOutboundAddress -ErrorAction Continue} Catch {}
Try { New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIp$unqiueid" -StartIpAddress $clientIp -EndIpAddress $clientIp -ErrorAction Continue} Catch {}

########################
Write-Host ("`tStep 4: Import SQL backpac for release artifacts storage account" ) -ForegroundColor Gray

    $importRequest = New-AzureRmSqlDatabaseImport -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -StorageKeytype $StorageKeyType -StorageKey $StorageKey -StorageUri $StorageUri -AdministratorLogin $credential.UserName -AdministratorLoginPassword $credential.Password -Edition Standard -ServiceObjectiveName S0 -DatabaseMaxSizeBytes 50000
    Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    Start-Sleep -s 100

########################
Write-Host ("`tStep 5: Update Azure SQL DB Data masking policy" ) -ForegroundColor Gray

# Start Dynamic Data Masking
    Get-AzureRmSqlDatabaseDataMaskingPolicy -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName
    Set-AzureRmSqlDatabaseDataMaskingPolicy -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -DataMaskingState Enabled
    Get-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName
    New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Customers" -ColumnName "FirstName" -MaskingFunction Default
    New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Customers" -ColumnName "LastName" -MaskingFunction Default
    New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Customers" -ColumnName "Customer_Id" -MaskingFunction SocialSecurityNumber 
# End Dynamic Data Masking



Write-Host ("`tStep 6: Update SQL Server for Azure Active Directory administrator =" + $SqlAdAdminUserName ) -ForegroundColor Gray

# Create an Azure Active Directory administrator for SQL
Set-AzureRmSqlServerActiveDirectoryAdministrator -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DisplayName $SqlAdAdminUserName
            
########################
Write-Host ("`tStep 7: Encrypt SQL DB column Credit card Information" ) -ForegroundColor Gray

# Start Encryption Columns
Import-Module "SqlServer"

# Connect to your database.
$connStr = "Server=tcp:" + $SQLServerName + ".database.windows.net,1433;Initial Catalog=" + "`"" + $DatabaseName + "`"" + ";Persist Security Info=False;User ID=" + "`"" + $SQLServerAdministratorLoginUserName + "`"" + ";Password=`"" + $SQLServerAdministratorLoginPassword + "`"" + ";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$connection.ConnectionString = $connStr
$connection.Connect()
$server = New-Object Microsoft.SqlServer.Management.Smo.Server($connection)
$database = $server.Databases[$databaseName]


#policy for the UserPrincipal
    Write-Host ("`tGiving Key Vault access permissions to the users and serviceprincipals ..") -ForegroundColor Gray

        Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -UserPrincipalName $userPrincipalName -ResourceGroupName $ResourceGroupName -PermissionsToKeys all  -PermissionsToSecrets all

        Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -UserPrincipalName $SqlAdAdminUserName -ResourceGroupName $ResourceGroupName -PermissionsToKeys all -PermissionsToSecrets all

        Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -ServicePrincipalName $azureAdApplicationClientId -ResourceGroupName $ResourceGroupName -PermissionsToKeys all -PermissionsToSecrets all

    Write-Host ("`tGranted permissions to the users and serviceprincipals ..") -ForegroundColor Gray


# Creating Master key settings

    $key = (Add-AzureKeyVaultKey -VaultName $KeyVaultName -Name $keyName -Destination 'Software').ID
    $cmkSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyURL $key


# Start - Switching SQL commands context to the AD Application
    #Add-SqlAzureAuthenticationContext -Interactive 
    
    New-SqlColumnMasterKey -Name $cmkName -InputObject $database -ColumnMasterKeySettings $cmkSettings
    Add-SqlAzureAuthenticationContext -ClientID $azureAdApplicationClientId -Secret $azureAdApplicationClientSecret -Tenant $context.Tenant.TenantId
    New-SqlColumnEncryptionKey -Name $cekName -InputObject $database -ColumnMasterKey $cmkName
    
    # Encrypt the selected columns (or re-encrypt, if they are already encrypted using keys/encrypt types, different than the specified keys/types.
    $ces = @()
    $ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Customers.CreditCard_Number" -EncryptionType "Deterministic" -EncryptionKey $cekName
	$ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Customers.CreditCard_Code" -EncryptionType "Deterministic" -EncryptionKey $cekName
	$ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Customers.CreditCard_Expiration" -EncryptionType "Deterministic" -EncryptionKey $cekName

    Set-SqlColumnEncryption -InputObject $database -ColumnEncryptionSettings $ces

    # End Encryption Columns

# End - Switching SQL commands context to the AD Application

########################
Write-Host "OMS Updates..." -foreground Yellow 

Write-Host ("`tStep 8: OMS -- Update all services for Diagnostics Logging" ) -ForegroundColor Gray

# Start OMS Diagnostics
$omsWS = Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName

$resourceTypes = @( "Microsoft.Network/applicationGateways",
                    "Microsoft.Network/NetworkSecurityGroups",
                    "Microsoft.Web/serverFarms",
                    "Microsoft.Sql/servers/databases",
                    "Microsoft.Compute/virtualMachines",
                    "Microsoft.Web/sites",
                    "Microsoft.KeyVault/Vaults" ,
					"Microsoft.Automation/automationAccounts")

<#
    Install-Script -Name Enable-AzureRMDiagnostics -Force
    Install-Script -Name AzureDiagnosticsAndLogAnalytics -Force
    Install-Module -Name Enable-AzureRMDiagnostics -Force
    Import-Module -Name AzureDiagnosticsAndLogAnalytics -Force
#>

foreach($resourceType in $resourceTypes)
{
    Enable-AzureRMDiagnostics -ResourceGroupName $ResourceGroupName -SubscriptionId $subscriptionId -WSID $omsWS.ResourceId -Force -Update `
    -ResourceType $resourceType -ErrorAction SilentlyContinue
}

$workspace = Find-AzureRmResource -ResourceType "Microsoft.OperationalInsights/workspaces" -ResourceNameContains $omsWS.Name

########################
Write-Host ("`tStep 8.1: OMS -- Send Diagnostcis to OMS workspace" ) -ForegroundColor Gray

foreach($resourceType in $resourceTypes)
{
    Write-Host ("Add-AzureDiagnosticsToLogAnalytics to " + $resourceType) -ForegroundColor Gray
    $resource = Find-AzureRmResource -ResourceType $resourceType 
    Add-AzureDiagnosticsToLogAnalytics $resource $workspace -ErrorAction SilentlyContinue
}

# End OMS Diagnostics

########################

Read-Host -Prompt "The script executed. Press enter to exit."





