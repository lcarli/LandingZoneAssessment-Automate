# Management.ps1

<#
.SYNOPSIS
    Functions related to Management assessment.

.DESCRIPTION
    This script contains functions to evaluate the Management area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-ManagementAssessment {
    Write-Host "Evaluating the Management design area..."

    $results = @()

    return $results
}
