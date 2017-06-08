	$ErrorActionPreference = 'Stop'
	Set-ExecutionPolicy RemoteSigned;
	Write "Installing Modules if not already installed.."

	############################################################
	# Install Azure Resource Manager Powershell Modules
	############################################################
	If (Get-Module -ListAvailable -Name AzureRM*) 
	{Get-Module -ListAvailable -Name AzureRM* | Import-Module -NoClobber -Force }
	Else{Install-Module AzureRM -AllowClobber; Write-Host "Installed AzureRM Module"}

	############################################################
	# Install Azure Active Directory Powershell Modules
	############################################################

	If (Get-Module -ListAvailable -Name AzureAD) 
	{Get-Module -ListAvailable -Name AzureAD | Import-Module -NoClobber -Force }
	Else{Install-Module AzureAD -AllowClobber; Write-Host "Installed AzureAD Module"}	
	############################################################
	# Install Auditing and OMS Powershell Modules
	############################################################
	# 

	If (!(Get-InstalledScript -Name Enable-AzureRMDiagnostics)) 
	{Install-Script -Name Enable-AzureRMDiagnostics -Force}

	If (Get-Module -ListAvailable -Name AzureDiagnosticsAndLogAnalytics) 
	{Get-Module -ListAvailable -Name AzureDiagnosticsAndLogAnalytics | Import-Module -Force }
	Else{Install-Module AzureDiagnosticsAndLogAnalytics -AllowClobber; Write-Host "Installed AzureDiagnosticsAndLogAnalytics Module"}

	############################################################
	# Install SQL Server Powershell Modules
	############################################################
	# Test Import SQL Server Modules. If this fails, please follow deployment guide for installing SQL Server Client components
    
	If (Get-Module -ListAvailable -Name SqlServer) 
	{Get-Module -ListAvailable -Name SqlServer | Import-Module -Force }
	Else{ Install-Module -Name SqlServer -AllowClobber; Write "Installed SqlServer Module. Please follow deployment guide for missing modules and installation steps."
	}	
