# Power BI Remapping
Power BI preparations with scripts to complete the re-mapping of Power BI tenants from one location (e.g. Singapore) to another (e.g. Australia). This is not the 'migration' process as outlined at https://learn.microsoft.com/en-us/fabric/known-issues/known-issue-923-tenant-migrations-paused-january-2025.

**Update to include new Microsoft Remapping reference**

Microsoft have now published information about remapping tenants at https://learn.microsoft.com/en-us/power-bi/support/service-admin-region-move

With assistance from the Microsoft Support Team, the re-mapping process involves the removal of the old tenant and creation of a new tenant in the preferred region. Power BI Tenant, Capacity, and Workspace Administrators are then required to recreate their Power BI set-up according to the organisation's needs and 're-map' Power BI assets (workspaces, semantic models, reports, etc) into the new tenant. This re-mapping exercise provides organisations with an opportunity to start afresh by removing old assets in bulk, then selectively re-adding assets back, as required. It further provides an opportunity to reconfigure Power BI according to an updated or refreshed governance framework structured by domains and sub-domains with workspaces assigned accordingly for a better browsing experience in OneLake or Microsoft Purview (if connected to the Fabric tenant). 

To be able to complete the remapping process successfully, a number of pre-requisites must and should be completed first. It is also recommended that a communications plan is developed and deployed to support staff across the organisation through the process, particularly where organisations have historically allowed users to create Workspaces or manage Capacities on their own rather than centrally. 

The pre-requisites listed below have been compiled from experience, advice provided by the Microsoft Support Team, and using references sourced from: 
- [Fabric Fundamentals](https://learn.microsoft.com/en-us/fabric/fundamentals/), 
- [Power BI PowerShell Cmdlets](https://learn.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps), 
- [Fabric API](https://learn.microsoft.com/en-us/rest/api/fabric/admin/tenants/list-tenant-settings?tabs=HTTP), and
- https://github.com/chris1642/Power-BI-Backup-Impact-Analysis-Governance-Solution.


## Microsoft Support Team - Awareness Points:

- Customers will lose all their data, and all gateways to connect to data will need to be removed and reinstalled.
- Microsoft Fabric Trial should end, and it is the customer responsibility to start a new trial in the new region.
- Microsoft Fabric might not be available in all regions. [Per Fabric region availability, Fabric available in Australia East and Australia Southeast](https://learn.microsoft.com/en-us/fabric/admin/region-availability)
- The customer removes all Power BI Premium capacities as they are not retained during the remap. The capacity admin will need to add them re-provision capacities as needed.
- The customer removes all Microsoft Fabric capacities as they are not retained during the remap. The capacity admin will need to add them re-provision capacities as needed.
- The customer needs to delete the Private Links, if any, before they request for Tenant Remap. Confirmation must be provided by the customer before acknowledging the remap request.
- In post-remapping, customer logs back into Power BI, is authenticated via AAD, and the service will direct them to their new tenant in the Data Centre in the new location.
- In post-remapping, customer: 
    1. starts a new capacity (check licensing too, if required),
    2. adds new gateways, workspaces, and Apps they may have been using,
    3. provisions access rights to users in capacities and workspaces,
    4. Rebuilds reports and dashboards,
    5. Re-shares links to reports and dashboards, as required.
	6. Advises users to sign out of Power BI and clear browser cache.


### Common Q&A:

Q. May I pick specific hours and dates on which I want the remapping to occur?

  A. Yes and it's recommended. If you don't provide a date/time, the remapping can happen anytime within 2 or 3 working days after submitting the request form.
  
Q. How long will it take to complete the process?

  A. If you ask for a specific date and time, and the PBI back teams (Ship room) have acknowledged it, it will take between 1-3 hours.
  
Q. Will this affect my O365 subscription?

  A. No, this will only affect the Power BI subscriptions.
  
Q. Will this apply to all my Power BI subscriptions or may I keep some in their original location?

  A. No, this will apply to all Power BI subscriptions associated with the tenant.
  
Q. Will I lose all my Apps, datasets, data models, reports, and dashboards?

  A. Yes.
  
Q. Will I lose all the personal and enterprise gateways I have created to connect to my various data sources?

  A. Yes. All gateways associated with Power BI, PowerApps, Flow, and Logic Apps will need to be renewed after the re-mapping has been completed.
  
Q. Can I simply migrate my data myself?

  A. Yes, this process requires users to back-up or download data themselves. The "PBIX Download" feature may be able to provide a partial solution by allowing the saving of reports and datasets to a .pbix file. This file may then be uploaded to Power BI Desktop or reloaded back into a new Power BI tenant.  
  
  NOTE: Download of PBIX is only possible for the owner of the reports and datasets. If assets have been edited using Power BI Service or through Excel, they will not be downloadable and must be replicated using screenshots or re-created from scratch.
  
Q. How do I identify active reports?

  A. Using Feature usage and Adoption reports; using Power BI activity log to track user activities in Power BI, you can filter specific events like view report to check which reports are used in past one month; Metadata scanning overview is also a good tool to get basic information for all items in Power BI. 


## Internal Preparations

1. To be able to complete the auditing and back-ups in this process, a user must firstly be added to Fabric/Power BI as a Fabric Administrator or Power Platform Administrator, see https://learn.microsoft.com/en-us/fabric/admin/microsoft-fabric-admin#power-platform-and-fabric-admin-roles. 
2. Once the correct Admin roles have been provisioned, access the [Feature Usage and Adoption Reports](https://learn.microsoft.com/en-us/fabric/admin/feature-usage-adoption) to gauge usage statistics and trends.
3. Identify 'Power Users' and Capacity/Workspace Administrators who should be contacted early, in order to plan back-up and export requirements. Workspace Users can also be extracted using the PowerShell Cmdlet in the [01-PBI-Audit-Backup.ps1](https://github.com/e-Lehoa/PowerBI-Remapping/blob/main/01-PBI-Audit-Backup.ps1) script from lines 209-236. Alternatively, use the [02-PBI-GetUserLogs.ps1](https://github.com/e-Lehoa/PowerBI-Remapping/blob/main/02-PBI-GetUserLogs.ps1) script to extract all users' activities. A test run is included from lines 19-35.
4. Edit and run PowerShell [01-PBI-Audit-Backup.ps1](https://github.com/e-Lehoa/PowerBI-Remapping/blob/main/01-PBI-Audit-Backup.ps1) script to run back-up #1 of all Power BI assets and data. Make sure to test the script end-to-end before completing a final run and before completing the pre-requisite deletions for the remapping. Organisations with large numbers of assets will take longer to run the export components of the scripts, particularly for large PBIX and audit report exports.
   
     **NOTE:**
   - PBIX files can only be exported if they have been created and published from Power BI Desktop.
   - Reports created and edited in Power BI Service will not export automatically using PowerShell and cannot be saved using the Power BI Service *'Download this file'* feature. Those reports will need to be identified using a discrepancy analysis or a 'catch error' in PowerShell to inform owners that they will need to back-up (via screenshots or using the 'Export > PDF') and re-create those reports manually.
   - Power BI Service reports created using the [Publish to Power BI from Microsoft Excel](https://learn.microsoft.com/en-us/power-bi/connect-data/service-publish-from-excel) cannot be exported using PowerShell nor the Power BI Service *'Download this file'* feature. The 'Publish to Power BI from Microsoft Excel' feature is being deprecated by Microsoft, so users should be encouraged to avoid using this feature.
   - There may be other types of assets that cannot be backed-up or exported using PowerShell or GitHub, so users should be actively encouraged to take screenshots or use the Power BI Service export to PDF feature to help them rebuild (yes, from scratch!) within the re-mapped environment. Alternatively, use the re-mapping as an opportunity to work with users to update their Power BI assets to use supported Fabric/Power BI features.
     
5. If PBIX back-ups have been completed progressively and users are still creating new reports, run the [03-Get-Report-Discrepancy.ps1](https://github.com/e-Lehoa/PowerBI-Remapping/blob/main/03-Get-Report-Discrepancy.ps1) to identify the new reports that need to be exported. We did this because we didn't have a lock-down period in which the organisation were requested to not make further changes. We didn't have a lock-down period because we deemed it too onerous/disruptive on usual business.
6. Script Git https://github.com/e-Lehoa/PowerBI-Remapping/blob/main/GitHub_Integration/README.md to run back-up #2 of all Fabric scripts and assets. Make sure to test the script end-to-end before completing a final run and before completing the pre-requisite deletions for the remapping. Using GitHub Integration can be a good way to backup some objects that are otherwise not downloadable, such as reports created/copied inside of Service.
7. Create communications plan with strategic points of communications, eg:
   - 3 months before re-mapping, send an individual/personalised preparation email. In this email, we sent staff a personalised list of all their workspaces and assets where they are listed as an Admin or Contributor. We did this to ensure staff hadn't forgotten about historic workspaces and assets created;
   - 2 months before re-mapping, send video of process, e.g. [Power BI Data Migration](https://youtu.be/-LDiRyy0Ckg?si=uZ1MpAZXo-GTf3n8) **Note:** We deliberately called it a 'migration' with our users to simplify the message;
   - 1 month before re-mapping, confirm dates and process, particularly if there is a shutdown period or 'no more updates' period;
   - 1 week before re-mapping, send org-wide email stating that back-up process will start and confirm re-mapping downtime;
   - 1 day or week after re-mapping, send org-wide email/video confirming process completion and next steps to support users, e.g. [Power BI Migration Complete](https://youtu.be/EI7HGxVrGug?si=Rt2hfWI4eBI7ufSR).  
8. Implement comms plan and scripts. **NOTE:** we were informed about https://github.com/chris1642/Power-BI-Backup-Impact-Analysis-Governance-Solution/tree/main, a few days before our re-mapping was to occur, so used it as an alternative point of reference to the scripts already implemented. Based on this https://github.com/chris1642/Power-BI-Backup-Impact-Analysis-Governance-Solution/blob/main/Final%20PS%20Script.txt, we adjusted our own script to run a combined alternative [04-Final Export Script.ps1](https://github.com/e-Lehoa/PowerBI-Remapping/blob/main/04-Final%20Export%20Script.ps1)
9. Script bulk re-creation of Workspaces & assign Admins to relevant staff, groups, or teams. Refer to [05-Workspace-Admin-setUp.ps1](https://github.com/e-Lehoa/PowerBI-Remapping/blob/main/05-Workspace-Admin-setUp.ps1) for importing and creating the bulk workspaces.


## Microsoft Support Team Process:

1. Customer's Global Admin completes request/acknowledgement form and sends back to Microsoft through support ticket. O365 Global Admin must complete the form and upload the form, for security confirmation purposes. If the customer Global Admin is not the Org's Support Engineer, the customer's Support Engineer's details must be included as a contact. This person is responsible for re-installing the Gateways.
2. Power BI back-end team will validate information in request form and proceed with the re-mapping of the tenant on the desired date listed in request form.
3. If information is not verified, the form along with instructions on what additional information or clarifications needed will be sent to the Support Engineer for the customer.
4. Upon completion of the re-mapping, the Power BI back-end team will contact the Support Engineer and confirm that the work has been completed.
5. Customer can verify that their tenant has been moved to the new geo-region by restarting their browser, clicking on the ? icon in the ribbon in Power BI, then clicking on About Power BI, and will be shown "Your data is stored in [name of data center]".
6. Customer to formally confirm the tenant re-mapping is visible with a screenshot of the About Power BI dialog box.


## Internal Process - Post Re-mapping:
- Establish Gateways
- Check Admin Portal Configurations and re-instate according to organisation's needs. For example, Change Workspace creation to only Admins.
- Manually create workspaces and assign Admins to test functions, processes, and connections.
  
### Cube-based Sources:
1. Reconnect Cubes
2. Open pbix and update M Query/link to data
3. Republish to new Workspace
4. Check Service functionalities, including assignment of user access.
5. Embed in SharePoint
   
### On-Prem Data Warehouse Semantic Models:
1. Reconnect High Stakes Semantic Model
2. Open pbix and update M Query/link to data, and check for any DirectQuery connections. If there are DQ connections, they need to be relinked Transform data > Data source settings.
3. Republish to new Workspace
4. Check Service functionalities, including assignment of user access.
5. Embed in SharePoint.
   
### SharePoint Sources:
1. Open pbix and update M Query/link to data
2. Republish to new Workspace
3. Check Service functionalities, including assignment of user access.
4. Embed in SharePoint.

### Other:
Test and re-instate Fabric Git back-ups & scripts

Run PowerShell to create bulk Workspaces and assign Admins [05-Workspace-Admin-setUp.ps1](https://github.com/e-Lehoa/PowerBI-Remapping/blob/main/05-Workspace-Admin-setUp.ps1).

When Microsoft advises for users to sign out of Power BI, this doesn't only apply to the browser, but also is a must for desktop tools such as Power BI Report Builder (Paginated Report UI). If you don't sign out the "Add Power BI Semantic Model connection" applet will only list models from your old environment. Meaning, for example, workspaces will appear empty if they didn't exist in the old environment with the same name.


