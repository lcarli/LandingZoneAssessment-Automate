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


# START TRANSCRIPT
$transcriptPath = "$PSScriptRoot/../logs/Initialize-Environment_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $transcriptPath

# Load configuration file
$configPath = "$PSScriptRoot/../shared/config.json"
$config = Get-Content -Path $configPath | ConvertFrom-Json

#Initialize environment
Measure-ExecutionTime -ScriptBlock {
    Initialize-Environment
} -FunctionName "Initialize-Environment"

# Main function
function Main {
    $contractType = $config.ContractType
    Write-Host "Contract Type: $contractType"

    $generalResult = [PSCustomObject]@{
        Billing              = @()
        IAM                  = @()
        ResourceOrganization = @()
        Network              = @()
        Governance           = @()
        Security             = @()
        DevOps               = @()
        Management           = @()
    }

    $designAreas = $config.DesignAreas

    if ($designAreas.Billing) {     
        $generalResult.Billing = Invoke-AzureBillingandMicrosoftEntraIDTenantsAssessment -Checklist $global:Checklist -ContractType $contractType
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
        $generalResult.DevOps = Invoke-PlatformAutomationandDevOpsAssessment -Checklist $global:Checklist
    }
    if ($designAreas.Management) {
        $generalResult.Management = Invoke-ManagementAssessment -Checklist $global:Checklist
    }

    Measure-ExecutionTime -ScriptBlock {
        Export-Report -generalResult $generalResult
    } -FunctionName "Export-Report"
}

function Export-Report {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$generalResult
    )

    # Create JSON file
    $jsonPath = "$PSScriptRoot/../reports/report.json"
    $generalResult | ConvertTo-Json -Depth 15 | Out-File -FilePath $jsonPath

    Write-Host "Creating the web site..."
    & "$PSScriptRoot/CreateWebSite.ps1"
}


# Register a Ctrl+C handler
$null = [Console]::CancelKeyPress.Register({
    param($sender, $e)
    Write-Host "`n`nCtrl+C detected. Cleaning up resources and exiting gracefully..." -ForegroundColor Yellow
    # Set the Cancel property to True to prevent the process from terminating immediately
    $e.Cancel = $true
})

# Call the main function
try {
    Measure-ExecutionTime -ScriptBlock {
        Main
    } -FunctionName "Main"
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Cleanup global resources if any exist
    if ($global:AzData) {
        Write-Host "Cleaning up global resources..." -ForegroundColor Cyan
        $global:AzData = $null
    }
    
    # Stop transcript
    Stop-Transcript
}