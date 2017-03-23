$subscriptionID = 'c53e6ef0-cc4c-4a73-be8f-00c5d97812e8'
	Try  
	{  
		Get-AzureRmContext -ErrorAction Continue  
	}  
	Catch [System.Management.Automation.PSInvalidOperationException]  
	{  
		 #Add-AzureRmAccount 
		$sub = Login-AzureRmAccount -SubscriptionId $subscriptionID
        Add-AzureRmAccount -SubscriptionId $subscriptionID -TenantId $sub.Context.Tenant.TenantId
	} 

$sub = Get-AzureRmSubscription -SubscriptionId $subscriptionID | Select-AzureRmSubscription

$wafToASEHttpRule = New-AzureRmNetworkSecurityRuleConfig -Name allow-wafHttp -Description "RESTRICT HTTP" -Direction Inbound -Priority 100 -Access Allow -SourceAddressPrefix '10.0.2.0/24'  -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '80' -Protocol 'TCP' 
$wafToASEHttpsRule = New-AzureRmNetworkSecurityRuleConfig -Name allow-wafHttps -Description "RESTRICT HTTPS" -Direction Inbound -Priority 100 -Access Allow -SourceAddressPrefix '10.0.2.0/24'  -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '443' -Protocol 'TCP' 


Get-AzureRmNetworkSecurityGroup -Name "nsg-generic" -ResourceGroupName '001-ASC-guru' | | Set-AzureRmNetworkSecurityGroup
Get-AzureRmNetworkSecurityGroup -Name "nsg-generic" -ResourceGroupName '001-ASC-guru' | Add-AzureRmNetworkSecurityRuleConfig -Name "RESTRICT HTTPS" -Direction Inbound -Priority 300 -Access Allow -SourceAddressPrefix '10.0.2.0/24'  -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '443' -Protocol 'TCP' | Set-AzureRmNetworkSecurityGroup

#Get-AzureRmNetworkSecurityGroup -Name "nsg-generic" | Set-AzureRmNetworkSecurityRuleConfig -Description "RESTRICT HTTPS" -Type Inbound -Priority 300 -Action Allow -SourceAddressPrefix '10.0.2.0/24'  -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '443' -Protocol TCP
Update-Module -Force

Uninstall-Module -Name 'AzureADPreview'

