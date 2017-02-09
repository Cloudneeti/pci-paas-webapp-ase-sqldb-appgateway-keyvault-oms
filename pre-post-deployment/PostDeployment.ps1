Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,# Provide Resource Group Name Created through ARM template
	[string] [Parameter(Mandatory=$true)] $ServerName, # Provide Sql Server name (not required full name) Created through ARM template
	[string] [Parameter(Mandatory=$true)] $sqlPassword,# Provide password of sql server
	[string] [Parameter(Mandatory=$true)] $ClientIPAddress,# Provide Client IP address (get by running ipconfig in cmd prompt)
	[string] [Parameter(Mandatory=$true)] $ASEOutboundAddress,# Provide ASE Outbound address, we will get it in ASE properties in Azure portal
	[string] [Parameter(Mandatory=$true)] $ADAdministrator,# Provide AD Administrator, same we used for ARM Deployment
	[string] [Parameter(Mandatory=$true)] $subscriptionName,# Provide your Azure subscription
	[string] [Parameter(Mandatory=$true)] $KeyVaultName# Provide Key Vault Name Created through ARM template
)
$DatabaseName = "ContosoClinicDB"
$StorageName = "stgpcipaasreleases"
$StorageKeyType = "StorageAccessKey"
$SQLContainerName = "pci-paas-sql-container"
$SQLBackupName = "pcidb.bacpac"
$StorageUri = "http://$StorageName.blob.core.windows.net/$SQLContainerName/$SQLBackupName"
$ArtifactssubscriptionName = 'Cloudly Dev Visual Studio'
$cmkName = "CMK1" 
$cekName = "CEK1" 
$keyName = "CMK1" 
$sqluserId = "sqladmin"
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
$connStr = "Server=tcp:" + $ServerName + ".database.windows.net,1433;Initial Catalog=" + $DatabaseName + ";Persist Security Info=False;User ID=" + $sqluserId + ";Password=" + $sqlPassword + ";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
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

Read-Host -Prompt "The script executed. Press enter to exists."





