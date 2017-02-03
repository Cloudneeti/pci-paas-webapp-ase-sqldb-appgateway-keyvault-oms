$subscriptionName = 'Cloudly Dev Visual Studio'
$BlobName = "ContosoClinic.zip"
$PackageToUpload = "C:\PCIPublish\ContosoClinic.zip"
$SQLBackupToUpload = "C:\SQLBackup\pcidb.bacpac"
$location = 'East US'

#------------------------------
$resourceGroupName = 'pci-samples-releases'
$StorageAccountName = "stgpcipaasreleases"
$WebContainerName = "pci-paas-web-container"
$SQLContainerName = "pci-paas-sql-container"
$SQLBackupContainerName = "pci-paas-sql-backup-container"


# Check if there is already a login session in Azure Powershell, if not, sign in Azure  
Try  
{  
    Get-AzureRmContext -ErrorAction Continue  
}  
Catch [System.Management.Automation.PSInvalidOperationException]  
{  
    Login-AzureRmAccount  
} 

# Get Subscription Id
$subscriptionId = (Get-AzureRmSubscription -SubscriptionName $subscriptionName).SubscriptionId
Set-AzureRmContext -SubscriptionId $subscriptionId
#Create Pre Deployment Resource Group
New-AzureRmResourceGroup –Name $resourceGroupName –Location $location
 
 # Create a new storage account.
 New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -AccountName $StorageAccountName -Location $Location -Type "Standard_GRS"

 # Set a default storage account.
 Set-AzureRmCurrentStorageAccount -StorageAccountName $StorageAccountName -ResourceGroupName $resourceGroupName
 # Create a new Web container.
 New-AzureStorageContainer -Name $WebContainerName -Permission Container

  # Create a new SQL container.
 New-AzureStorageContainer -Name $SQLContainerName -Permission Container

  # Create a new SQL Backup container.
 New-AzureStorageContainer -Name $SQLBackupContainerName -Permission Container

 # Upload a blob into a web container.
 Set-AzureStorageBlobContent -Container $WebContainerName -File $PackageToUpload

 # Upload a blob into a sql container.
 Set-AzureStorageBlobContent -Container $SQLContainerName -File $SQLBackupToUpload



