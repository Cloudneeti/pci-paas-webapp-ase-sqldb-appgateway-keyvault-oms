<#
.Synopsis
    Clean-up resources deployed within subscription during deployment.
.DESCRIPTION
    This script removes all the resources that were deployed by the solution. This script will also remove Azure AD user accounts that were created during the
        deployment.
    Important: This script needs to be run by Global AD Administrator (aka Company Administrator)
.EXAMPLE 1
    # Deletes Users, ResourceGroup & Azure AD Application created during the deployment.
    .\Clean-Deployment.ps1 -azureADDomainName domain@contoso.com -subscriptionID xxxx-xxxx-xxx-xxxx -resourceGroupName demorg -globalAdminUserName  `
        admin@contoso.com -globalAdminPassword ********* -azureADApplicationID xxxx-xxxx-xxxx-xxxx
.EXAMPLE 2
    # Deletes Users from Azure AD created during the deployment.
    .\Clean-Deployment.ps1 -azureADDomainName domain@contoso.com -subscriptionID xxxx-xxxx-xxx-xxxx -globalAdminUserName admin@contoso.com`
        -globalAdminPassword *********
.EXAMPLE 3
    # Deletes Users from Azure AD & ResourceGroup created during the deployment.
    .\Clean-Deployment.ps1 -azureADDomainName domain@contoso.com -subscriptionID xxxx-xxxx-xxx-xxxx -resourceGroupName demorg -globalAdminUserName `
        admin@contoso.com -globalAdminPassword *********    
#>
param (
    # Provide Azure AD Domain name for the subscription
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $azureADDomainName,

    # Provide Subscription ID used to deploy the solution
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $subscriptionID,

    # Provide ResourceGroup Name
    [String]
    $resourceGroupName,

    # Provide your Azure AD Global Admin UserName
	[Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]
	$globalAdminUserName,

	# Provide your Azure AD Global Admin Password
	[Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [SecureString]
    $globalAdminPassword,

	# Provide Azure AD Application ID
    [String]
    $azureADApplicationID    

)
Begin
{
    # constructing variables
    $sqlADAdminName = "sqladmin@"+$azureADDomainName
    $receptionistUserName = "receptionist_EdnaB@"+$azureADDomainName
}
Process {
    Write-Host "`nPre-Requisite: This script needs to be run by Global AD Administrator (aka Company Administrator)" -ForegroundColor Yellow

    # Login to Azure AD & Subscription
    $psCred = New-Object System.Management.Automation.PSCredential ($globalAdminUserName, $globalAdminPassword)
  
    Write-Host -ForegroundColor Yellow "`nConnecting Powershell to Azure AD & Subscription ID - $subscriptionID.." 
    try {
        Connect-AzureAD -Credential $psCred
        Write-Host -ForegroundColor Yellow "`nSuccessfully connected to AzureAD."
    }
    catch {
        Write-Host -ForegroundColor Red "`nFailed to connect Azure AD. $_.Exception.GetBaseException()"
        Break;
    }
    try {
        Login-AzureRmAccount -SubscriptionId $subscriptionID -Credential $psCred
        Write-Host -ForegroundColor Yellow "`nSuccessfully connected to Azure Subscription."
    }
    catch {
        Write-Host -ForegroundColor Red "`nFailed to login to Azure subscription.`n$_.Exception.GetBaseException()"
        Break;
    }

    # Removing users from AD, if exist.
    Write-Host ("`nStep 1:Remove AD Users" ) -ForegroundColor Yellow
    
    $sqlADAdminObjectId = (Get-MsolUser -UserPrincipalName $SQLADAdminName -ErrorAction SilentlyContinue).ObjectID
    if ($sqlADAdminObjectId -ne $null)  
    {    
        Remove-MsolUser -UserPrincipalName $SQLADAdminName -Force
    }
    $receptionistUserObjectId = (Get-MsolUser -UserPrincipalName $receptionistUserName -ErrorAction SilentlyContinue).ObjectID
    if ($receptionistUserObjectId -ne $null)  
    {    
        Remove-MsolUser -UserPrincipalName $receptionistUserName -Force
    }
    Write-Host "`nRemoved users successfully." -ForegroundColor Yellow

    # Removing Azure Resource Group
    if ($resourceGroupName){
        Write-Host ("`nStep 2:Remove Azure Resource Group" ) -ForegroundColor Yellow
        try {
            Remove-AzureRmResourceGroup -Name $resourceGroupName -Force
            Write-Host -ForegroundColor Yellow "$resourceGroupName has been deleted."
        }
        catch [System.Exception] {
            Write-Host -ForegroundColor Red $_.Exception.GetBaseException()
        }
    }

    # Removing Azure AD Application, if exist
    if ($azureADApplicationID) {
        Write-Host ("`nStep 3:Remove Azure Application Id" ) -ForegroundColor Yellow
        try {
            $ADObjectId = (Get-AzureADApplication).AppId -eq $ADApplicationId
            if ($ADObjectId -ne $null)  
            {
                Remove-AzureADApplication -ObjectId $ADObjectId
                Write-Host -ForegroundColor Yellow "Application with ID - $azureADApplicationID has been deleted."
            }
            else {
                Write-Host -ForegroundColor Red "Application with ID - $azureADApplicationID could not be found."
            }
        }
        catch {
            Write-Host -ForegroundColor Red $_.Exception.GetBaseException()
        }        
    }
}