################################################################################
##  Solution Name - Deploy-PCI-PaaS-Solution.ps1     
##  Version - 1.0.0
################################################################################

##FIND ##$$BUG$$ 


<#
This powershell script is desgined to call and deploy various scripts & templates
that are used to deploy a PCI-Compliant-PaaS-Solution reference architecture
and enable simple deployment.
.DESCRIPTION
This script helps you deploy entire Azure Blueprint - Payment processing solution
for PCI DSS enablement by executing this single deployment script.You need download 
Deploy-PCI-PaaS-Solution.ps1 to a folder and then follow example to execute the script.

.EXAMPLE Deploy with a customer SSL certificate

& ".\Deploy-PCI-PaaS-Solution.ps1" -resourceGroupName deploy6 
-location eastus -globalAdminUserName user@email.com -globalAdminPassword [PASSWORD]
 -automationAccLocation eastus2 -subscriptionID 8e082b0c-f760-4a7e-bd98-000000000000 -suffix 
 azurepcisamples -customDomain azurepcisample.com -enableSSL $true -sqlTDAlertEmailAddress "user@email.com"
 
.EXAMPLE Deploy with self signed certificate

& ".\Deployment\Deploy-PCI-PaaS-Solution.ps1" -resourceGroupName deploy6 
-location eastus -globalAdminUserName user@email.com -globalAdminPassword [PASSWORD] 
-automationAccLocation eastus2 -subscriptionID 8e082b0c-f760-4a7e-bd98-000000000000 -suffix azurepcisamples 
-customDomain azurepcisample.com -enableSSL $true -certificatePath **Your Certificate path** 
-certificatePassword **Your certificate password** -sqlTDAlertEmailAddress "user@email.com"


#>

[CmdletBinding()]
param
(
	# <Provide ResourceGroupName for deployment>
    [string] [Parameter(Mandatory=$true)] 
	$resourceGroupName,
	# <Provide Location for deployment>
    [string] [Parameter(Mandatory=$true)] 
	$location,
	# <Provide your Azure AD Global Admin UserName>
	[string] [Parameter(Mandatory=$true)] 
	$globalAdminUserName,
	# <Provide your Azure AD Global Admin Password>
	[string] [Parameter(Mandatory=$true)] 
    $globalAdminPassword,
    # <Provide Supported Location/Region for Automation Account >
    [string] [Parameter(Mandatory=$true)] 
	$automationAccLocation,
	# <Provide your Azure subscription ID>
    [string] [Parameter(Mandatory=$true)] 
	$subscriptionID,
	# <This is used to create a unique website name in your organization. This could be your company name or business unit name>
    [string] [Parameter(Mandatory=$true)] 
	$suffix,
	# <Provide CustomDomain which will be used for creating ASE subdomain.>
##$$BUG$$ ###############FIX NEEDED########################## First check if FALSE, --- we cannot use a .com or anything that may have a REAL DNS address.
    [string] [Parameter(Mandatory=$true)] ##$$BUG$$ ###########################LOGIC NEEDS TO ADDRESS THAT IF FALSE WE USE THE BUILD IN DOMAIN
	$customDomain,
	# <Enter boolean value to enable or disable SSL on application gateway.>
    [bool]
	$enableSSL = $false,
	# <Provide Certificate path to use your own certificate on application gateway.>
    [string]
	$certificatePath,
	# <Enter password for the certificate provided.>
    [string]
	$certificatePassword,    
	# <Provide Email address for SQL Threat Detection Alerts.>
    [string]
    $sqlTDAlertEmailAddress = "internet@mail.com" ##$$BUG$$ ###################### again a real DNS name CANNOT BE USED - unless the user fills it in.

)

Begin
{
    
    $ErrorActionPreference = 'Stop'
	Set-ExecutionPolicy RemoteSigned; ##$$BUG$$ ################################# NO WE CANNOT DO THIS Installing as part of the solution. We need to leave this as it's own deployment effort
    cd $PSScriptRoot    

    ### Manage directories
    Write "`nCreating directory structure for scripts & certificates.."
	mkdir $pwd\Scripts -Force
	mkdir $pwd\Scripts\Certificates -Force
    mkdir $pwd\Output -Force

	### Loading Functions

    Write "`nLoading functions.." ##$$BUG$$  ########################### -----------REMOVE WE DO NOT WANT TO CONTROL THE USERS COMPUTER IN THIS SCRIPT
	function Download-FromGithub ($url, $filename)
	{
		$webclient = New-Object System.Net.WebClient
		$filepath = "$pwd\Scripts\$filename"
		$webclient.DownloadFile($url,$filepath)
	}

	function New-RandomPassword () ##$$BUG$$ ###########FUNCTION COMMENT provide details what is happening
	{
		(-join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})) + ` ##$$BUG$$ ################## no 11 to 15 it has to be 15 all times - eg you need min here (Get-Random -Minimum 10 -Maximum 99)
        ((10..99) | Get-Random -Count 1) + `
        ('@','%','!','^' | Get-Random -Count 1) +`
        (-join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})) + `
        ((10..99) | Get-Random -Count 1)
	}

	function Convert-Certificate ($certPath) ##$$BUG$$ ###########FUNCTION COMMENT provide details what is happening
	{
        $fileContentBytes = get-content "$certPath" -Encoding Byte
        [System.Convert]::ToBase64String($fileContentBytes)
	}

    ###  Login to Azure 

    Write-Host "`nLogging into Azure Powershell.."
    $secpasswd = ConvertTo-SecureString $GlobalAdminPassword -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($GlobalAdminUserName, $secpasswd)
    Connect-MsolService -Credential $mycreds
    $Login = Login-AzureRmAccount -SubscriptionId $SubscriptionID -Credential $mycreds
    Save-AzureRmContext -Path $PWD\Scripts\auth.json -Force   ##$$BUG$$ ######################################### This file needs to be deleted when the scripts are done
    Try  
    {  
        Get-AzureRmContext
    }  
    Catch [System.Management.Automation.PSInvalidOperationException]  
    {  
        Login-AzureRmAccount  -SubscriptionId $subscriptionId
    } 

	### Manage Variables

	Write "`nLoading variables.."
    $Global:AzureADDomainName = $Login.Context.Tenant.Directory
    $tenantID = (Get-AzureRmContext).Tenant.TenantId
    if ($tenantID -eq $null){$tenantID = (Get-AzureRmContext).Tenant.Id}        
	$automationaccname = "automationacc" + (Get-Random -Maximum 999) ##$$BUG$$ why 0 to 999? Maybe put a min of 10? or use this less chance of collision ((Get-Date).ToUniversalTime()).ToString('MMdd-HH')
	$AutomationADApplication = "AutomationAppl" + (Get-Random -Maximum 9999)  ##$$BUG$$ why 0 to 9999? Maybe put a min of 10? or use this less chance of collision ((Get-Date).ToUniversalTime()).ToString('MMdd-HH')
	$TemplateUri = "https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master/azuredeploy.json"  ##$$BUG$$ Must make this a variable in top of script https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master
	$DeploymentName = "PCI-Deploy-"+ ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')
    $_artifactsLocation = "https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master" ##$$BUG$$ Must make this a variable in top of script https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master
    $_artifactsLocationSasToken = "null"
    $commonPassword = New-RandomPassword
}
Process
{
    Write-Output "`nDownloading Scripts from GitHub..." ##$$BUG$$ Must make all references to a variable in top of script https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master
    try {
        Download-FromGithub -url https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master/pre-post-deployment/Install-azure-powershell-modules.ps1 -filename Install-azure-powershell-modules.ps1
        Download-FromGithub -url https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master/pre-post-deployment/PreDeployment.ps1 -filename PreDeployment.ps1
        Download-FromGithub -url https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master/pre-post-deployment/New-RunAsAccount.ps1 -filename New-RunAsAccount.ps1
        Download-FromGithub -url https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master/pre-post-deployment/PostDeployment.ps1 -filename PostDeployment.ps1
        Download-FromGithub -url https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master/pre-post-deployment/New-Deployment.ps1 -filename New-Deployment.ps1
        Download-FromGithub -url https://raw.githubusercontent.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/master/pre-post-deployment/PostDeploymentSQL.sql -filename PostDeploymentSQL.sql
    }
    catch {
        "Unable to download scripts from Public GitHub. Please make sure you are connected to internet and able to access https://github.com/."
        Break
    }

	### Installing powershell modules

    Write "`nLoading powershell modules.."

    .\Scripts\Install-azure-powershell-modules.ps1 ##$$BUG$$ Remove --- not good practice to make the user do this to his computer. This just needs the script to catch and fail

    Start-Sleep -Seconds 10

	Write-Output "`nExecuting pre-deployment script.."
    if($enableSSL){
        $sslORnon_ssl = "ssl"
	    if($CertificatePath) {
            .\Scripts\PreDeployment.ps1 -azureADDomainName $AzureADDomainName -subscriptionID $subscriptionID -suffix $suffix -sqlADAdminPassword $commonPassword -AzureADApplicationClientSecret $commonPassword -customHostName $CustomDomain -enableSSL $true -certificatePath $CertificatePath -certificatePassword $certificatePassword
	    }
	    Else{
            Write-Output ""
            .\Scripts\PreDeployment.ps1 -azureADDomainName $AzureADDomainName -subscriptionID $subscriptionID -suffix $suffix -sqlADAdminPassword $commonPassword -AzureADApplicationClientSecret $commonPassword -customHostName $CustomDomain -enableSSL $true 
	    }
    }
    Else{
        $sslORnon_ssl = "non-ssl"
        .\Scripts\PreDeployment.ps1 -azureADDomainName $AzureADDomainName -subscriptionID $subscriptionID -suffix $suffix -sqlADAdminPassword $commonPassword -AzureADApplicationClientSecret $commonPassword -customHostName $CustomDomain
    }
    
    $sqlAdAdminUsername = $Global:SQLADAdminName

    Start-Sleep -Seconds 10

	Write-Output "`nCreating a New Resource Group - $ResourceGroupName at $Location"
	New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -Force -ErrorAction Stop ##$$BUG$$ can location fail if it's not avalible? are we doing a check?

	Write-Output "`nCreating a New Automation Account - $automationaccname at $AutomationAccLocation"
	New-AzureRmAutomationAccount -Name "$automationaccname" -Location "$AutomationAccLocation" -ResourceGroupName "$ResourceGroupName"

	Write-Output "`nCreating RunAs account for runbooks to execute."  ##$$BUG$$ Remove --- too many security violations.. This just needs the script to catch and fail
	.\Scripts\New-RunAsAccount.ps1 -ResourceGroup $ResourceGroupName -AutomationAccountName $automationaccname -SubscriptionId $subscriptionID -ApplicationDisplayName $AutomationADApplication -SelfSignedCertPlainPassword $commonPassword -CreateClassicRunAsAccount $false

    $azureAdApplicationClientId = $Global:azureAdApplication.ApplicationId.Guid
    $azureAdApplicationObjectId = $Global:azureAdApplication.ObjectId.Guid
    Write "`nInitiating deployment..."
    try {
        Start-Process Powershell -ArgumentList "-NoExit", ".\Scripts\New-Deployment.ps1 -DeploymentName $DeploymentName -ResourceGroupName $ResourceGroupName -Location $Location -TemplateUri $TemplateUri -_artifactsLocation $_artifactsLocation -_artifactsLocationSasToken $_artifactsLocationSasToken -sslORnon_ssl $sslORnon_ssl -certData $Global:certData -certPassword $Global:certPassword -aseCertData $Global:aseCertData -asePfxBlobString $Global:asePfxBlobString -asePfxPassword $Global:asePfxPassword -aseCertThumbprint $Global:aseCertThumbprint -bastionHostAdministratorPassword $commonPassword -sqlAdministratorLoginPassword $commonPassword -sqlThreatDetectionAlertEmailAddress $SqlTDAlertEmailAddress -automationAccountName $automationaccname -customHostName $CustomDomain -azureAdApplicationClientId $azureAdApplicationClientId -azureAdApplicationClientSecret $commonPassword -azureAdApplicationObjectId $azureAdApplicationObjectId -sqlAdAdminUserName $Global:SQLADAdminName -sqlAdAdminUserPassword $commonPassword"
    }
    catch {
        "Failed to execute powershell."
        Break
    }
    
    do
    {
        Write-Host "Waiting for deployment deploy-SQLServerSQLDb to submit.. " -ForegroundColor Yellow
        Write-Host "Checking deployment in 60 secs.." -ForegroundColor Yellow
        Start-sleep -seconds 60
    }
    until ((Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name 'deploy-SQLServerSQLDb' -ErrorAction SilentlyContinue) -ne $null) 
    do
      {
            Write-Output " Deployment 'deploy-SQLServerSQLDb' is currently running.. Checking Deployment in 60 seconds.."
            Start-Sleep -Seconds 60
      }
    While ((Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name 'deploy-SQLServerSQLDb').ProvisioningState -notin ('Failed','Succeeded'))

    $DeploymentStatus = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name deploy-SQLServerSQLDb).ProvisioningState

        
    if ($DeploymentStatus -eq 'Succeeded')
      {
            Write-Output "`nDeployment deploy-SQLServerSQLDb has completed successfully. Executing Post Deployment Script.."

            $ClientIPAddress = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip
            $AllResource = (Get-AzureRmResource | ? ResourceGroupName -EQ $ResourceGroupName)
            $SqlServer=  ($AllResource | ? ResourceType -eq 'Microsoft.Sql/servers').ResourceName
            $KeyVault = ($AllResource | ? ResourceType -eq 'Microsoft.KeyVault/vaults').ResourceName
            .\Scripts\PostDeployment.ps1 -SubscriptionId $SubscriptionID -ResourceGroupName $ResourceGroupName -ClientIPAddress $ClientIPAddress -SQLServerName $SqlServer -SQLServerAdministratorLoginUserName 'sqladmin' -SQLServerAdministratorLoginPassword $commonPassword -KeyVaultName $KeyVault -AzureAdApplicationClientId $azureAdApplicationClientId -AzureAdApplicationClientSecret $commonPassword -SqlAdAdminUserName $Global:SQLADAdminName -SqlAdAdminUserPassword $commonPassword
      }
    else
      {
            Write-Error "Deployment deploy-SQLServerSQLDb has failed. Post-Deployment script has failed to execute."
      }
#>  
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
