$SubscriptionId = 'fb828b18-79dd-400c-919a-a393d88835e5' #<your sub id> # Provide your Azure subscription ID
$ResourceGroupName = 'Contosoclinic' #'001-azurepcisamples-avyan' # Provide Resource Group Name Created through ARM template
$ClientIPAddress = '131.107.160.167' #<your client IP address>  # Eg: 168.62.48.129 Provide Client IP address (get by running ipconfig in cmd prompt)
$ASEOutboundAddress = '13.92.27.211' # <virtual outbound IP address of the ASE> # Provide ASE Outbound address we will get it in ASE properties in Azure portal
$SQLServerName = 'sqlserver-fbikvpe4mjhgu' #<your sql server name> # Provide Sql Server name (not required full name) Created through ARM template
$SQLServerAdministratorLoginUserName = 'sqladmin'  # Provide admin user name of sql server used for ARM template parameter "sqlAdministratorLoginUserName" 
$SQLServerAdministratorLoginPassword = 'h6^UPWPLE$' #<your sqlserver admin password> # Provide admin password of sql server used for ARM template parameter "sqlAdministratorLoginPassword" 
$KeyVaultName = 'kv-pcisamples-fbikvpe4' #<your keyvault name> # Provide Key Vault Name Created through ARM template
$AzureAdApplicationClientId = '2fef9133-5184-44bd-ac21-4d0f942c3cae' #<your app id> # AD Application ClientID - the same one you used in the ARM template
$AzureAdApplicationClientSecret = "Password@123" #<your password> # AD Application ClientID - the same one you used in the ARM template
$SqlAdAdminUserName = 'sqladmin@pcidemoxoutlook560.onmicrosoft.com' #<your sqladadmin user principal name> # Provide SQL AD Administrator Name same we used for ARM Deployment for parameter sqlAdAdminUserName
$SqlAdAdminUserPassword = 'h6^UPWPLE$' #<your password> # Provide SQL AD Administrator Name same we used for ARM Deployment for parameter sqlAdAdminUserPassword, available for consistency purposes only.



$DatabaseName = "ContosoClinicDB"
$StorageName = "stgreleases"+$SQLServerName.Substring(10,5).ToLower()
$StorageKeyType = "StorageAccessKey"
$SQLContainerName = "pci-paas-sql-container"
$SQLBackupName = "clinic.bacpac"
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
    New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageName -Location $Location -Type "Standard_GRS"
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
Try { New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIpRule" -StartIpAddress $ClientIPAddress -EndIpAddress $ClientIPAddress -ErrorAction Continue} Catch {}
Try { New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "AseOutboundRule" -StartIpAddress $ASEOutboundAddress -EndIpAddress $ASEOutboundAddress -ErrorAction Continue} Catch {}
Try { New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIp" -StartIpAddress $clientIp -EndIpAddress $clientIp -ErrorAction Continue} Catch {}

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
    New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Patients" -ColumnName "FirstName" -MaskingFunction Default
    New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Patients" -ColumnName "LastName" -MaskingFunction Default
    New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -SchemaName "dbo" -TableName "Patients" -ColumnName "SSN" -MaskingFunction SocialSecurityNumber 
# End Dynamic Data Masking



Write-Host ("`tStep 6: Update SQL Server for Azure Active Directory administrator =" + $SqlAdAdminUserName ) -ForegroundColor Gray

# Create an Azure Active Directory administrator for SQL
Set-AzureRmSqlServerActiveDirectoryAdministrator -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DisplayName $SqlAdAdminUserName
            
########################
Write-Host ("`tStep 7: Encrypt SQL DB columns SSN, Birthdate and Credit card Information" ) -ForegroundColor Gray

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
    $ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Patients.CreditCard_Number" -EncryptionType "Deterministic" -EncryptionKey $cekName
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





