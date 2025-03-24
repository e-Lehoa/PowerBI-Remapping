##
## Create Workspaces
## Set-up
## Import Power BI if not installed yet
Import-Module MicrosoftPowerBIMgmt

## Connect to Power BI each time - use PowerShell in 'run as Administrator' mode
Connect-PowerBIServiceAccount


## Change path as required
$path = "Set up\"

## import the csv which lists the new WorkspaceName per row to be created

$workspaceCsv = Import-Csv -Path $path"New-Workspaces.csv"

# Loop through each row in the CSV and create a Power BI workspace
foreach ($workspace in $workspaceCsv) {

    $workspaceName = $workspace.WorkspaceName
    # Create Power BI workspace
    New-PowerBIWorkspace -Name $workspaceName
}



# Import the CSV file containing admins with 2 columns: WorkspaceName & userPrincipalName

$adminCsv = Import-Csv -Path $path"Admins.csv"

$workspaces = Get-PowerBIWorkspace -Scope Organization -All

# iterate through list to add admins
foreach ($admin in $adminCsv) {

    $workspaceName = $admin.WorkspaceName
    $user = $admin.userPrincipalName
    Add-PowerBIWorkspaceUser -WorkspaceName $workspaceName -userPrincipalName $user -Role Admin
}
