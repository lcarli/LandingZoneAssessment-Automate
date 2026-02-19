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

    # Build data-driven assessment task list from configuration
    $assessmentDefs = @(
        @{ ConfigKey = 'Billing';              ResultKey = 'Billing';              Label = 'Azure Billing and Microsoft Entra ID Tenants'; Script = 'AzureBillingandMicrosoftEntraIDTenants.ps1'; Function = 'Invoke-AzureBillingandMicrosoftEntraIDTenantsAssessment'; UseContractType = $true }
        @{ ConfigKey = 'IAM';                  ResultKey = 'IAM';                  Label = 'Identity and Access Management';               Script = 'IdentityandAccessManagement.ps1';                       Function = 'Invoke-IdentityandAccessManagementAssessment';         UseContractType = $false }
        @{ ConfigKey = 'ResourceOrganization'; ResultKey = 'ResourceOrganization'; Label = 'Resource Organization';                        Script = 'ResourceOrganization.ps1';                              Function = 'Invoke-ResourceOrganizationAssessment';                UseContractType = $false }
        @{ ConfigKey = 'Network';              ResultKey = 'Network';              Label = 'Network Topology and Connectivity';            Script = 'NetworkTopologyandConnectivity.ps1';                    Function = 'Invoke-NetworkTopologyandConnectivityAssessment';      UseContractType = $false }
        @{ ConfigKey = 'Governance';           ResultKey = 'Governance';           Label = 'Governance';                                   Script = 'Governance.ps1';                                        Function = 'Invoke-GovernanceAssessment';                          UseContractType = $false }
        @{ ConfigKey = 'Security';             ResultKey = 'Security';             Label = 'Security';                                     Script = 'Security.ps1';                                          Function = 'Invoke-SecurityAssessment';                            UseContractType = $false }
        @{ ConfigKey = 'DevOps';               ResultKey = 'DevOps';              Label = 'Platform Automation and DevOps';               Script = 'PlatformAutomationandDevOps.ps1';                       Function = 'Invoke-PlatformAutomationandDevOpsAssessment';         UseContractType = $false }
        @{ ConfigKey = 'Management';           ResultKey = 'Management';           Label = 'Management';                                   Script = 'Management.ps1';                                        Function = 'Invoke-ManagementAssessment';                          UseContractType = $false }
    )

    # Filter to only enabled design areas
    $enabledAssessments = @()
    foreach ($def in $assessmentDefs) {
        if ($designAreas.($def.ConfigKey)) {
            $enabledAssessments += $def
        }
    }

    if ($enabledAssessments.Count -eq 0) {
        Write-Output "No design areas enabled in configuration. Skipping assessments."
    }
    else {
        # Determine if parallel execution is available (PowerShell 7+)
        $canParallel = ($PSVersionTable.PSVersion.Major -ge 7) -and ($enabledAssessments.Count -gt 1)

        if ($canParallel) {
            Write-Output ""
            Write-Output "PowerShell 7+ detected - running $($enabledAssessments.Count) assessments in parallel (ThrottleLimit: 4)..."
            Write-Output ""

            $assessmentStartTime = Get-Date

            # Capture paths and globals for parallel runspaces (via $using:)
            $scriptRoot = $PSScriptRoot
            $sharedEnumsPath       = [System.IO.Path]::GetFullPath("$PSScriptRoot/../shared/Enums.ps1")
            $sharedErrorPath       = [System.IO.Path]::GetFullPath("$PSScriptRoot/../shared/ErrorHandling.ps1")
            $sharedFunctionsPath   = [System.IO.Path]::GetFullPath("$PSScriptRoot/../shared/SharedFunctions.ps1")
            $functionsDir          = [System.IO.Path]::GetFullPath("$PSScriptRoot/../functions")

            $azData          = $global:AzData
            $graphData       = $global:GraphData
            $graphConnected  = $global:GraphConnected
            $tenantId        = $global:TenantId
            $checklist       = $global:Checklist
            $ctType          = $contractType

            $parallelResults = $enabledAssessments | ForEach-Object -Parallel {
                $task = $_

                # Retrieve parent-scope variables
                $sr               = $using:scriptRoot
                $enumsPath        = $using:sharedEnumsPath
                $errorPath        = $using:sharedErrorPath
                $funcPath         = $using:sharedFunctionsPath
                $fnDir            = $using:functionsDir

                # Set up globals in this runspace
                $global:AzData         = $using:azData
                $global:GraphData      = $using:graphData
                $global:GraphConnected = $using:graphConnected
                $global:TenantId       = $using:tenantId
                $global:Checklist      = $using:checklist

                # Dot-source shared dependencies (all 3 files explicitly)
                . $enumsPath
                . $errorPath
                . $funcPath

                # Dot-source the specific assessment module
                $moduleFile = Join-Path $fnDir $task.Script
                . $moduleFile

                # Build parameters
                $params = @{ Checklist = $global:Checklist }
                if ($task.UseContractType) {
                    $params['ContractType'] = $using:ctType
                }

                $taskStart = Get-Date
                try {
                    $result = & $task.Function @params
                    $elapsed = (Get-Date) - $taskStart
                    Write-Host "$($task.Label) assessment completed in $($elapsed.ToString('mm\:ss\.fff'))"
                    [PSCustomObject]@{ Key = $task.ResultKey; Data = $result; Success = $true }
                }
                catch {
                    $elapsed = (Get-Date) - $taskStart
                    Write-Host "$($task.Label) assessment FAILED after $($elapsed.ToString('mm\:ss\.fff')): $($_.Exception.Message)"
                    [PSCustomObject]@{ Key = $task.ResultKey; Data = @(); Success = $false }
                }
            } -ThrottleLimit 4

            # Collect parallel results into generalResult
            foreach ($pr in $parallelResults) {
                if ($null -ne $pr -and $pr -is [PSCustomObject] -and $null -ne $pr.PSObject.Properties['Key']) {
                    $generalResult.($pr.Key) = $pr.Data
                }
            }

            $totalElapsed = (Get-Date) - $assessmentStartTime
            Write-Output ""
            Write-Output "All parallel assessments completed in $($totalElapsed.ToString('mm\:ss\.fff'))"
        }
        else {
            # Sequential execution (PS 5.1 compatible, or single assessment)
            if ($PSVersionTable.PSVersion.Major -lt 7) {
                Write-Output "PowerShell 5.x detected - running assessments sequentially."
            }
            Write-Output ""

            foreach ($task in $enabledAssessments) {
                Write-Output "Running $($task.Label) Assessment..."
                try {
                    $params = @{ Checklist = $global:Checklist }
                    if ($task.UseContractType) {
                        $params['ContractType'] = $contractType
                    }
                    $generalResult.($task.ResultKey) = & $task.Function @params
                    Write-Output "$($task.Label) assessment completed"
                }
                catch {
                    Write-Output "$($task.Label) assessment failed: $($_.Exception.Message)"
                }
            }
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
