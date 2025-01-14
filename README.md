﻿Stop / Start all or only tagged Azure VMs
=========================================

            

**DESCRIPTION**


This PowerShell Runbook (compatible with PowerShell Core) connects to Azure using an Automation Run As account, retrieves the power status of VMs and turns off / on in sequence those that are turned on / off. You can attach a recurring schedule to this runbook
 to run it at a specific time.


**REQUIRED**


1. An Automation connection asset called AzureRunAsConnection that contains the information for connecting with Azure using a service principal. To use an asset with a different name you can pass the asset name as a input parameter to this runbook.


2. An Action input parameter value that allows runbook to handle VMs power state. The parameter must be set to 'Stop' or 'Start'.


3. All the following PowerShell modules are required to run the cmdlets : Az.Accounts, Az.Resources, Az.Compute and Az.Automation.


**OPTIONAL**


3. A TagName input parameter value that allows scoping the VMs to only tagged VMs.


4. A TagValue input parameter value that allows scoping the VMs to a particular tag value.


**AUTHOR**


Farouk FRIHA


**LAST EDIT**


2021-17-11


**RELEASE NOTES**


2019-19-05 First release

2019-19-05 Handle changes to parameters

2021-16-11 Corrected issue in line 21, changed parameter shutdown to bolean and adjust variables

2021-17-11 Rollback changed parameter to string and add comment to help when create schedule


**RUNBOOK CONTENT**


** **


** **

** **




 


        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
