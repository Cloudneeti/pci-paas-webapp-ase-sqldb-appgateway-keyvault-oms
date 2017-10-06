<#
.Synopsis
   This Powershell script takes input from parent script - Deploy-PCI-PaaS-Solution.ps1
   and initiate template deployment for PCI-PaaS Reference Architecture.
.DESCRIPTION
   NA
.EXAMPLE
   NA
#>
    param
    (
    # Provide Azure AD UserName with Global Administrator permission on Azure AD and Service Administrator / Co-Admin permission on Subscription.
    [Parameter(Mandatory=$True)] 
    [string]$subscriptionID,

    # Provide Azure AD UserName with Global Administrator permission on Azure AD and Service Administrator / Co-Admin permission on Subscription.
    [Parameter(Mandatory=$True)] 
    [string]$globalAdminUserName, 

    # Provide password for Azure AD UserName.
    [Parameter(Mandatory=$True)]
    [string]$globalAdminPassword,

    [string] [Parameter(Mandatory=$true)] 
	$deploymentName,

    [string] [Parameter(Mandatory=$true)] 	
    $resourceGroupName,

    [string] [Parameter(Mandatory=$true)] 
	$location,

    [string] [Parameter(Mandatory=$true)] 
	$templateFile,

    [string] [Parameter(Mandatory=$true)] 
	$_artifactsLocation,

    [string] [Parameter(Mandatory=$true)] 
	$_artifactsLocationSasToken,

    [string] [Parameter(Mandatory=$true)] 
	$sslORnon_ssl,

    [string] [Parameter(Mandatory=$true)] 
	$certData,

    [string] [Parameter(Mandatory=$true)] 
	$certPassword,

    [string] [Parameter(Mandatory=$true)] 
	$aseCertData,

    [string] [Parameter(Mandatory=$true)] 
	$asePfxBlobString,

    [string] [Parameter(Mandatory=$true)] 
	$asePfxPassword,

    [string] [Parameter(Mandatory=$true)] 
	$aseCertThumbprint,

    [string] [Parameter(Mandatory=$true)] 
	$bastionHostAdministratorPassword,

    [string] [Parameter(Mandatory=$true)] 
	$sqlAdministratorLoginPassword,

    [string] [Parameter(Mandatory=$true)] 
	$sqlThreatDetectionAlertEmailAddress,

    [string] [Parameter(Mandatory=$true)] 
	$automationAccountName,

    [string] [Parameter(Mandatory=$true)] 
	$customHostName,

    [string] [Parameter(Mandatory=$true)] 
	$azureAdApplicationClientId,

    [string] [Parameter(Mandatory=$true)] 
	$azureAdApplicationClientSecret,

    [string] [Parameter(Mandatory=$true)] 
	$azureAdApplicationObjectId,

    [string] [Parameter(Mandatory=$true)] 
	$sqlAdAdminUserName,

    [string] [Parameter(Mandatory=$true)] 
	$sqlAdAdminUserPassword
    )

    Begin
    {
        Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy UnRestricted -Force
        $ErrorActionPreference = 'Stop'
        cd $PSScriptRoot


        # Creating a Login credential.
        $secpasswd = ConvertTo-SecureString $globalAdminPassword -AsPlainText -Force
        $psCred = New-Object System.Management.Automation.PSCredential ($globalAdminUserName, $secpasswd)
        
        ########### Establishing connection to Azure ###########
        try {
            Write-Host -ForegroundColor Green "`nStep 1: Establishing connection to Azure AD & Subscription"

            # Connecting to MSOL Service
            Write-Host -ForegroundColor Yellow  "`t* Connecting to Msol service."
            Connect-MsolService -Credential $psCred | Out-null
            if(Get-MsolDomain){
                Write-Host -ForegroundColor Yellow "`t* Connection to Msol Service established successfully."
            }
            
            # Connecting to Azure Subscription
            Write-Host -ForegroundColor Yellow "`t* Connecting to AzureRM Subscription - $subscriptionID."
            Login-AzureRmAccount -Credential $psCred -SubscriptionId $subscriptionID | Out-null
            if(Get-AzureRmContext){
                Write-Host -ForegroundColor Yellow "`t* Connection to AzureRM Subscription established successfully."
            }
        }
        catch {
            Throw $_
        }
        Try  
        {  
            Get-AzureRmContext  -ErrorAction Continue  
        }  
        Catch [System.Management.Automation.PSInvalidOperationException]  
        {  
            Login-AzureRmAccount  -SubscriptionId $subscriptionId
        }
        $OptionalParameters = New-Object -TypeName Hashtable
        $OptionalParameters["_artifactsLocation"] = "$_artifactsLocation"
        $OptionalParameters["_artifactsLocationSasToken"] = ""
        $OptionalParameters["sslORnon_ssl"] = "$sslORnon_ssl"  
        $OptionalParameters["certData"] = "$certData" 
        $OptionalParameters["certPassword"] = "$certPassword" 
        $OptionalParameters["aseCertData"] = "$aseCertData"
        $OptionalParameters["asePfxBlobString"] = "$asePfxBlobString"
        $OptionalParameters["asePfxPassword"] = "$asePfxPassword" 
        $OptionalParameters["aseCertThumbprint"] = "$aseCertThumbprint" 
        $OptionalParameters["bastionHostAdministratorPassword"] = "$bastionHostAdministratorPassword" 
        $OptionalParameters["sqlAdministratorLoginPassword"] = "$sqlAdministratorLoginPassword" 
        $OptionalParameters["sqlThreatDetectionAlertEmailAddress"] = "$sqlThreatDetectionAlertEmailAddress"
        $OptionalParameters["automationAccountName"] = "$automationAccountName"
        $OptionalParameters["customHostName"] = "$customHostName"
        $OptionalParameters["azureAdApplicationClientId"] = "$azureAdApplicationClientId"
        $OptionalParameters["azureAdApplicationClientSecret"] = "$azureAdApplicationClientSecret"
        $OptionalParameters["azureAdApplicationObjectId"] = "$azureAdApplicationObjectId"
        $OptionalParameters["sqlAdAdminUserName"] = "$sqlAdAdminUserName"
        $OptionalParameters["sqlAdAdminUserPassword"] = "$sqlAdAdminUserPassword"
    }
    Process
    {
        Write-Host -ForegroundColor Green "`nStep 2: Initiating template deployment.."
        try
        {
            New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -Mode Incremental -TemplateParameterObject $OptionalParameters -TemplateFile $templateFile -DeploymentDebugLogLevel All -Force -Verbose
        }
        catch
        {
            Write-Host -ForegroundColor Red "`nCommand failed to execute. Please try to run it manually"
            Write-Host -ForegroundColor Red "`nCommand executed:`n`nNew-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -Mode Incremental -TemplateParameterObject $OptionalParameters -TemplateFile $templateFile -DeploymentDebugLogLevel All -Force -Verbose"
            $OptionalParameters | Sort-Object Name | Format-Table -AutoSize -Wrap -Expand EnumOnly
            Break
        }
    }

