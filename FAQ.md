# FAQ AND FIXES

#### I can't seem to be able to log in, or run the PowerShell scripts with my Subscription user? 
> You require to create an AAD admin as identified in the document. This is required as a subscription admin does not automatically receive DS or AAD credentials. This is a security feature that enables RBAC and role separation in Azure.
#### Why do I need to add my subscription administrator to the AAD Admin role?
>Role based access control requires that a administrator grants themselfs administrative rights in AAD. Refer to this blog for a detailed explaination.
> [Delegating Admin Rights in Microsoft Azure](https://www.petri.com/delegating-admin-rights-in-microsoft-azure)
> [PowerShell - Connecting to Azure Active Directory using Microsoft Account](http://stackoverflow.com/questions/29485364/powershell-connecting-to-azure-active-directory-using-microsoft-account)
#### What should I do if my SSL pxf files is not working?
> Consider reviewing the following artiles, and blogs.
> [How to install a SSL certification on Azure](https://www.ssl.com/how-to/install-a-ssl-certificate-on-a-microsoft-azure-web-appwebsite-and-cloud-service/)
> [Web sites configuring SSL certificate](https://docs.microsoft.com/en-us/azure/app-service-web/web-sites-configure-ssl-certificate)
#### Why do I required a paid Azure account to use this solution?
> Many of the features used in the solution are not available in an Azure trial account. You will also require to have access to manage the subscription as a [Subscription Admins role and co-administrator of the subscription](https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles#global-administrator).
#### Why do I need an SSL certificate?
> The installation requires a custom domain and SSL certificate to meet PCI DSS requirements and protect the client side traffic from snooping. Microsoft
recommends that a custom domain be purchased with [an SSL package](https://d.docs.live.net/7b2b5032e10686e1/Azure%20Compliance/PCI%20DSS%20quickstart/1.%09https:/docs.microsoft.com/en-us/azure/app-service-web/web-sites-purchase-ssl-web-site).
Microsoft offers the ability to create a domain and request an SSL certificate from a Microsoft partner.
#### Why do I need local admin rights to run the `./pre-post-deployment` script ?
> PowerShell modules require elivated privileges to install service modules on your PC. This solution provides several scripts, and commands to verify that all the modules are installed, in the 'Client software requirements' section of the deployment guide.
#### Why do Application gateway backend health status showing `unhealthy` ?
> This deployment assumes that VIP address [ASE ILB >> Properties >> Virtual IP Address] assinged to ASE ILB would be 10.0.3.8 (observed behaviour). However, it might get changed to 10.0.3.9. If  the application gateway backend health is listed as `un-healthy`, verify that ASE ILB VIP address and application backend pool targets are same. Update the application gateway backend pool targets with ASE ILB VIP. (https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-create-gateway-portal#add-servers-to-backend-pools)
#### How do I set up the administrator properly to use this solution.
> Review the 'Configure your global admin for the solution' section of the installation guide
#### I get a script failed, error. User permission error. Insuficient permission error?
> Review 'LOGGING INTO POWERSHELL WITH CORRECT CREDENTIALS' section of the installation guide
#### The ARM template fails to run because of my password complexity?
> **NOTE**: Strong passwords **(Minimum 15 characters, with Upper and Lower case letters, at least 1 number and 1 special character)** are recommended throughout the solution.
#### The ARM template fails to deploy `xxxxxxxx` service
> Currently this solution requires that you deploy in US EAST. Limitation to service avalibility in all regions may prevent the solution from deploying storage accounts, or the AES. This solution was tested with the following resource group `New-AzureRmResourceGroup -Name [RESOURCE GROUP NAME] -Location "East US"`
#### The deployment of my services is taking a long time (over two hours), is that normal?
> The total deployment of the services is estimated to take approximately 1.5 hours from when the you select **Purchase** on the ARM template. ASE takes 2 hours to provision.
[How to deploy ASE](http://www.bizbert.com/bizbert/2016/01/07/AppServiceEnvironmentsHowToDeployAPIAppsToAVirtualNetwork.aspx)
#### How do I use this solution in my production deployment, environment?
> This solution including the scripts, template, and documentation are designed to help you build a pilot or demo site. Utilizing this solution does not provide a customer ready to run solution, it only illustrates the components required to build for a secure and compliant end to end solution. For instance, Custom Host Names, SSL Certificates, Virtual network address spacing, NSG routing, existing Storage and Databases, existing enterprise-wide OMS workspaces and solutions, Key vault rotation policies, usage of existing AD Admins and RBAC roles, usage of existing AD Applications and Service Principals will require customization and change to meet your custom production ready solution.


# AZURE MARKETPLACE - 3RD PARTY GUIDANCE
The following Azure Marketplace products are recommendations to help you achieve and manage continuous compliance  

| Security Layer                           	| Azure Marketplace Product(s)                                                                                                                                         	|
|------------------------------------------	|----------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| Continuous Compliance Monitoring         	| [CloudNeeti - Continuous Governance of Azure Assets](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/cloudneeti.cloudneeti_enterpise?tab=Overview)     	|
| Network Security and Management      	| [Azure Marketplace: Network Security](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/category/networking?page=1)                                     	|
| Extending Identity Security           	| [Azure Marketplace: Security + Identity](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/category/security-identity?page=1)                           	|
| Extending Monitoring and Diagnostics 	| [Azure Marketplace: Monitoring + Diagnostics](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/category/monitoring-management?page=1&subcategories=monitoring-diagnostics) 	|

 

# SUPPORT PROCESS

This blueprint is maintained in three repositories, one private, and two public. For a consutation/demo/workshop, contact your Microsoft account representative.  Avyan Consulting team provided the development of this solution, any questions or concerns contact. azurecompliance@avyanconsulting.com **Developed under MIT licensing**

The current version of the blueprint is avalible in preview, and no stable build has been commited. Please check back frequently for updates for the official release of this solution.
The next version pre-release, fixes and updates are located at [Avyan Consulting Git Repo](https://github.com/AvyanConsultingCorp/pci-paas-webapp-ase-sqldb-appgateway-keyvault-oms/)


  ![](images/deploy.png)
  
  