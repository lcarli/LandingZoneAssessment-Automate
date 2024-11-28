<#
.SYNOPSIS
    Main script to evaluate the Azure Landing Zone.

.DESCRIPTION
    This main script connects to Azure, reads the configuration file, and calls the appropriate functions for assessment. It generates a consolidated report at the end.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import necessary modules
. "$PSScriptRoot/Initialize.ps1"
. "$PSScriptRoot/../functions/Billing.ps1"
. "$PSScriptRoot/../functions/IAM.ps1"
. "$PSScriptRoot/../functions/ResourceOrganization.ps1"
. "$PSScriptRoot/../functions/NetworkTopologyandConnectivity.ps1"

# Load configuration file
$configPath = "$PSScriptRoot/../shared/config.json"
$config = Get-Content -Path $configPath | ConvertFrom-Json

#Initialize environment
Initialize-Environment

# Main function
function Main {
    $contractType = $config.ContractType
    Write-Host "Contract Type: $contractType"

    $generalResult = [PSCustomObject]@{
        Billing = @{}
        IAM =  @{}
        ResourceOrganization =  @{}
        Network =  @{}
        Governance =  @{}
        Security =  @{}
        DevOps =  @{}
        Management =  @{}
    }

    $designAreas = $config.DesignAreas

    if ($designAreas.Billing) {     
        $generalResult.Billing = Invoke-BillingAssessment -Checklist $checklist -ContractType $contractType
    }
    if ($designAreas.IAM) {
        $generalResult.IAM = Invoke-IAMAssessment
    }
    if ($designAreas.ResourceOrganization) {
        $generalResult.ResourceOrganization = Invoke-ResourceOrganizationAssessment
    }
    if ($designAreas.Network) {
        $generalResult.Network = Invoke-NetworkTopologyandConnectivityAssessment -Checklist $checklistPath
    }
    if ($designAreas.Governance) {     
        $generalResult.Governance = Invoke-GovernanceAssessment -Checklist $checklistPath
    }
    if ($designAreas.Security) {
        $generalResult.Security = Invoke-SecurityAssessmen
    }
    if ($designAreas.DevOps) {
        $generalResult.DevOps = Invoke-DevOpsAssessment
    }
    if ($designAreas.Management) {
        $generalResult.Management = Invoke-ManagementAssessment
    }

    Export-Report -generalResult $generalResult
}

function Export-Report {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$generalResult
    )

    # Create CSV file
    $csvPath = "$PSScriptRoot/../reports/report.csv"
    $generalResult | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $csvPath

    # Create JSON file
    $jsonPath = "$PSScriptRoot/../reports/report.json"
    $generalResult | ConvertTo-Json | Out-File -FilePath $jsonPath
}


# Call the main function
Main
