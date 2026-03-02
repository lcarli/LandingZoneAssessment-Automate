<#
.SYNOPSIS
    Shared functions for multiple uses.

.DESCRIPTION
    This script contains functions for multiple uses shared across multiple scripts.

.LICENSE
    MIT License

.AUTHOR
    maximeroy@microsoft.com
#>

# ========================================
# RESOURCE TYPES THAT DO NOT SUPPORT DIAGNOSTIC SETTINGS
# ========================================
# These types return "The resource type '<type>' does not support diagnostic settings."
# when queried with Get-AzDiagnosticSetting. Pre-filtering avoids thousands of
# unnecessary (and failing) API calls per assessment run.
$global:DiagnosticSettingsUnsupportedTypes = @(
    "microsoft.alertsmanagement/smartdetectoralertrules"
    "microsoft.app/managedenvironments/certificates"
    "microsoft.automation/automationaccounts/runbooks"
    "microsoft.azurearcdata/sqlserverinstances"
    "microsoft.azurearcdata/sqlserverinstances/databases"
    "microsoft.communication/emailservices"
    "microsoft.communication/emailservices/domains"
    "microsoft.compute/galleries"
    "microsoft.compute/galleries/images"
    "microsoft.compute/galleries/images/versions"
    "microsoft.compute/images"
    "microsoft.compute/restorepointcollections"
    "microsoft.compute/snapshots"
    "microsoft.compute/sshpublickeys"
    "microsoft.compute/virtualmachines/extensions"
    "microsoft.containerregistry/registries/replications"
    "microsoft.devtestlab/schedules"
    "microsoft.hybridcompute/machines"
    "microsoft.hybridcompute/machines/extensions"
    "microsoft.insights/actiongroups"
    "microsoft.insights/datacollectionendpoints"
    "microsoft.insights/metricalerts"
    "microsoft.insights/scheduledqueryrules"
    "microsoft.insights/workbooks"
    "microsoft.migrate/assessmentprojects"
    "microsoft.migrate/migrateprojects"
    "microsoft.migrate/movecollections"
    "microsoft.network/dnsresolvers/inboundendpoints"
    "microsoft.network/dnsresolvers/outboundendpoints"
    "microsoft.network/localnetworkgateways"
    "microsoft.network/privatednszones/virtualnetworklinks"
    "microsoft.network/privateendpoints"
    "microsoft.network/routetables"
    "microsoft.offazure/mastersites"
    "microsoft.offazure/vmwaresites"
    "microsoft.operationalinsights/querypacks"
    "microsoft.operationsmanagement/solutions"
    "microsoft.portal/dashboards"
    "microsoft.resources/templatespecs"
    "microsoft.resources/templatespecs/versions"
    "microsoft.saas/resources"
    "microsoft.security/automations"
    "microsoft.sentinelplatformservices/sentinelplatformservices"
    "microsoft.visualstudio/account"
    "microsoft.web/certificates"
)

function Invoke-AzGraphQueryWithPagination {
    [CmdletBinding()]
    param (
        [string]$Query,
        [int]$PageSize = 1000
    )

    $results = @()
    $skipToken = $null

    # Scope to known subscriptions to avoid tenant-level auth (MFA/Conditional Access issues)
    $subscriptionIds = if ($global:AzData -and $global:AzData.Subscriptions) {
        @($global:AzData.Subscriptions | ForEach-Object { $_.Id } | Where-Object { $_ })
    } else { @() }

    # If no subscriptions are available, skip the query to avoid unauthenticated tenant calls
    if ($subscriptionIds.Count -eq 0) {
        return @()
    }

    do {
        $graphParams = @{
            Query        = $Query
            First        = $PageSize
            Subscription = $subscriptionIds
        }
        if ($skipToken) { $graphParams['SkipToken'] = $skipToken }
        $response = Search-AzGraph @graphParams
        $results += $response.Data
        $skipToken = $response.SkipToken
    } while ($skipToken)

    return $results
}

function Set-EvaluationResultObject {
    [CmdletBinding()]
    param (
        [string]$status,
        [int]$estimatedPercentageApplied,
        [Object]$checklistItem,
        [Object]$rawData
    )

    $weight = switch ($checklistItem.severity) {
        'Low'       { 1 }
        'Medium'    { 3 }
        'High'      { 5 }
        'Important' { 7 }
        Default     { 0 }
    }
    
    $resultObject = [PSCustomObject]@{
        Status                     = $status
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = ($weight * $estimatedPercentageApplied) / 100
        QuestionId                 = $checklistItem.id
        QuestionText               = $checklistItem.text
        RawData                    = $rawData
        RawSource                  = $checklistItem
    }

    return $resultObject
}

function Test-QuestionAzureResourceGraph {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0

    try {
        $queryResults = Invoke-AzGraphQueryWithPagination -Query "$($checklistItem.graph)" -PageSize 1000
        if ($queryResults.count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            if ($queryResults.Compliant -contains 0) {
                if ($queryResults.Compliant -contains 1){
                    $status = [Status]::PartiallyImplemented
                }
                else {
                    $status = [Status]::NotImplemented
                }
                $compliantCount = $($queryResults.Compliant | Where-Object { $_ -eq 1 }).Count
                $estimatedPercentageApplied = (($compliantCount / $($queryResults.Compliant).Count) * 100)
            }
            else {
                $estimatedPercentageApplied = 100
                $status = [Status]::Implemented
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $_ -rawData $queryResults
}

function Measure-ExecutionTime {
    param (
        [ScriptBlock]$ScriptBlock,
        [string]$FunctionName = "Unnamed Function"
    )

    # Record the start time
    $startTime = Get-Date
    
    # Execute the script block
    & $ScriptBlock
    
    # Record the end time
    $endTime = Get-Date
    
    # Calculate and output the duration
    $executionTime = $endTime - $startTime
    Write-Host "Function '$FunctionName' Execution Time: $($executionTime.TotalSeconds) seconds" -ForegroundColor Cyan
}

# Helper function to test if a cmdlet is available
function Test-CmdletAvailable {
    param(
        [string]$CmdletName,
        [string]$ModuleName = $null
    )
    
    try {
        $cmd = Get-Command $CmdletName -ErrorAction SilentlyContinue
        if ($cmd) {
            return $true
        }
        
        # If module name is provided, try to import it
        if ($ModuleName) {
            Import-Module $ModuleName -Force -ErrorAction SilentlyContinue
            $cmd = Get-Command $CmdletName -ErrorAction SilentlyContinue
            return $null -ne $cmd
        }
        
        return $false
    }
    catch {
        return $false
    }
}

# Helper function to safely execute Azure cmdlets with fallback
function Invoke-AzCmdletSafely {
    param(
        [scriptblock]$ScriptBlock,
        [string]$CmdletName,
        [string]$ModuleName = $null,
        [object]$FallbackValue = $null,
        [string]$WarningMessage = "Cmdlet not available"
    )
    
    if (Test-CmdletAvailable -CmdletName $CmdletName -ModuleName $ModuleName) {
        try {
            return & $ScriptBlock
        }
        catch {
            Write-Host "  Warning: $WarningMessage - $($_.Exception.Message)" -ForegroundColor Yellow
            return $FallbackValue
        }
    }
    else {
        Write-Host "  Warning: $CmdletName not available. Install module: $ModuleName" -ForegroundColor Yellow
        return $FallbackValue
    }
}

# ========================================
# STANDARDIZED LOGGING FUNCTIONS
# ========================================

<#
.SYNOPSIS
    Standardized logging functions for consistent output formatting across the assessment.

.DESCRIPTION
    These functions provide consistent colored output for different types of messages:
    - Write-AssessmentInfo: General information (Cyan)
    - Write-AssessmentProgress: Progress messages (Green) 
    - Write-AssessmentWarning: Warning messages (Yellow)
    - Write-AssessmentError: Error messages (Red)
    - Write-AssessmentSuccess: Success messages (Green)
    - Write-AssessmentHeader: Section headers (Magenta)

.NOTES
    All functions write to the host (transcript) only and do not pollute the object pipeline.
#>

function Write-AssessmentInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Cyan
}

function Write-AssessmentProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Green
}

function Write-AssessmentWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Yellow
}

function Write-AssessmentError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Red
}

function Write-AssessmentSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Green
}

function Write-AssessmentHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Magenta
}

function Test-ConfigValidation {
    <#
    .SYNOPSIS
        Validates the config.json structure, required fields, and value formats.
    .DESCRIPTION
        Checks for required properties, validates TenantId as a GUID, validates
        ContractType against the enum, validates DesignAreas structure, and
        validates the checklist file exists.
    .PARAMETER Config
        The parsed config object from config.json.
    .PARAMETER ConfigPath
        The path to the config.json file (used to resolve relative paths).
    .OUTPUTS
        PSCustomObject with IsValid (bool), Errors (string[]), and Warnings (string[]).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    $errors = @()
    $warnings = @()
    $guidRegex = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    $validContractTypes = @('EnterpriseAgreement', 'MicrosoftCustomerAgreement', 'CloudSolutionProvider', 'MicrosoftEntraIDTenants')
    $validDesignAreas = @('Billing', 'IAM', 'ResourceOrganization', 'Network', 'Governance', 'Security', 'DevOps', 'Management')

    # --- Required fields ---
    # TenantId
    if ($null -eq $Config.PSObject.Properties['TenantId'] -or [string]::IsNullOrWhiteSpace($Config.TenantId)) {
        $errors += "TenantId is required and cannot be empty."
    }
    elseif ($Config.TenantId -notmatch $guidRegex) {
        $errors += "TenantId '$($Config.TenantId)' is not a valid GUID format (expected: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
    }

    # ContractType
    if ($null -eq $Config.PSObject.Properties['ContractType'] -or [string]::IsNullOrWhiteSpace($Config.ContractType)) {
        $errors += "ContractType is required and cannot be empty."
    }
    elseif ($Config.ContractType -notin $validContractTypes) {
        $errors += "ContractType '$($Config.ContractType)' is not valid. Valid options: $($validContractTypes -join ', ')."
    }

    # AlzChecklist
    if ($null -eq $Config.PSObject.Properties['AlzChecklist'] -or [string]::IsNullOrWhiteSpace($Config.AlzChecklist)) {
        $errors += "AlzChecklist is required and cannot be empty."
    }
    else {
        $configDir = Split-Path -Parent (Resolve-Path $ConfigPath -ErrorAction SilentlyContinue)
        if ($null -ne $configDir) {
            $checklistFullPath = Join-Path $configDir $Config.AlzChecklist
            if (-not (Test-Path $checklistFullPath)) {
                $errors += "Checklist file '$($Config.AlzChecklist)' not found at: $checklistFullPath"
            }
        }
    }

    # DesignAreas
    if ($null -eq $Config.PSObject.Properties['DesignAreas'] -or $null -eq $Config.DesignAreas) {
        $errors += "DesignAreas object is required."
    }
    else {
        foreach ($area in $validDesignAreas) {
            if ($null -eq $Config.DesignAreas.PSObject.Properties[$area]) {
                $errors += "DesignAreas is missing required key: '$area'."
            }
            elseif ($Config.DesignAreas.$area -isnot [bool]) {
                $errors += "DesignAreas.$area must be a boolean (true/false), got: '$($Config.DesignAreas.$area)'."
            }
        }

        # Check no design areas are enabled
        $enabledCount = ($validDesignAreas | Where-Object { $Config.DesignAreas.$_ -eq $true }).Count
        if ($enabledCount -eq 0) {
            $warnings += "No design areas are enabled. The assessment will not evaluate any area."
        }
    }

    # --- Optional fields with validation ---
    # DefaultSubscriptionId (optional but validate GUID if provided)
    if ($null -ne $Config.PSObject.Properties['DefaultSubscriptionId'] -and -not [string]::IsNullOrWhiteSpace($Config.DefaultSubscriptionId)) {
        if ($Config.DefaultSubscriptionId -notmatch $guidRegex) {
            $warnings += "DefaultSubscriptionId '$($Config.DefaultSubscriptionId)' is not a valid GUID format."
        }
    }

    # DefaultRegion (optional, warn if missing)
    if ($null -eq $Config.PSObject.Properties['DefaultRegion'] -or [string]::IsNullOrWhiteSpace($Config.DefaultRegion)) {
        $warnings += "DefaultRegion is not set. Defaulting to 'eastus2'."
    }

    return [PSCustomObject]@{
        IsValid  = ($errors.Count -eq 0)
        Errors   = $errors
        Warnings = $warnings
    }
}