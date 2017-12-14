<#
This script deploys and configures Azure resources as a part of a -pre-deployment- activity

This script should run before you start deployment of PCI-PaaS solution templates. Use your Azure AD Global Administrator account with
        Owner permission at Subscription level to execute this script. 
		If you are not sure about your permissions, run 0-Setup-AdministrativeAccountAndPermission.ps1 before you execute this script.

    This script performs several pre-requisites including 
        -   Create 2 Azure AD Accounts - 1) SQL Account with Company Administrator Role and Contributor Permission on a Subscription.
                                         2) Receptionist Account with Limited access.
        -   Creates AD Application and Service Principle to AD Application.
        -   Generates self-signed SSL certificate for Internal App Service Environment and Application gateway (if required) and Converts them into Base64 string
                for template deployment.

    You can use the following switches parameters - 
    1) enableSSL - Use this switch to create new self-signed certificate or convert existing certificate (by providing appGatewaySslCertPath & appGatewaySslCertPwd ) for Application Gateway SSL endpoint. 
    2) enableADDomainPasswordPolicy - Use this switch to setup password policy with 60 days of validity at Domain Level.

You will use appGatewaySslCertPath & appGatewaySslCertPwd parameter only when you are willing to upload your own certificate for Application Gateway HTTPS endpoint. appGatewaySslCertPath parameter 
    will require you to enter absolute path for your certificate pfx file. Make sure certificate is in .pfx format with password protected.

Please note - By default, Application gateway will always communicate with App Service Environment using HTTPS.
    
USAGE 1, Create Azure AD Accounts, self-signed certificate for ASE ILB, customer provided customHostName, self-signed certificate for Application Gateway & setup password policy with 60 days.
	
    .\1-DeployAndConfigureAzureResources.ps1 -resourceGroupName contosowebstore -globalAdminUserName admin1@contoso.com -globalAdminPassword ********** -azureADDomainName contoso.com -subscriptionID xxxxxxx-f760-xxxx-bd98-xxxxxxxx -suffix PCIDemo -sqlTDAlertEmailAddress email@dummy.com -customHostName dummydomain.com -enableSSL -enableADDomainPasswordPolicy
    
USAGE 2, Create Azure AD Accounts, self-signed certificate for ASE ILB, default customHostName, self-signed certificate for Application Gateway & setup password policy with 60 days.
	
   .\1-DeployAndConfigureAzureResources.ps1 -resourceGroupName contosowebstore -globalAdminUserName admin1@contoso.com -globalAdminPassword ********** -azureADDomainName contoso.com -subscriptionID xxxxxxx-f760-xxxx-bd98-xxxxxxxx -suffix PCIDemo -sqlTDAlertEmailAddress email@dummy.com -enableSSL -enableADDomainPasswordPolicy

USAGE 3,  Create Azure AD Accounts, customer provided customHostName & certificate for AppGateway SSL endpoint.

    .\1-DeployAndConfigureAzureResources.ps1 -resourceGroupName contosowebstore -globalAdminUserName admin1@contoso.com -globalAdminPassword ********** -azureADDomainName contoso.com -subscriptionID xxxxxxx-f760-xxxx-bd98-xxxxxxxx -suffix PCIDemo -sqlTDAlertEmailAddress email@dummy.com -customHostName dummydomain.com -appGatewaySslCertPath 'C:\...pfx' -appGatewaySslCertPwd 'Pass' -enableSSL 

USAGE 4,  Create Azure AD Accounts & self-signed certificate for ASE ILB with default customHostName only. (No HTTPS endpoint on Application Gateway.)

    .\1-DeployAndConfigureAzureResources.ps1 -resourceGroupName contosowebstore -globalAdminUserName admin1@contoso.com -globalAdminPassword ********** -azureADDomainName contoso.com -subscriptionID xxxxxxx-f760-xxxx-bd98-xxxxxxxx -suffix PCIDemo -sqlTDAlertEmailAddress email@dummy.com

#>
[CmdletBinding()]
Param
    (
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
        [ValidateNotNullOrEmpty()]
        [string]
        $suffix,

        # Provide Email address for SQL Threat Detection Alerts
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]        
        $sqlTDAlertEmailAddress,

        # Provide CustomDomain that will be used for creating ASE SubDomain & WebApp HostName e.g. contoso.com. This is not a Mandatory parameter. You can also leave
        #   it blank if you want to use built-in domain - azurewebsites.net. 
        [string]
        $customHostName = "azurewebsites.net",

        # Provide certificate path if you are willing to provide your own frontend ssl certificate for Application gateway.
        [ValidateScript({
            if(
                (Test-Path $_)
            ){$true}
            else {Throw "Parameter validtion failed due to invalid file path"}
        })]  
        [string]
        $appGatewaySslCertPath,

        # Enter password for the certificate provided.
        [string]
        $appGatewaySslCertPwd,

        # Use this swtich in combination with appGatewaySslCertPath parameter to setup frontend ssl on Application gateway.     
        [switch]
        $enableSSL,

        # Use this switch to enable new password policy with 60 days expiry at Azure AD Domain level.
        [switch]$enableADDomainPasswordPolicy               
    )

Begin
    {
        # Preference variable
        $ProgressPreference = 'SilentlyContinue'
        $ErrorActionPreference = 'Stop'
        $WarningPreference = "SilentlyContinue"
        Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy UnRestricted -Force
        
        #Change Path to Script directory
        Set-location $PSScriptRoot

        Write-Host -ForegroundColor Green "`nStep 0: Checking Pre-requisites."

        # Checking AzureRM Context version
        Write-Host -ForegroundColor Yellow "`nChecking AzureRM Context version.."
        if ((get-command get-azurermcontext).version -le "3.0"){
            Write-Host -ForegroundColor Red "`nThis script requires PowerShell to 3.0 or greater"
            Break
        }

        ########### Manage directories ###########
        # Create folder to store self-signed certificates
        Write-Host -ForegroundColor Yellow "`nCreating Certificates folder to store self-signed certificates."
        if(!(Test-path $pwd\certificates)){mkdir $pwd\certificates -Force | Out-Null }

        ### Create Output  folder to store logs, deploymentoutputs etc.
        if(! (Test-Path -Path "$(Split-Path $MyInvocation.MyCommand.Path)\output")) {
            New-Item -Path $(Split-Path $MyInvocation.MyCommand.Path) -Name 'output' -ItemType Directory
        }
        else {
            Remove-Item -Path "$(Split-Path $MyInvocation.MyCommand.Path)\output" -Force -Recurse
            Start-Sleep -Seconds 2
            New-Item -Path $(Split-Path $MyInvocation.MyCommand.Path) -Name 'output' -ItemType Directory
        }
        $outputFolderPath = "$(Split-Path $MyInvocation.MyCommand.Path)\output"
        ########### Functions ###########
        Write-Host -ForegroundColor Green "`nStep 1: Loading functions."

        <#
        .SYNOPSIS
            Registers RPs
        #>
        Function RegisterRP {
            Param(
                [string]$ResourceProviderNamespace
            )

            Write-Host -ForegroundColor Yellow "`t* Registering resource provider '$ResourceProviderNamespace'";
            Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace | Out-Null;
        }

        # Function to convert certificates into Base64 String.
        function Convert-Certificate ($certPath)
        {
            $fileContentBytes = get-content "$certPath" -Encoding Byte
            [System.Convert]::ToBase64String($fileContentBytes)
        }

        # Function to create a strong 15 length Strong & Random password for the solution.
        function New-RandomPassword () 
        {
            # This function generates a strong 15 length random password using Capital & Small Aplhabets,Numbers and Special characters.
            (-join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})) + `
            ((10..99) | Get-Random -Count 1) + `
            ('@','%','!','^' | Get-Random -Count 1) +`
            (-join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})) + `
            ((10..99) | Get-Random -Count 1)
        }

        #  Function for self-signed certificate generator. Reference link - https://gallery.technet.microsoft.com/scriptcenter/Self-signed-certificate-5920a7c6
        .".\1-click-deployment-nested\New-SelfSignedCertificateEx.ps1"

        Write-Host -ForegroundColor Yellow "`t* Functions loaded successfully."

        ########### Manage Variables ###########
        $location = 'eastus'
        $automationAcclocation = 'eastus2'
        $scriptFolder = Split-Path -Parent $PSCommandPath
        $sqlAdAdminUserName = "sqlAdmin@"+$azureADDomainName
        $receptionistUserName = "receptionist_EdnaB@"+$azureADDomainName
        $pciAppServiceURL = "http://pcisolution"+(Get-Random -Maximum 999)+'.'+$azureADDomainName
        $suffix = $suffix.Replace(' ', '').Trim()
        $displayName = ($suffix + " Azure PCI PAAS Sample")
        if($enableSSL){
            $sslORnon_ssl = 'ssl'
        }else{
            $sslORnon_ssl = 'non-ssl'
        }
        $automationaccname = "automationacc" + ((Get-Date).ToUniversalTime()).ToString('MMddHHmm')
        $automationADApplication = "AutomationAppl" + ((Get-Date).ToUniversalTime()).ToString('MMddHHmm')
        $deploymentName = "PCI-Deploy-"+ ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')
        $_artifactslocationSasToken = "null"
        $clientIPAddress = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip
        $databaseName = "ContosoPayments"
        $artifactsStorageAccKeyType = "StorageAccessKey"
        $cmkName = "CMK1" 
        $cekName = "CEK1" 
        $keyName = "CMK1" 
        Set-Variable ArtifactsLocationName '_artifactsLocation' -Option ReadOnly -Force
        Set-Variable ArtifactsLocationSasTokenName '_artifactsLocationSasToken' -Option ReadOnly -Force
        $storageContainerName = 'pci-container'
        $storageResourceGroupName = 'pcistageartifacts' + ((Get-Date).ToUniversalTime()).ToString('MMddHHmm')                 

        # Generating common password 
        $newPassword = New-RandomPassword
        $secNewPasswd = ConvertTo-SecureString $newPassword -AsPlainText -Force

        # Creating a Login credential.
        $secpasswd = ConvertTo-SecureString $globalAdminPassword -AsPlainText -Force
        $psCred = New-Object System.Management.Automation.PSCredential ($globalAdminUserName, $secpasswd)
        
        ########### Establishing connection to Azure ###########
        try {
            Write-Host -ForegroundColor Green "`nStep 2: Establishing connection to Azure AD,Subscription & Registering Resource Provider."

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
        $subId = ((Get-AzureRmContext).Subscription.Id).Replace('-', '').substring(0, 19)
        $context = Set-AzureRmContext -SubscriptionId $subscriptionId
        $userPrincipalName = $context.Account.Id
        $artifactsStorageAcc = "stage$subId" 
        $sqlBacpacUri = "http://$artifactsStorageAcc.blob.core.windows.net/$storageContainerName/artifacts/ContosoPayments.bacpac"
        $sqlsmodll = (Get-ChildItem "$env:programfiles\WindowsPowerShell\Modules\SqlServer" -Recurse -File -Filter "Microsoft.SqlServer.Smo.dll").FullName

    }
    
Process
    {
        try {
            # Register RPs
            $resourceProviders = @(
                "Microsoft.Storage",
                "Microsoft.Compute",
                "Microsoft.KeyVault",
                "Microsoft.Network",
                "Microsoft.Web"
            )
            if($resourceProviders.length) {
                Write-Host -ForegroundColor Yellow "`t* Registering resource providers"
                foreach($resourceProvider in $resourceProviders) {
                    RegisterRP($resourceProvider);
                }
            }
        }
        catch {
            throw $_
        }
        
        try {
            # Create a storage account name if none was provided
            $StorageAccount = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $artifactsStorageAcc})

            # Create the storage account if it doesn't already exist
            if($StorageAccount -eq $null){
                Write-Host -ForegroundColor Yellow "`t* Creating an Artifacts Resource group & Storage account."
                New-AzureRmResourceGroup -Location "$location" -Name $storageResourceGroupName -Force | Out-Null
                $StorageAccount = New-AzureRmStorageAccount -StorageAccountName $artifactsStorageAcc -Type 'Standard_LRS' -ResourceGroupName $storageResourceGroupName -Location "$location"
            }
            $StorageAccountContext = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $artifactsStorageAcc}).Context
            
            $_artifactsLocation = $StorageAccountContext.BlobEndPoint + $storageContainerName
            
            # Copy files from the local storage staging location to the storage account container
            New-AzureStorageContainer -Name $storageContainerName -Context $StorageAccountContext -Permission Container -ErrorAction SilentlyContinue | Out-Null

            $ArtifactFilePaths = Get-ChildItem $pwd\nested -Recurse -File | ForEach-Object -Process {$_.FullName}
            foreach ($SourcePath in $ArtifactFilePaths) {
                $BlobName = $SourcePath.Substring(($PWD.Path).Length + 1)
                Set-AzureStorageBlobContent -File $SourcePath -Blob $BlobName -Container $storageContainerName -Context $StorageAccountContext -Force | Out-Null
            }
            $ArtifactFilePaths = Get-ChildItem $pwd\artifacts -Recurse -File | ForEach-Object -Process {$_.FullName}
            foreach ($SourcePath in $ArtifactFilePaths) {
                $BlobName = $SourcePath.Substring(($PWD.Path).Length + 1)
                Set-AzureStorageBlobContent -File $SourcePath -Blob $BlobName -Container $storageContainerName -Context $StorageAccountContext -Force | Out-Null
            }

            # Retrieve Access Key 
            $artifactsStorageAccKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -name $storageAccount.StorageAccountName -ErrorAction Stop)[0].value 
            
        }
        catch {
            throw $_
        }

        try {
            ########### Creating Users in Azure AD ###########
            Write-Host ("`nStep 3: Create AD Users for SQL AD Admin & Receptionist to test various scenarios" ) -ForegroundColor Green
            
            # Creating SQL Admin & Receptionist Account if does not exist already.
            Write-Host -ForegroundColor Yellow "`t* Checking is $sqlAdAdminUserName already exist in the directory."
            $sqlADAdminDetails = Get-MsolUser -UserPrincipalName $sqlAdAdminUserName -ErrorAction SilentlyContinue
            $sqlADAdminObjectId= $sqlADAdminDetails.ObjectID
            if ($sqlADAdminObjectId -eq $null)  
            {    
                $sqlADAdminDetails = New-MsolUser -UserPrincipalName $sqlAdAdminUserName -DisplayName "SQLADAdministrator PCI Samples" -FirstName "SQL AD Administrator" -LastName "PCI Samples" -PasswordNeverExpires $false -StrongPasswordRequired $true
                $sqlADAdminObjectId= $sqlADAdminDetails.ObjectID
                # Make the SQL Account a Global AD Administrator
                Write-Host -ForegroundColor Yellow "`t* Promoting SQL AD User Account as Company Administrator."
                Add-MsolRoleMember -RoleName "Company Administrator" -RoleMemberObjectId $sqlADAdminObjectId
            }

            # Setting up new password for SQL Global AD Admin.
            Write-Host -ForegroundColor Yellow "`t* Setting up password for SQL AD Admin Account"
            Set-MsolUserPassword -userPrincipalName $sqlAdAdminUserName -NewPassword $newPassword -ForceChangePassword $false | Out-Null
            Start-Sleep -Seconds 30

            # Grant 'SQL Global AD Admin' access to the Azure subscription
            $RoleAssignment = Get-AzureRmRoleAssignment -ObjectId $sqlADAdminObjectId -RoleDefinitionName Contributor -Scope ('/subscriptions/'+ $subscriptionID) -ErrorAction SilentlyContinue
            if ($RoleAssignment -eq $null){
                Write-Host -ForegroundColor Yellow "`t* Assigning $($sqlADAdminDetails.SignInName) with Contributor Role on Subscription - $subscriptionID"
                New-AzureRmRoleAssignment -ObjectId $sqlADAdminObjectId -RoleDefinitionName Contributor -Scope ('/subscriptions/' + $subscriptionID )
                if (Get-AzureRmRoleAssignment -ObjectId $sqlADAdminObjectId -RoleDefinitionName Contributor -Scope ('/subscriptions/'+ $subscriptionID))
                {
                    Write-Host -ForegroundColor Cyan "`t* $($sqlADAdminDetails.SignInName) has been successfully assigned with Contributor Role on Subscription."
                }
            }
            else{ Write-Host -ForegroundColor Cyan "`t* $($sqlADAdminDetails.SignInName) has already been assigned with Contributor Role on Subscription."}

            Write-Host -ForegroundColor Yellow "`t* Checking is $receptionistUserName already exist in the directory."
            $receptionistUserObjectId = (Get-MsolUser -UserPrincipalName $receptionistUserName -ErrorAction SilentlyContinue).ObjectID
            if ($receptionistUserObjectId -eq $null)  
            {    
                New-MsolUser -UserPrincipalName $receptionistUserName -DisplayName "Edna Benson" -FirstName "Edna" -LastName "Benson" -PasswordNeverExpires $false -StrongPasswordRequired $true
            }
            # Setting up new password for Receptionist user account.
            Write-Host -ForegroundColor Yellow "`t* Setting up password for Receptionist User Account"
            Set-MsolUserPassword -userPrincipalName $receptionistUserName -NewPassword $newPassword -ForceChangePassword $false | Out-Null
        }
        catch {
            throw $_
        }

        try {
            ########### Create Azure Active Directory apps in default directory ###########
            Write-Host ("`nStep 4: Create Azure AD application in Default directory") -ForegroundColor Green
            # Get tenant ID
            $tenantID = (Get-AzureRmContext).Tenant.TenantId
            if ($tenantID -eq $null){$tenantID = (Get-AzureRmContext).Tenant.Id}

            # Create Active Directory Application
            Write-Host ("`t* Step 4.1: Attempting to Azure AD application") -ForegroundColor Yellow
            $azureAdApplication = New-AzureRmADApplication -DisplayName $displayName -HomePage $pciAppServiceURL -IdentifierUris $pciAppServiceURL -Password $newPassword
            $azureAdApplicationClientId = $azureAdApplication.ApplicationId.Guid
            $azureAdApplicationObjectId = $azureAdApplication.ObjectId.Guid            
            Write-Host ("`t* Azure Active Directory apps creation successful. AppID is " + $azureAdApplication.ApplicationId) -ForegroundColor Yellow

            # Create a service principal for the AD Application and add a Reader role to the principal 
            Write-Host ("`t* Step 4.2: Attempting to create Service Principal") -ForegroundColor Yellow
            $principal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId
            Start-Sleep -s 30 # Wait till the ServicePrincipal is completely created. Usually takes 20+secs. Needed as Role assignment needs a fully deployed servicePrincipal
            Write-Host ("`t* Service Principal creation successful - " + $principal.DisplayName) -ForegroundColor Yellow
            Start-Sleep -Seconds 30

            # Assign Reader Role to Service Principal on Azure Subscription
            $scopedSubs = ("/subscriptions/" + $subscriptionID)
            Write-Host ("`t* Step 4.3: Attempting Reader Role assignment" ) -ForegroundColor Yellow
            New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $azureAdApplication.ApplicationId.Guid -Scope $scopedSubs | Out-Null
            Write-Host ("`t* Reader Role assignment successful" ) -ForegroundColor Yellow    
        }
        catch {
            throw $_
        }

        try {
            ########### Create Self-signed certificate for ASE ILB and Application Gateway ###########
            Write-Host -ForegroundColor Green "`nStep 5: Create Self-signed certificate for ASE ILB and Application Gateway "

            # Generate App Gateway Front End SSL certificate, if required and converts it to Base64 string.
            if($enableSSL){
                if($appGatewaySslCertPath) {
                    Write-Host -ForegroundColor Yellow "`t* Converting customer provided certificate to Base64 string"
                    $certData = Convert-Certificate -certPath $appGatewaySslCertPath
                    $certPassword = $appGatewaySslCertPwd
                }
                else{
                    Write-Host -ForegroundColor Yellow "`t* No valid certificate path was provided. Creating a new self-signed certificate and converting to Base64 string"
                    $fileName = "appgwfrontendssl"
                    $certificate = New-SelfSignedCertificateEx -Subject "CN=www.$customHostName" -SAN "www.$customHostName" -EKU "Server Authentication", "Client authentication" `
                    -NotAfter $((Get-Date).AddYears(5)) -KU "KeyEncipherment, DigitalSignature" -SignatureAlgorithm SHA256 -Exportable
                    $certThumbprint = "cert:\CurrentUser\my\" + $certificate.Thumbprint
                    Write-Host -ForegroundColor Yellow "`t* Certificate created successfully. Exporting certificate into pfx format."
                    Export-PfxCertificate -cert $certThumbprint -FilePath "$scriptFolder\Certificates\$fileName.pfx" -Password $secNewPasswd | Out-null
                    $certData = Convert-Certificate -certPath "$scriptFolder\Certificates\$fileName.pfx"
                    $certPassword = $newPassword
                }
            }
            else{
                $certData = "null"
                $certPassword = "null"
            }

            ### Generate self-signed certificate for ASE ILB and convert into base64 string
            Write-Host -ForegroundColor Yellow "`t* Creating a self-signed certificate for ASE ILB and converting to Base64 string"
            $fileName = "aseilbcertificate"
            $certificate = New-SelfSignedCertificateEx -Subject "CN=*.ase.$customHostName" -SAN "*.ase.$customHostName", "*.scm.ase.$customHostName" -EKU "Server Authentication", "Client authentication" `
            -NotAfter $((Get-Date).AddYears(5)) -KU "KeyEncipherment, DigitalSignature" -SignatureAlgorithm SHA256 -Exportable
            $certThumbprint = "cert:\CurrentUser\my\" + $certificate.Thumbprint
            Write-Host -ForegroundColor Yellow "`t* Certificate created successfully. Exporting certificate into .pfx & .cer format."
            Export-PfxCertificate -cert $certThumbprint -FilePath "$scriptFolder\Certificates\$fileName.pfx" -Password $secNewPasswd | Out-null
            Export-Certificate -Cert $certThumbprint -FilePath "$scriptFolder\Certificates\$fileName.cer" | Out-null
            Start-Sleep -Seconds 3
            $aseCertData = Convert-Certificate -certPath "$scriptFolder\Certificates\$fileName.cer"
            $asePfxBlobString = Convert-Certificate -certPath "$scriptFolder\Certificates\$fileName.pfx"
            $asePfxPassword = $newPassword
            $aseCertThumbprint = $certificate.Thumbprint
        }
        catch {
            throw $_
        }

        # Setup up Password Policy at Azure AD Domain Level, if allowed.
        try{
            if($enableADDomainPasswordPolicy){
                Write-Host -ForegroundColor Green "`nStep 6: Setting up password policy for $azureADDomainName domain"
                Set-MsolPasswordPolicy -ValidityPeriod 60 -NotificationDays 14 -DomainName "$azureADDomainName"
                if (($passwordPolicy = Get-MsolPasswordPolicy -DomainName $azureADDomainName).ValidityPeriod -eq 60 ) {
                    Write-Host -ForegroundColor Yellow "`t* Password policy has been set to 60 Days."
                    $passwordValidityPeriod = $passwordPolicy.ValidityPeriod
                }else{
				Write-Host -ForegroundColor Red "`t* Failed to set password policy to 60 Days." 
				Write-Host -ForegroundColor Yellow "Please refer output for current password policy settings."
				}
            }else{Write-Host -ForegroundColor Green "`nStep 6: Setting up password policy for $azureADDomainName domain - Skipped"}
        }
        catch{
            throw $_
        }

        # Create Resource group, Automation account, RunAs Account for Runbook.
        try {
            Write-Host -ForegroundColor Green "`nStep 7: Preparing for Template Deployment"
            # Create Resource Group
            Write-Host -ForegroundColor Yellow "`t* Creating a New Resource Group - $resourceGroupName at $location"
            New-AzureRmResourceGroup -Name $resourceGroupName -location $location -Force | Out-Null
            Write-Host -ForegroundColor Yellow "`t* ResoureGroup - $resourceGroupName has been created successfully"
            Start-Sleep -Seconds 5
            }

        catch {
            throw $_
        }
        # Initiate template deployment
        try {
            Write-Host -ForegroundColor Green "`nStep 8: Initiating template deployment."
            # Submitting templte deployment to new powershell session
            Write-Host -ForegroundColor Yellow "`t* Submitting deployment"
            Start-Process Powershell -ArgumentList "-NoExit", ".\1-click-deployment-nested\Initiate-TemplateDeployment.ps1 -subscriptionID $subscriptionID -globalAdminUserName $globalAdminUserName -globalAdminPassword $globalAdminPassword -deploymentName $deploymentName -resourceGroupName $resourceGroupName -location $location -templateFile '$scriptFolder\azuredeploy.json' -_artifactsLocation $_artifactsLocation -_artifactsLocationSasToken $_artifactsLocationSasToken -sslORnon_ssl $sslORnon_ssl -certData $certData -certPassword $certPassword -aseCertData $aseCertData -asePfxBlobString $asePfxBlobString -asePfxPassword $asePfxPassword -aseCertThumbprint $aseCertThumbprint -bastionHostAdministratorPassword $newPassword -sqlAdministratorLoginPassword $newPassword -sqlThreatDetectionAlertEmailAddress $SqlTDAlertEmailAddress -automationAccountName $automationaccname -customHostName $customHostName -azureAdApplicationClientId $azureAdApplicationClientId -azureAdApplicationClientSecret $newPassword -azureAdApplicationObjectId $azureAdApplicationObjectId -sqlAdAdminUserName $sqlAdAdminUserName -sqlAdAdminUserPassword $newPassword"
            Write-Host "`t`t-> Waiting for deployment $deploymentName to submit.. " -ForegroundColor Yellow
            $count=0
            $status=1
            do
            {
                if($count -lt 10){                
                Write-Host "`t`t-> Checking deployment in 60 secs.." -ForegroundColor Yellow
                Start-sleep -seconds 60
                $count +=1
                }
                else{
                    $status=0
                    Break
                    
                }
            }
            until ((Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -ErrorAction SilentlyContinue ) -ne $null)             
            if($status){
                Write-Host -ForegroundColor Yellow "`t* Deployment has been submitted successfully."
            }            
            else{
                throw "Deployment fail to submit. Please redeploy the solution."
            
            }
            
        }
        catch {
            throw $_
        }

        # Loop to check SQL server deployment.
        try {
            Write-Host "`t`t-> Waiting for deployment deploy-SQLServerSQLDb to submit.. " -ForegroundColor Yellow            
            do
            {
                Write-Host "`t`t-> Checking deployment in 60 secs.." -ForegroundColor Yellow
                Start-sleep -seconds 60
            }
            until ((Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name 'deploy-SQLServerSQLDb' -ErrorAction SilentlyContinue) -ne $null) 
            Write-Host -ForegroundColor Yellow "`t* Deployment 'deploy-SQLServerSQLDb' has been submitted."
            do
            {
                Write-Host -ForegroundColor Yellow "`t`t-> Deployment 'deploy-SQLServerSQLDb' is currently running.. Checking Deployment in 60 seconds.."
                Start-Sleep -Seconds 60
            }
            While ((Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name 'deploy-SQLServerSQLDb').ProvisioningState -notin ('Failed','Succeeded'))

            if ((Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name deploy-SQLServerSQLDb).ProvisioningState -eq 'Succeeded')
            {
                Write-Host -ForegroundColor Yellow "`t* Deployment deploy-SQLServerSQLDb has completed successfully."
            }
            else
            {
                throw "Deployment deploy-SQLServerSQLDb has failed. Please check portal for the reason."
            }
        }
        catch {
            throw $_
        }

        # Updating SQL server firewall rule
        Write-Host -ForegroundColor Green "`nStep 9: Updating SQL server firewall rule."
        try {
            # Getting SqlServer resource object
            Write-Host -ForegroundColor Yellow "`t* Getting SQLServer resource object."
            $allResource = (Get-AzureRmResource | ? ResourceGroupName -EQ $resourceGroupName)
            $sqlServerName =  ($allResource | ? ResourceType -eq 'Microsoft.Sql/servers').ResourceName
            Write-Host -ForegroundColor Yellow ("`t* Updating SQL firewall with your ClientIp = " + $clientIPAddress)
            $unqiueid = ((Get-Date).ToUniversalTime()).ToString('MMddHHmm')
            New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -FirewallRuleName "ClientIpRule$unqiueid" -StartIpAddress $clientIPAddress -EndIpAddress $clientIPAddress
        }
        catch {
            throw $_
        }

        # Import SQL bacpac and update azure SQL DB Data masking policy
        Write-Host -ForegroundColor Green "`nStep 10: Importing SQL bacpac and Updating Azure SQL DB Data Masking Policy"
        try{
            # Getting Keyvault reource object
            Write-Host -ForegroundColor Yellow "`t* Getting KeyVault resource object."
            $keyVaultName = ($allResource | ? ResourceType -eq 'Microsoft.KeyVault/vaults').ResourceName
            # Importing bacpac file
            Write-Host ("`n`t* Importing SQL backpac from release artifacts storage account" ) -ForegroundColor Green
            New-AzureRmSqlDatabaseImport -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -DatabaseName $databaseName -StorageKeytype $artifactsStorageAccKeyType -StorageKey $artifactsStorageAccKey -StorageUri $sqlBacpacUri -AdministratorLogin 'sqladmin' -AdministratorLoginPassword $secNewPasswd -Edition Standard -ServiceObjectiveName S0 -DatabaseMaxSizeBytes 50000
            Start-Sleep -s 100
            Write-Host ("`n`t* Updating Azure SQL DB Data masking policy on FirstName & LastName Column" ) -ForegroundColor Yellow
            Set-AzureRmSqlDatabaseDataMaskingPolicy -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -DatabaseName $databaseName -DataMaskingState Enabled
            Start-Sleep -s 15
            New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -DatabaseName $databaseName -SchemaName "dbo" -TableName "Customers" -ColumnName "FirstName" -MaskingFunction Default
            New-AzureRmSqlDatabaseDataMaskingRule -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -DatabaseName $databaseName -SchemaName "dbo" -TableName "Customers" -ColumnName "LastName" -MaskingFunction Default
        }
        catch {
            throw $_
        }
        
        # Create an Azure Active Directory administrator for SQL
        try {
            Write-Host ("`nStep 11: Update SQL Server for Azure Active Directory administrator =" + $SqlAdAdminUserName ) -ForegroundColor Green
            Set-AzureRmSqlServerActiveDirectoryAdministrator -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DisplayName $SqlAdAdminUserName
        }
        catch {
            throw $_
        }

        # Encrypting Credit card information within database
        try {
            Write-Host ("`nStep 12: Encrypt SQL DB column Credit card Information" ) -ForegroundColor Green
            # Connect to your database.
            Add-Type -Path $sqlsmodll
            Write-Host -ForegroundColor Yellow "`t* Connecting database - $databaseName on $sqlServerName"
            $connStr = "Server=tcp:" + $sqlServerName + ".database.windows.net,1433;Initial Catalog=" + "`"" + $databaseName + "`"" + ";Persist Security Info=False;User ID=" + "`"" + "sqladmin" + "`"" + ";Password=`"" + "$newPassword" + "`"" + ";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
            $connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
            $connection.ConnectionString = $connStr
            $connection.Connect()
            $server = New-Object Microsoft.SqlServer.Management.Smo.Server($connection)
            $database = $server.Databases[$databaseName]

            #Granting Users & ServicePrincipal full access on Keyvault
            Write-Host ("`t* Giving Key Vault access permissions to the Users and ServicePrincipal ..") -ForegroundColor Yellow
            Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -UserPrincipalName $userPrincipalName -ResourceGroupName $resourceGroupName -PermissionsToKeys all  -PermissionsToSecrets all
            Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -UserPrincipalName $SqlAdAdminUserName -ResourceGroupName $resourceGroupName -PermissionsToKeys all -PermissionsToSecrets all 
            Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -ServicePrincipalName $azureAdApplicationClientId -ResourceGroupName $resourceGroupName -PermissionsToKeys all -PermissionsToSecrets all
            Write-Host ("`t* Granted permissions to the users and serviceprincipals ..") -ForegroundColor Yellow

            # Creating KeyVault Key to encrypt DB
            Write-Host -ForegroundColor Yellow "`t* Creating a New Keyvault key."
            $key = (Add-AzureKeyVaultKey -VaultName $KeyVaultName -Name $keyName -Destination 'Software').ID

            # Switching SQL commands context to the AD Application
            Write-Host -ForegroundColor Yellow "`t* Creating SQL Column Master Key & Column Encryption Key."
            $cmkSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyURL $key
            $sqlMasterKey = Get-SqlColumnMasterKey -Name $cmkName -InputObject $database -ErrorAction SilentlyContinue
            if ($sqlMasterKey){Write-Host -ForegroundColor Yellow "`t* SQL Master Key $cmkName already exists."} 
            Else{New-SqlColumnMasterKey -Name $cmkName -InputObject $database -ColumnMasterKeySettings $cmkSettings}
            Add-SqlAzureAuthenticationContext -ClientID $azureAdApplicationClientId -Secret $newPassword -Tenant $tenantID
            New-SqlColumnEncryptionKey -Name $cekName -InputObject $database -ColumnMasterKey $cmkName
                
            Write-Host -ForegroundColor Yellow "`t* SQL encryption has been successfully created. Encrypting SQL Columns.."
            # Encrypt the selected columns (or re-encrypt, if they are already encrypted using keys/encrypt types, different than the specified keys/types.
            $ces = @()
            $ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Customers.CreditCard_Number" -EncryptionType "Deterministic" -EncryptionKey $cekName
            $ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Customers.CreditCard_Code" -EncryptionType "Deterministic" -EncryptionKey $cekName
            $ces += New-SqlColumnEncryptionSettings -ColumnName "dbo.Customers.CreditCard_Expiration" -EncryptionType "Deterministic" -EncryptionKey $cekName
            Set-SqlColumnEncryption -InputObject $database -ColumnEncryptionSettings $ces
            Write-Host -ForegroundColor Yellow "`t* Column CreditCard_Number, CreditCard_Code, CreditCard_Expiration have been successfully encrypted"            
        }
        catch {
            Write-Host -ForegroundColor Red "`t Column encryption has failed."
            throw $_
        }
            # Enabling the Azure Security Center Policies.
        try {
            Write-Host ("`nStep 13: Enable Azure-Security-Center Policies." ) -ForegroundColor Green
            Write-Host "" -ForegroundColor Yellow
            
            $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
            Write-Host "`t* Checking AzureRM Context." -ForegroundColor Yellow
            $currentAzureContext = Get-AzureRmContext
            $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
            
            Write-Host "`t* Getting Access Token and Setting Variables to Invoke REST-API." -ForegroundColor Yellow
            Write-Host ("`t* Getting access token for tenant " + $currentAzureContext.Subscription.TenantId) -ForegroundColor Yellow
            $token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId)
            $token = $token.AccessToken
            $Script:asc_clientId = "1950a258-227b-4e31-a9cf-717495945fc2"              # Well-known client ID for Azure PowerShell
            $Script:asc_redirectUri = "urn:ietf:wg:oauth:2.0:oob"                      # Redirect URI for Azure PowerShell
            $Script:asc_resourceAppIdURI = "https://management.azure.com/"             # Resource URI for REST API
            $Script:asc_url = 'management.azure.com'                                   # Well-known URL endpoint
            $Script:asc_version = "2015-06-01-preview"                                 # Default API Version
            $PolicyName = 'default'
            $asc_APIVersion = "?api-version=$asc_version" #Build version syntax.
            $asc_endpoint = 'policies' #Set endpoint.
            
            Write-Host "`t* Creating auth header." -ForegroundColor Yellow
            Set-Variable -Name asc_requestHeader -Scope Script -Value @{"Authorization" = "Bearer $token"}
            Set-Variable -Name asc_subscriptionId -Scope Script -Value $currentAzureContext.Subscription.Id
            
            #Retrieve existing policy and build hashtable
            Write-Host "`t* Retrieving data for $PolicyName..." -ForegroundColor Yellow
            $asc_uri = "https://$asc_url/subscriptions/$asc_subscriptionId/providers/microsoft.Security/$asc_endpoint/$PolicyName$asc_APIVersion"
            $asc_request = Invoke-RestMethod -Uri $asc_uri -Method Get -Headers $asc_requestHeader
            $a = $asc_request 
            $json_policy = @{
                properties = @{
                    policyLevel = $a.properties.policyLevel
                    policyName = $a.properties.name
                    unique = $a.properties.unique
                    logCollection = $a.properties.logCollection
                    recommendations = $a.properties.recommendations
                    logsConfiguration = $a.properties.logsConfiguration
                    omsWorkspaceConfiguration = $a.properties.omsWorkspaceConfiguration
                    securityContactConfiguration = $a.properties.securityContactConfiguration
                    pricingConfiguration = $a.properties.pricingConfiguration
                }
            }
            if ($json_policy.properties.recommendations -eq $null){Write-Error "The specified policy does not exist."; return}
            
            #Set all params to on,
            $json_policy.properties.recommendations.patch = "On"
            $json_policy.properties.recommendations.baseline = "On"
            $json_policy.properties.recommendations.antimalware = "On"
            $json_policy.properties.recommendations.diskEncryption = "On"
            $json_policy.properties.recommendations.acls = "On"
            $json_policy.properties.recommendations.nsgs = "On"
            $json_policy.properties.recommendations.waf = "On"
            $json_policy.properties.recommendations.sqlAuditing = "On"
            $json_policy.properties.recommendations.sqlTde = "On"
            $json_policy.properties.recommendations.ngfw = "On"
            $json_policy.properties.recommendations.vulnerabilityAssessment = "On"
            $json_policy.properties.recommendations.storageEncryption = "On"
            $json_policy.properties.recommendations.jitNetworkAccess = "On"
            $json_policy.properties.recommendations.appWhitelisting = "On"
            $json_policy.properties.securityContactConfiguration.areNotificationsOn = $true
            $json_policy.properties.securityContactConfiguration.sendToAdminOn = $true
            $json_policy.properties.logCollection = "On"
            $json_policy.properties.pricingConfiguration.selectedPricingTier = "Standard"
            try {
                $json_policy.properties.securityContactConfiguration.securityContactEmails = $siteAdminUserName
            }
            catch {
                $json_policy.properties.securityContactConfiguration | Add-Member -NotePropertyName securityContactEmails -NotePropertyValue $siteAdminUserName
            }
            Start-Sleep 5
            
            Write-Host "`t* Enabling ASC Policies.." -ForegroundColor Yellow
            $JSON = ($json_policy | ConvertTo-Json -Depth 3)
            $asc_uri = "https://$asc_url/subscriptions/$asc_subscriptionId/providers/microsoft.Security/$asc_endpoint/$PolicyName$asc_APIVersion"
            $result = Invoke-WebRequest -Uri $asc_uri -Method Put -Headers $asc_requestHeader -Body $JSON -UseBasicParsing -ContentType "application/json"
            
        }
        catch {
            throw $_
        }
    }
End
    {
        Write-Host -ForegroundColor Green "`nCommon variables created for deployment"

        Write-Host -ForegroundColor Green "`n########################### Template Input Parameters - Start ###########################"
        $templateInputTable = New-Object -TypeName Hashtable
        $templateInputTable.Add('sslORnon_ssl',$sslORnon_ssl)
        $templateInputTable.Add('certData',$certData)
        $templateInputTable.Add('certPassword',$certPassword)
        $templateInputTable.Add('aseCertData',$aseCertData)
        $templateInputTable.Add('asePfxBlobString',$asePfxBlobString)
        $templateInputTable.Add('asePfxPassword',$asePfxPassword)
        $templateInputTable.Add('aseCertThumbprint',$aseCertThumbprint)
        $templateInputTable.Add('bastionHostAdministratorUserName','bastionadmin')
        $templateInputTable.Add('bastionHostAdministratorPassword',$newPassword)
        $templateInputTable.Add('sqlAdministratorLoginUserName','sqladmin')
        $templateInputTable.Add('sqlAdministratorLoginPassword',$newPassword)
        $templateInputTable.Add('sqlThreatDetectionAlertEmailAddress',$sqlTDAlertEmailAddress)
        $templateInputTable.Add('customHostName',$customHostName)
        $templateInputTable.Add('azureAdApplicationClientId',$azureAdApplicationClientId)
        $templateInputTable.Add('azureAdApplicationClientSecret',$newPassword)        
        $templateInputTable.Add('azureAdApplicationObjectId',$azureAdApplicationObjectId)
        $templateInputTable.Add('sqlAdAdminUserName',$sqlAdAdminUserName)
        $templateInputTable.Add('sqlAdAdminUserPassword',$newPassword)
        $templateInputTable | Sort-Object Name  | Format-Table -AutoSize -Wrap -Expand EnumOnly 
        Write-Host -ForegroundColor Green "`n########################### Template Input Parameters - End ###########################"

        Write-Host -ForegroundColor Green "`n########################### Other Deployment Details - Start ###########################"
        $outputTable = New-Object -TypeName Hashtable
        $outputTable.Add('tenantId',$tenantID)
        $outputTable.Add('subscriptionId',$subscriptionID)
        $outputTable.Add('receptionistUserName',$receptionistUserName)
        $outputTable.Add('receptionistPassword',$newPassword)
        $outputTable.Add('passwordValidityPeriod',$passwordValidityPeriod)
        $outputTable | Sort-Object Name  | Format-Table -AutoSize -Wrap -Expand EnumOnly 

        #Merging the Two Tables 
        $MergedtemplateoutputTable = $templateInputTable + $outputTable

        Write-Host -ForegroundColor Green "`n########################### Other Deployment Details - End ###########################`n"

        ## Store deployment output to CloudDrive folder else to Output folder.
        if (Test-Path -Path "$HOME\CloudDrive") {
            Write-Host "CloudDrive was found. Saving deploymentOutput.json to CloudDrive.."
            $MergedtemplateoutputTable | ConvertTo-Json | Out-File -FilePath "$HOME\CloudDrive\deploymentOutput.json"
            Write-Host "Output file has been generated - $HOME\CloudDrive\deploymentOutput.json." -ForegroundColor Green
        }
        Else {
            Write-Host "CloudDrive was not found. Saving deploymentOutput.json to Output folder.."
            $MergedtemplateoutputTable | ConvertTo-Json | Out-File -FilePath "$outputFolderPath\deploymentOutput.json"
            Write-Host "Output file has been generated - $outputFolderPath\deploymentOutput.json." -ForegroundColor Green
        }
    }


####################  End of Script ###############################
