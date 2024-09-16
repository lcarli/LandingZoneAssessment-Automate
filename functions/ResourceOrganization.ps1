# ResourceOrganization.ps1

<#
.SYNOPSIS
    Functions related to ResourceOrganization assessment.

.DESCRIPTION
    This script contains functions to evaluate the ResourceOrganization area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-ResourceOrganizationAssessment {
    Write-Host "Evaluating the ResourceOrganization design area..."

    $results = @()

    return $results
}
