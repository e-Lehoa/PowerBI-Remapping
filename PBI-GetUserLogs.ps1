## Initial Install set-up for first time run to install required modules

Install-Module -Name MicrosoftPowerBIMgmt -AllowClobber


## Alternatively, connect to Power BI each time - use PowerShell in 'run as Administrator' mode
Connect-PowerBIServiceAccount


$today = Get-Date -Format "yyyyMMdd"
## Change path as required
$path = "..\OneDrive\Power BI Backups\"

## Add user running the script
$currentUser = "[principal id or access email]"


#-----------------------------------------------------------------------
### test run
# add the numbers of days required to check:
$NbrOfDaysToCheck = 5

#Use today:
$DayUTC = (([datetime]::Today.ToUniversalTime()).Date)

#Iteratively loop through each of the last N days to view events:
For($LoopNbr=0; $LoopNbr -le $NbrOfDaysToCheck; $LoopNbr++)
{
    $PeriodStart=$DayUTC.AddDays(-$LoopNbr)
    $ActivityDate=$PeriodStart.ToString("yyyy-MM-dd")
    Write-Verbose "Checking $ActivityDate" -Verbose

#Check activity events once per loop (once per day):
    Get-PowerBIActivityEvent -StartDateTime ($ActivityDate + 'T00:00:00') -EndDateTime ($ActivityDate + 'T23:59:59') -User $currentUser
    }




########################
## Get User Logs for each person. Runs only last 30 max days.

function Get-PowerBIWorkspaceWithRetry {
    param (
        [int]$RetryCount = 3,
        [int]$RetryDelay = 5
    )

    $attempt = 0
    while ($attempt -lt $RetryCount) {
        try {
            return Get-PowerBIWorkspace -Scope Organization -All
        } catch {
            Write-Warning "Attempt $($attempt + 1) failed: $_"
            Start-Sleep -Seconds $RetryDelay
            $attempt++
        }
    }
    throw "Failed to get Power BI workspaces after $RetryCount attempts."
}

$Workspaces = Get-PowerBIWorkspaceWithRetry

# Initialize an array to store users
$Users = @()

# Initialize a counter for progress
$UserCounter = 0

foreach ($Workspace in $Workspaces) {
    foreach ($User in $Workspace.Users) {
        $Users += $User.Identifier
        $UserCounter++
    }
}

# Update the required number of days:
$NbrOfDaysToCheck = 30

# Use today to start counting back the number of days to check:
$DayUTC = (([datetime]::Today.ToUniversalTime()).Date)

# Initialize an array to store activity logs
$ActivityLogs = @()

# Iteratively loop through each of the last N days to view events:
For($LoopNbr=0; $LoopNbr -le $NbrOfDaysToCheck; $LoopNbr++) {
    $PeriodStart = $DayUTC.AddDays(-$LoopNbr)
    $ActivityDate = $PeriodStart.ToString("yyyy-MM-dd")
    Write-Verbose "Checking $ActivityDate" -Verbose

    # Check activity events once per loop (once per day):
    foreach ($User in $Users) {
        $ActivityEvents = Get-PowerBIActivityEvent -StartDateTime ($ActivityDate + 'T00:00:00') -EndDateTime ($ActivityDate + 'T23:59:59') -User $User
        if ($ActivityEvents) {
            foreach ($Event in $ActivityEvents) {
                $ActivityLogs += [PSCustomObject]@{
                    User         = $User
                    ActivityDate = $ActivityDate
                    Event        = $Event
                }
            }
        } else {
            Write-Verbose "No activity events found for $User on $ActivityDate" -Verbose
        }
    }

    # Update progress
    Write-Progress -Activity "Checking activity logs" -Status "Day $LoopNbr of $NbrOfDaysToCheck" -PercentComplete (($LoopNbr / $NbrOfDaysToCheck) * 100)
}

# Check if any activity logs were captured
if ($ActivityLogs.Count -gt 0) {
    # Export activity logs to CSV
    $ActivityLogs | Export-Csv -Path $path"ActivityLogs.csv" -NoTypeInformation
    Write-Output "Activity logs exported to ActivityLogs.csv"
} else {
    Write-Output "No activity logs found for the specified period."
}