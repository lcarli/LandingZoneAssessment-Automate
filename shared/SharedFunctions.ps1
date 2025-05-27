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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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
    $originalErrorActionPreference = $ErrorActionPreference
    $originalProgressPreference = $ProgressPreference

    try {
        # Create a runspace to execute the script block
        # This approach isolates the execution to prevent issues when interrupted with Ctrl+C
        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("ScriptBlock", $ScriptBlock)
        $runspace.SessionStateProxy.SetVariable("ErrorActionPreference", $ErrorActionPreference)
        $runspace.SessionStateProxy.SetVariable("ProgressPreference", $ProgressPreference)
        
        $powershell = [powershell]::Create()
        $powershell.Runspace = $runspace
        $powershell.AddScript({
            # Execute the script block in an isolated context
            & $ScriptBlock
        }) | Out-Null

        # Execute the script and handle interruptions
        $asyncResult = $powershell.BeginInvoke()
        
        # Wait for the script to complete or be interrupted
        while (-not $asyncResult.IsCompleted) {
            # Check if Ctrl+C was pressed
            if ([Console]::KeyAvailable -and [Console]::ReadKey($true).Key -eq [ConsoleKey]::C -and [Console]::KeyAvailable -and [Console]::ReadKey($true).Modifiers -eq [ConsoleModifiers]::Control) {
                Write-Host "`nExecution canceled by user (Ctrl+C). Cleaning up resources..."
                $powershell.Stop()
                break
            }
            # Add small delay to reduce CPU usage
            Start-Sleep -Milliseconds 100
        }

        # Get the result (if not interrupted)
        if ($asyncResult.IsCompleted) {
            $powershell.EndInvoke($asyncResult)
        }
    }
    catch {
        Write-Host "An error occurred during execution: $_"
    }
    finally {
        # Ensure resources are properly disposed
        if ($powershell) {
            $powershell.Dispose()
        }
        if ($runspace) {
            $runspace.Close()
            $runspace.Dispose()
        }
        
        # Restore original preferences
        $ErrorActionPreference = $originalErrorActionPreference
        $ProgressPreference = $originalProgressPreference

        # Record the end time
        $endTime = Get-Date

        # Calculate and output the duration
        $executionTime = $endTime - $startTime
        Write-Host "Function '$FunctionName' Execution Time: $($executionTime.TotalSeconds) seconds"
    }
}