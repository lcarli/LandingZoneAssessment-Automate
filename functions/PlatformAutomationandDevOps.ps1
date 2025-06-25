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

# Dot-source shared modules
. "$PSScriptRoot/../shared/Enums.ps1"
. "$PSScriptRoot/../shared/ErrorHandling.ps1"
. "$PSScriptRoot/../shared/SharedFunctions.ps1"

function Invoke-PlatformAutomationandDevOpsAssessment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )

    Write-AssessmentHeader "Evaluating the Platform Automation and DevOps design area..."
    
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

function Test-QuestionH0101 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires a manual verification of the organizational setup, roles, and responsibilities for the Azure Landing Zone DevOps Platform Team."

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

function Test-QuestionH0102 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires a manual verification to ensure that Azure Landing Zone Platform team functions are well-defined and documented."

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

function Test-QuestionH0103 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

function Test-QuestionH0104 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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
}

function Test-QuestionH0105 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires manual verification of unit test integration in build pipelines."

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

function Test-QuestionH0106 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires manual verification to ensure Key Vault is used for sensitive information."

    try {
        # Question: Use Key Vault secrets to avoid hard-coding sensitive information such as credentials (virtual machines user passwords), certificates or keys.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/development-strategy-development-lifecycle#automated-builds
        
        # Check if Key Vaults exist in the environment
        if ($global:AzData -and $global:AzData.Resources) {
            $keyVaults = $global:AzData.Resources | Where-Object { $_.ResourceType -eq "Microsoft.KeyVault/vaults" }
            
            if ($keyVaults -and $keyVaults.Count -gt 0) {
                $status = [Status]::Passed
                $estimatedPercentageApplied = 85 # Partial - existence indicates usage but manual verification needed for proper implementation
                $rawData = @{
                    KeyVaultCount = $keyVaults.Count
                    KeyVaultNames = $keyVaults.Name
                    Note = "Key Vaults found in environment. Manual verification needed to confirm proper usage for sensitive information storage."
                }
            } else {
                $status = [Status]::Failed
                $estimatedPercentageApplied = 0
                $rawData = "No Key Vaults found in the environment. Consider implementing Key Vault for storing sensitive information."
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = "Unable to check Key Vault existence automatically. Manual verification required."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionH0107 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires manual verification to validate code quality gates in your pipelines."

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

function Test-QuestionH0201 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires manual verification to confirm proper use of IaC in deployment pipelines."

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

function Test-QuestionH0202 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires manual verification for RBAC compliance within deployment pipelines."

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

function Test-QuestionH0203 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires manual verification for artifact repository management in pipelines."

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

function Test-QuestionH0204 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires manual verification of secrets management integration in pipelines."

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

function Test-QuestionH0301 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires manual verification to ensure Infrastructure as Code usage."

    try {
        # Question: Leverage Declarative Infrastructure as Code Tools such as Azure Bicep, ARM Templates or Terraform to build and maintain your Azure Landing Zone architecture.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/infrastructure-as-code
        
        # Check for evidence of IaC usage through resource group tags or deployment history
        $iacEvidence = @{
            DeploymentTemplates = 0
            ResourceGroupsWithDeploymentTags = 0
            TotalResourceGroups = 0
        }
        
        if ($global:AzData -and $global:AzData.ResourceGroups) {
            $iacEvidence.TotalResourceGroups = $global:AzData.ResourceGroups.Count
            
            # Check for deployment-related tags that indicate IaC usage
            $deploymentTags = @('deployedBy', 'deployment', 'template', 'bicep', 'terraform', 'arm', 'iac')
            $rgWithDeploymentTags = $global:AzData.ResourceGroups | Where-Object {
                $rgTags = $_.Tags
                if ($rgTags) {
                    $tagKeys = $rgTags.Keys | ForEach-Object { $_.ToLower() }
                    ($deploymentTags | Where-Object { $tagKeys -contains $_ }).Count -gt 0
                }
            }
            
            if ($rgWithDeploymentTags) {
                $iacEvidence.ResourceGroupsWithDeploymentTags = $rgWithDeploymentTags.Count
            }
            
            # Check deployment history for template deployments (limited check)
            if ($global:AzData.Resources) {
                # Look for resources that typically indicate template deployment
                $templateDeployedResources = $global:AzData.Resources | Where-Object {
                    $_.Tags -and ($_.Tags.Keys | Where-Object { $deploymentTags -contains $_.ToLower() })
                }
                
                if ($templateDeployedResources) {
                    $iacEvidence.DeploymentTemplates = $templateDeployedResources.Count
                }
            }
            
            # Evaluate IaC usage
            $totalIndicators = $iacEvidence.ResourceGroupsWithDeploymentTags + $iacEvidence.DeploymentTemplates
            
            if ($totalIndicators -gt 0) {
                $status = [Status]::Passed
                $estimatedPercentageApplied = [Math]::Min(90, ($totalIndicators / $iacEvidence.TotalResourceGroups) * 100)
                $rawData = @{
                    IaCEvidence = $iacEvidence
                    Note = "Found evidence of IaC usage through deployment tags and resource metadata. Full verification recommended."
                }
            } else {
                $status = [Status]::ManualVerificationRequired
                $estimatedPercentageApplied = 0
                $rawData = @{
                    IaCEvidence = $iacEvidence
                    Note = "No clear evidence of IaC usage found in resource tags. Manual verification required to assess actual IaC implementation."
                }
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = "Unable to check IaC evidence automatically. Manual verification required to assess Infrastructure as Code implementation."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionH0401 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This Platform Automation and DevOps item requires manual verification to ensure that processes and policies are aligned."

    try {
        # Question: Integrate security into the already combined process of development and operations in DevOps to mitigate risks in the innovation process.
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
