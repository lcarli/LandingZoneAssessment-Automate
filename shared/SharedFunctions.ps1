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
        [string]$questionId,
        [string]$subCategory
    )

    $localChecklist = $global:Checklist
    $currentChecklistItem = $localChecklist.items | Where-Object { $_.id -eq $questionId } | ConvertTo-Json -Depth 5
    if ($subCategory) {
        $currentChecklistItem = $currentChecklistItem | Where-Object { $_.id -eq $questionId -and $_.subCategory -eq $subCategory} | ConvertTo-Json -Depth 5
    }

    $weight = switch ($currentChecklistItem.severity) {
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
        QuestionId                 = $currentChecklistItem.id
        QuestionText               = $currentChecklistItem.text
        RawData                    = $currentChecklistItem
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

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $_ -rawData $queryResults

    return $result
}