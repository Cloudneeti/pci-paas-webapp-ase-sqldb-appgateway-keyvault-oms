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
    [string] [Parameter(Mandatory=$true)] 
	$DeploymentName,

    [string] [Parameter(Mandatory=$true)] 	
    $ResourceGroupName,

    [string] [Parameter(Mandatory=$true)] 
	$Location,

    [string] [Parameter(Mandatory=$true)] 
	$TemplateUri,

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
        $ErrorActionPreference = 'Stop'
	    Set-ExecutionPolicy RemoteSigned;
        cd $PSScriptRoot
        Write "Connecting to Azure.. "
        Import-AzureRmContext -Path "$pwd\auth.json" -ErrorAction Stop
        <#
        $mycreds = Get-Credential
        $Login = Login-AzureRmAccount -SubscriptionId $SubscriptionID -Credential $mycreds
        Connect-MsolService -Credential $mycreds
        #>
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
        Write "Initiating template deployment.."
        try
        {
            New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName  -Mode Incremental -TemplateParameterObject $OptionalParameters -TemplateUri $TemplateUri -DeploymentDebugLogLevel All -Force -Verbose
        }
        catch
        {
            "Command failed to execute. Please try to run it manually"
            "New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName  -Mode Incremental -TemplateParameterObject $OptionalParameters -TemplateUri $TemplateUri -DeploymentDebugLogLevel All -Force -Verbose"
            $OptionalParameters | Sort-Object Name | Format-Table -AutoSize -Wrap -Expand EnumOnly
            Break
        }
    }

