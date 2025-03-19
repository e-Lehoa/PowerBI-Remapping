# PowerBI-Remapping
Power BI script to complete the re-mapping of Power BI tenants from one location (e.g. Singapore) to another (e.g. Australia). This is not the 'migration' process as outlined at https://learn.microsoft.com/en-us/fabric/known-issues/known-issue-923-tenant-migrations-paused-january-2025.

With assistance from the Microsoft Support Team, the re-mapping process involves the removal of the old tenant and creation of a new tenant in the preferred region. Power BI Tenant, Capacity, and Workspace Administrators are then required to recreate their Power BI set-up according to the organisation's needs and 're-map' Power BI assets (workspaces, semantic models, reports, etc) into the new tenant. This re-mapping exercise provides organisations with an opportunity to start afresh by removing old assets in bulk, then selectively re-adding assets back, as required. It further provides an opportunity to reconfigure Power BI according to an updated or refreshed governance framework structured by domains and sub-domains with workspaces assigned accordingly for a better browsing experience in OneLake or Microsoft Purview (if connected to the Fabric tenant). 

To be able to complete the remapping process successfully, a number of pre-requisites must and should be completed first. It is also recommended that a communications plan is developed and deployed to support staff across the organisation through the process, particularly where organisations have historically allowed users to create Workspaces or manage Capacities on their own rather than centrally. The pre-requisites listed below have been compiled from advice provided by the Microsoft Support Team, using references sourced from [Fabric Fundamentals](https://learn.microsoft.com/en-us/fabric/fundamentals/), [Power BI PowerShell Cmdlets](https://learn.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps), and [Fabric API](https://learn.microsoft.com/en-us/rest/api/fabric/admin/tenants/list-tenant-settings?tabs=HTTP), and from experience.


Microsoft Support Team - Awareness Points:

Customers will lose all their data, and all gateways to connect to data will need to be removed and reinstalled.
Microsoft Fabric Trial should end, and it is the customer responsibility to start a new trial in the new region.
Microsoft Fabric might not be available in all regions. [Per Fabric region availability, Fabric available in Australia East and Australia Southeast](https://learn.microsoft.com/en-us/fabric/admin/region-availability)
The customer removes all Power BI Premium capacities as they are not retained during the remap. The capacity admin will need to add them re-provision capacities as needed.
The customer removes all Microsoft Fabric capacities as they are not retained during the remap. The capacity admin will need to add them re-provision capacities as needed.
The customer needs to delete the Private Links, if any, before they request for Tenant Remap. Confirmation must be provided by the customer before acknowledging the remap request.
In post-remapping, customer logs back into Power BI, is authenticated via AAD, and the service will direct them to their new tenant in the Data Centre in the new location.
In post-remapping, customer: 
  1. starts a new capacity (check licensing too, if required),
  2. adds new gateways, workspaces, and Apps they may have been using,
  3. provisions access rights to users in capacities and workspaces,
  4. Rebuilds reports and dashboards,
  5. Re-shares links to reports and dashboards, as required.


Common Q&A:

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


Internal Preparations

1. Access the Feature Usage and Adoption Reports to gauge usage statistics and trends.
2. Identify Power Users and Capacity/Workspace Administrators who should be contacted early in order to plan back-up requirements. Workspace Users can also be extracted using the PowerShell Cmdlet in the PBI-Audit.ps1 script.
3. Edit and run PowerShell PBI-Audit.ps1 script to run back-up #1 of all assets and data. Make sure to test the script end-to-end before completing a final run and before completing the pre-requisite deletions for the remapping.
4. Script Git [David's code reference here] to run back-up #2 of all scripts and assets. Make sure to test the script end-to-end before completing a final run and before completing the pre-requisite deletions for the remapping.
5. Create communications plan with strategic points of communications, eg:
   - 3 months before re-mapping, send an individual/personalised preparation email;
   - 2 months before re-mapping, send video of process;
   - 1 month before re-mapping, confirm dates and process, particularly if there is a shutdown period or 'no more updates' period;
   - 1 week before re-mapping, send org-wide email stating that back-up process will start and confirm re-mapping downtime;
   - 1 day or week after re-mapping, send org-wide email confirming process completion and next steps to support users.  
7. Implement comms plan.
8. Script bulk re-creation of Workspaces & assign Admins to relevant staff, groups, or teams.


MS Process:

1. Customer Global Admin completes request/acknowledgement form and sends back to Microsoft through support ticket. O365 Global Admin must complete the form and upload the form, for security confirmation purposes. If the customer Global Admin is not the Org's Support Engineer, the customer's Support Engineer's details must be included as a contact. This person is responsible for re-installing the Gateways.
2. PBI back-end will validate information in request form and proceed with the re-mapping of the tenant on the desired date listed in request form.
3. If information is not verified, the form along with instructions on what additional information or clarifications needed will be sent to the Support Engineer for the customer.
4. Upon completion of the re-mapping, the Power BI back-end team will contact the Support Engineer and confirm that the work has been completed. Customer can verify that their tenant has been moved to the new geo-region by restarting their browser, clicking on the ? icon in the ribbon in Power BI, then clicking on About Power BI, and will be shown "Your data is stored in [name of data center]".
5. Customer to formally confirm the tenant re-mapping is visible with a screenshot of the About Power BI dialog box.


Internal Process - Post Re-mapping:
- Establish Gateways
- Check Admin Portal Configs: Change Workspace creation to only Admins
- Manually create workspaces and assign Admins to test functions, processes, and connections.
  
Cube-based Sources:
1. Reconnect Cubes
2. Open pbix and update M Query/link to data
3. Republish to new Workspace
4. Check Service functionalities, including assignment of user access.
5. Embed in SharePoint
   
DW Semantic Models:
1. Reconnect High Stakes Semantic Model
2. Open pbix and update M Query/link to data, and check for any DirectQuery connections. If there are DQ connections, they need to be relinked Transform data > Data source settings.
3. Republish to new Workspace
4. Check Service functionalities, including assignment of user access.
5. Embed in SharePoint.
   
SharePoint Sources:
1. Open pbix and update M Query/link to data
2. Republish to new Workspace
3. Check Service functionalities, including assignment of user access.
4. Embed in SharePoint.

Test and re-instate Fabric Git back-ups & scripts
Run PowerShell to create bulk Workspaces and assign Admins.




