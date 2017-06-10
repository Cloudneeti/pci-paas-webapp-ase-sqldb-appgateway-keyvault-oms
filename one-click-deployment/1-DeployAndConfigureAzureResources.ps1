<#
.Synopsis
   Deploys and Configures Azure resources as a part of pre-deployment activity before deploying PCI-PaaS solution ARM templates.
.DESCRIPTION
    This script is used to create additional AD users to run various scenarios and creates AD Application and creates service principle to AD Application.This script 
        should run by Global AD Administrator you created Global AD Admin in previous script(0-Setup-AdministrativeAccountAndPermission.ps1).
    It also generate self signed certificate SSL for Internal App Service Environment and Application gateway (if required).If you already have your own valid SSL
        certificate, you can provide it as an input parameters so it can be converted into base64 string for the purpose of template deployment.
    
    
    
    Important Note: This script should run before you start deployment of PCI-PaaS solution ARM templates. 


.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
[CmdletBinding()]
Param
    (
        # Provide Azure AD Domain Name.
        [Parameter(Mandatory=$true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $azureADDomainName,

        # Provide Subscription ID that will be used for deployment
        [Parameter(Mandatory=$true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $subscriptionID,

        # This is used to create a unique website name in your organization. This could be your company name or business unit name
        [Parameter(Mandatory=$true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $suffix,

        # Param2 help description
        [Parameter(Mandatory=$true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $Param2,

        # Param2 help description
        [Parameter(Mandatory=$true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $Param2,
        
        # Param2 help description
        [Parameter(Mandatory=$true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $Param2          
    )

Begin
    {
    }
Process
    {
    }
End
    {
        Write-Host -ForegroundColor DarkGray "`n`tKindly save the below information for future reference purpose:"
        $outputTable = New-Object -TypeName Hashtable
        $outputTable.Add('resourceGroupName',$resourceGroupName)
        $outputTable.Add('deploymentName',$DeploymentName)
        $outputTable.Add('deploymentLocation',$location)
        $outputTable.Add('deploymentType',$sslORnon_ssl)
        $outputTable.Add('globalAdminUsername',$globalAdminUserName)
        $outputTable.Add('globalAdminPassword',$globalAdminPassword)
        $outputTable.Add('customDomain',$customDomain)
        $outputTable.Add('Email address for SQL Threat Detection Alerts',$sqlTDAlertEmailAddress)
        $outputTable.Add('automationAccountName',$automationaccname)
        $outputTable.Add('azureADApplicationId',$azureAdApplicationClientId)
        $outputTable.Add('azureADApplicationSecret',$commonPassword)
        $outputTable.Add('applicationGatewaySslCert',$certData)
        $outputTable.Add('applicationGatewaySslPassword',$certPassword)
        $outputTable.Add('applicationGatewayBackendCertData',$aseCertData)
        $outputTable.Add('aseIlbCertData',$asePfxBlobString)
        $outputTable.Add('aseIlbCertPassword',$asePfxPassword)
        $outputTable.Add('aseCertThumbprint',$Global:aseCertThumbprint)
        $outputTable.Add('bastionVMAdmin','bastionadmin')
        $outputTable.Add('bastionVMAdminPassword',$commonPassword)
        $outputTable.Add('sqlServerName',$SqlServer)
        $outputTable.Add('sqlADAdminUsername',$sqlAdAdminUsername)
        $outputTable.Add('sqlADAdminPassword',$commonPassword)
        $outputTable.Add('sqlAdminUsername','sqladmin')
        $outputTable.Add('salAdminPassword',$commonPassword)
        $outputTable.Add('keyvaultName',$KeyVault)
        $outputTable | Sort-Object Name | Format-Table -AutoSize -Wrap -Expand EnumOnly 
    }
