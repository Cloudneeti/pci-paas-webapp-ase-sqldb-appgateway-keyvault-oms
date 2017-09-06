<#
    .DESCRIPTION
        Runbook to restart webapp using the Run As Account (Service Principal)
    .NOTES
        NA
#>

# Suspend the runbook if any errors, not just exceptions, are encountered
$ErrorActionPreference = "Stop"

# Get ResourceGroupName
$ResourceGroupName = Get-AutomationVariable -Name 'metricresourceGroupName'

$connectionName = "AzureRunAsConnection"

try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

Restart-AzureRmWebapp -Name webapp-pciwebapp -ResourceGroupName $ResourceGroupName
