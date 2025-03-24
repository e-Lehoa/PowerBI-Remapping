## Import Power BI if not installed yet
Import-Module MicrosoftPowerBIMgmt

## Connect to Power BI each time - use PowerShell in 'run as Administrator' mode
Connect-PowerBIServiceAccount

# Load necessary modules
Import-Module ImportExcel

# Define the folder path
$folderPath = ".../PBIX Exports/"


# Get the list of files in the folder
$fileList = Get-ChildItem -Path $folderPath | Select-Object -ExpandProperty Name

# Create a DataTable to store file names and extracted information
$fileTable = New-Object System.Data.DataTable
$fileTable.Columns.Add("file_names", [string])
$fileTable.Columns.Add("reportName", [string])
$fileTable.Columns.Add("workspaceName", [string])

# Function to extract text based on the second last part of the file name
function Extract-Text {
    param ($fileName)
    $parts = $fileName -split "-"
    if ($parts.Length -ge 3) {
        return $parts[$parts.Length - 2]
    } else {
        return $null
    }
}

# Function to extract text based on the first part of the file name
function Extract-BeforeFirst {
    param ($fileName)
    $parts = $fileName -split "-"
    if ($parts.Length -ge 2) {
        return $parts[0]
    } else {
        return $null
    }
}

# Populate the DataTable with file names and extracted information
foreach ($fileName in $fileList) {
    $reportName = Extract-Text -fileName $fileName
    $workspaceName = Extract-BeforeFirst -fileName $fileName
    $row = $fileTable.NewRow()
    $row["file_names"] = $fileName
    $row["reportName"] = $reportName
    $row["workspaceName"] = $workspaceName
    $fileTable.Rows.Add($row)
}

# Export the DataTable to a CSV file
$csvFilePath = "/PBIX Exports-Files-$((Get-Date).ToString('yyyy-MM-dd')).csv"
$fileTable | Export-Csv -Path $csvFilePath -NoTypeInformation -Force




function Ensure-AdminAccess {
    param (
        [string]$workspaceId,
        [string]$userPrincipalName = "[add user name]"
    )

    $adminAccess = Get-PowerBIWorkspace -WorkspaceId $workspaceId | Where-Object { $_.UserPrincipalName -eq $userPrincipalName -and $_.AccessRight -eq 'Admin' }
    if (-not $adminAccess) {
        Add-PowerBIWorkspaceUser -Scope Organization -WorkspaceId $workspaceId -UserPrincipalName $userPrincipalName -AccessRight Admin
        return $true
    }
    return $false
}





# $currentUser = Add user running the script
$currentUser = "[add user name]"

$today = Get-Date -Format "yyyyMMdd"

## Change path as required
$path = "...\Data Estate\"


#--------------------------------------------------
# run functions - Workspace returns Workspace names, users, and roles when exported to json 
$workspaces = Get-PowerBIWorkspace -Scope Organization -All
$reportsall = Get-PowerBIReport -Scope Organization

$totalWorkspaces = $workspaces.Count
$currentWorkspace = 0
$nReports = 0
$totalReports = $reportsall.Count


## discrepancy to rerun the pbix export without doing the whole thing again...

# Initialize a list to hold the hash tables
$workspaceReports = [System.Collections.Generic.List[PSObject]]::new()

# Get the total number of workspaces and reports for progress tracking
$totalWorkspaces = $workspaces.Count
$totalReports = $reportsall.Count

# Initialize counters for progress tracking
$currentWorkspace = 0
$nReports = 0

foreach ($workspace in $workspaces) {
    $currentWorkspace++
    $wasAdminAdded = Ensure-AdminAccess -workspaceId $workspace.Id -userPrincipalName $currentUser

    # Get all reports in the current workspace
    $reports = Get-PowerBIReport -WorkspaceId $workspace.Id

    foreach ($report in $reports) {
        $nReports++
        if ($nReports % 10 -eq 0) { # Update progress every 10 reports
            Write-Progress -Activity "Processing Reports" -Status "Processing $nReports of $totalReports in $($workspace.Name) (workspaces: $currentWorkspace of $totalWorkspaces)"
        }

        $workspaceReports.Add([PSCustomObject]@{
            WorkspaceName = $workspace.Name
            ReportName    = $report.Name
            ReportId      = $report.Id
        })
    }
}


# Export the array to a CSV file
$workspaceReports | Export-Csv -Path $path"Exports\Workspaces-Reports-"$today".csv" -NoTypeInformation

## update the dates as needed
$completed = Import-Csv -Path $path"PBIX Exports\PBIX Exports-Files-2025-02-26.csv"

## update the dates as needed
$exported = Import-Csv -Path $path"Exports\Workspaces-Reports-20250227.csv"

$filteredReports = $exported | Where-Object { $_.ReportName -notin $completed.Name }
$filteredReports | Export-Csv -Path $path"Exports\DiscrepancyCheck-"$today".csv" -NoTypeInformation




## add counter
$totalReports = $filteredReports.Count
$currentReports = 0

# Loop through each workspace and get reports
foreach ($filteredReport in $filteredReports) {

    $currentReports++
    Write-Progress -Activity "Processing Reports" -Status "Processing dataset $currentReports of $totalReports"

        # Export the report
        $originalFileName = $filteredReport.ReportName
        $cleanFileName = $originalFileName -replace '[\\/:*?"&,<>|]', ''

        $PBIXexportPath = $path+"PBIX Exports\"+$filteredReport.WorkspaceName+"-"+$cleanFileName+"-"+$today+".pbix"
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


## final check - check all reports because Workspaces had Admin allocation errors.

$reports = Get-PowerBIReport -Scope Organization
$completed = Import-Csv -Path $path"PBIX Exports\PBIX Exports-Files-2025-02-27.csv"

foreach ($report in $reports) {
    $report | Add-Member -MemberType NoteProperty -Name CleanedNames -Value ($report.Name -replace '[\\/:*?"&,<>|]', '')
}

$filteredReports = $reports | Where-Object { $_.CleanedNames -notin $completed.reportName }
$filteredReports | Export-Csv -Path $path"Exports\DiscrepancyCheck-Final-"$today".csv" -NoTypeInformation

# Loop through each workspace and get reports
foreach ($filteredReport in $filteredReports) {

    $currentReports++
    Write-Progress -Activity "Processing Reports" -Status "Processing dataset $currentReports of $totalReports"

        # Export the report
        $originalFileName = $filteredReport.ReportName
        $cleanFileName = $originalFileName -replace '[\\/:*?"&,<>|]', ''

        $PBIXexportPath = $path+"PBIX Exports\"+$filteredReport.WorkspaceName+"-"+$cleanFileName+"-"+$today+".pbix"
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

