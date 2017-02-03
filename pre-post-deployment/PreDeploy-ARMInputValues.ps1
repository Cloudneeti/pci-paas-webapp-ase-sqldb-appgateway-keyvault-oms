$DoaminName = "@avyanconsulting.onmicrosoft.com" #(Domain Name)
$ClientID = "49a49561-8391-439d-83f7-bee3494ee216" #(ClientID is from AAD application)


#------------------------------
Connect-MsolService

###
#Imp: This script need to run by Global Administror and in server
###

# Create User Object ID for Guru and Laxmi and use same in ARM deployment

New-MsolUser -UserPrincipalName "adadmin$DoaminName" -DisplayName "Administror" -FirstName "PCI" -LastName "Samples"
New-MsolUser -UserPrincipalName "sqladmin$DoaminName" -DisplayName "SQLAdmin" -FirstName "PCI" -LastName "Samples"
New-MsolUser -UserPrincipalName "user1$DoaminName" -DisplayName "User" -FirstName "PCI" -LastName "Samples"

$ADAdminObjectId = (Get-AzureRmADUser -UserPrincipalName "adadmin$DoaminName").id
$SQLAdminObjectId = (Get-AzureRmADUser -UserPrincipalName "sqladmin$DoaminName").id
$UserObjectId = (Get-AzureRmADUser -UserPrincipalName "user1$DoaminName").id
Write-Host 'AD Admin Object Id= '$ADAdminObjectId -foreground Red 
Write-Host 'SQL Admin Object Id= '$SQLAdminObjectId -foreground Red 
Write-Host 'User Object ID= '$UserObjectId -foreground Red 
# Get Application Object ID by passing client ID (ClientID is from AAD application)

$ApplicationObjectId = (Get-AzureRmADServicePrincipal -ServicePrincipalName $ClientID) 
Write-Host 'Application Object ID= '$ApplicationObjectId -foreground Red 