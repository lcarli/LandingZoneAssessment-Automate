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

# Ensure module autoloading is enabled (may have been disabled by a previous run)
$global:PSModuleAutoLoadingPreference = 'All'

# Start transcript
$logsDir = "$PSScriptRoot/../logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}
$transcriptPath = "$logsDir/LandingZone-Assessment_$(Get-Date -Format 'yyyyMMdd_HHmmss')_transcript.log"
$global:TranscriptActive = $false
try {
    Start-Transcript -Path $transcriptPath -ErrorAction Stop
    $global:TranscriptActive = $true
}
catch {
    Write-Warning "Start-Transcript not supported in this host ($($Host.Name)). Logging to file instead."
    # Fallback: redirect all output streams to log file via Tee
    $global:LogFilePath = $transcriptPath
    "=== LandingZone Assessment Log ===" | Out-File -FilePath $transcriptPath -Encoding utf8
    "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $transcriptPath -Append -Encoding utf8
    "Host: $($Host.Name) | PS $($PSVersionTable.PSVersion)" | Out-File -FilePath $transcriptPath -Append -Encoding utf8
    "===================================" | Out-File -FilePath $transcriptPath -Append -Encoding utf8
}

# Helper: Write-Log outputs to console AND log file when transcript is not active
function Write-Log {
    param([string]$Message)
    Write-Output $Message
    if (-not $global:TranscriptActive -and $global:LogFilePath) {
        $Message | Out-File -FilePath $global:LogFilePath -Append -Encoding utf8
    }
}

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

# Validate configuration
$validation = Test-ConfigValidation -Config $config -ConfigPath $configPath
if ($validation.Warnings.Count -gt 0) {
    foreach ($w in $validation.Warnings) {
        Write-Warning "Config: $w"
    }
}
if (-not $validation.IsValid) {
    Write-Output ""
    Write-Output "Configuration validation FAILED:"
    foreach ($e in $validation.Errors) {
        Write-Output "  ERROR: $e"
    }
    throw "Configuration validation failed. Please fix the errors in $configPath"
}
Write-Output "Configuration validation passed"

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
        # Sequential execution — parallel runspaces cause .NET assembly conflicts
        # with Az modules (different versions of the same DLL cannot coexist in one process)
        $progressId = 1
        $totalSteps = $enabledAssessments.Count + 1  # +1 for report generation
        $assessmentStartTime = Get-Date

        Write-Output "Running $($enabledAssessments.Count) assessment(s) sequentially..."
        Write-Output ""

        $stepIndex = 0
        $succeeded = 0
        $failed = 0

        foreach ($task in $enabledAssessments) {
            $stepIndex++
            $pctDone = [math]::Round((($stepIndex - 1) / $totalSteps) * 100)

            # Update progress bar with current assessment name
            Write-Progress -Id $progressId -Activity "Azure Landing Zone Assessment" `
                -Status "[$stepIndex/$($enabledAssessments.Count)] Running: $($task.Label)..." `
                -PercentComplete $pctDone

            Write-Output "===================="
            Write-Output "[$stepIndex/$($enabledAssessments.Count)] Starting: $($task.Label)"
            Write-Output "===================="

            $taskStart = Get-Date
            try {
                $params = @{ Checklist = $global:Checklist }
                if ($task.UseContractType) {
                    $params['ContractType'] = $contractType
                }
                $generalResult.($task.ResultKey) = & $task.Function @params

                $elapsed = (Get-Date) - $taskStart
                $succeeded++
                Write-Output "[$stepIndex/$($enabledAssessments.Count)] Completed: $($task.Label) ($($elapsed.ToString('mm\:ss\.fff')))"
            }
            catch {
                $elapsed = (Get-Date) - $taskStart
                $failed++
                Write-Output "[$stepIndex/$($enabledAssessments.Count)] FAILED: $($task.Label) ($($elapsed.ToString('mm\:ss\.fff')))"
                Write-Warning "  Error: $($_.Exception.Message)"
            }
            Write-Output ""
        }

        $totalElapsed = (Get-Date) - $assessmentStartTime

        $pctDone = [math]::Round(($enabledAssessments.Count / $totalSteps) * 100)
        Write-Progress -Id $progressId -Activity "Azure Landing Zone Assessment" `
            -Status "Assessments complete ($succeeded OK, $failed failed)" `
            -PercentComplete $pctDone

        Write-Output "===================="
        Write-Output "All assessments completed in $($totalElapsed.ToString('mm\:ss\.fff')) ($succeeded OK, $failed failed)"
        Write-Output "===================="
    }

    # Generate reports
    Write-Output ""
    Write-Output "=================================================================================="
    Write-Output "======================= REPORT GENERATION ======================================"
    Write-Output "=================================================================================="
    Write-Output ""

    if ($enabledAssessments.Count -gt 0) {
        Write-Progress -Id $progressId -Activity "Azure Landing Zone Assessment" -Status "Generating reports..." -PercentComplete 95
    }
    
    try {
        Measure-ExecutionTime -ScriptBlock {
            Export-Report -generalResult $generalResult
        } -FunctionName "Export-Report"
        Write-Output "Report generation completed"
    }
    catch {
        Write-Output "Report generation failed: $($_.Exception.Message)"
    }

    # Complete the progress bar
    if ($enabledAssessments.Count -gt 0) {
        Write-Progress -Id $progressId -Activity "Azure Landing Zone Assessment" -Status "Complete" -PercentComplete 100 -Completed
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
    if ($global:TranscriptActive) {
        try { Stop-Transcript } catch { }
    }
    elseif ($global:LogFilePath) {
        "===================================" | Out-File -FilePath $global:LogFilePath -Append -Encoding utf8
        "Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $global:LogFilePath -Append -Encoding utf8
    }
}
