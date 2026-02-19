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

        $evidence = @{
            DevOpsGroups = @()
            PlatformServicePrincipals = @()
        }

        # Check Entra ID groups for DevOps/Platform team indicators
        if ($global:GraphData -and $global:GraphData.Groups) {
            $devOpsKeywords = @('devops', 'platform', 'landing zone', 'alz', 'cloud engineering', 'sre', 'infrastructure')
            $evidence.DevOpsGroups = @($global:GraphData.Groups | Where-Object {
                $name = $_.DisplayName
                if ($name) {
                    ($devOpsKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            } | Select-Object -Property DisplayName, Id -First 20)
        }

        # Check service principals for automation/pipeline indicators
        if ($global:GraphData -and $global:GraphData.ServicePrincipals) {
            $spKeywords = @('azure devops', 'github', 'pipeline', 'terraform', 'deployment', 'automation')
            $evidence.PlatformServicePrincipals = @($global:GraphData.ServicePrincipals | Where-Object {
                $name = $_.DisplayName
                if ($name) {
                    ($spKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            } | Select-Object -Property DisplayName, Id -First 20)
        }

        $hasEvidence = ($evidence.DevOpsGroups.Count -gt 0) -or ($evidence.PlatformServicePrincipals.Count -gt 0)

        if ($hasEvidence) {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 30
            $rawData = @{
                Evidence = $evidence
                DevOpsGroupCount = $evidence.DevOpsGroups.Count
                ServicePrincipalCount = $evidence.PlatformServicePrincipals.Count
                Note = "Found indicators of DevOps/Platform team structure. Manual verification required to confirm cross-functional team responsibilities."
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = @{
                Evidence = $evidence
                Note = "No DevOps/Platform team indicators found in Entra ID groups or service principals. Manual verification required to assess team structure."
            }
        }
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

        $evidence = @{
            PlatformGroups = @()
            RoleAssignmentCount = 0
        }

        # Check for groups with platform team naming patterns
        if ($global:GraphData -and $global:GraphData.Groups) {
            $platformKeywords = @('platform', 'landing zone', 'alz', 'connectivity', 'identity', 'management', 'security')
            $evidence.PlatformGroups = @($global:GraphData.Groups | Where-Object {
                $name = $_.DisplayName
                if ($name) {
                    ($platformKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            } | Select-Object -Property DisplayName, Id -First 20)
        }

        # Check for role assignments to indicate defined responsibilities
        if ($global:GraphData -and $global:GraphData.RoleAssignments) {
            $evidence.RoleAssignmentCount = $global:GraphData.RoleAssignments.Count
        }

        if ($evidence.PlatformGroups.Count -gt 0) {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 25
            $rawData = @{
                Evidence = $evidence
                PlatformGroupCount = $evidence.PlatformGroups.Count
                Note = "Found $($evidence.PlatformGroups.Count) groups with platform team naming patterns. Manual verification required to confirm team functions are well-defined."
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = @{
                Evidence = $evidence
                Note = "No groups with platform team naming patterns found. Manual verification required to assess team function definitions."
            }
        }
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

        $evidence = @{
            CustomRoles = @()
            CustomRoleCount = 0
        }

        # Check for custom RBAC role definitions
        $customRoles = Invoke-AzCmdletSafely -CmdletName "Get-AzRoleDefinition" -Parameters @{ Custom = $true } -Description "Retrieving custom RBAC role definitions"

        if ($customRoles) {
            $evidence.CustomRoles = @($customRoles | Select-Object -Property Name, Id, Description -First 20)
            $evidence.CustomRoleCount = @($customRoles).Count
        }

        if ($evidence.CustomRoleCount -gt 0) {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = 50
            $rawData = @{
                Evidence = $evidence
                Note = "Found $($evidence.CustomRoleCount) custom RBAC role definitions. Review roles to ensure workload teams have self-sufficient access without requiring Platform Team intervention."
            }
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = @{
                Evidence = $evidence
                Note = "No custom RBAC role definitions found. Consider creating custom roles to enable workload team self-sufficiency."
            }
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionH0104 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to confirm CI/CD pipeline usage for IaC deployment."

    try {
        # Question: Use a CI/CD pipeline to deploy IaC artifacts and ensure the quality of your deployment and Azure environments.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/infrastructure-as-code

        $evidence = @{
            DeploymentScripts = @()
            DevOpsResources = @()
            PipelineServicePrincipals = @()
            IaCTaggedResources = 0
        }

        if ($global:AzData -and $global:AzData.Resources) {
            # Check for deployment script resources
            $evidence.DeploymentScripts = @($global:AzData.Resources | Where-Object {
                $_.ResourceType -eq "Microsoft.Resources/deploymentScripts"
            } | Select-Object -Property Name, ResourceGroupName -First 20)

            # Check for Azure DevOps pipeline resources
            $evidence.DevOpsResources = @($global:AzData.Resources | Where-Object {
                $_.ResourceType -like "Microsoft.DevOps/*" -or $_.ResourceType -like "Microsoft.DevCenter/*"
            } | Select-Object -Property Name, ResourceType, ResourceGroupName -First 20)

            # Check for IaC-tagged resources indicating pipeline deployment
            $iacTags = @('deployedBy', 'deployment', 'template', 'bicep', 'terraform', 'arm', 'iac', 'pipeline', 'cicd')
            $evidence.IaCTaggedResources = @($global:AzData.Resources | Where-Object {
                $_.Tags -and ($_.Tags.Keys | Where-Object { $iacTags -contains $_.ToLower() })
            }).Count
        }

        # Check for pipeline service principals
        if ($global:GraphData -and $global:GraphData.ServicePrincipals) {
            $pipelineKeywords = @('azure devops', 'github actions', 'pipeline', 'cicd', 'deployment')
            $evidence.PipelineServicePrincipals = @($global:GraphData.ServicePrincipals | Where-Object {
                $name = $_.DisplayName
                if ($name) {
                    ($pipelineKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            } | Select-Object -Property DisplayName, Id -First 20)
        }

        $totalIndicators = $evidence.DeploymentScripts.Count + $evidence.DevOpsResources.Count + $evidence.PipelineServicePrincipals.Count + $evidence.IaCTaggedResources

        if ($totalIndicators -gt 0) {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = [Math]::Min(70, $totalIndicators * 10)
            $rawData = @{
                Evidence = $evidence
                TotalIndicators = $totalIndicators
                Note = "Found evidence of CI/CD pipeline usage: $totalIndicators indicators detected. Manual verification recommended to confirm pipeline quality gates and IaC deployment practices."
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
            $rawData = @{
                Evidence = $evidence
                Note = "No CI/CD pipeline indicators found in Azure resources or service principals. Manual verification required."
            }
        }
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

        # Unit test integration cannot be verified from Azure resource data.
        # Collect pipeline evidence to provide context for manual review.
        $evidence = @{
            PipelineServicePrincipals = @()
            HasPipelineEvidence = $false
        }

        if ($global:GraphData -and $global:GraphData.ServicePrincipals) {
            $pipelineKeywords = @('azure devops', 'github actions', 'pipeline', 'cicd')
            $evidence.PipelineServicePrincipals = @($global:GraphData.ServicePrincipals | Where-Object {
                $name = $_.DisplayName
                if ($name) {
                    ($pipelineKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            } | Select-Object -Property DisplayName, Id -First 10)
            $evidence.HasPipelineEvidence = $evidence.PipelineServicePrincipals.Count -gt 0
        }

        $status = [Status]::ManualVerificationRequired
        if ($evidence.HasPipelineEvidence) {
            $rawData = @{
                Evidence = $evidence
                Note = "CI/CD pipelines detected: $($evidence.PipelineServicePrincipals.Count) pipeline SPs found. Verify that unit tests for IaC such as Pester, tflint, or bicep linter are integrated into build pipelines."
            }
        } else {
            $rawData = @{
                Evidence = $evidence
                Note = "No CI/CD pipeline indicators found. Manual verification required to assess unit test integration in build processes."
            }
        }
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
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 85 # Partial - existence indicates usage but manual verification needed for proper implementation
                $rawData = @{
                    KeyVaultCount = $keyVaults.Count
                    KeyVaultNames = $keyVaults.Name
                    Note = "Key Vaults found in environment. Manual verification needed to confirm proper usage for sensitive information storage."
                }
            } else {
                $status = [Status]::NotImplemented
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
    $rawData = "This Platform Automation and DevOps item requires manual verification of subscription vending automation."

    try {
        # Question: Implement automation for new landing zone for applications and workloads through subscription vending.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/subscription-vending

        $evidence = @{
            ManagementGroupCount = 0
            ManagementGroupNames = @()
            HasALZStructure = $false
            SubscriptionCount = 0
            VendingPolicies = @()
        }

        # Check management group structure for ALZ patterns (indicates structured subscription management)
        if ($global:AzData -and $global:AzData.ManagementGroups) {
            $evidence.ManagementGroupCount = $global:AzData.ManagementGroups.Count
            $evidence.ManagementGroupNames = @($global:AzData.ManagementGroups | ForEach-Object {
                if ($_.DisplayName) { $_.DisplayName } else { $_.Name }
            })

            # Check for ALZ-standard MG naming patterns
            $alzPatterns = @('sandbox', 'decommissioned', 'corp', 'online', 'platform', 'landing zone', 'connectivity', 'identity', 'management')
            $matchingMGs = @($evidence.ManagementGroupNames | Where-Object {
                $mgName = $_
                ($alzPatterns | Where-Object { $mgName -ilike "*$_*" }).Count -gt 0
            })

            $evidence.HasALZStructure = $matchingMGs.Count -ge 3
        }

        # Check subscriptions count
        if ($global:AzData -and $global:AzData.Subscriptions) {
            $evidence.SubscriptionCount = $global:AzData.Subscriptions.Count
        }

        # Check for subscription governance policies
        if ($global:AzData -and $global:AzData.Policies) {
            $vendingKeywords = @('subscription', 'vending', 'landing zone', 'naming', 'tagging')
            $evidence.VendingPolicies = @($global:AzData.Policies | Where-Object {
                $name = if ($_.Properties.DisplayName) { $_.Properties.DisplayName } else { $_.Name }
                if ($name) {
                    ($vendingKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            } | Select-Object -Property Name -First 20)
        }

        if ($evidence.HasALZStructure) {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = 40
            $rawData = @{
                Evidence = $evidence
                MatchingMGPatterns = $matchingMGs
                Note = "ALZ management group structure detected with $($evidence.ManagementGroupCount) management groups. Manual verification required to confirm subscription vending automation is in place."
            }
        } elseif ($evidence.ManagementGroupCount -gt 1) {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 10
            $rawData = @{
                Evidence = $evidence
                Note = "Management groups exist but no ALZ-standard naming detected. Manual verification required to assess subscription vending setup."
            }
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = @{
                Evidence = $evidence
                Note = "No management group structure found for subscription vending. Consider implementing subscription vending automation."
            }
        }
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
    $rawData = "This Platform Automation and DevOps item requires manual verification to confirm a version control system is in use."

    try {
        # Question: Ensure a version control system is used for source code of applications and IaC developed. Microsoft recommends Git.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/infrastructure-as-code

        $evidence = @{
            DevOpsResources = @()
            GitHubConnectors = @()
            SourceControlServicePrincipals = @()
        }

        # Check for Azure DevOps and GitHub related resources
        if ($global:AzData -and $global:AzData.Resources) {
            $evidence.DevOpsResources = @($global:AzData.Resources | Where-Object {
                $_.ResourceType -like "Microsoft.DevOps/*" -or
                $_.ResourceType -like "Microsoft.DevHub/*" -or
                $_.ResourceType -eq "Microsoft.Web/sourcecontrols"
            } | Select-Object -Property Name, ResourceType, ResourceGroupName -First 20)

            # Check for GitHub/DevOps security connectors
            $evidence.GitHubConnectors = @($global:AzData.Resources | Where-Object {
                $_.ResourceType -eq "Microsoft.Security/securityConnectors" -and $_.Name -ilike "*github*"
            } | Select-Object -Property Name, ResourceGroupName -First 10)
        }

        # Check service principals for source control indicators
        if ($global:GraphData -and $global:GraphData.ServicePrincipals) {
            $scmKeywords = @('azure devops', 'github', 'azure repos', 'bitbucket', 'gitlab')
            $evidence.SourceControlServicePrincipals = @($global:GraphData.ServicePrincipals | Where-Object {
                $name = $_.DisplayName
                if ($name) {
                    ($scmKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            } | Select-Object -Property DisplayName, Id -First 20)
        }

        $totalIndicators = $evidence.DevOpsResources.Count + $evidence.GitHubConnectors.Count + $evidence.SourceControlServicePrincipals.Count

        if ($totalIndicators -gt 0) {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = 60
            $rawData = @{
                Evidence = $evidence
                TotalIndicators = $totalIndicators
                Note = "Found evidence of version control system integration (Azure DevOps/GitHub). Manual verification recommended to confirm all IaC and application code is managed in VCS."
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
            $rawData = @{
                Evidence = $evidence
                Note = "No version control system indicators found in Azure resources. Manual verification required - VCS may be configured externally."
            }
        }
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
    $rawData = "This Platform Automation and DevOps item requires manual verification for branching strategy implementation."

    try {
        # Question: Follow a branching strategy to allow teams to collaborate better and efficiently manage version control of IaC and application Code. Review options such as Github Flow.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/development-strategy-development-lifecycle

        # Branching strategy cannot be verified from Azure resource data alone.
        # Provide context about detected source control integration.
        $evidence = @{
            SourceControlDetected = $false
        }

        if ($global:GraphData -and $global:GraphData.ServicePrincipals) {
            $scmKeywords = @('azure devops', 'github', 'azure repos', 'bitbucket', 'gitlab')
            $scmSPs = @($global:GraphData.ServicePrincipals | Where-Object {
                $name = $_.DisplayName
                if ($name) {
                    ($scmKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            })
            $evidence.SourceControlDetected = $scmSPs.Count -gt 0
        }

        $status = [Status]::ManualVerificationRequired
        if ($evidence.SourceControlDetected) {
            $rawData = @{
                Evidence = $evidence
                Note = "Source control integration detected. Review branching strategy such as GitHub Flow or GitFlow with DevOps team to confirm it is defined and followed."
            }
        } else {
            $rawData = @{
                Evidence = $evidence
                Note = "No source control integration detected in Azure. Manual verification required to assess branching strategy adoption."
            }
        }
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
    $rawData = "This Platform Automation and DevOps item requires manual verification for pull request strategy adoption."

    try {
        # Question: Adopt a pull request strategy to help keep control of code changes merged into branches.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/development-strategy-development-lifecycle

        # Pull request strategy cannot be verified from Azure resource data alone.
        $evidence = @{
            SourceControlDetected = $false
        }

        if ($global:GraphData -and $global:GraphData.ServicePrincipals) {
            $scmKeywords = @('azure devops', 'github', 'azure repos')
            $scmSPs = @($global:GraphData.ServicePrincipals | Where-Object {
                $name = $_.DisplayName
                if ($name) {
                    ($scmKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            })
            $evidence.SourceControlDetected = $scmSPs.Count -gt 0
        }

        $status = [Status]::ManualVerificationRequired
        if ($evidence.SourceControlDetected) {
            $rawData = @{
                Evidence = $evidence
                Note = "Source control integration detected. Review with DevOps team to confirm pull request policies (branch protection, required reviewers, CI checks) are configured."
            }
        } else {
            $rawData = @{
                Evidence = $evidence
                Note = "No source control integration detected in Azure. Manual verification required to assess pull request strategy adoption."
            }
        }
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
    $rawData = "This Platform Automation and DevOps item requires manual verification of quick fix management processes."

    try {
        # Question: Establish a process for using code to implement quick fixes. Always register quick fixes in your team's backlog so each fix can be reworked at a later point, and you can limit technical debt.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/management-platform

        # Quick fix process is organizational and cannot be fully verified from Azure data.
        # Check for DevOps/boards integration as indirect evidence.
        $evidence = @{
            DevOpsIntegration = $false
            TrackingServicePrincipals = @()
        }

        if ($global:GraphData -and $global:GraphData.ServicePrincipals) {
            $trackingKeywords = @('azure devops', 'azure boards', 'jira', 'servicenow', 'github')
            $evidence.TrackingServicePrincipals = @($global:GraphData.ServicePrincipals | Where-Object {
                $name = $_.DisplayName
                if ($name) {
                    ($trackingKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            } | Select-Object -Property DisplayName, Id -First 10)
            $evidence.DevOpsIntegration = $evidence.TrackingServicePrincipals.Count -gt 0
        }

        $status = [Status]::ManualVerificationRequired
        if ($evidence.DevOpsIntegration) {
            $rawData = @{
                Evidence = $evidence
                Note = "Work item tracking integration detected with $($evidence.TrackingServicePrincipals.Count) service principals. Verify that quick fixes are registered in the backlog and reworked to limit technical debt."
            }
        } else {
            $rawData = @{
                Evidence = $evidence
                Note = "No work item tracking integration detected. Manual verification required to assess quick fix management and backlog tracking processes."
            }
        }
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
                $status = [Status]::Implemented
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
    $rawData = "This Platform Automation and DevOps item requires manual verification to ensure DevSecOps integration."

    try {
        # Question: Integrate security into the already combined process of development and operations in DevOps to mitigate risks in the innovation process.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/landing-zone-security#secure

        $evidence = @{
            DefenderForDevOps = @()
            SecurityConnectors = @()
            DevSecOpsPolicies = @()
        }

        # Check for Microsoft Defender for DevOps / Security Connectors
        if ($global:AzData -and $global:AzData.Resources) {
            $evidence.SecurityConnectors = @($global:AzData.Resources | Where-Object {
                $_.ResourceType -eq "Microsoft.Security/securityConnectors"
            } | Select-Object -Property Name, ResourceGroupName -First 20)

            # Check for Defender for DevOps specifically
            $evidence.DefenderForDevOps = @($global:AzData.Resources | Where-Object {
                ($_.ResourceType -eq "Microsoft.Security/securityConnectors") -and
                ($_.Name -ilike "*devops*" -or $_.Name -ilike "*github*" -or $_.Name -ilike "*azuredevops*")
            } | Select-Object -Property Name, ResourceGroupName -First 10)
        }

        # Check for security-related policies in DevOps context
        if ($global:AzData -and $global:AzData.Policies) {
            $secDevOpsKeywords = @('devsecops', 'secure development', 'code scanning', 'vulnerability', 'security connector')
            $evidence.DevSecOpsPolicies = @($global:AzData.Policies | Where-Object {
                $name = if ($_.Properties.DisplayName) { $_.Properties.DisplayName } else { $_.Name }
                if ($name) {
                    ($secDevOpsKeywords | Where-Object { $name -ilike "*$_*" }).Count -gt 0
                }
            } | Select-Object -Property Name -First 20)
        }

        $hasSecurityIntegration = ($evidence.DefenderForDevOps.Count -gt 0) -or ($evidence.SecurityConnectors.Count -gt 0) -or ($evidence.DevSecOpsPolicies.Count -gt 0)

        if ($hasSecurityIntegration) {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = 50
            $rawData = @{
                Evidence = $evidence
                SecurityConnectorCount = $evidence.SecurityConnectors.Count
                DefenderForDevOpsCount = $evidence.DefenderForDevOps.Count
                Note = "Found security integration in DevOps pipeline (Defender for DevOps or security connectors). Manual verification recommended to confirm full DevSecOps adoption."
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
            $rawData = @{
                Evidence = $evidence
                Note = "No Defender for DevOps or security connector resources found. Manual verification required to assess DevSecOps integration."
            }
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}
