# PlatformAutomationandDevOps.ps1

<#
.SYNOPSIS
    Functions related to PlatformAutomationandDevOps assessment.

.DESCRIPTION
    This script contains functions to evaluate the PlatformAutomationandDevOps area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-PlatformAutomationandDevOpsAssessment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )
    Measure-ExecutionTime -ScriptBlock {
        $results = @()
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H01.01") }) | Test-QuestionH0101
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H01.02") }) | Test-QuestionH0102
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H01.03") }) | Test-QuestionH0103
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H01.04") }) | Test-QuestionH0104
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H01.05") }) | Test-QuestionH0105
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H01.06") }) | Test-QuestionH0106
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H01.07") }) | Test-QuestionH0107
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H02.01") }) | Test-QuestionH0201
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H02.02") }) | Test-QuestionH0202
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H02.03") }) | Test-QuestionH0203
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H02.04") }) | Test-QuestionH0204
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H03.01") }) | Test-QuestionH0301
        $results += ($Checklist.items | Where-Object { ($_.id -eq "H04.01") }) | Test-QuestionH0401

        $script:FunctionResult = $results
    } -FunctionName "Invoke-PlatformAutomationandDevOpsAssessment"

    return $script:FunctionResult
}

# Function for Management item H01.01
function Test-QuestionH0101 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires a manual verification of the organizational setup, roles, and responsibilities for the Azure Landing Zone DevOps Platform Team."

    try {
        # Question: Ensure you have a cross functional DevOps Platform Team to build, manage and maintain your Azure Landing Zone architecture.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/platform-automation-devops
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item H01.02
function Test-QuestionH0102 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires a manual verification to ensure that Azure Landing Zone Platform team functions are well-defined and documented."

    try {
        # Question: Aim to define functions for Azure Landing Zone Platform team.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/devops-teams-topologies#design-recommendations
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item H01.03
function Test-QuestionH0103 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires a manual verification to ensure that RBAC roles are defined and applied appropriately for application workload team self-sufficiency."

    try {
        # Question: Aim to define functions for application workload teams to be self-sufficient and not require DevOps Platform Team support. Achieve this through the use of custom RBAC role.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/devops-teams-topologies#design-recommendations

        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Platform Automation and DevOps item H01.04
function Test-QuestionH0104 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires a manual verification to ensure that RBAC roles are defined and applied appropriately for application workload team self-sufficiency."

    try {
        # Question: Use a CI/CD pipeline to deploy IaC artifacts and ensure the quality of your deployment and Azure environments.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/infrastructure-as-code

        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
    return $result
}

# Function for H01.05
function Test-QuestionH0105 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification of unit test integration in build pipelines."

    try {
        # Question: Include unit tests for IaC and application code as part of your build process.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/development-strategy-development-lifecycle#automated-builds
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for H01.06
function Test-QuestionH0106 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure proper implementation of end-to-end tests."

    try {
        # Question: Ensure end-to-end tests are included in your deployment pipeline.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/development-strategy-development-lifecycle#automated-builds
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for H01.07
function Test-QuestionH0107 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to validate code quality gates in your pipelines."

    try {
        # Question: Validate code quality gates in your pipelines.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/subscription-vending
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for H02.01
function Test-QuestionH0201 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to confirm proper use of IaC in deployment pipelines."

    try {
        # Question: Use Infrastructure as Code (IaC) in deployment pipelines.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/infrastructure-as-code
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for H02.02
function Test-QuestionH0202 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification for RBAC compliance within deployment pipelines."

    try {
        # Question: Ensure RBAC compliance in deployment pipelines.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/development-strategy-development-lifecycle
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for H02.03
function Test-QuestionH0203 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification for artifact repository management in pipelines."

    try {
        # Question: Use artifact repositories to manage shared libraries in pipelines.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/development-strategy-development-lifecycle
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for H02.04
function Test-QuestionH0204 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification of secrets management integration in pipelines."

    try {
        # Question: Integrate secrets management in deployment pipelines.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/management-platform
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item H03.01
function Test-QuestionH0301 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure that processes and policies are aligned."

    try {
        # Question: Ensure appropriate processes and practices are in place for H03.01.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/infrastructure-as-code
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item H04.01
function Test-QuestionH0401 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure that processes and policies are aligned."

    try {
        # Question: Ensure appropriate processes and practices are in place for H04.01.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/landing-zone-security#secure
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}
