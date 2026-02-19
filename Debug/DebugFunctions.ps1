<#
.SYNOPSIS
    Script to debug and validate individual functions.

.DESCRIPTION
    This script allows you to run individual functions from the assessment scripts to validate their output by providing the function name as a parameter.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>



param (
    [string]$FunctionName
)

# Import the necessary modules
. "$PSScriptRoot/../functions/AzureBillingandMicrosoftEntraIDTenants.ps1"
. "$PSScriptRoot/../functions/IdentityandAccessManagement.ps1"
. "$PSScriptRoot/../functions/Governance.ps1"
. "$PSScriptRoot/../functions/NetworkTopologyandConnectivity.ps1"
. "$PSScriptRoot/../functions/Management.ps1"
. "$PSScriptRoot/../functions/ResourceOrganization.ps1"
. "$PSScriptRoot/../functions/Security.ps1"
. "$PSScriptRoot/../functions/PlatformAutomationandDevOps.ps1"
. "$PSScriptRoot/../shared/ErrorHandling.ps1"
. "$PSScriptRoot/../shared/Enums.ps1"
. "$PSScriptRoot/../shared/SharedFunctions.ps1"

# Try to load Initialize.ps1 and run Initialize-Environment
# If it fails (e.g., PS 5.1 parse issues), load checklist directly
Write-Host "Initializing environment..."
try {
    . "$PSScriptRoot/../scripts/Initialize.ps1"
    Initialize-Environment
}
catch {
    Write-Warning "Initialize-Environment failed: $($_.Exception.Message)"
    Write-Host "Loading checklist directly as fallback..."
    
    # Load checklist directly
    $checklistPath = Join-Path $PSScriptRoot "../shared/alz_checklist.en.json"
    if (Test-Path $checklistPath) {
        $global:Checklist = Get-Content -Path $checklistPath -Raw | ConvertFrom-Json
        Write-Host "Checklist loaded: $($global:Checklist.items.Count) items" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Checklist file not found at $checklistPath" -ForegroundColor Red
        exit 1
    }
    
    # Initialize empty global data if not present
    if (-not $global:AzData) { $global:AzData = @{} }
    if (-not $global:GraphData) { $global:GraphData = @{} }
}

# Function to handle the function execution
function Test-Custom {
    param (
        [string]$functionName
    )

    try {
        # For testing specific questions, we need to find the correct checklist item
        if ($functionName -like "Test-Question*") {
            # Extract question ID from function name (e.g., Test-QuestionF0102 -> F01.02)
            $idRaw = $functionName -replace 'Test-Question', ''
            $questionId = "$($idRaw.Substring(0,3)).$($idRaw.Substring(3))"
            
            # Look up the checklist item from the global checklist
            $checklistItem = $global:Checklist.items | Where-Object { $_.id -eq $questionId } | Select-Object -First 1
            
            if (-not $checklistItem) {
                Write-Host "Checklist item not found for ID: $questionId (function: $functionName)" -ForegroundColor Red
                Write-Host "Available IDs starting with '$($idRaw.Substring(0,3))':"
                $global:Checklist.items | Where-Object { $_.id -like "$($idRaw.Substring(0,3))*" } | ForEach-Object { Write-Host "  $($_.id) - $($_.text)" }
                return
            }
            
            Write-Host "`nTesting function: $functionName"
            Write-Host "Checklist item: $($checklistItem.id) - $($checklistItem.text)"
            Write-Host "Category: $($checklistItem.category) | Severity: $($checklistItem.severity)"
            Write-Host ""
            
            # Execute the function with the checklist item
            $result = & $functionName $checklistItem
        } else {
            # Execute the function using Invoke-Expression for other types
            $result = Invoke-Expression $functionName
        }

        if ($result) {
            Write-Host "`nFunction Output:"
            $result | Format-List
        } else {
            Write-Host "`nFunction executed but returned no output."
        }
    }
    catch {
        Write-Host "Error executing function ${functionName}: $_" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    }
}

# Main script
if (-not $FunctionName) {
    Write-Host "Please provide the function name as a parameter. Example: .\DebugFunctions.ps1 -FunctionName 'Test-QuestionB0304'"
    exit
} else {
    Test-Custom -functionName $FunctionName
}
