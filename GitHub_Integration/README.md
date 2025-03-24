# Configuring GitHub Integration for Backup of Fabric/Power BI

Initial Setup Doco by Microsoft:  
https://learn.microsoft.com/en-us/fabric/cicd/git-integration/intro-to-git-integration?tabs=azure-devops#supported-items
https://learn.microsoft.com/en-us/fabric/cicd/git-integration/intro-to-git-integration?tabs=github#supported-items
https://learn.microsoft.com/en-us/fabric/cicd/git-integration/git-get-started?tabs=github%2CGitHub%2Ccommit-to-git

Background...
This document provides some suggestions and personally adopted rules that were noted during a recent Premium Capacity Remapping / Region change. Use it to enhance your own planning, but know that it doesn't fit everyone's needs.  It mentions 

Extra rules when using GitHub Integration for backup & recovery...
1. Don't leave workspace GitHub connections until the last days. You want to start weeks in advance and allow for up to 2 hours for each workspace to be connected and synced. This is especially true for workspaces with dozens of objects or workspaces that include various unsupported object types.
2. Keep the Main (default) branch empty.  No changes to main can be allowed for this multi-branch method to work successfully.
	- even the ReadMe.md file shouldn't have been there. Alternatively, limit the README.md file to be a link to a OneNote paragraph. (This allows for inclusion of dynamic text to be included when displayed inside GitHub, without causing changes to be tracked inside GitHub.)
3. Create a branch (off of main) for each workspace, named after the workspace.
	- Character restrictions apply to the naming, so have a character replacement system in mind
	- Such as: space >> underscore(_); square brackets ([,]) >> percent(%)
4. Keep folder name blank (unused) unless you preplan to merge many workspaces into one workspace in the new environment.
5. For best results, ensure the user configuring GitHub is the same user who controls most of the objects in the workspace.  This is because credentials and gateway configurations are encrypted using the user account's private key.
6. Also remember that GitHub Integration doesn't backup any workspace or App configurations.

## Troubleshooting
The initial sync operation might timeout and either give an error message or show spinning wheel indefinitely.  When this happens, use a new browser window to open the branch contents list in the GitHub site. You can see if any or all objects have successfully been pushed. Simply understand that GitHub enforces a limit to the amount of activity over time (throttling)
If an error message states there are too many objects to sync in one operation, you need to use the checkboxes to commit 5-10 objects at a time.  Sometimes you might find that it's the validation step that takes too long and causes the timeout.

There are some rare situations when a commit/sync operation will fail due to an unexpected issue with a specific object.  When this occurs, you have no choice but to selectively commit objects until you can isolate which object to avoid. This can happen for models that are too old for Power BI to convert to pbip folders, too large/complex, or related to this known issue: https://learn.microsoft.com/en-au/fabric/known-issues/known-issue-966-sync-content-git-workspace-fails?wt.mc_id=fabric_inproduct_knownissues.  You might find that these objects can still be synced later - they just need to be selected for commit by themselves.

Another common error occurs when you have two objects with the same name inside the workspace. If this happens you'll simply need to rename one of them and try committing/connecting to GitHub again.


# Configuring GitHub Integration for Restore of Fabric/Power BI (after remapping / capacity recreated)

Observations showed that using GitHub Integration to restore, generally works well.  Many exceptions apply however.  Objects are restored automatically, but refresh of semantic models is required and Dataflows need to be recreated from exported json files.  For best results, ensure the person performing GitHub Integration configuration is the same account used that owned/controlled the datasets.  Credentials and some other configs are encrypted by user key, so configuration (incl. creds) of datasets is performed upon restore if the account/user is the same.

Before doing any workspace restorations, ensure you have your Gateways reconfigured to the new region and include all necessary database connections.  GitHub Integration used as a restoration tool, works best if you reference exactly the same server and database names as configured before - including the same case.  Also, don't forget to provide the right people with user access to the connections. Naming of the connection aliases to be the same, is only beneficial if a bot (like Power Automate) was used to set the semantic model gateways to a specific dropdown value.


## Order of steps to rebuild each workspace
Notes / Instructions for restore:
 
### Dataflow source…  (follow these steps only if you have a dataflow as a data source, per workspace)
	1. Prepare the dataflow json file.
		a. Open the file in Notepad++ or editor of choice.
		b. Locate the property "allowNativeQueries" and change the value to false.
		c. Save and close the file.
	2. Starting with your central dataflow workspace, create new Dataflow Gen 1, using the Import option to browse your machine for the relevant json export file.
		a. Give it a Sensitivity Label
		b. Also in settings, turn on Enhanced Compute (if you had it turned on beforehand and reference it from a semantic model).
		c. Check that credentials are fine and that it refreshes successfully (if you've turned on Enhanced Compute just now, ensure you refresh after making that change - it seems to be a necessary thing)
Follow these supplementary steps if you use the deployment pipeline for your central dataflow workspace...
	3. Deploy to Test - Use the deployment pipeline to deploy the dataflow from [Dev] to [Test]
		a. Recommend setting comment to "Initial Deploy"
	4. If previously used, Configure Deployment Rules for the [Test] space.
	5. Deploy (again) to Test
		a. Recommend setting comment to "Applying deployment rules"
	6. Open the dataflow in [Test] and…
		a. Set / check credentials
		b. Remove any canary queries (and remove any final steps from queries that refer to incremental refresh)
		c. Save & Close, and refresh when asked (a button appears at the top right)
		d. Continue to next steps when the refresh is successful
	7. Deploy to Prod
	8. In Prod…
		a. Check the credentials carried (are okay),
		b. In settings, set Enhanced Compute to ON (if you had it turned on beforehand and reference it from a semantic model).
		c. Refresh
		d. Take note of the GUID for this dataflow
	9. If incremental refresh was previously configured, reconfigure it now.
		
### New Workspace…
	1. Get GitHub ready for sync, by performing GitHub surgery on the *.tmdl files inside the respective branch for this workspace.
		a. Pull the relevant branch or clone the repo locally if not yet done so
		b. Remember to take a backup of the folder just in case you make a mistake in the following surgery steps. The next couple of steps are a suggestion only, for making the process smoother due to changes to GUID references. Editing tmdl files comes with risks. I don't accept responsibility for problems arising from modifications to repo files.
		c. Remove any folders in the branch that pertain to objects requiring dependant sources that don't exist yet. If this is difficult to determine now, you can come back to it later after Microsoft advises you which objects can't be created due to dependencies.
		c. Use Notepad++ to perform the following "Find in Files" (CTRL-H) replacements to *.tmdl files…
		[previous workspace guid] >> [new workspace guid]
		[previous dataflow guid] >> [new dataflow guid]
		Surrounding the GUIDs with double quotes can also help with accuracy. You can also use "GitHub surgery" to perform any other in-place reference fixes.
		d. Commit and sync to Github
	2. Connect the new workspace to GitHub (performed by the same person who configured GitHub backups and/or controlled most of the objects in the original workspace)
		a. As mentioned in the Troubleshooting section for backup, you might encounter problems such as GitHub throttling, be prevented from syncing too many objects in one go, or if one/some of the objects in the repo are invalid (esp. if a mistake was made while performing the GitHub surgery using Notepad++) https://learn.microsoft.com/en-au/fabric/known-issues/known-issue-966-sync-content-git-workspace-fails?wt.mc_id=fabric_inproduct_knownissues.
	3. Refresh each model/dataset.  If any errors occur it might require manual setup of credentials/gateway, more surgery or you might decide to remove them completely for now.
	4. Run your Power Automate flows or automation scripts for reconfiguring semantic models, incl. RLS memberships and refresh schedules.
