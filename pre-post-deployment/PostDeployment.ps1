Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName, # Provide Resource Group Name Created through ARM template
	[string] [Parameter(Mandatory=$true)] $SQLServerName, # Provide Sql Server name (not required full name) Created through ARM template
	[string] [Parameter(Mandatory=$true)] $sqlPassword, # Provide password of sql server
	[string] [Parameter(Mandatory=$true)] $ClientIPAddress, # Eg: 168.62.48.129 Provide Client IP address (get by running ipconfig in cmd prompt)
	[string] [Parameter(Mandatory=$true)] $ASEOutboundAddress, # Provide ASE Outbound address, we will get it in ASE properties in Azure portal
	[string] [Parameter(Mandatory=$true)] $SQLADAdministrator, # Provide SQL AD Administrator Name, same we used for ARM Deployment
	[string] [Parameter(Mandatory=$true)] $subscriptionName, # Provide your Azure subscription
	[string] [Parameter(Mandatory=$true)] $KeyVaultName # Provide Key Vault Name Created through ARM template
)
$DatabaseName = "ContosoClinicDB"
$StorageName = "stgreleases"+$SQLServerName.Substring(0,2).ToLower()
$StorageKeyType = "StorageAccessKey"
$SQLContainerName = "pci-paas-sql-container"
$SQLBackupName = "pcidb.bacpac"
$StorageUri = "http://$StorageName.blob.core.windows.net/$SQLContainerName/$SQLBackupName"
$cmkName = "CMK1" 
$cekName = "CEK1" 
$keyName = "CMK1" 
$sqluserId = "sqladmin"
$location = 'East US'
$SQLBackupToUpload = ".\pcidb.bacpac"
# Check if there is already a login session in Azure Powershell, if not, sign in to Azure  

Write-Host "Azure Subscription Login " -foreground Yellow 
Write-Host ("Step 1: Please use Contributor/Owner access to Login to Azure Subscription Name = " + $subscriptionName) -ForegroundColor Gray

Try  
{  
    Get-AzureRmContext  -ErrorAction Continue  
}  
Catch [System.Management.Automation.PSInvalidOperationException]  
{  
    Login-AzureRmAccount  -SubscriptionName $subscriptionName
} 
$PWord = ConvertTo-SecureString -String $sqlPassword -AsPlainText -Force
$credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $sqluserId, $PWord
$subscriptionId = (Get-AzureRmSubscription -SubscriptionName $subscriptionName).SubscriptionId
Set-AzureRmContext -SubscriptionId $subscriptionId
$userPrincipalName = (Set-AzureRmContext -SubscriptionId $subscriptionId).Account.Id
Invoke-WebRequest https://stgpcipaasreleases.blob.core.windows.net/pci-paas-sql-container/pcidb.bacpac -OutFile $SQLBackupToUpload

# Create a new storage account.
$StorageAccountExists = Get-AzureRmStorageAccount -Name $StorageName -ResourceGroupName $ResourceGroupName -ErrorAction Ignore
if ($StorageAccountExists -eq $null)  
{    
    New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageName -Location $Location -Type "Standard_GRS"
}
Write-Host ("Step 2: Creating storage account for SQL Artifacts") -ForegroundColor Gray
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
Write-Host ("Step 3: Update SQL firewall with your ClientIp = " + $ClientIPAddress + " and ASE's virtual-ip = " + $ASEOutboundAddress ) -ForegroundColor Gray
$clientIp =  Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip  
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIpRule" -StartIpAddress $ClientIPAddress -EndIpAddress $ClientIPAddress
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "AseOutboundRule" -StartIpAddress $ASEOutboundAddress -EndIpAddress $ASEOutboundAddress

########################
Write-Host ("Step 4: Import SQL backpac for release artifacts storage account" ) -ForegroundColor Gray

$importRequest = New-AzureRmSqlDatabaseImport -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -StorageKeytype $StorageKeyType -StorageKey $StorageKey -StorageUri $StorageUri -AdministratorLogin $credential.UserName -AdministratorLoginPassword $credential.Password -Edition Standard -ServiceObjectiveName S0 -DatabaseMaxSizeBytes 50000
Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
Start-Sleep -s 100

########################
Write-Host ("Step 5: Update Azure SQL DB Data masking policy" ) -ForegroundColor Gray

# Start Dynamic Data Masking
Get-AzureRmSqlDatabaseDataMaskingPolicy -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName
Set-AzureRmSqlDatabaseDataMaskingPolicy -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -DataMaskingState Enabled
Get-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName
New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Patients" -ColumnName "FirstName" -MaskingFunction Default
New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Patients" -ColumnName "LastName" -MaskingFunction Default
New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Patients" -ColumnName "SSN" -MaskingFunction SocialSecurityNumber 
# End Dynamic Data Masking



Write-Host ("Step 6: Update SQL Server for Azure Active Directory administrator =" + $SQLADAdministrator ) -ForegroundColor Gray

# Create an Azure Active Directory administrator for SQL
Set-AzureRmSqlServerActiveDirectoryAdministrator -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DisplayName $SQLADAdministrator
########################
Write-Host ("Step 7: Encrypt SQL DB columns SSN, Birthdate and Credit card Information" ) -ForegroundColor Gray

# Start Encryption Columns
Import-Module "SqlServer"

# Connect to your database.
$connStr = "Server=tcp:" + $SQLServerName + ".database.windows.net,1433;Initial Catalog=" + $DatabaseName + ";Persist Security Info=False;User ID=" + $sqluserId + ";Password=" + $sqlPassword + ";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$connection.ConnectionString = $connStr
$connection.Connect()
$server = New-Object Microsoft.SqlServer.Management.Smo.Server($connection)
$database = $server.Databases[$databaseName]

Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName -PermissionsToKeys all -UserPrincipalName $userPrincipalName
Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -UserPrincipalName $userPrincipalName -PermissionsToSecrets all
Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName -PermissionsToKeys all -UserPrincipalName $SQLADAdministrator
Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -UserPrincipalName $SQLADAdministrator -PermissionsToSecrets all
$key = (Add-AzureKeyVaultKey -VaultName $KeyVaultName -Name $keyName -Destination 'Software').ID
$cmkSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyURL $key

New-SqlColumnMasterKey -Name $cmkName -InputObject $database -ColumnMasterKeySettings $cmkSettings
New-SqlColumnEncryptionKey -Name $cekName -InputObject $database -ColumnMasterKey $cmkName

# Encrypt the selected columns (or re-encrypt, if they are already encrypted using keys/encrypt types, different than the specified keys/types.
$ces = @()
$ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Patients.CreditCard_Number" -EncryptionType "Randomized" -EncryptionKey $cekName
Set-SqlColumnEncryption -InputObject $database -ColumnEncryptionSettings $ces
# End Encryption Columns


########################
Write-Host "OMS Updates..." -foreground Yellow 

Write-Host ("Step 8: OMS -- Update all services for Diagnostics Logging" ) -ForegroundColor Gray

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
Install-Script -Name Enable-AzureRMDiagnostics -Force
Install-Script -Name AzureDiagnosticsAndLogAnalytics -Force
Install-Module -Name Enable-AzureRMDiagnostics -Force
Install-Module -Name AzureDiagnosticsAndLogAnalytics -Force

foreach($resourceType in $resourceTypes)
{
    Enable-AzureRMDiagnostics -ResourceGroupName $ResourceGroupName -SubscriptionId $subscriptionId -WSID $omsWS.ResourceId -Force -Update `
    -ResourceType $resourceType -ErrorAction SilentlyContinue
}

$workspace = Find-AzureRmResource -ResourceType "Microsoft.OperationalInsights/workspaces" -ResourceNameContains $omsWS.Name

########################
Write-Host ("Step 9: OMS -- Send Diagnostcis to OMS workspace" ) -ForegroundColor Gray

foreach($resourceType in $resourceTypes)
{
    $resource = Find-AzureRmResource -ResourceType $resourceType 
    Add-AzureDiagnosticsToLogAnalytics $resource $workspace -ErrorAction SilentlyContinue
}

# End OMS Diagnostics

########################

Read-Host -Prompt "The script executed. Press enter to exit."





