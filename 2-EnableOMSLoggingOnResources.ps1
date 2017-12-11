<#
This script enables diagnostics logging on the resources and configure Log analytics to collect the logs.

Make sure you import AzureRM and AzureDiagnosticsAndLogAnalytics modules before executing this script.

USAGE:
    .\2-EnableOMSLoggingOnResources.ps1 -resourceGroupName demorg -globalAdminUserName globaladmin@azuredomain.com -globalAdminPassword *******
    -subscriptionID xxxxxxx-f760-xxxx-bd98-xxxxxxxx

#>

[CmdletBinding()]
param (
        # Provide resourceGroupName for deployment
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,64)]
        [ValidatePattern('^[\w]+$')]
        [string]
        $resourceGroupName,

        # Provide Azure AD UserName with Global Administrator permission on Azure AD and Service Administrator / Co-Admin permission on Subscription.
        [Parameter(Mandatory=$True)] 
        [string]$globalAdminUserName, 

        # Provide password for Azure AD UserName.
        [Parameter(Mandatory=$True)] 
        [string]$globalAdminPassword,

        # Provide Subscription ID that will be used for deployment
        [Parameter(Mandatory=$true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $subscriptionID

)

try {
    
    Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy UnRestricted -Force
    
    # Creating a Login credential.
    $secpasswd = ConvertTo-SecureString $globalAdminPassword -AsPlainText -Force
    $psCred = New-Object System.Management.Automation.PSCredential ($globalAdminUserName, $secpasswd)

    # Connecting to Azure Subscription
    Write-Host -ForegroundColor Yellow "`nConnecting to AzureRM Subscription - $subscriptionID."
    Login-AzureRmAccount -Credential $psCred -SubscriptionId $subscriptionID | Out-null
    if(Get-AzureRmContext){
        Write-Host -ForegroundColor Yellow "`t* Connection to AzureRM Subscription established successfully."
    }
            
    # Start OMS Diagnostics
    Write-Host ("`nGetting OMS Workspace details.." ) -ForegroundColor Yellow
    $omsWS = Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName

    Write-Host ("`nCollecting list of resourcetype to enable log analytics." ) -ForegroundColor Yellow
    $resourceTypes = @( "Microsoft.Network/applicationGateways",
                        "Microsoft.Network/NetworkSecurityGroups",
                        "Microsoft.Web/serverFarms",
                        "Microsoft.Sql/servers/databases",
                        "Microsoft.Compute/virtualMachines",
                        "Microsoft.Web/sites",
                        "Microsoft.KeyVault/Vaults" )

    Write-Host ("`nEnabling diagnostics for each resource type." ) -ForegroundColor Yellow
    foreach($resourceType in $resourceTypes)
    {
        Enable-AzureRMDiagnostics -ResourceGroupName $resourceGroupName -SubscriptionId $subscriptionId -WSID $omsWS.ResourceId -ResourceType $resourceType -Force -Update -EnableLogs -EnableMetrics 
    }

    $workspace = Find-AzureRmResource -ResourceType "Microsoft.OperationalInsights/workspaces" -ResourceNameContains $omsWS.Name -ResourceGroupNameEquals $resourceGroupName
    Write-Host ("`nConfigure Log Analytics to collect Azure diagnostic logs" ) -ForegroundColor Yellow
    foreach($resourceType in $resourceTypes)
    {
        Write-Host ("`n`t-> Adding Azure Diagnostics to Log Analytics for -" + $resourceType) -ForegroundColor Yellow
        $resource = Find-AzureRmResource -ResourceType $resourceType -ResourceGroupNameEquals $resourceGroupName
        Add-AzureDiagnosticsToLogAnalytics $resource $workspace
    }
    # End OMS Diagnostics    
}
catch {
    throw $_
}

