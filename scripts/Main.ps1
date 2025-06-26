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

# Start transcript
$transcriptPath = "$PSScriptRoot/../logs/LandingZone-Assessment_$(Get-Date -Format 'yyyyMMdd_HHmmss')_transcript.log"
Start-Transcript -Path $transcriptPath

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

Write-Output ""
Write-Output "=================================================================================="
Write-Output "=========== AZURE LANDING ZONE ASSESSMENT ======================================"
Write-Output "=================================================================================="
Write-Output ""

# Load configuration file
$configPath = "$PSScriptRoot/../shared/config.json"
try {
    $config = Get-Content -Path $configPath | ConvertFrom-Json
    Write-Output "Configuration loaded successfully"
}
catch {
    Write-Output "Failed to load configuration: $($_.Exception.Message)"
    throw "Configuration loading failed"
}

# Initialize environment
Write-Output ""
Write-Output "=================================================================================="
Write-Output "============== ENVIRONMENT INITIALIZATION ======================================"
Write-Output "=================================================================================="
Write-Output ""

$initStartTime = Get-Date
try {
    Measure-ExecutionTime -ScriptBlock {
        Initialize-Environment
    } -FunctionName "Initialize-Environment"
    
    $initDuration = (Get-Date) - $initStartTime
    Write-Output "Environment initialization completed in $($initDuration.ToString('mm\:ss\.fff'))"
}
catch {
    Write-Output "Environment initialization failed: $($_.Exception.Message)"
    throw "Initialization failed"
}

# Main function
function Main {
    Write-Output ""
    Write-Output "=================================================================================="
    Write-Output "=============== MAIN ASSESSMENT EXECUTION ======================================"
    Write-Output "=================================================================================="
    Write-Output ""
    
    $contractType = $config.ContractType
    Write-Output "Starting assessment execution for contract type: $contractType"

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

    # Execute assessments based on configuration
    if ($designAreas.Billing) {
        Write-Output "Running Azure Billing and Microsoft Entra ID Tenants Assessment..."
        try {     
            $generalResult.Billing = Invoke-AzureBillingandMicrosoftEntraIDTenantsAssessment -Checklist $global:Checklist -ContractType $contractType
            Write-Output "Billing assessment completed"
        }
        catch {
            Write-Output "Billing assessment failed: $($_.Exception.Message)"
        }
    }    
    if ($designAreas.IAM) {
        Write-Output "Running Identity and Access Management Assessment..."
        try {
            $generalResult.IAM = Invoke-IdentityandAccessManagementAssessment -Checklist $global:Checklist
            Write-Output "Identity and Access Management assessment completed"
        }
        catch {
            Write-Output "Identity and Access Management assessment failed: $($_.Exception.Message)"
        }
    }
    
    if ($designAreas.ResourceOrganization) {
        Write-Output "Running Resource Organization Assessment..."
        try {
            $generalResult.ResourceOrganization = Invoke-ResourceOrganizationAssessment -Checklist $global:Checklist
            Write-Output "Resource Organization assessment completed"
        }
        catch {
            Write-Output "Resource Organization assessment failed: $($_.Exception.Message)"
        }
    }
    
    if ($designAreas.Network) {
        Write-Output "Running Network Topology and Connectivity Assessment..."
        try {
            $generalResult.Network = Invoke-NetworkTopologyandConnectivityAssessment -Checklist $global:Checklist
            Write-Output "Network assessment completed"
        }
        catch {
            Write-Output "Network assessment failed: $($_.Exception.Message)"
        }
    }
    
    if ($designAreas.Governance) {
        Write-Output "Running Governance Assessment..."
        try {     
            $generalResult.Governance = Invoke-GovernanceAssessment -Checklist $global:Checklist
            Write-Output "Governance assessment completed"
        }
        catch {
            Write-Output "Governance assessment failed: $($_.Exception.Message)"        }
    }
    
    if ($designAreas.Security) {
        Write-Output "Running Security Assessment..."
        try {
            $generalResult.Security = Invoke-SecurityAssessment -Checklist $global:Checklist
            Write-Output "Security assessment completed"
        }
        catch {
            Write-Output "Security assessment failed: $($_.Exception.Message)"
        }
    }
    
    if ($designAreas.DevOps) {
        Write-Output "Running Platform Automation and DevOps Assessment..."
        try {
            $generalResult.DevOps = Invoke-PlatformAutomationandDevOpsAssessment -Checklist $global:Checklist
            Write-Output "DevOps assessment completed"
        }
        catch {
            Write-Output "DevOps assessment failed: $($_.Exception.Message)"
        }
    }
    
    if ($designAreas.Management) {
        Write-Output "Running Management Assessment..."
        try {
            $generalResult.Management = Invoke-ManagementAssessment -Checklist $global:Checklist
            Write-Output "Management assessment completed"
        }
        catch {
            Write-Output "Management assessment failed: $($_.Exception.Message)"
        }
    }

    # Generate reports
    Write-Output ""
    Write-Output "=================================================================================="
    Write-Output "======================= REPORT GENERATION ======================================"
    Write-Output "=================================================================================="
    Write-Output ""
    
    try {
        Measure-ExecutionTime -ScriptBlock {
            Export-Report -generalResult $generalResult
        } -FunctionName "Export-Report"
        Write-Output "Report generation completed"
    }
    catch {
        Write-Output "Report generation failed: $($_.Exception.Message)"
    }
}

function Export-Report {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$generalResult
    )
    
    # Create JSON file
    $jsonPath = "$PSScriptRoot/../reports/report.json"
    $generalResult | ConvertTo-Json -Depth 15 | Out-File -FilePath $jsonPath
    Write-Output "JSON report created at: $jsonPath"

    Write-Output "Creating web site..."
    try {
        & "$PSScriptRoot/CreateWebSite.ps1"
        Write-Output "Web site created successfully"
    }
    catch {
        Write-Output "Web site creation failed: $($_.Exception.Message)"
    }
}

# Call the main function
try {
    $mainStartTime = Get-Date
    Measure-ExecutionTime -ScriptBlock {
        Main
    } -FunctionName "Main"
    
    $mainDuration = (Get-Date) - $mainStartTime
    Write-Output ""
    Write-Output "=================================================================================="
    Write-Output "======================= EXECUTION SUMMARY ======================================"
    Write-Output "=================================================================================="
    Write-Output ""
    Write-Output "Main execution completed successfully in $($mainDuration.ToString('hh\:mm\:ss\.fff'))"
}
catch {
    Write-Output "Critical error in main execution: $($_.Exception.Message)"
    Write-Output "Stack trace: $($_.ScriptStackTrace)"
}
finally {
    # Cleanup global resources if any exist
    if ($global:AzData) {
        Write-Output "Cleaning up global resources..."
        $global:AzData = $null
    }
    
    # Stop transcript
    Stop-Transcript
}
