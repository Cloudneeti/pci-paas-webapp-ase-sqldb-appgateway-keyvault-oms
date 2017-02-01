$subscriptionName =     "Avyan MPN Subscription"          # name of the Azure subscription

$servicePrincipalPath=  (".\" + $subscriptionName + ".json" )

$resourceGroupName = 'guru-OMS-Tests'
$automationAccountName = 'automation-OMS'

### 1. Login to Azure Resource Manager and save the profile locally to avoid relogins (used primarily for debugging purposes)
#############################################################################################
Write-Host ("Step 1: Logging in to Azure Subscription"+ $subscriptionName) -ForegroundColor Gray

# To login to Azure Resource Manager
if(![System.IO.File]::Exists($servicePrincipalPath)){
    # file with path $path doesn't exist

    #Add-AzureRmAccount 
    Login-AzureRmAccount -SubscriptionName $subscriptionName
    
    Save-AzureRmProfile -Path $servicePrincipalPath
}

Select-AzureRmProfile -Path $servicePrincipalPath




# To select a default subscription for your current session
#Get-AzureRmSubscription –SubscriptionName “Cloudly Dev (Visual Studio Ultimate)” | Select-AzureRmSubscription

$sub = Get-AzureRmSubscription –SubscriptionName $subscriptionName | Select-AzureRmSubscription 


###1. Create New Resource Group
############################################################################################
New-AzureRmResourceGroup -Name $resourceGroupName -Location "West US"


### 2. Create Azure Automation Account
#############################################################################################

New-AzureRmAutomationAccount -ResourceGroupName $resourceGroupName -Location eastus2 -Name $automationAccountName -Plan Free

