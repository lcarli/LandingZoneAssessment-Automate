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

# Load configuration file
$configPath = "$PSScriptRoot/../shared/config.json"
$config = Get-Content -Path $configPath | ConvertFrom-Json

# Connect to Azure
Connect-AzAccount

# Main function
function Main {
    $contractType = $config.ContractType
    Write-Host "Contract Type: $contractType"


    //create a customobject with design areas with empty values
    $eneralResult = [PSCustomObject]@{
        Billing = @{}
        Security =  @{}
        Networking =  @{}
    }



    $designAreas = $config.DesignAreas
    if ($designAreas.Billing) {     
        $generalResult.Billing = Invoke-BillingAssessment -ContractType $contractType
    }
    if ($designAreas.IAM) {
        $generalResult.IAM = Invoke-IAMAssessment -ContractType $contractType
    }
    if ($designAreas.ResourceOrganization) {
        $generalResult.ResourceOrganization = Invoke-ResourceOrganizationAssessment -ContractType $contractType
    }


    # Generate report
    Generate-Report
}

# Call the main function
Main
