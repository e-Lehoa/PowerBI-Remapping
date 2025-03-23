## Set-up
## Import Power BI if not installed yet
Import-Module MicrosoftPowerBIMgmt

## Connect to Power BI each time - use PowerShell in 'run as Administrator' mode
Connect-PowerBIServiceAccount

#Login-PowerBI

$today = Get-Date -Format "yyyyMMdd"
## Change path as required
$path = "..\OneDrive\Power BI Backups\"

## Add user running the script
$currentUser = "[principal id or access email]"

#--------------------------------------------------
# run functions - Workspace returns Workspace names, users, and roles when exported to json 
$workspaces = Get-PowerBIWorkspace -Scope Organization -All

## JSON Format for workspaces
# Convert the data to JSON format
$jsonData = $workspaces | ConvertTo-Json -Depth 10

# Export the JSON data to a file
$jsonData | Out-File -FilePath $path"\Exports\PowerBIWorkspaces-"$today".json"

# Export to csv for point of difference in file format
$workspaces | Export-Csv -Path $path"\Exports\PowerBIWorkspaceData-"$today".csv" -NoTypeInformation
# Write-Output $path"PowerBIWorkspaceData-"$today".csv"

#--------------------------------------------------
# export PBI asset details
$reports = Get-PowerBIReport -Scope Organization
$reports | Export-Csv -Path $path"\Exports\PowerBIReports-"$today".csv" -NoTypeInformation

## export json format
$jsonReports = $reports | ConvertTo-Json -Depth 10
$jsonReports | Out-File -FilePath $path"\Exports\PowerBIReports-"$today".json"

#--------------------------------------------------
## export dataflows
$dataflows = Get-PowerBIDataflow -Scope Organization
$dataflows | Export-Csv -Path $path"\Dataflow Exports\PowerBIDataflows-"$today".csv" -NoTypeInformation

## Loop to export dataflow source information
foreach($dataflow in $dataflows){

    $dfName = $dataflow.Name
    $dfSource = Get-PowerBIDataflowDatasource -Scope Organization -DataflowId $dataflow.DataflowId
    $dfSource | Export-Csv -Path $path"\Dataflow Exports\PowerBIDataflows-"$dfName"-"$today".csv" -NoTypeInformation
}

#--------------------------------------------------
## export datasets
$datasets = Get-PowerBIDataset -Scope Organization
$datasets | Export-Csv -Path $path"\Datasets Exports\PowerBIDatasets-"$today".csv" -NoTypeInformation

$datasetDataSourceList = [System.Collections.Generic.List[PSCustomObject]]::new()

## export data source - uses dataset id
$datasets = Get-PowerBIDataset -Scope Organization
$totalDatasets = $datasets.Count
$currentDataset = 0

$datasets | ForEach-Object {

    $currentDataset++
    Write-Progress -Activity "Processing Datasets" -Status "Processing dataset $currentDataset of $totalDatasets" -PercentComplete (($currentDataset / $totalDatasets) * 100)

    $datasources = Get-PowerBIDatasource -DatasetId $_.Id -Scope Organization

    if($datasources){

        $datasources | ForEach-Object{

        $datasetDataSourceInfo = [PSCustomObject]@{
        DatasetId = $_.Id
        DatasetName = $_.Name
        DatasetConfiguredBy = $_.ConfiguredBy
        DatasetWebUrl = $_.WebUrl
        DatasourceId = $_.DatasourceId
        DatasourceName = $_.Name
        DatasourceType = $_.DatasourceType
        DatasourceConnectionString = $_.ConnectionString
        DatasourceConnectionDets = $_.ConnectionDetails
        DatasourceGatewayId = $_.GatewayId 

            }

            $datasetDataSourceList.Add($datasetDataSourceInfo) | Out-Null
            }
        } else {
            
            $datasetDataSourceInfo = [PSCustomObject]@{
            DatasetId = $_.Id
            DatasetName = $_.Name
            DatasetConfiguredBy = $_.ConfiguredBy
            DatasetWebUrl = $_.WebUrl
            DatasourceId = $null
            DatasourceName = $null
            DatasourceType = $null
            DatasourceConnectionString = $null
            DatasourceConnectionDets = $null
            DatasourceGatewayId = $null 

        }

        $datasetDataSourceList.Add($datasetDataSourceInfo) | Out-Null

            } 
        }
    
        if($datasetDataSourceList.Count -gt 0){
        
        $datasetDataSourceList | Export-Csv -Path $path"\Datasets Exports\PowerBIDatasource-"$today".csv" -NoTypeInformation
        
        } else { 
        Write-Host "Nada una vez"
        }


#--------------------------------------------------
## Loop to check access and export workspaces
# export all pbix files
# Function to check and add Admin access if needed

function Ensure-AdminAccess {
    param (
        [string]$workspaceId,
        [string]$userPrincipalName = "[add identity]"
    )

    $adminAccess = Get-PowerBIWorkspace -WorkspaceId $workspaceId | Where-Object { $_.UserPrincipalName -eq $userPrincipalName -and $_.AccessRight -eq 'Admin' }
    if (-not $adminAccess) {
        Add-PowerBIWorkspaceUser -Scope Organization -WorkspaceId $workspaceId -UserPrincipalName $userPrincipalName -AccessRight Admin
        return $true
    }
    return $false
}



## Add Exceptions, if required.
#$except = @("workspace ID1", "workspace ID2)


## add counter
$totalWorkspaces = $workspaces.Count
$currentWorkspace = 0
$nReports = Get-PowerBIReport -Scope Organization
$totalReports = $nReports.Count
$currentReports = 0

# Loop through each workspace and get reports
foreach ($workspace in $workspaces) {

    $currentWorkspace++
    $currentReports++
    Write-Progress -Activity "Processing Reports" -Status "Processing dataset $currentReports of $totalReports in $workspace.Name (n workspaces = $currentWorkspace of $totalWorkspaces)"

    # if($except -contains $workspace.Id){
    # Write-Host "Skipping UniSQIC Workspace"
    # continue
    # }

    # Ensure the user has Admin access
    $wasAdminAdded = Ensure-AdminAccess -workspaceId $workspace.Id -userPrincipalName $currentUser

    $reports = Get-PowerBIReport -Scope Organization -WorkspaceId $workspace.Id
    foreach ($report in $reports) {

        # Export the report
        $originalFileName = $report.Name
        $cleanFileName = $originalFileName -replace '[\\/:*?"&,<>|]', ''

        $PBIXexportPath = $path+"PBIX Exports\"+$workspace.Name+"-"+$cleanFileName+"-"+$today+".pbix"
        Export-PowerBIReport -Id $report.Id -OutFile $PBIXexportPath
        
        # Output the report details
         [PSCustomObject]@{
            ReportName = $report.Name
            ReportId = $report.Id
            WorkspaceName = $workspace.Name
            WorkspaceId = $workspace.Id
            ExportPath = $exportPath
        }
    }

    # Remove Admin access if it was added
    #if ($wasAdminAdded) {
    #    Remove-PowerBIWorkspaceUser -WorkspaceId $workspace.Id -UserPrincipalName $currentUser
    #}
}



# Create an array to hold extracted data
$data = @()

# Loop through each workspace and extract the required fields
foreach ($workspace in $workspaces) {
    if ($workspace.Users) {
        foreach ($user in $workspace.Users) {
            $data += [PSCustomObject]@{
                WorkspaceID = $workspace.Id
                WorkspaceName = $workspace.Name
                WorkspaceDescription = $workspace.Description
                WorkspaceType = $workspace.Type
                WorkspaceState = $workspace.State
                WorkspaceIsReadOnly = $workspace.IsReadOnly
                UserAccessRight = $user.AccessRight
                UserIdentifier = $user.Identifier
                UserPrincipalType = $user.PrincipalType
                # UserAccessed = $workspace.Users. - No access parameters anymore due to ActivityEvent defined by date
            }
        }
    }
}

$data | Export-Csv -Path $path"Exports\PowerBIWorkspaceUserData-"$today".csv" -NoTypeInformation

$jsonData = $data | ConvertTo-Json -Depth 10

$jsonData | Out-File -FilePath $path"Exports\PowerBIWorkspaceUserData-"$today".json"




#--------------------------------------------------
## Export PDFs - PDFs are not opening!!!
foreach ($workspace in $workspaces) {
    # Add the user as an administrator to the workspace
    Add-PowerBIWorkspaceUser -Scope Organization -Id $workspace.Id -UserPrincipalName $currentUser -AccessRight Admin

    # Get all reports in the workspace
    $reports = Get-PowerBIReport -WorkspaceId $workspace.Id

    foreach ($report in $reports) {

        # Export the report to PDF
        $pdfPath = $path+"PDF Exports\"+$workspace.Name+"-"+$report.Name+"-"+$today+".pdf"
        Export-PowerBIReport -Id $report.Id -OutFile $pdfPath

    }
}


