# NetworkTopologyandConnectivity.ps1

<#
.SYNOPSIS
    Functions related to NetworkTopologyandConnectivity assessment.

.DESCRIPTION
    This script contains functions to evaluate the NetworkTopologyandConnectivity area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    maximeroy@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"
Import-Module "$PSScriptRoot/../shared/SharedFunctions.ps1"
function Invoke-NetworkTopologyandConnectivityAssessment {
    Write-Host "Evaluating the NetworkTopologyandConnectivity design area..."

    $results = @()
    $config = Get-Content -Path "$PSScriptRoot/../shared/config.json" | ConvertFrom-Json
    $checklist = Get-Content -Path "$PSScriptRoot/../$($config.AlzChecklist)" | ConvertFrom-Json


    return $results
}

function Test-QuestionD0105 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = Set-WeightValue -Severity $checklistItem.severity
    $score = 0

    try {


        if ($numberOfTenants -eq 1) {

        }
        else {

            if ($estimatedPercentageApplied -eq 0) {
                $status = [Status]::NotImplemented
            }
            else {
                $status = [Status]::PartiallyImplemented
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}