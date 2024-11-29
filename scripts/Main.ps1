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
. "$PSScriptRoot/../functions/AzureBillingandMicrosoftEntraIDTenants.ps1"
. "$PSScriptRoot/../functions/Governance.ps1"
. "$PSScriptRoot/../functions/IdentityandAccessManagement.ps1"
. "$PSScriptRoot/../functions/Management.ps1"
. "$PSScriptRoot/../functions/NetworkTopologyandConnectivity.ps1"
. "$PSScriptRoot/../functions/PlatformAutomationandDevOps.ps1"
. "$PSScriptRoot/../functions/ResourceOrganization.ps1"
. "$PSScriptRoot/../functions/Security.ps1"

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
        Billing = @()
        IAM = @()
        ResourceOrganization = @()
        Network = @()
        Governance = @()
        Security = @()
        DevOps = @()
        Management = @()
    }

    $designAreas = $config.DesignAreas

    if ($designAreas.Billing) {     
        $generalResult.Billing = Invoke-BillingAssessment -Checklist $global:Checklist -ContractType $contractType
    }
    if ($designAreas.IAM) {
        $generalResult.IAM = Invoke-IdentityandAccessManagementAssessment -Checklist $global:Checklist
    }
    if ($designAreas.ResourceOrganization) {
        $generalResult.ResourceOrganization = Invoke-ResourceOrganizationAssessment -Checklist $global:Checklist
    }
    if ($designAreas.Network) {
        $generalResult.Network = Invoke-NetworkTopologyandConnectivityAssessment -Checklist $global:Checklist
    }
    if ($designAreas.Governance) {     
        $generalResult.Governance = Invoke-GovernanceAssessment -Checklist $global:Checklist
    }
    if ($designAreas.Security) {
        $generalResult.Security = Invoke-SecurityAssessment -Checklist $global:Checklist
    }
    if ($designAreas.DevOps) {
        $generalResult.DevOps = Invoke-DevOpsAssessment -Checklist $global:Checklist
    }
    if ($designAreas.Management) {
        $generalResult.Management = Invoke-ManagementAssessment -Checklist $global:Checklist
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
    $generalResult | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath

    Write-Host "Creating the web site..."
    & "$PSScriptRoot/CreateWebSite.ps1"
}


# Call the main function
Main
