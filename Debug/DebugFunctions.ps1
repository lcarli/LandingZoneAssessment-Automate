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
. "$PSScriptRoot/../scripts/Initialize.ps1"
. "$PSScriptRoot/../shared/ErrorHandling.ps1"


# Execute Initialize.ps1 to set up the environment
Write-Host "Initializing environment..."
Initialize-Environment

# Function to handle the function execution
function Assess-Custom {
    param (
        [string]$functionName
    )

    try {
        # Execute the function using Invoke-Expression
        $result = Invoke-Expression $functionName

        if ($result) {
            Write-Host "`nFunction Output:"
            $result | Format-List
        }
    }
    catch {
        Write-Host "Error executing function ${functionName}: $_"
    }
}

# Main script
if (-not $FunctionName) {
    Write-Host "Please provide the function name as a parameter. Example: .\DebugFunctions.ps1 -FunctionName 'Assess-EANotificationContacts'"
    exit
} else {
    Assess-Custom -functionName $FunctionName
}
