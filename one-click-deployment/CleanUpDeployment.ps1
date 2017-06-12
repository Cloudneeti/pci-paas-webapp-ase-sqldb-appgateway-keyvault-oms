# Purpose : 
# 1) This script is used to clean up a deployment 
# 2) This script must be run by Global AD Administrator


Param(
	[string] [Parameter(Mandatory=$true)] $azureADDomainName, # Provide your Azure AD Domain Name
	[string] [Parameter(Mandatory=$true)] $subscriptionID, # Provide your Azure subscription ID
	[string] [Parameter(Mandatory=$true)] $resourceGroupName # Provide your Azure subscription ID
)


Write-Host ("Pre-Requisite: This script needs to be run by Global AD Administrator (aka Company Administrator)" ) -ForegroundColor Yellow
#Connect to the Azure 
Try  
{  
    Get-AzureRmContext  -ErrorAction Continue  
}  
Catch [System.Management.Automation.PSInvalidOperationException]  
{  
    Login-AzureRmAccount  -SubscriptionId $subscriptionId
} 
#Connect to AD domain user
Connect-MsolService


$ADApplicationId ='' # Provide Application ClientID if it's created or else don't provide
$SQLADAdminName = "sqladmin@"+$azureADDomainName
$receptionistUserName = "receptionist_EdnaB@"+$azureADDomainName

Write-Host ("Step 1:Remove AD Users" ) -ForegroundColor Yellow
$sqlADAdminObjectId = (Get-MsolUser -UserPrincipalName $SQLADAdminName -ErrorAction SilentlyContinue -ErrorVariable errorVariable).ObjectID
if ($sqlADAdminObjectId -ne $null)  
{    
    Remove-MsolUser -UserPrincipalName $SQLADAdminName
}
$receptionistUserObjectId = (Get-MsolUser -UserPrincipalName $receptionistUserName -ErrorAction SilentlyContinue -ErrorVariable errorVariable).ObjectID
if ($receptionistUserObjectId -ne $null)  
{    
    Remove-MsolUser -UserPrincipalName $receptionistUserName -Force
}
$doctorUserObjectId = (Get-MsolUser -UserPrincipalName $doctorUserName -ErrorAction SilentlyContinue -ErrorVariable errorVariable).ObjectID
if ($doctorUserObjectId -ne $null)  
{    
    Remove-MsolUser -UserPrincipalName $doctorUserName -Force
}
Write-Host -Prompt "Removed users successfully." -ForegroundColor Yellow

Write-Host ("Step 2:Remove Azure Resource Group" ) -ForegroundColor Yellow

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

Remove-AzureRmResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue

Write-Host ("Step 3:Remove Azure Application Id" ) -ForegroundColor Yellow
$ADObjectId = (Get-AzureADApplication).AppId -eq $ADApplicationId
if ($ADObjectId -ne $null)  
{
	Remove-AzureADApplication -ObjectId $ADObjectId
}

Read-Host -Prompt "The script completed. Press any key to exit"