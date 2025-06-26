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

function Invoke-AzGraphQueryWithPagination {
    [CmdletBinding()]
    param (
        [string]$Query,
        [int]$PageSize = 1000
    )

    $results = @()
    $skipToken = $null

    do {
        $response = Search-AzGraph -Query "$Query" -First $PageSize -SkipToken $skipToken
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
        'Low' { $weight = 1;break; }
        'Medium' { $weight = 3;break; }
        'High' { $weight = 5;break; }
        'Important' { $weight = 7;break; }
        Default { break; }
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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
    Write-Output "Function '$FunctionName' Execution Time: $($executionTime.TotalSeconds) seconds"
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
            Write-Output "  Warning: $WarningMessage - $($_.Exception.Message)"
            return $FallbackValue
        }
    }
    else {
        Write-Output "  Warning: $CmdletName not available. Install module: $ModuleName"
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