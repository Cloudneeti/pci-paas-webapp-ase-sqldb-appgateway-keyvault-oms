# Refer to the README.md document for deployment 
#
# This is a Post-Deployment script that is to be run after a successful Azure Resource Manager Template deployment 
# Pre-Requisites to run this script
#      1) Global Azure AD admin credentials that has contributor access to the Azure Subscription
#      2) Successfully deployed pre-Deployment script and Azure Azure Resource Manager Template deployment
#
# This script will:
#      1) Downloads and copy the SQL bacpac file to a new Azure storage account
#      2) Updates SQL DB firewall to allow you (your clientIp) access to manage SQL DB and Allow the WebApp to be deployed using ASE 
#      3) Enable Always Encrypt in SQL (e.g. Credit card)
#      4) Set up the correct roles for the SQL AD Admin [refer command Set-AzureRmSqlServerActiveDirectoryAdministrator]
#      6) Enable logs are sent to OMS Workspace (script assumes that there's only one WS in the resourcegroup created by the Azure Resource Manager Template)
#


<#
# for advanced use, you can uncomment this code block AND commenting out the parameters block.
$SubscriptionId = <your sub id> # Provide your Azure subscription ID
$ResourceGroupName = '001-azurepcisamples' # Provide Resource Group Name Created through Azure Resource Manager Template  template
$ClientIPAddress = <your client IP address>  # Eg: 168.1.1.1 Provide Client IP address (get by running ipconfig in cmd prompt)
$ASEOutboundAddress = <virtual outbound IP address of the ASE> # Provide ASE Outbound address we will get it in ASE properties in Azure portal
$SQLServerName = <your sql server name> # Provide Sql Server name (not required full name) Created through Azure Resource Manager Template  
$SQLServerAdministratorLoginPassword = <your sqlserver admin password> # Provide admin password of sql server used for Azure Resource Manager Template parameter "sqlAdministratorLoginPassword" 
$KeyVaultName = <your keyvault name> # Provide Key Vault Name Created through Azure Resource Manager Template  
$AzureAdApplicationClientId = <your app id> # AD Application ClientID - the same one you used in the Azure Resource Manager Template  
$AzureAdApplicationClientSecret = <your password> # AD Application ClientID - the same one you used in the Azure Resource Manager Template  
$SqlAdAdminUserName = <your sqladadmin user principal name> # Provide SQL AD Administrator Name as used for Azure Resource Manager Template  Deployment for parameter sqlAdAdminUserName
$SqlAdAdminUserPassword = <your password> # Provide SQL AD Administrator Name as used for Azure Resource Manager Template Deployment for parameter sqlAdAdminUserPassword provided for use consistency
#>


Param(
	[string] [Parameter(Mandatory=$true)] $SubscriptionId , # Provide your Azure subscription ID
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName , # Provide Resource Group Name Created through Azure Resource Manager Template  
	[string] [Parameter(Mandatory=$true)] $ClientIPAddress , # Eg: 168.62.48.129 Provide Client IP address (get by running ipconfig in cmd prompt)
	[string] [Parameter(Mandatory=$true)] $SQLServerName , # Provide Sql Server name (not required full name) Created through ARM template
	[string] [Parameter(Mandatory=$true)] $SQLServerAdministratorLoginUserName, # Provide admin user name of sql server used for ARM template parameter "sqlAdministratorLoginUserName" 
	[string] [Parameter(Mandatory=$true)] $SQLServerAdministratorLoginPassword, # Provide admin password of sql server used for ARM template parameter "sqlAdministratorLoginPassword" 
	[string] [Parameter(Mandatory=$true)] $KeyVaultName , # Provide Key Vault Name Created through ARM template
	[string] [Parameter(Mandatory=$true)] $AzureAdApplicationClientId , # AD Application ClientID - the same one you used in the ARM template
    [string] [Parameter(Mandatory=$true)] $AzureAdApplicationClientSecret, # AD Application ClientID - the same one you used in the ARM template
	[string] [Parameter(Mandatory=$true)] $SqlAdAdminUserName, # Provide SQL AD Administrator Name, same we used for ARM Deployment for parameter sqlAdAdminUserName
	[string] [Parameter(Mandatory=$true)] $SqlAdAdminUserPassword # Provide SQL AD Administrator Name, same we used for ARM Deployment for parameter sqlAdAdminUserPassword, available for consistency purposes only.
)

### manage variables
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
$tenantID = (Get-AzureRmContext).Tenant.TenantId
if ($tenantID -eq $null){$tenantID = (Get-AzureRmContext).Tenant.Id}

# Check if there is already a login session in Azure Powershell, if not, sign in to Azure  
Write-Host "`nAzure Subscription Login " -foreground Yellow 
Write-Host ("`nStep 1: Please use Contributor/Owner access to Login to Azure Subscription Id = " + $subscriptionId) -ForegroundColor Yellow
<#
$cred = Get-Credential
$Login = Login-AzureRmAccount -SubscriptionId $SubscriptionID -Credential $mycreds
#>
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
$context = Set-AzureRmContext -SubscriptionId $subscriptionId
$userPrincipalName = $context.Account.Id
$downloadbacpacPath = "https://stgpcipaasreleases.blob.core.windows.net/pci-paas-sql-container/"+$SQLBackupName
Invoke-WebRequest $downloadbacpacPath -OutFile $SQLBackupToUpload


Write-Host ("Step 2: Creating storage account for SQL Artifacts") -ForegroundColor Yellow
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
Set-AzureStorageBlobContent -Container $SQLContainerName -File $SQLBackupToUpload -Force
$storageAccount = Get-AzureRmStorageAccount -ErrorAction Stop | where-object {$_.StorageAccountName -eq $StorageName} 
$StorageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -name $storageAccount.StorageAccountName -ErrorAction Stop)[0].value 

########################
Write-Host "`nSQL Server Updates" -foreground Yellow 
Write-Host ("`nStep 3: Update SQL firewall with your ClientIp = " + $ClientIPAddress + " and ASE's virtual-ip = " + $ASEOutboundAddress ) -ForegroundColor Yellow
#$clientIp =  Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip  
$unqiueid = Get-Random -Maximum 999
Try { New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIpRule$unqiueid" -StartIpAddress $ClientIPAddress -EndIpAddress $ClientIPAddress} 
Catch {
    "Failed to create SQL Server firewall rule."
    Break
}
########################
Write-Host ("`nStep 4: Import SQL backpac for release artifacts storage account" ) -ForegroundColor Yellow
    try
    {
        New-AzureRmSqlDatabaseImport -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -StorageKeytype $StorageKeyType -StorageKey $StorageKey -StorageUri $StorageUri -AdministratorLogin $credential.UserName -AdministratorLoginPassword $credential.Password -Edition Standard -ServiceObjectiveName S0 -DatabaseMaxSizeBytes 50000
        Start-Sleep -s 100
    }
    catch [Hyak.Common.CloudException]
    {
        Write-Host "`nDatabase is not empty."
    }
########################
Write-Host ("`nStep 5: Update Azure SQL DB Data masking policy" ) -ForegroundColor Yellow

# Start Dynamic Data Masking
    try {
        Set-AzureRmSqlDatabaseDataMaskingPolicy -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -DataMaskingState Enabled
    }
    catch {}
    try {New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Customers" -ColumnName "FirstName" -MaskingFunction Default}
    catch {}
    try{New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Customers" -ColumnName "LastName" -MaskingFunction Default}
    catch{}
    try {New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Customers" -ColumnName "Customer_Id" -MaskingFunction SocialSecurityNumber}
    catch {}

# End Dynamic Data Masking

Write-Host ("`nStep 6: Update SQL Server for Azure Active Directory administrator =" + $SqlAdAdminUserName ) -ForegroundColor Yellow

# Create an Azure Active Directory administrator for SQL
Set-AzureRmSqlServerActiveDirectoryAdministrator -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DisplayName $SqlAdAdminUserName
            
########################
Write-Host ("`nStep 7: Encrypt SQL DB column Credit card Information" ) -ForegroundColor Yellow

# Start Encryption Columns
Import-Module "SqlServer"

# Connect to your database.
$connStr = "Server=tcp:" + $SQLServerName + ".database.windows.net,1433;Initial Catalog=" + "`"" + $DatabaseName + "`"" + ";Persist Security Info=False;User ID=" + "`"" + $SQLServerAdministratorLoginUserName + "`"" + ";Password=`"" + $SQLServerAdministratorLoginPassword + "`"" + ";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$connection.ConnectionString = $connStr
$connection.Connect()
$server = New-Object Microsoft.SqlServer.Management.Smo.Server($connection)
$Global:database = $server.Databases[$databaseName]

#policy for the UserPrincipal
    Write-Host ("`nGiving Key Vault access permissions to the users and serviceprincipals ..") -ForegroundColor Yellow

        Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -UserPrincipalName $userPrincipalName -ResourceGroupName $ResourceGroupName -PermissionsToKeys all  -PermissionsToSecrets all

        Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -UserPrincipalName $SqlAdAdminUserName -ResourceGroupName $ResourceGroupName -PermissionsToKeys all -PermissionsToSecrets all

        Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -ServicePrincipalName $azureAdApplicationClientId -ResourceGroupName $ResourceGroupName -PermissionsToKeys all -PermissionsToSecrets all

    Write-Host ("`nGranted permissions to the users and serviceprincipals ..") -ForegroundColor Yellow

# Creating Master key settings

    $key = (Add-AzureKeyVaultKey -VaultName $KeyVaultName -Name $keyName -Destination 'Software').ID
    $cmkSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyURL $key

# Start - Switching SQL commands context to the AD Application
    $sqlMasterKey = Get-SqlColumnMasterKey -Name $cmkName -InputObject $database -ErrorAction SilentlyContinue
    if ($sqlMasterKey){Write "`nSQL Master Key $cmkName already exists."} 
    Else{New-SqlColumnMasterKey -Name $cmkName -InputObject $database -ColumnMasterKeySettings $cmkSettings}

    Add-SqlAzureAuthenticationContext -ClientID $azureAdApplicationClientId -Secret $azureAdApplicationClientSecret -Tenant $tenantID
    try {New-SqlColumnEncryptionKey -Name $cekName -InputObject $database -ColumnMasterKey $cmkName} catch {}
    
    # Encrypt the selected columns (or re-encrypt, if they are already encrypted using keys/encrypt types, different than the specified keys/types.
    $ces = @()
    $ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Customers.CreditCard_Number" -EncryptionType "Deterministic" -EncryptionKey $cekName
	$ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Customers.CreditCard_Code" -EncryptionType "Deterministic" -EncryptionKey $cekName
	$ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Customers.CreditCard_Expiration" -EncryptionType "Deterministic" -EncryptionKey $cekName
    try{
        Set-SqlColumnEncryption -InputObject $database -ColumnEncryptionSettings $ces
        Write "`nColumn CreditCard_Number, CreditCard_Code, CreditCard_Expiration have been successfully encrypted"
    }
    catch{
        Write "`nColumn encryption has failed."
        write "`n$Error[0]" ;Break
    }
    # End Encryption Columns

    ### creating user within SQL Server and Granting them with appropriate access.
    $connectionString = "Server=tcp:" + $SQLServerName + ".database.windows.net,1433;Initial Catalog=" + "`"" + $DatabaseName + "`"" + ";Persist Security Info=False;User ID=" + "`"" + $SqlAdAdminUserName + "`"" + ";Password=`"" + $SqlAdAdminUserPassword + "`"" + ";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Integrated;Connection Timeout=30;"
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection($connectionString)
    $query = [IO.File]::ReadAllText("$PWD\Scripts\PostDeploymentSQL.sql")
    $query = $query -replace "XXXX","$AzureADDomainName"
    $command = New-Object -TypeName System.Data.SqlClient.SqlCommand($query, $connection)
    $connection.Open()
    $command.ExecuteNonQuery()
    $connection.Close()

# End - Switching SQL commands context to the AD Application

########################
Write-Host "OMS Updates..." -foreground Yellow 

Write-Host ("`nStep 8: OMS -- Update all services for Diagnostics Logging" ) -ForegroundColor Yellow

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

foreach($resourceType in $resourceTypes)
{
    Enable-AzureRMDiagnostics -ResourceGroupName $ResourceGroupName -SubscriptionId $subscriptionId -WSID $omsWS.ResourceId -Force -Update `
    -ResourceType $resourceType -ErrorAction SilentlyContinue
}

$workspace = Find-AzureRmResource -ResourceType "Microsoft.OperationalInsights/workspaces" -ResourceNameContains $omsWS.Name

########################
Write-Host ("`nStep 8.1: OMS -- Send Diagnostcis to OMS workspace" ) -ForegroundColor Yellow

foreach($resourceType in $resourceTypes)
{
    Write-Host ("Add-AzureDiagnosticsToLogAnalytics to " + $resourceType) -ForegroundColor Yellow
    $resource = Find-AzureRmResource -ResourceType $resourceType 
    Add-AzureDiagnosticsToLogAnalytics $resource $workspace -ErrorAction SilentlyContinue
}

####### End of Script ###########
