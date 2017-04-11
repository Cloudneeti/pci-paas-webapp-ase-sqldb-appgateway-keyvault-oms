Set-ExecutionPolicy RemoteSigned;

############################################################
# Install Azure Resource Manager Powershell Modules
############################################################
    if (-not (Get-Module -Name AzureRM)) 
    { 
        Install-Module AzureRM -AllowClobber;
        Write-Host "Installed AzureRM Module"
    }

############################################################
# Install Azure Active Directory Powershell Modules
############################################################
    if (-not (Get-Module -Name AzureAD)) 
    { 
        Install-Module AzureAD -AllowClobber;
        Write-Host "Installed AzureAD Module"
    }

    if (-not (Get-Module -Name AzureADPreview)) 
    {
        Install-Module AzureADPreview -AllowClobber
        Import-Module AzureADPreview
        Write-Host "Installed ADPreview Module"
    }

############################################################
# Install Auditing and OMS Powershell Modules
############################################################
# 
    if (-not (Get-Module -Name Enable-AzureRMDiagnostics)) 
    {
        Install-Script -Name Enable-AzureRMDiagnostics -Force;
        Install-Module -Name Enable-AzureRMDiagnostics
        Write-Host "Installed Enable-AzureRMDiagnostics Module"
    }
    if (-not (Get-Module -Name AzureDiagnosticsAndLogAnalytics)) 
    {
        Install-Script -Name AzureDiagnosticsAndLogAnalytics -Force;
        Install-Module -Name AzureDiagnosticsAndLogAnalytics
        Write-Host "Installed AzureDiagnosticsAndLogAnalytics Module"
    }


############################################################
# Install SQL Server Powershell Modules
############################################################
# Test Import SQL Server Modules. If this fails, please follow deployment guide for installing SQL Server Client components
    
    if (-not (Get-Module -Name SqlServer)) 
    {
        Write-Host "SQL Powershell Modules not available. Please follow deployment guide for installing SQL Server Client components and powershell modules will get installed along with it."
    }
   
Read-Host "Check if there were any errors. Please follow deployment guide for missing modules and installation steps"
