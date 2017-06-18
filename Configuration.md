# TABLE OF CONTENTS 
<!-- TOC -->
- <a href="Overview.md"> Solution Overview </a> 
- <a href="Configuration.md"> Configuration and setup for solution </a> 
- <a href="Payment processing solution.md"> The Payment Processing Solution (PCI)</a> 
- <a href="Payment Sample dataset.md"> Customer Samples, and monitoring</a> 
- <a href="FAQ.md"> Frequently Asked Questions </a> 


<!-- /TOC -->


# PRE DEPLOYMENT CONSIDERATIONS 

This section provides  information about items you will need during installation of the solution. These items ensures that account, and user access. 

**IMPORTANT**  The solution requires **a paid subscription** on Azure, a **trial** subscription account will not work, as many of the features used in this deployment are not available in an Azure trial account. You will also require to have access to manage the subscription as a [Subscription Admins role and co-administrator of the subscription](https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles#global-administrator).

>If you have not already done so, it is advisable to download, or clone a copy of solution.


### Using PCI Compliant SSL, vs Self-Signed SSL
 This solution can be deployed with a self-signed certificate for testing purpose (**Self-signed certificates will not meet PCI DSS compliance requirements**). 

>To use a self signed certificate - you can use the **certificatePath** switch, in the deployment script. 

Setting up a [custom domain with a DNS
record](https://docs.microsoft.com/en-us/azure/app-service-web/custom-dns-web-site-buydomains-web-app)
and a root domain can be configured in the [Azure
Portal](https://portal.azure.com/).

#### Custom domain, SSL certificate (Third party )
Microsoft recommends that a custom domain be purchased with [an SSL
package](https://d.docs.live.net/7b2b5032e10686e1/Azure%20Compliance/PCI%20DSS%20quickstart/1.%09https:/docs.microsoft.com/en-us/azure/app-service-web/web-sites-purchase-ssl-web-site).
Microsoft offers the ability to create a domain and request an SSL certificate
from a Microsoft partner.



## Local computer setup requirements

The local configuration of PowerShell will require that the installation script
be run with local admin privileges or remotely signed credentials to ensure that
local permissions do not prevent the installer from running correctly.

### Client software requirements

The following software applications and modules are required on the client
computer throughout the installation of this solution.

1.  [SQL Management
    Tools](https://msdn.microsoft.com/en-us/library/bb500441.aspx) to manage the
    SQL database.

2.  [Powershell
    version](https://msdn.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell)
    v5.x or greater. For example, in PowerShell you can use the following
    commands:

```powershell
    $PSVersionTable.psversion
```

0-Setup-AdministrativeAccountAndPermission.ps1 is an automated script to verify local configuration, and administrative right configuration.