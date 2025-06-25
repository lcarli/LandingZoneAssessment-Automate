# Governance.ps1

<#
.SYNOPSIS
    Functions related to Governance assessment.

.DESCRIPTION
    This script contains functions to evaluate the Governance area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-GovernanceAssessment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )

    Write-AssessmentHeader "Evaluating the Governance design area..."
    Measure-ExecutionTime -ScriptBlock {
        $results = @()
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.01") }) | Test-QuestionE0101
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.03") }) | Test-QuestionE0103
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.04") }) | Test-QuestionE0104
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.05") }) | Test-QuestionE0105
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.06") }) | Test-QuestionE0106
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.07") }) | Test-QuestionE0107
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.08") }) | Test-QuestionE0108
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.09") }) | Test-QuestionE0109
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.10") }) | Test-QuestionE0110
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.11") }) | Test-QuestionE0111
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.12") }) | Test-QuestionE0112
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E01.13") }) | Test-QuestionE0113
        $results += ($Checklist.items | Where-Object { ($_.id -eq "E02.02") }) | Test-QuestionE0202

        $script:FunctionResult = $results
    } -FunctionName "Invoke-GovernanceAssessment"

    return $script:FunctionResult
}


function Test-QuestionE0101 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Leverage Azure Policy strategically, define controls for your environment, using Policy Initiatives to group related policies.
        # Reference: https://learn.microsoft.com/azure/governance/policy/overview

        
        # Retrieve all Policy Assignments in the subscription
        $policyAssignments = $global:AzData.Policies

        if ($policyAssignments.Count -eq 0) {
            # No Policy Assignments found
            $status = [Status]::NotImplemented
            $rawData = "No Policy Assignments are currently applied in the environment."
            $estimatedPercentageApplied = 0
        } else {
            # Check for Policy Assignments linked to Initiatives
            $totalAssignments = $policyAssignments.Count
            $initiativeAssignments = $policyAssignments | Where-Object { $_.Properties.PolicyDefinitionId -match "/providers/Microsoft.Authorization/policySetDefinitions/" }

            if ($initiativeAssignments.Count -eq $totalAssignments) {
                $status = [Status]::Implemented
                $rawData = "All Policy Assignments are linked to Policy Initiatives."
                $estimatedPercentageApplied = 100
            } elseif ($initiativeAssignments.Count -eq 0) {
                $status = [Status]::NotImplemented
                $rawData = "No Policy Assignments are linked to Policy Initiatives."
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $rawData = @{
                    TotalAssignments          = $totalAssignments
                    InitiativeAssignments     = $initiativeAssignments.Count
                    InitiativeAssignmentList  = $initiativeAssignments
                }
                $estimatedPercentageApplied = ($initiativeAssignments.Count / $totalAssignments) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionE0103 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Map regulatory and compliance requirements to Azure Policy definitions and Azure role assignments.
        # Reference: https://learn.microsoft.com/azure/governance/policy/samples/policy-compliance


        # Retrieve all Policy Assignments in the subscription
        $policyAssignments = $global:AzData.Policies

        if ($policyAssignments.Count -eq 0) {
            # No Policy Assignments found
            $status = [Status]::NotImplemented
            $rawData = "No Policy Assignments are currently applied in the environment."
            $estimatedPercentageApplied = 0
        } else {
            # Check if MCSB (Microsoft Cloud Security Benchmark) Initiative is assigned
            $mcsbInitiativeId = "/providers/Microsoft.Authorization/policySetDefinitions/MicrosoftCloudSecurityBenchmark"
            $mcsbAssignments = $policyAssignments | Where-Object { $_.Properties.PolicyDefinitionId -eq $mcsbInitiativeId }

            if ($mcsbAssignments.Count -eq $policyAssignments.Count) {
                $status = [Status]::Implemented
                $rawData = "The Microsoft Cloud Security Benchmark Initiative is assigned for all Policy Assignments."
                $estimatedPercentageApplied = 100
            } elseif ($mcsbAssignments.Count -eq 0) {
                $status = [Status]::NotImplemented
                $rawData = "The Microsoft Cloud Security Benchmark Initiative is not assigned."
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $rawData = @{
                    TotalAssignments    = $policyAssignments.Count
                    MCSBAssignments     = $mcsbAssignments.Count
                    MCSBAssignmentList  = $mcsbAssignments
                }
                $estimatedPercentageApplied = ($mcsbAssignments.Count / $policyAssignments.Count) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
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

function Test-QuestionE0104 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Establish Azure Policy definitions at the intermediate root management group so that they can be assigned at inherited scopes.
        # Reference: https://learn.microsoft.com/azure/governance/policy/overview

        # Retrieve all Management Groups
        $managementGroups = $global:AzData.ManagementGroups

        if ($managementGroups.Count -eq 0) {
            # No Management Groups found
            $status = [Status]::NotImplemented
            $rawData = "No Management Groups are defined in the environment."
            $estimatedPercentageApplied = 0
        } else {
            # Initialize variables
            $rootGroup = $managementGroups | Where-Object { -not $_.ParentId }
            $evaluatedGroups = @()
            $levelsWithPolicies = 0
            $totalLevelsChecked = 3

            # Traverse the hierarchy up to 3 levels
            $currentLevelGroups = @($rootGroup)

            for ($level = 1; $level -le $totalLevelsChecked; $level++) {
                if ($currentLevelGroups.Count -eq 0) {
                    break
                }

                foreach ($group in $currentLevelGroups) {
                    $evaluatedGroups += $group

                    # Check if policies are assigned at the current group level
                    $policyAssignments = $global:AzData.Policies | Where-Object { $_.Properties.Scope -eq $group.Id }
                    if ($policyAssignments.Count -gt 0) {
                        $levelsWithPolicies++
                    }
                }

                # Get children of the current level to process the next level
                $currentLevelGroups = $managementGroups | Where-Object { $_.ParentId -in ($currentLevelGroups | Select-Object -ExpandProperty Id) }
            }

            # Calculate the percentage of levels with policies
            if ($levelsWithPolicies -eq $totalLevelsChecked) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = "All three levels of Management Groups have policies assigned."
            } elseif ($levelsWithPolicies -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = "None of the first three levels of Management Groups have policies assigned."
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($levelsWithPolicies / $totalLevelsChecked) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalLevelsChecked = $totalLevelsChecked
                    LevelsWithPolicies = $levelsWithPolicies
                    EvaluatedGroups    = $evaluatedGroups
                }
            }
        }
    } catch {
        # Handle errors with the standard pattern
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    # Return result object using Set-EvaluationResultObject
    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionE0105 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Manage policy assignments at the highest appropriate level with exclusions at bottom levels, if required.
        # Reference: https://learn.microsoft.com/azure/governance/policy/overview


        $rootGroup = $global:AzData.ManagementGroups | Where-Object { -not $_.ParentId }

        if (-not $rootGroup) {
            $status = [Status]::NotImplemented
            $rawData = "No root Management Group is defined in the environment."
            $estimatedPercentageApplied = 0
        } else {
            $policyAssignments = $global:AzData.Policies

            if (-not $policyAssignments -or $policyAssignments.Count -eq 0) {
                $status = [Status]::NotImplemented
                $rawData = "No Policy Assignments are currently applied in the environment."
                $estimatedPercentageApplied = 0
            } else {
                $rootPolicyAssignments = $policyAssignments | Where-Object { $_.Scope -eq $rootGroup.Id }
                $assignmentsAtHighestLevel = $rootPolicyAssignments.Count

                $assignmentsWithExclusions = $policyAssignments | Where-Object { $_.Properties.NotScopes.Count -gt 0 } | Measure-Object | Select-Object -ExpandProperty Count

                $totalAssignments = $policyAssignments.Count

                if ($assignmentsAtHighestLevel -eq $totalAssignments -and $assignmentsWithExclusions -gt 0) {
                    $status = [Status]::Implemented
                    $estimatedPercentageApplied = 100
                    $rawData = @{
                        TotalAssignments          = $totalAssignments
                        AssignmentsAtHighestLevel = $assignmentsAtHighestLevel
                        AssignmentsWithExclusions = $assignmentsWithExclusions
                    }
                } elseif ($assignmentsAtHighestLevel -eq 0 -and $assignmentsWithExclusions -eq 0) {
                    $status = [Status]::NotImplemented
                    $estimatedPercentageApplied = 0
                    $rawData = "No Policy Assignments are managed at the highest level, and no exclusions are applied at lower levels."
                } else {
                    $status = [Status]::PartiallyImplemented
                    $estimatedPercentageApplied = (($assignmentsAtHighestLevel + $assignmentsWithExclusions) / (2 * $totalAssignments)) * 100
                    $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                    $rawData = @{
                        TotalAssignments          = $totalAssignments
                        AssignmentsAtHighestLevel = $assignmentsAtHighestLevel
                        AssignmentsWithExclusions = $assignmentsWithExclusions
                    }
                }
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

function Test-QuestionE0106 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Use Azure Policy to control which services users can provision at the subscription/management group level.
        # Reference: https://learn.microsoft.com/azure/governance/policy/overview


        $policyAssignments = $global:AzData.Policies
        $managementGroups = $global:AzData.ManagementGroups
        $subscriptions = $global:AzData.Subscriptions

        if (-not $policyAssignments -or $policyAssignments.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No Policy Assignments are applied in the environment."
            $estimatedPercentageApplied = 0
        } else {
            $policiesRestrictingServices = @()

            foreach ($assignment in $policyAssignments) {
                try {
                    $policyDefinition = Get-AzPolicyDefinition -Id $assignment.Properties.PolicyDefinitionId -ErrorAction Stop

                    if ($policyDefinition -and $policyDefinition.Properties -and $policyDefinition.Properties.PolicyRule) {
                        $policyRules = $policyDefinition.Properties.PolicyRule
                        if (($policyRules.then.effect -eq "Deny" -or $policyRules.then.effect -eq "Allow") -and $policyRules.if.field -eq "type") {
                            $policiesRestrictingServices += $assignment
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to get policy definition for assignment $($assignment.Properties.PolicyDefinitionId): $($_.Exception.Message)"
                    continue
                }
            }

            $totalScopes = $managementGroups.Count + $subscriptions.Count
            $scopesWithPolicies = ($policiesRestrictingServices | Select-Object -ExpandProperty Scope | Sort-Object -Unique).Count

            if ($scopesWithPolicies -eq $totalScopes) {
                $status = [Status]::Implemented
                $rawData = "Policies with 'Deny' or 'Allow' effect for Resource Types are applied at all Management Groups and Subscriptions."
                $estimatedPercentageApplied = 100
            } elseif ($scopesWithPolicies -eq 0) {
                $status = [Status]::NotImplemented
                $rawData = "No policies with 'Deny' or 'Allow' effect for Resource Types are applied at any Management Group or Subscription."
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $rawData = @{
                    TotalScopes             = $totalScopes
                    ScopesWithPolicies      = $scopesWithPolicies
                    ScopesWithoutPolicies   = $totalScopes - $scopesWithPolicies
                    PoliciesRestrictingList = $policiesRestrictingServices
                }
                $estimatedPercentageApplied = ($scopesWithPolicies / $totalScopes) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
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

function Test-QuestionE0107 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to evaluate if custom policies can be replaced with built-in policies to minimize operational overhead."

    try {
        # Question: Use built-in policies where possible to minimize operational overhead.
        # Reference: https://learn.microsoft.com/azure/governance/policy/samples/

        # No automated logic is implemented here
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionE0108 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Assign the built-in Resource Policy Contributor role at a particular scope to enable application-level governance.
        # Reference: https://learn.microsoft.com/azure/governance/policy/overview

        $managementGroups = $global:AzData.ManagementGroups
        $subscriptions = $global:AzData.Subscriptions
        $roleAssignments = Get-AzRoleAssignment

        if (-not $roleAssignments -or $roleAssignments.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No role assignments found in the environment."
            $estimatedPercentageApplied = 0
        } else {
            # Check for Resource Policy Contributor in Management Groups and Subscriptions
            $mgAssignments = $managementGroups | ForEach-Object {
                Get-AzRoleAssignment -Scope $_.Id | Where-Object {
                    $_.RoleDefinitionName -eq "Resource Policy Contributor"
                }
            }            
            $subscriptionAssignments = $subscriptions | ForEach-Object {
                $roleAssignments | Where-Object { 
                    $_.Scope -eq "/subscriptions/$($_.Id)" -and $_.RoleDefinitionName -eq "Resource Policy Contributor" 
                }
            }

            $totalScopes = $managementGroups.Count + $subscriptions.Count
            $scopesWithAssignments = ($mgAssignments.Count + $subscriptionAssignments.Count)

            if ($scopesWithAssignments -eq $totalScopes) {
                $status = [Status]::Implemented
                $rawData = "The Resource Policy Contributor role is assigned at all Management Groups and Subscriptions."
                $estimatedPercentageApplied = 100
            } elseif ($scopesWithAssignments -eq 0) {
                $status = [Status]::NotImplemented
                $rawData = "The Resource Policy Contributor role is not assigned at any Management Group or Subscription."
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($scopesWithAssignments / $totalScopes) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalScopes                  = $totalScopes
                    ScopesWithAssignments        = $scopesWithAssignments
                    ScopesWithoutAssignments     = $totalScopes - $scopesWithAssignments
                    ManagementGroupAssignments   = $mgAssignments
                    SubscriptionAssignments      = $subscriptionAssignments
                }
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

function Test-QuestionE0109 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to determine if the number of Azure Policy assignments at the root management group scope is appropriately limited to avoid excessive use of exclusions."

    try {
        # Question: Limit the number of Azure Policy assignments made at the root management group scope to avoid managing through exclusions at inherited scopes.
        # Reference: https://learn.microsoft.com/azure/governance/policy/overview

        # No automated logic is implemented here
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionE0110 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to determine if Azure Policies are deployed to enforce data sovereignty requirements, based on existing regulatory and organizational needs."

    try {
        # Question: If any data sovereignty requirements exist, Azure Policies should be deployed to enforce them.
        # Reference: https://learn.microsoft.com/azure/governance/policy/overview

        # No automated logic is implemented here
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionE0111 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure that the sovereignty policy baseline is deployed and assigned at the correct management group level for Sovereign Landing Zone."

    try {
        # Question: For Sovereign Landing Zone, deploy sovereignty policy baseline and assign at correct management group level.
        # Reference: https://learn.microsoft.com/industry/sovereignty/policy-portfolio-baseline

        # No automated logic is implemented here
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionE0112 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to document Sovereign Control objectives to policy mapping for Sovereign Landing Zone."

    try {
        # Question: For Sovereign Landing Zone, document Sovereign Control objectives to policy mapping.
        # Reference: https://learn.microsoft.com/industry/sovereignty/policy-portfolio-baseline

        # No automated logic is implemented here
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionE0113 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure a process is in place for the management of 'Sovereign Control objectives to policy mapping' for Sovereign Landing Zone."

    try {
        # Question: For Sovereign Landing Zone, ensure process is in place for management of 'Sovereign Control objectives to policy mapping'.
        # Reference: https://learn.microsoft.com/industry/sovereignty/policy-portfolio-baseline#sovereignty-baseline-policy-initiatives

        # No automated logic is implemented here
        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionE0202 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Configure 'Actual' and 'Forecasted' Budget Alerts.
        # Reference: https://learn.microsoft.com/azure/cost-management-billing/costs/tutorial-acm-create-budgets

        $subscriptions = $global:AzData.Subscriptions
        $totalSubscriptions = $subscriptions.Count
        $subscriptionsWithBudgetAlerts = 0

        foreach ($subscription in $subscriptions) {
            Set-AzContext -Subscription $subscription.Id -Tenant $TenantId

            # Get all budgets for the subscription
            $budgets = Get-AzConsumptionBudget

            if ($budgets.Count -eq 0) {
                Write-Warning "No budgets found for subscription: $($subscription.Name)"
                continue
            }

            foreach ($budget in $budgets) {
                $notificationKeys = $budget.Notification.Keys

                $hasActualAlert = $notificationKeys | Where-Object { $_ -match "actual" }
                $hasForecastAlert = $notificationKeys | Where-Object { $_ -match "forecast" }

                if ($hasActualAlert -and $hasForecastAlert) {
                    $subscriptionsWithBudgetAlerts++
                    break
                }
            }
        }

        if ($subscriptionsWithBudgetAlerts -eq $totalSubscriptions) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = "All subscriptions have budgets configured with both 'Actual' and 'Forecasted' alerts."
        } elseif ($subscriptionsWithBudgetAlerts -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No subscriptions have budgets configured with both 'Actual' and 'Forecasted' alerts."
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($subscriptionsWithBudgetAlerts / $totalSubscriptions) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            $rawData = @{
                TotalSubscriptions              = $totalSubscriptions
                SubscriptionsWithBudgetAlerts   = $subscriptionsWithBudgetAlerts
                SubscriptionsWithoutBudgetAlerts = $totalSubscriptions - $subscriptionsWithBudgetAlerts
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
