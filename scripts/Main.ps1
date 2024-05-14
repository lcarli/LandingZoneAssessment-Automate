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
Import-Module "$PSScriptRoot/Initialize.ps1"
Import-Module "$PSScriptRoot/../functions/Billing.ps1"
Import-Module "$PSScriptRoot/../functions/Security.ps1"
Import-Module "$PSScriptRoot/../functions/Networking.ps1"
Import-Module "$PSScriptRoot/../functions/OtherArea.ps1"

# Load configuration file
$configPath = "$PSScriptRoot/../shared/config.json"
$config = Get-Content -Path $configPath | ConvertFrom-Json

# Connect to Azure
Connect-AzAccount

# Main function
function Main {
    $contractType = $config.ContractType
    Write-Host "Contract Type: $contractType"

    $designAreas = $config.DesignAreas
    if ($designAreas.Billing) {
        Invoke-Billing -ContractType $contractType
    }
    if ($designAreas.Security) {
        Invoke-Security -ContractType $contractType
    }
    if ($designAreas.Networking) {
        Invoke-Networking -ContractType $contractType
    }
    if ($designAreas.OtherArea) {
        Invoke-OtherArea -ContractType $contractType
    }

    # Generate report
    Generate-Report
}

# Call the main function
Main
