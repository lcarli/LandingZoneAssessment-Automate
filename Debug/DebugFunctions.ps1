<#
.SYNOPSIS
    Script to debug and validate individual functions.

.DESCRIPTION
    This script allows you to run individual functions from the assessment scripts
    to validate their output by providing the function name as a parameter.

    Supports:
      - Test-Question* functions (e.g., Test-QuestionB0304)
      - Invoke-*Assessment functions (e.g., Invoke-SecurityAssessment)
      - Any other function loaded by the assessment modules

.EXAMPLE
    .\DebugFunctions.ps1 -FunctionName 'Test-QuestionB0304'

.EXAMPLE
    .\DebugFunctions.ps1 -FunctionName 'Invoke-SecurityAssessment'

.EXAMPLE
    .\DebugFunctions.ps1 -List

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

param (
    [string]$FunctionName,
    [switch]$List
)

# Import shared modules first (order matters: Enums before SharedFunctions)
. "$PSScriptRoot/../shared/Enums.ps1"
. "$PSScriptRoot/../shared/ErrorHandling.ps1"
. "$PSScriptRoot/../shared/SharedFunctions.ps1"

# Import all 8 assessment modules
. "$PSScriptRoot/../functions/AzureBillingandMicrosoftEntraIDTenants.ps1"
. "$PSScriptRoot/../functions/IdentityandAccessManagement.ps1"
. "$PSScriptRoot/../functions/Governance.ps1"
. "$PSScriptRoot/../functions/NetworkTopologyandConnectivity.ps1"
. "$PSScriptRoot/../functions/Management.ps1"
. "$PSScriptRoot/../functions/ResourceOrganization.ps1"
. "$PSScriptRoot/../functions/Security.ps1"
. "$PSScriptRoot/../functions/PlatformAutomationandDevOps.ps1"

# Load configuration
$configPath = Join-Path $PSScriptRoot "../shared/config.json"
$debugConfig = $null
if (Test-Path $configPath) {
    $debugConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json
}

# Initialize environment: try full init, fall back to local mock
Write-Host "Initializing environment..." -ForegroundColor Cyan
try {
    . "$PSScriptRoot/../scripts/Initialize.ps1"
    Initialize-Environment
    Write-Host "Full environment initialized successfully." -ForegroundColor Green
}
catch {
    Write-Warning "Initialize-Environment failed: $($_.Exception.Message)"
    Write-Host "Loading local mock data as fallback..." -ForegroundColor Yellow

    # Load checklist from config or default
    $checklistFile = if ($debugConfig -and $debugConfig.AlzChecklist) { $debugConfig.AlzChecklist } else { "alz_checklist.en.json" }
    $checklistPath = Join-Path $PSScriptRoot "../shared/$checklistFile"
    if (Test-Path $checklistPath) {
        $global:Checklist = Get-Content -Path $checklistPath -Raw | ConvertFrom-Json
        Write-Host "  Checklist loaded: $($global:Checklist.items.Count) items" -ForegroundColor Green
    }
    else {
        Write-Host "  ERROR: Checklist file not found at $checklistPath" -ForegroundColor Red
        exit 1
    }

    # TenantId from config
    $global:TenantId = if ($debugConfig -and $debugConfig.TenantId) { $debugConfig.TenantId } else { "00000000-0000-0000-0000-000000000000" }

    # Mock AzData with proper structure (matches Collect-AzData in Initialize.ps1)
    if (-not $global:AzData) {
        $global:AzData = [PSCustomObject]@{
            Tenant           = $null
            ManagementGroups = @()
            Subscriptions    = @()
            Resources        = @()
            Policies         = @()
        }
        Write-Host "  AzData: empty mock (no Azure connection)" -ForegroundColor Yellow
    }

    # Mock GraphData with proper structure (matches Collect-GraphData in Initialize.ps1)
    if (-not $global:GraphData) {
        $global:GraphData = @{
            Organization                  = $null
            Users                         = @()
            Groups                        = @()
            Applications                  = @()
            ServicePrincipals             = @()
            DirectoryRoles                = @()
            Domains                       = @()
            RoleDefinitions               = @()
            RoleAssignments               = @()
            ConditionalAccessPolicies     = @()
            NamedLocations                = @()
            AuthenticationMethodPolicies  = $null
            SecurityDefaultsPolicy        = $null
            AccessReviews                 = @()
        }
        Write-Host "  GraphData: empty mock (no Graph connection)" -ForegroundColor Yellow
    }

    $global:GraphConnected = $false
}

# List mode: show all available Test-Question* and Invoke-*Assessment functions
if ($List) {
    Write-Host "`nAvailable Invoke-*Assessment functions:" -ForegroundColor Cyan
    Get-Command -Name 'Invoke-*Assessment' -CommandType Function -ErrorAction SilentlyContinue |
        Sort-Object Name |
        ForEach-Object { Write-Host "  $($_.Name)" }

    Write-Host "`nAvailable Test-Question* functions:" -ForegroundColor Cyan
    Get-Command -Name 'Test-Question*' -CommandType Function -ErrorAction SilentlyContinue |
        Sort-Object Name |
        ForEach-Object { Write-Host "  $($_.Name)" }

    exit 0
}

# Validate function name was provided
if (-not $FunctionName) {
    Write-Host "Usage: .\DebugFunctions.ps1 -FunctionName 'Test-QuestionB0304'" -ForegroundColor Yellow
    Write-Host "       .\DebugFunctions.ps1 -FunctionName 'Invoke-SecurityAssessment'" -ForegroundColor Yellow
    Write-Host "       .\DebugFunctions.ps1 -List" -ForegroundColor Yellow
    exit 1
}

# Verify the function actually exists before calling it
$cmdInfo = Get-Command -Name $FunctionName -CommandType Function -ErrorAction SilentlyContinue
if (-not $cmdInfo) {
    Write-Host "ERROR: Function '$FunctionName' not found." -ForegroundColor Red
    Write-Host "Use -List to see all available functions." -ForegroundColor Yellow
    exit 1
}

# Execute the requested function
function Invoke-DebugFunction {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        if ($Name -like "Test-Question*") {
            # Extract question ID from function name (e.g., Test-QuestionF0102 -> F01.02)
            $idRaw = $Name -replace 'Test-Question', ''
            $questionId = "$($idRaw.Substring(0,3)).$($idRaw.Substring(3))"

            $checklistItem = $global:Checklist.items |
                Where-Object { $_.id -eq $questionId } |
                Select-Object -First 1

            if (-not $checklistItem) {
                Write-Host "Checklist item not found for ID: $questionId (function: $Name)" -ForegroundColor Red
                Write-Host "Available IDs starting with '$($idRaw.Substring(0,3))':"
                $global:Checklist.items |
                    Where-Object { $_.id -like "$($idRaw.Substring(0,3))*" } |
                    ForEach-Object { Write-Host "  $($_.id) - $($_.text)" }
                return
            }

            Write-Host "`nTesting: $Name" -ForegroundColor Cyan
            Write-Host "Checklist: $($checklistItem.id) - $($checklistItem.text)"
            Write-Host "Category: $($checklistItem.category) | Severity: $($checklistItem.severity)"
            Write-Host ""

            $result = & $Name $checklistItem
        }
        elseif ($Name -like "Invoke-*Assessment") {
            # Assessment functions need -Checklist; Billing also needs -ContractType
            Write-Host "`nRunning assessment: $Name" -ForegroundColor Cyan
            Write-Host ""

            $params = @{ Checklist = $global:Checklist }
            if ($Name -eq 'Invoke-AzureBillingandMicrosoftEntraIDTenantsAssessment') {
                $ct = if ($debugConfig -and $debugConfig.ContractType) { $debugConfig.ContractType } else { "EnterpriseAgreement" }
                $params['ContractType'] = $ct
                Write-Host "ContractType: $ct"
            }

            $result = & $Name @params
        }
        else {
            # Generic function call (no arguments)
            Write-Host "`nCalling: $Name" -ForegroundColor Cyan
            Write-Host ""
            $result = & $Name
        }

        if ($result) {
            Write-Host "`nFunction Output:" -ForegroundColor Green
            $result | Format-List
        }
        else {
            Write-Host "`nFunction executed but returned no output." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error executing function ${Name}: $_" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    }
}

Invoke-DebugFunction -Name $FunctionName
