# Governance.ps1

<#
.SYNOPSIS
    Functions related to Governance assessment.

.DESCRIPTION
    This script contains functions to evaluate the Governance area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-GovernanceAssessment {
    Write-Host "Evaluating the Governance design area..."

    $results = @()

    return $results
}
