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
. "$PSScriptRoot/../scripts/Initialize.ps1"
. "$PSScriptRoot/../shared/ErrorHandling.ps1"


# Execute Initialize.ps1 to set up the environment
Write-Host "Initializing environment..."
Initialize-Environment

# Function to handle the function execution
function Test-Custom {
    param (
        [string]$functionName
    )

    try {
        # For testing specific questions, we need to create a mock checklist item
        if ($functionName -like "Test-Question*") {
            # Create a sample checklist item for the test
            $checklistItem = [PSCustomObject]@{
                id = "E01.06"
                text = "Use Azure Policy to control which services users can provision at the subscription/management group level."
                category = "Governance"
            }
            
            Write-Host "`nTesting function: $functionName"
            Write-Host "Mock checklist item: $($checklistItem.id) - $($checklistItem.text)"
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
