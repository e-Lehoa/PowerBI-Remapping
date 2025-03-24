### Borrows part of script from https://github.com/chris1642 on: 

## https://github.com/chris1642/Power-BI-Backup-Impact-Analysis-Governance-Solution/blob/main/Final%20PS%20Script.txt


# Define the base folder and script paths at the beginning of the script

$baseFolderPath = "[add a path here]"


# Enter Workspace ID between quotation marks if you only want script to run in 1 or 2 workspaces. Leave BOTH empty if you want to loop through all.

$SpecificWorkspaceID1 = ""  # Replace with your actual workspace ID or leave empty and the script will loop through every workspace

$SpecificWorkspaceID2 = ""  # Replace with your actual workspace ID or leave empty and the script will loop through every workspace

$ErrorActionPreference = "SilentlyContinue"



# Connect to the Power BI Service
function Connect-PowerBI {
    Connect-PowerBIServiceAccount
    $global:accessTokenObject = Get-PowerBIAccessToken
    $global:accessToken = $accessTokenObject.Authorization -replace 'Bearer ', ''
    # Write the access token to a temporary file
    Set-Content -Path $env:TEMP\PowerBI_AccessToken.txt -Value $global:accessToken
}

# Track script start time
$scriptStartTime = Get-Date
Connect-PowerBI

# Function to refresh the token in a background job
function Start-TokenRefreshJob {
    $jobScript = {
        function Connect-PowerBI {
            Connect-PowerBIServiceAccount
            $global:accessTokenObject = Get-PowerBIAccessToken
            $global:accessToken = $accessTokenObject.Authorization -replace 'Bearer ', ''
            # Write the access token to a temporary file
            Set-Content -Path $env:TEMP\PowerBI_AccessToken.txt -Value $global:accessToken
        }
        while ($true) {
            Start-Sleep -Seconds 3300  # Sleep for 55 minutes
            Connect-PowerBI
        }
    }
    Start-Job -ScriptBlock $jobScript -Name "TokenRefreshJob"
}

# Start the background job to refresh the token
Start-TokenRefreshJob

# Function to get the current access token
function Get-CurrentAccessToken {
    $global:accessToken = Get-Content -Path $env:TEMP\PowerBI_AccessToken.txt
    return $global:accessToken
}

# Create a variable date
$date = (Get-Date -UFormat "%Y-%m-%d")








#### Start of Power BI Environment Detail Extract ####


# Define the Information Extract Excel file path
$excelFile = "$baseFolderPath\Power BI Environment Detail.xlsx"

# Function to rename properties in objects and handle duplicates
function Rename-Properties {
    param ($object, $renameMap)
    $newObject = New-Object PSObject
    foreach ($originalName in $renameMap.Keys) {
        $newPropertyName = $renameMap[$originalName]
        $propertyValue = if ($object.PSObject.Properties[$originalName]) { $object.$originalName } else { $null }
        if ($newObject.PSObject.Properties[$newPropertyName]) { $newPropertyName += "_duplicate" }
        $newObject | Add-Member -MemberType NoteProperty -Name $newPropertyName -Value $propertyValue
    }
    foreach ($property in $object.PSObject.Properties) {
        if (-not $renameMap.ContainsKey($property.Name)) {
            $newObject | Add-Member -MemberType NoteProperty -Name $property.Name -Value $property.Value
        }
    }
    return $newObject
}

# Define renaming maps for each type of object
$workspaceRenameMap = @{
    "id" = "WorkspaceId";
    "name" = "WorkspaceName";
    "isReadOnly" = "WorkspaceIsReadOnly";
    "isOnDedicatedCapacity" = "WorkspaceIsOnDedicatedCapacity";
    "capacityId" = "WorkspaceCapacityId";
    "defaultDatasetStorageFormat" = "WorkspaceDefaultDatasetStorageFormat";
    "type" = "WorkspaceType"
}

$datasetRenameMap = @{
    "id" = "DatasetId";
    "name" = "DatasetName";
    "webUrl" = "DatasetWebUrl";
    "addRowsAPIEnabled" = "DatasetAddRowsAPIEnabled";
    "configuredBy" = "DatasetConfiguredBy";
    "isRefreshable" = "DatasetIsRefreshable";
    "isEffectiveIdentityRequired" = "DatasetIsEffectiveIdentityRequired";
    "isEffectiveIdentityRolesRequired" = "DatasetIsEffectiveIdentityRolesRequired";
    "isOnPremGatewayRequired" = "DatasetIsOnPremGatewayRequired";
    "targetStorageMode" = "DatasetTargetStorageMode";
    "queryScaleOutSettings" = "DatasetQueryScaleOutSettings";
    "createdDate" = "DatasetCreatedDate"
}

$datasetDatasourceRenameMap = @{
    "datasourceType" = "DatasetDatasourceType";
    "datasourceId" = "DatasetDatasourceId";
    "gatewayId" = "DatasetDatasourceGatewayId";
    "connectionDetails" = "DatasetDatasourceConnectionDetails"
}

$dataflowDatasourceRenameMap = @{
    "datasourceType" = "DataflowDatasourceType";
    "datasourceId" = "DataflowDatasourceId";
    "gatewayId" = "DataflowDatasourceGatewayId";
    "connectionDetails" = "DataflowDatasourceConnectionDetails"
}

$datasetRefreshRenameMap = @{
    "requestId" = "DatasetRefreshRequestId";
    "id" = "DatasetRefreshId";
    "startTime" = "DatasetRefreshStartTime";
    "endTime" = "DatasetRefreshEndTime";
    "status" = "DatasetRefreshStatus";
    "refreshType" = "DatasetRefreshType"
}

$dataflowRefreshRenameMap = @{
    "requestId" = "DataflowRefreshRequestId";
    "id" = "DataflowRefreshId";
    "startTime" = "DataflowRefreshStartTime";
    "endTime" = "DataflowRefreshEndTime";
    "status" = "DataflowRefreshStatus" ;
    "refreshType" = "DataflowRefreshType" ;
    "errorInfo" = "DataflowErrorInfo"
}

$dataflowRenameMap = @{
    "configuredBy"      = "DataflowConfiguredBy";
    "description"       = "DataflowDescription";
    "modelUrl"         = "DataflowJsonURL";
    "modifiedBy"       = "DataflowModifiedBy";
    "modifiedDateTime" = "DataflowModifiedDateTime";
    "name"             = "DataflowName";
    "objectId"         = "DataflowId";
    "generation" = "DataflowGeneration"
}

$dataflowLineageRenameMap = @{
    "datasetObjectId"   = "DatasetId";
    "dataflowObjectId"  = "DataflowId";
    "workspaceObjectId" = "WorkspaceId"
}

$reportRenameMap = @{
    "id" = "ReportId";
    "name" = "ReportName";
    "webUrl" = "ReportWebUrl";
    "embedUrl" = "ReportEmbedUrl";
    "isFromPbix" = "ReportIsFromPbix";
    "isOwnedByMe" = "ReportIsOwnedByMe";
    "datasetId" = "DatasetId";
    "datasetWorkspaceId" = "DatasetWorkspaceId";
    "reportType" = "ReportType"
}

$pageRenameMap = @{
    "name" = "PageName";
    "displayName" = "PageDisplayName";
    "order" = "PageOrder"
}

$appRenameMap = @{
    "id" = "AppId";
    "name" = "AppName";
    "lastUpdate" = "AppLastUpdate";
    "description" = "AppDescription";
    "publishedBy" = "AppPublishedBy";
    "workspaceId" = "AppWorkspaceId";
    "users" = "AppUsers"
}

$appReportRenameMap = @{
    "id" = "AppReportId";
    "reportType" = "AppReportType";
    "name" = "ReportName";
    "webUrl" = "AppReportWebUrl";
    "embedUrl" = "AppReportEmbedUrl";
    "isOwnedByMe" = "AppReportIsOwnedByMe";
    "datasetId" = "AppReportDatasetId";
    "originalReportObjectId" = "ReportId";
    "users" = "AppUsers";
    "subscriptions" = "AppReportSubscriptions";
    "sections" = "AppReportSections"
}

# Fetch and filter workspaces
$workspacesUrl = "https://api.powerbi.com/v1.0/myorg/groups"
$workspacesResponse = Invoke-PowerBIRestMethod -Method GET -Url $workspacesUrl | ConvertFrom-Json
$workspacesInfo = @()

foreach ($workspace in $workspacesResponse.value) {
    # Check if we should use specific workspace IDs for filtering
# If only SpecificWorkspaceID1 is provided, filter on that alone
if ($SpecificWorkspaceID1 -and -not $SpecificWorkspaceID2 -and $workspace.id -ne $SpecificWorkspaceID1) {
    continue
}
# If only SpecificWorkspaceID2 is provided, filter on that alone
elseif ($SpecificWorkspaceID2 -and -not $SpecificWorkspaceID1 -and $workspace.id -ne $SpecificWorkspaceID2) {
    continue
}
# If both workspace IDs are provided, filter based on either ID
elseif ($SpecificWorkspaceID1 -and $SpecificWorkspaceID2 -and 
        ($workspace.id -ne $SpecificWorkspaceID1 -and $workspace.id -ne $SpecificWorkspaceID2)) {
    continue
}
    # Add the workspace to workspacesInfo if it passes the checks
    $workspacesInfo += Rename-Properties -object $workspace -renameMap $workspaceRenameMap
}

# Initialize collections for all necessary information
$datasetsInfo = @()
$datasetSourcesInfo = @()
$reportsInfo = @()
$reportPagesInfo = @()
$appsInfo = @()
$reportsInAppInfo = @()
$datasetNameLookup = @{}
$datasetRefreshHistory = @()


# Loop through filtered workspaces
foreach ($workspace in $workspacesInfo) {
    # Fetch datasets
    $datasetsUrl = "https://api.powerbi.com/v1.0/myorg/groups/$($workspace.WorkspaceId)/datasets"
    $datasets = Invoke-PowerBIRestMethod -Method GET -Url $datasetsUrl | ConvertFrom-Json

    foreach ($dataset in $datasets.value) {
        $renamedDataset = Rename-Properties -object $dataset -renameMap $datasetRenameMap
        $renamedDataset | Add-Member -NotePropertyName "WorkspaceId" -NotePropertyValue $workspace.WorkspaceId -Force
        $renamedDataset | Add-Member -NotePropertyName "WorkspaceName" -NotePropertyValue $workspace.WorkspaceName -Force
        
    # Store the DatasetId and DatasetName in the lookup table
        $datasetNameLookup[$dataset.id] = $dataset.name
        $datasetsInfo += $renamedDataset

        # Fetch dataset sources
        $datasourcesUrl = "https://api.powerbi.com/v1.0/myorg/groups/$($workspace.WorkspaceId)/datasets/$($dataset.id)/datasources"
        $datasources = Invoke-PowerBIRestMethod -Method GET -Url $datasourcesUrl | ConvertFrom-Json

        foreach ($datasource in $datasources.value) {
            $renamedDatasource = Rename-Properties -object $datasource -renameMap $datasetDatasourceRenameMap
            $renamedDatasource | Add-Member -NotePropertyName "WorkspaceId" -NotePropertyValue $workspace.WorkspaceId -Force
            $renamedDatasource | Add-Member -NotePropertyName "WorkspaceName" -NotePropertyValue $workspace.WorkspaceName -Force
            $renamedDatasource | Add-Member -NotePropertyName "DatasetId" -NotePropertyValue $dataset.id -Force
            $renamedDatasource | Add-Member -NotePropertyName "DatasetName" -NotePropertyValue $dataset.name -Force
            if ($datasource.connectionDetails) {
                $renamedDatasource.DatasetDatasourceConnectionDetails = $datasource.connectionDetails | ConvertTo-Json -Compress
            }
            $datasetSourcesInfo += $renamedDatasource
        }
    }

    # Fetch reports
    $reportsUrl = "https://api.powerbi.com/v1.0/myorg/groups/$($workspace.WorkspaceId)/reports"
    $reports = Invoke-PowerBIRestMethod -Method GET -Url $reportsUrl | ConvertFrom-Json

	# Create a hash set to store Report IDs
	$reportIds = @{}

    foreach ($report in $reports.value) {
        $renamedReport = Rename-Properties -object $report -renameMap $reportRenameMap
        $renamedReport | Add-Member -NotePropertyName "WorkspaceId" -NotePropertyValue $workspace.WorkspaceId -Force
        $renamedReport | Add-Member -NotePropertyName "WorkspaceName" -NotePropertyValue $workspace.WorkspaceName -Force


        # Retrieve and add the correct DatasetName from the lookup table if DatasetId exists
        $datasetId = $report.datasetId
        if ($datasetId -and $datasetNameLookup.ContainsKey($datasetId)) {
            $renamedReport | Add-Member -NotePropertyName "DatasetName" -NotePropertyValue $datasetNameLookup[$datasetId] -Force
        } else {
            $renamedReport | Add-Member -NotePropertyName "DatasetName" -NotePropertyValue "Unknown Dataset" -Force
        }

        $reportsInfo += $renamedReport

        # Fetch report pages
        $pagesUrl = "https://api.powerbi.com/v1.0/myorg/groups/$($workspace.WorkspaceId)/reports/$($report.id)/pages"
        $pages = Invoke-PowerBIRestMethod -Method GET -Url $pagesUrl | ConvertFrom-Json
        foreach ($page in $pages.value) {
            $renamedPage = Rename-Properties -object $page -renameMap $pageRenameMap
            $renamedPage | Add-Member -NotePropertyName "WorkspaceId" -NotePropertyValue $workspace.WorkspaceId -Force
            $renamedPage | Add-Member -NotePropertyName "WorkspaceName" -NotePropertyValue $workspace.WorkspaceName -Force
            $renamedPage | Add-Member -NotePropertyName "ReportId" -NotePropertyValue $report.id -Force
            $renamedPage | Add-Member -NotePropertyName "ReportName" -NotePropertyValue $report.name -Force
            $reportPagesInfo += $renamedPage

            # Store the report ID in the hash set
            $reportIds[$report.id] = $true
        }
    }
}

# Fetch Apps and App Reports that are in filtered workspaces
$appsUrl = "https://api.powerbi.com/v1.0/myorg/apps"
$apps = Invoke-PowerBIRestMethod -Method GET -Url $appsUrl | ConvertFrom-Json

# Create a hash set to store App Report IDs
$appReportIds = @{}
$originalReportObjectIds = @{}

foreach ($app in $apps.value) {
    if ($workspacesInfo.WorkspaceId -contains $app.workspaceId) {
        $renamedApp = Rename-Properties -object $app -renameMap $appRenameMap
        $appsInfo += $renamedApp

        # Fetch reports within each app
        $appReportsUrl = "https://api.powerbi.com/v1.0/myorg/apps/$($app.id)/reports"
        $appReports = Invoke-PowerBIRestMethod -Method GET -Url $appReportsUrl | ConvertFrom-Json

        foreach ($report in $appReports.value) {
            $renamedAppReport = Rename-Properties -object $report -renameMap $appReportRenameMap
            $renamedAppReport | Add-Member -NotePropertyName "AppId" -NotePropertyValue $app.id -Force
            $renamedAppReport | Add-Member -NotePropertyName "AppName" -NotePropertyValue $app.name -Force
            $reportsInAppInfo += $renamedAppReport

            # Store the app report ID in the hash set
            $appReportIds[$report.id] = $true
            $originalReportObjectIds[$report.originalReportObjectId] = $true
        }
    }
}


# Fetch Refresh History for Datasets
foreach ($workspace in $workspacesInfo) {
    foreach ($dataset in $datasetsInfo | Where-Object { $_.WorkspaceId -eq $workspace.WorkspaceId }) {
        $refreshHistoryUrl = "https://api.powerbi.com/v1.0/myorg/groups/$($workspace.WorkspaceId)/datasets/$($dataset.DatasetId)/refreshes"
        $refreshHistoryResponse = Invoke-PowerBIRestMethod -Method GET -Url $refreshHistoryUrl | ConvertFrom-Json

        foreach ($refresh in $refreshHistoryResponse.value) {
            $renamedRefreshRecord = Rename-Properties -object $refresh -renameMap $datasetRefreshRenameMap
            $renamedRefreshRecord | Add-Member -NotePropertyName "WorkspaceId" -NotePropertyValue $workspace.WorkspaceId -Force
            $renamedRefreshRecord | Add-Member -NotePropertyName "WorkspaceName" -NotePropertyValue $workspace.WorkspaceName -Force
            $renamedRefreshRecord | Add-Member -NotePropertyName "DatasetId" -NotePropertyValue $dataset.DatasetId -Force
            $renamedRefreshRecord | Add-Member -NotePropertyName "DatasetName" -NotePropertyValue $dataset.DatasetName -Force

            $datasetRefreshHistory += $renamedRefreshRecord
        }
    }
}  







#### Start of 'My Workspace' detail extract ####

# Check if either variable is filled out, if so, skip this section
if (-not $SpecificWorkspaceID1 -and -not $SpecificWorkspaceID2) {

# Define "My Workspace" constants
$myWorkspaceId = "My Workspace"
$myWorkspaceName = "My Workspace"

# Manually add "My Workspace" breakdown to workspacesInfo
$myWorkspaceDetails = [PSCustomObject]@{
    WorkspaceId                 = $myWorkspaceId
    WorkspaceName               = $myWorkspaceName
    WorkspaceType               = "Workspace"
    WorkspaceIsReadOnly         = $false
    WorkspaceIsOnDedicatedCapacity = $false
}
$workspacesInfo += $myWorkspaceDetails

# Fetch datasets from "My Workspace"
$myWorkspaceDatasetsUrl = "https://api.powerbi.com/v1.0/myorg/datasets"
$myWorkspaceDatasets = Invoke-PowerBIRestMethod -Method GET -Url $myWorkspaceDatasetsUrl | ConvertFrom-Json

foreach ($dataset in $myWorkspaceDatasets.value) {
    $renamedDataset = Rename-Properties -object $dataset -renameMap $datasetRenameMap
    $renamedDataset | Add-Member -NotePropertyName "WorkspaceId" -NotePropertyValue $myWorkspaceId -Force
    $renamedDataset | Add-Member -NotePropertyName "WorkspaceName" -NotePropertyValue $myWorkspaceName -Force

    # Store the DatasetId and DatasetName in the lookup table
    $datasetNameLookup[$dataset.id] = $dataset.name
    $datasetsInfo += $renamedDataset

    # Fetch dataset sources
    $datasourcesUrl = "https://api.powerbi.com/v1.0/myorg/datasets/$($dataset.id)/datasources"
    $datasources = Invoke-PowerBIRestMethod -Method GET -Url $datasourcesUrl | ConvertFrom-Json

    foreach ($datasource in $datasources.value) {
        $renamedDatasource = Rename-Properties -object $datasource -renameMap $datasetDatasourceRenameMap
        $renamedDatasource | Add-Member -NotePropertyName "WorkspaceId" -NotePropertyValue $myWorkspaceId -Force
        $renamedDatasource | Add-Member -NotePropertyName "WorkspaceName" -NotePropertyValue $myWorkspaceName -Force
        $renamedDatasource | Add-Member -NotePropertyName "DatasetId" -NotePropertyValue $dataset.id -Force
        $renamedDatasource | Add-Member -NotePropertyName "DatasetName" -NotePropertyValue $dataset.name -Force
        if ($datasource.connectionDetails) {
            $renamedDatasource.DatasetDatasourceConnectionDetails = $datasource.connectionDetails | ConvertTo-Json -Compress
        }
        $datasetSourcesInfo += $renamedDatasource
    }
}

# Fetch reports from "My Workspace"
$myWorkspaceReportsUrl = "https://api.powerbi.com/v1.0/myorg/reports"
$myWorkspaceReports = Invoke-PowerBIRestMethod -Method GET -Url $myWorkspaceReportsUrl | ConvertFrom-Json

# Flag to track if any shared report exists
$sharedReportExists = $false

foreach ($report in $myWorkspaceReports.value) {
    # Skip reports that exist in either the Report list or the App Report list
    if ($appReportIds.ContainsKey($report.id) -or $reportIds.ContainsKey($report.id) -or $originalReportObjectIds.ContainsKey($report.id)) {
        continue
    }

    # Check if the report is owned by me
    if ($report.isOwnedByMe -eq $false) {
        $workspaceIdValue = "Shared Reports (No Workspace Access)"
        $workspaceNameValue = "Shared Reports (No Workspace Access)"
        $sharedReportExists = $true  # Set flag if a shared report is found
    } else {
        $workspaceIdValue = $myWorkspaceId
        $workspaceNameValue = $myWorkspaceName
    }

    $renamedReport = Rename-Properties -object $report -renameMap $reportRenameMap
    $renamedReport | Add-Member -NotePropertyName "WorkspaceId" -NotePropertyValue $workspaceIdValue -Force
    $renamedReport | Add-Member -NotePropertyName "WorkspaceName" -NotePropertyValue $workspaceNameValue -Force

    # Retrieve and add the correct DatasetName from the lookup table if DatasetId exists
    $datasetId = $report.datasetId
    if ($datasetId -and $datasetNameLookup.ContainsKey($datasetId)) {
        $renamedReport | Add-Member -NotePropertyName "DatasetName" -NotePropertyValue $datasetNameLookup[$datasetId] -Force
    } else {
        $renamedReport | Add-Member -NotePropertyName "DatasetName" -NotePropertyValue "Unknown Dataset" -Force
    }

    $reportsInfo += $renamedReport

    # Fetch report pages
    $pagesUrl = "https://api.powerbi.com/v1.0/myorg/reports/$($report.id)/pages"
    $pages = Invoke-PowerBIRestMethod -Method GET -Url $pagesUrl | ConvertFrom-Json
    foreach ($page in $pages.value) {
        $renamedPage = Rename-Properties -object $page -renameMap $pageRenameMap
        $renamedPage | Add-Member -NotePropertyName "WorkspaceId" -NotePropertyValue $workspaceIdValue -Force
        $renamedPage | Add-Member -NotePropertyName "WorkspaceName" -NotePropertyValue $workspaceNameValue -Force
        $renamedPage | Add-Member -NotePropertyName "ReportId" -NotePropertyValue $report.id -Force
        $renamedPage | Add-Member -NotePropertyName "ReportName" -NotePropertyValue $report.name -Force
        $reportPagesInfo += $renamedPage
    }
}

# After processing all reports, add a single row to workspacesInfo if at least one shared report exists

if ($sharedReportExists) {
    # Define "Shared Reports (My Workspace)" constants
    $sharedWorkspaceId = "Shared Reports (No Workspace Access)"
    $sharedWorkspaceName = "Shared Reports (No Workspace Access)"

    # Add one entry to workspacesInfo for all shared reports
    $sharedWorkspaceDetails = [PSCustomObject]@{
        WorkspaceId                 = $sharedWorkspaceId
        WorkspaceName               = $sharedWorkspaceName
        WorkspaceType               = "Workspace"
        WorkspaceIsReadOnly         = $false
        WorkspaceIsOnDedicatedCapacity = $false
    }
    $workspacesInfo += $sharedWorkspaceDetails
}



# Add refresh history for each dataset in "My Workspace"
foreach ($dataset in $datasetsInfo | Where-Object { $_.WorkspaceId -eq $myWorkspaceId }) {
    $refreshHistoryUrl = "https://api.powerbi.com/v1.0/myorg/datasets/$($dataset.DatasetId)/refreshes"
    $refreshHistoryResponse = Invoke-PowerBIRestMethod -Method GET -Url $refreshHistoryUrl | ConvertFrom-Json

    foreach ($refresh in $refreshHistoryResponse.value) {
        # Rename properties based on the map and dynamically include dataset context
        $renamedRefreshRecord = Rename-Properties -object $refresh -renameMap $datasetRefreshRenameMap
        $renamedRefreshRecord | Add-Member -NotePropertyName "WorkspaceId" -NotePropertyValue $myWorkspaceId -Force
        $renamedRefreshRecord | Add-Member -NotePropertyName "WorkspaceName" -NotePropertyValue $myWorkspaceName -Force
        $renamedRefreshRecord | Add-Member -NotePropertyName "DatasetId" -NotePropertyValue $dataset.DatasetId -Force
        $renamedRefreshRecord | Add-Member -NotePropertyName "DatasetName" -NotePropertyValue $dataset.DatasetName -Force

        $datasetRefreshHistory += $renamedRefreshRecord
	    }
	}
    } else {
	Write-Host "Skipping 'My Workspace' processing because Specific Workspace ID is provided."
}

$today = Get-Date -Format "yyyyMMdd"

$excelFile = "\Final Audit Exports\"


$workspacesInfo | Export-Csv -Path $excelFile"workspacesInfo-"$today".csv"

$datasetsInfo | Export-Csv -Path $excelFile"datasetsInfo-"$today".csv"

$datasetSourcesInfo | Export-Csv -Path $excelFile"datasetSourcesInfo-"$today".csv"

$datasetRefreshHistory | Export-Csv -Path $excelFile"datasetRefreshHistory-"$today".csv"

$reportsInfo | Export-Csv -Path $excelFile"reportsInfo-"$today".csv"

$reportPagesInfo | Export-Csv -Path $excelFile"reportPagesInfo-"$today".csv"

$appsInfo | Export-Csv -Path $excelFile"appsInfo-"$today".csv"

$reportsInAppInfo | Export-Csv -Path $excelFile"reportsInAppInfo-"$today".csv"


 






#### Start of Model Backup ####



# Loop through datasetsInfo collection to perform model export
foreach ($dataset in $datasetsInfo) {
    $workspaceName = $dataset.WorkspaceName -replace '\[', '%5B' -replace '\]', '%5D' -replace ' ', '%20'
    $datasetId = $dataset.DatasetId
    $datasetName = $dataset.DatasetName

    # Clean up workspace name
    $cleanDatasetWorkspaceName = $dataset.WorkspaceName -replace '\[', '(' -replace '\]', ')'
    $cleanDatasetWorkspaceName = $cleanDatasetWorkspaceName -replace "[^a-zA-Z0-9\(\)&,.-]", " "
    $cleanDatasetWorkspaceName = $cleanDatasetWorkspaceName.TrimStart()

    # Clean up dataset name
    $cleanDatasetName = $datasetName -replace '\[', '(' -replace '\]', ')'
    $cleanDatasetName = $cleanDatasetName -replace "[^a-zA-Z0-9\(\)&,.-]", " "
    $cleanDatasetName = $cleanDatasetName.TrimStart()

    # Construct the folder path and create it if it doesn't exist
    $modelBackupsPath = "\Models Backup"


    if (-not (Test-Path $modelBackupsPath)) {
        New-Item -ItemType Directory -Force -Path $modelBackupsPath
    }

    # Construct the date model backup folder path and create it if it doesn't exist
    $folderPath = "Models Backup"
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Force -Path $folderPath
    }

    # Define the new model database name
    $newModelDatabaseName = "$cleanDatasetWorkspaceName ~ $cleanDatasetName"

    # Create the C# script to rename the Model.Database.Name
    $csharpScript = @"
Model.Database.Name = `"$newModelDatabaseName`";
"@

    # Save the C# script to a temporary file
    $tempScriptPath = [System.IO.Path]::GetTempFileName()
    $tempScriptPath = [System.IO.Path]::ChangeExtension($tempScriptPath, ".cs")
    Set-Content -Path $tempScriptPath -Value $csharpScript

    # Construct the argument list for the model export with renaming
    $modelExportArgs = "`"Provider=MSOLAP;Data Source=powerbi://api.powerbi.com/v1.0/myorg/$workspaceName;Password=$(Get-CurrentAccessToken)`" $datasetId -S `"$tempScriptPath`" -B `"$folderPath\$cleanDatasetWorkspaceName ~ $cleanDatasetName.bim`""
    
    # Start the Tabular Editor process for model export and renaming
    Start-Process -FilePath "$TabularEditor2Path" -Wait -NoNewWindow -PassThru -ArgumentList $modelExportArgs

    # Clean up the temporary script file
    Remove-Item -Path $tempScriptPath
	
}








#### Start of Report Backup ####


$baseFolderPath = "[add path here]"


# Define the report backups path
$reportBackupsPath = Join-Path -Path $baseFolderPath -ChildPath "Report Backups"

# Check if the base folder exists, if not create it
if (-not (Test-Path -Path $baseFolderPath)) {
    New-Item -Path $baseFolderPath -ItemType Directory -Force
}

# Check if the "Report Backups" folder exists, if not create it
if (-not (Test-Path -Path $reportBackupsPath)) {
    New-Item -Path $reportBackupsPath -ItemType Directory -Force
}

# Create a new sub folder for the date
$newDateFolder = Join-Path -Path $reportBackupsPath -ChildPath $date
if (-not (Test-Path -Path $newDateFolder)) {
    New-Item -Path $newDateFolder -ItemType Directory -Force
}

# Define the temporary extraction folder
$tempExtractFolder = "$baseFolderPath\Config\Temp"

# Check if the temp extract folder exists, if not create it
if (-not (Test-Path -Path $tempExtractFolder)) {
    New-Item -Path $tempExtractFolder -ItemType Directory -Force
}

foreach ($workspace in $workspacesInfo) {
    $workspaceName = $workspace.WorkspaceName
    $workspaceId = $workspace.WorkspaceId

    # Clean up workspace name
    $cleanWorkspaceName = $workspaceName -replace '\[', '(' -replace '\]', ')'
    $cleanWorkspaceName = $cleanWorkspaceName -replace "[^a-zA-Z0-9\(\)&,.-]", " "
    $cleanWorkspaceName = $cleanWorkspaceName.TrimStart()

    # Fetch reports from the existing list, NOT from Get-PowerBIReport
    $reports = $reportsInfo | Where-Object { $_.WorkspaceId -eq $workspaceId }

    # Export each report in the workspace
    foreach ($report in $reports) {

    $reportName = $report.ReportName
    $reportId = $report.ReportId

        # Clean up report name
        $cleanReportName = $reportName -replace '\[', '(' -replace '\]', ')'
        $cleanReportName = $cleanReportName -replace "[^a-zA-Z0-9\(\)&,.-]", " "
        $cleanReportName = $cleanReportName.TrimStart()

        # Determine the file extension based on the report type
        $fileExtension = if ($report.WebUrl -like "*/rdlreports/*") { "rdl" } else { "pbix" }
        $filename = "$cleanWorkspaceName ~ $cleanReportName.$fileExtension"
        $filepath = Join-Path -Path $newDateFolder -ChildPath $filename
        $extractFolder = Join-Path -Path $tempExtractFolder -ChildPath "$cleanWorkspaceName ~ $cleanReportName"

        # Check if the file exists and remove it if it does
        if (Test-Path $filepath) {
            Remove-Item $filepath -Force
        }

        Write-Output "Exporting $cleanWorkspaceName ~ $cleanReportName"
        Export-PowerBIReport -Id $reportId -OutFile $filepath

        # Only process model extraction if the Workspace is not Premium or Fabric Capacity (i.e. only Pro Workspaces)
    }
}



