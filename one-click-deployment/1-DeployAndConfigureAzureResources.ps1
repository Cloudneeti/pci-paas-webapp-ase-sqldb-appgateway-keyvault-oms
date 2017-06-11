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
        # Provide Azure AD UserName with Global Administrator permission on Azure AD and Service Administrator / Co-Admin permission on Subsciption.
        [Parameter(Mandatory=$True)] 
        [string]$globalAdminUserName, 

        # Provide password for Azure AD UserName.
        [Parameter(Mandatory=$True)] 
        [string]$globalAdminPassword,

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
        [string]
        $customHostName,

        # Param2 help description
        [string]
        $enableSSL,
        
        # Param2 help description
        [string]
        $certificatePath

        # Use this switch to enable new password policy with 60 days validity.
        [switch]$enableADDomainPasswordPolicy               
    )

Begin
    {
        $ErrorActionPreference = 'stop'

        ########### Functions ###########
        Write-Host -ForegroungColor Green "`nStep 1: Loading functions."
        # Function to convert certificates into Base64 String.
        function Convert-Certificate ($certPath)
        {
            $fileContentBytes = get-content "$certPath" -Encoding Byte
            [System.Convert]::ToBase64String($fileContentBytes)
        }

        # Function to create a strong 15 length Strong & Random password for Azure AD Gobal Admin Account.
        function New-RandomPassword () 
        {
            # This function generates a strong 15 length random password using Capital & Small Aplhabets,Numbers and Special characters.
            (-join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})) + `
            ((10..99) | Get-Random -Count 1) + `
            ('@','%','!','^' | Get-Random -Count 1) +`
            (-join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})) + `
            ((10..99) | Get-Random -Count 1)
        }
        Write-Host -ForegroundColor Yellow "`nFunctions loaded successfully."

        ########### Manage Variables ###########
        $ScriptFolder = Split-Path -Parent $PSCommandPath
        $sqlADAdminName = "sqlAdmin@"+$azureADDomainName
        $receptionistUserName = "receptionist_EdnaB@"+$azureADDomainName
        $cloudwiseAppServiceURL = "http://pcisolution"+(Get-Random -Maximum 999)+'.'+$azureADDomainName
        $suffix = $suffix.Replace(' ', '').Trim()
        $displayName = ($suffix + " Azure PCI PAAS Sample")

        # Generating common password 
        $newPassword = New-RandomPassword

        # Creating a Login credential.
        $secpasswd = ConvertTo-SecureString $globalAdminPassword -AsPlainText -Force
        $psCred = New-Object System.Management.Automation.PSCredential ($globalAdminUserName, $secpasswd)

        ########### Establishing connection to Azure ###########
        try {
            Write-Host -ForegroundColor Green "`nStep 2:Establishing connection to Azure AD & Subscription"

            # Connecting to MSOL Service
            Write-Host -ForegroundColor Yellow  "`t* Connecting to MSOL service."
            Connect-MsolService -Credential $psCred
            if(Get-MsolDomain){
                Write-Host -ForegroundColor Yellow "`t* Connection to Msol Service established successfully."
            }
            
            # Connecting to Azure Subscription
            Write-Host -ForegroundColor Yellow "`t* Connecting to AzureRM Subscription - $subscriptionID."
            Login-AzureRmAccount -Credential $psCred -SubscriptionId $subscriptionID
            if(Get-AzureRmContext){
                Write-Host -ForegroundColor Yellow "`t* Connection to AzureRM Subscription established successfully."
            }
        }
        catch {
            Throw $_
        }
    }
Process
    {

        try {
            ########### Creating Users in Azure AD ###########
            Write-Host ("`nStep 3:Create AD Users for SQL AD Admin & Receptionist to test various scenarios" ) -ForegroundColor Green
            
            # Creating SQL Admin & Receptionist Account if does not exist already.
            Write-Host -ForegroundColor Yellow "`t* Checking is $sqlADAdminName already exist in the directory."
            $sqlADAdminObjectId = (Get-MsolUser -UserPrincipalName $sqlADAdminName -ErrorAction SilentlyContinue).ObjectID
            if ($sqlADAdminObjectId -eq $null)  
            {    
                $sqlADAdminDetails = New-MsolUser -UserPrincipalName $sqlADAdminName -DisplayName "SQLADAdministrator PCI Samples" -FirstName "SQL AD Administrator" -LastName "PCI Samples" -PasswordNeverExpires $false -StrongPasswordRequired $true
                $sqlADAdminObjectId= $sqlADAdminDetails.ObjectID
                # Make the SQL Account a Global AD Administrator
                Write-Host -ForegroundColor Yellow "`t* Promoting SQL AD User Account as Company Administrator."
                Add-MsolRoleMember -RoleName "Company Administrator" -RoleMemberObjectId $sqlADAdminObjectId
            }
            # Setting up new password for SQL Global AD Admin.
            Write-Host -ForegroundColor Yellow "`t* Setting up password for SQL AD Admin Account"
            Set-MsolUserPassword -userPrincipalName $SQLADAdminName -NewPassword $newPassword -ForceChangePassword $false
            Start-Sleep -Seconds 10
            # Grant 'SQL Global AD Admin' access to the Azure subscription
            $RoleAssignment = Get-AzureRmRoleAssignment -ObjectId $sqlADAdminObjectId -RoleDefinitionName Contributor -Scope ('/subscriptions/'+ $subscriptionID) -ErrorAction SilentlyContinue
            if ($RoleAssignment -eq $null){New-AzureRmRoleAssignment -ObjectId $sqlADAdminObjectId -RoleDefinitionName Contributor -Scope ('/subscriptions/' + $subscriptionID )}
            Else{ Write-Output "$($sqlADAdminDetails.SignInName) has already been assigned with Contributor permission on Subscription."}

            Write-Host -ForegroundColor Yellow "`t* Checking is $receptionistUserName already exist in the directory."
            $receptionistUserObjectId = (Get-MsolUser -UserPrincipalName $receptionistUserName -ErrorAction SilentlyContinue).ObjectID
            if ($receptionistUserObjectId -eq $null)  
            {    
                New-MsolUser -UserPrincipalName $receptionistUserName -DisplayName "Edna Benson" -FirstName "Edna" -LastName "Benson" -PasswordNeverExpires $false -StrongPasswordRequired $true
            }
            # Setting up new password for Receptionist user account.
            Write-Host -ForegroundColor Yellow "`t* Setting up password for Receptionist User Account"
            Set-MsolUserPassword -userPrincipalName $receptionistUserName -NewPassword $newPassword -ForceChangePassword $false
        }
        catch {
            
        }

        try {
            ########### Create Azure Active Directory apps in default directory ###########
            Write-Host ("`nStep 4: Create Azure AD application in Default directory") -ForegroundColor Green
            # Get tenant ID
            $tenantID = (Get-AzureRmContext).Tenant.TenantId
            if ($tenantID -eq $null){$tenantID = (Get-AzureRmContext).Tenant.Id}

            # Create Active Directory Application
            Write-Host ("`tStep 4.1: Attempting to Azure AD application") -ForegroundColor Yellow
            $azureAdApplication = New-AzureRmADApplication -DisplayName $displayName -HomePage $cloudwiseAppServiceURL -IdentifierUris $cloudwiseAppServiceURL -Password $newPassword
            Write-Host ("`tAzure Active Directory apps creation successful. AppID is " + $azureAdApplication.ApplicationId) -ForegroundColor Yellow

            # Create a service principal for the AD Application and add a Reader role to the principal 
            Write-Host ("`tStep 4.2: Attempting to create Service Principal") -ForegroundColor Yellow
            $principal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId
            Start-Sleep -s 30 # Wait till the ServicePrincipal is completely created. Usually takes 20+secs. Needed as Role assignment needs a fully deployed servicePrincipal
            Write-Host ("`tService Principal creation successful - " + $principal.DisplayName) -ForegroundColor Yellow
            
            # Assign Reader Role to Service Principal on Azure Subscription
            $scopedSubs = ("/subscriptions/" + $sub.Subscription)
            Write-Host ("`tStep 4.3: Attempting Reader Role assignment" ) -ForegroundColor Yellow
            New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $azureAdApplication.ApplicationId.Guid -Scope $scopedSubs
            Write-Host ("`tReader Role assignment successful" ) -ForegroundColor Yellow    
        }
        catch {
            throw $_
        }


### 4. Create a Self-signed certificate for ASE ILB and Application Gateway.

### Generate App Gateway Front End SSL certificate string
if($enableSSL){
	if($certificatePath) {
		$certData = Convert-Certificate -certPath $certificatePath
		$certPassword = "$certificatePassword"
	}
	Else{
		$fileName = "appgwfrontendssl"
		$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "www.$customHostName"
		$certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint
		$pfxpass = $sqlADAdminPassword
		$password = ConvertTo-SecureString -String "$pfxpass" -Force -AsPlainText
		Export-PfxCertificate -cert $certThumbprint -FilePath "$ScriptFolder\Certificates\$fileName.pfx" -Password $password
		$certData = Convert-Certificate -certPath "$ScriptFolder\Certificates\$fileName.pfx"
		$certPassword = $pfxpass
	}
}
Else{
	$certData = "null"
	$certPassword = "null"
}

### Generate self-signed certificate for ASE ILB and convert into base64 string

$fileName = "aseilbcertificate"
$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "*.ase.$customHostName", "*.scm.ase.$customHostName"
$certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint
$pfxpass = $sqlADAdminPassword
$password = ConvertTo-SecureString -String "$pfxpass" -Force -AsPlainText
Export-PfxCertificate -cert $certThumbprint -FilePath "$ScriptFolder\Certificates\$fileName.pfx" -Password $password
Export-Certificate -Cert $certThumbprint -FilePath "$ScriptFolder\Certificates\$fileName.cer"
Start-Sleep -Seconds 3
$aseCertData = Convert-Certificate -certPath "$ScriptFolder\Certificates\$fileName.cer"
$asePfxBlobString = Convert-Certificate -certPath "$ScriptFolder\Certificates\$fileName.pfx"
$asePfxPassword = $pfxpass
$aseCertThumbprint = $certificate.Thumbprint

      




        if($enableADDomainPasswordPolicy){
            # Setting up password policy 
            Write "`nStep 4:Setting up password policy for $azureADDomainName domain"
            Set-MsolPasswordPolicy -ValidityPeriod 60 -NotificationDays 14 -DomainName "$azureADDomainName"
        }

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
        $outputTable.Add('aseCertThumbprint',$aseCertThumbprint)
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
