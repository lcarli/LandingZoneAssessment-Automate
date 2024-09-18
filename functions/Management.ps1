# Management.ps1

<#
.SYNOPSIS
    Functions related to Management assessment.

.DESCRIPTION
    This script contains functions to evaluate the Management area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/SharedFunctions.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-ManagementAssessment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ContractType
    )
    Write-Host "Evaluating the Management design area..."

    $results = @()

    # Run Management questions
    $results += Test-QuestionF0101
    $results += Test-QuestionF0103
    $results += Test-QuestionF0105

    return $results
}

function Test-QuestionF0101 {
    Write-Host "Assessing question: Use a single monitor logs workspace to manage platforms centrally except where Azure RBAC, data sovereignty requirements, or data retention policies mandate separate workspaces."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0

    try {
        # Get all subscriptions
        $subscriptions = Get-AzSubscription

        if ($subscriptions.Count -eq 0) {
            # No subscriptions found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalWorkspaces = 0
            $justifiedWorkspaces = 0
            $allWorkspaces = @()

            foreach ($subscription in $subscriptions) {
                Set-AzContext -SubscriptionId $subscription.Id

                # Get all Log Analytics workspaces in the subscription
                $workspaces = Get-AzOperationalInsightsWorkspace

                $allWorkspaces += $workspaces
            }

            $totalWorkspaces = $allWorkspaces.Count

            if ($totalWorkspaces -eq 0) {
                # No workspaces found
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } elseif ($totalWorkspaces -eq 1) {
                # Only one workspace exists
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } else {
                # Multiple workspaces found
                # Check for data sovereignty, data retention, and RBAC differences

                # Group workspaces by region
                $regions = $allWorkspaces | Select-Object -ExpandProperty Location -Unique

                # Check data retention settings
                $retentionValues = $allWorkspaces | Select-Object -ExpandProperty RetentionInDays -Unique

                # For RBAC, collect role assignments per workspace
                $rbacAssignments = @{}

                foreach ($workspace in $allWorkspaces) {
                    $workspaceId = $workspace.ResourceId
                    $roleAssignments = Get-AzRoleAssignment -Scope $workspaceId
                    $rbacAssignments[$workspaceId] = $roleAssignments
                }

                # Determine if workspaces are justified
                # If regions, retention policies, or RBAC assignments differ, increment justifiedWorkspaces

                $justifiedWorkspaces = 0

                if ($regions.Count -gt 1) {
                    # Multiple regions
                    $justifiedWorkspaces++
                }

                if ($retentionValues.Count -gt 1) {
                    # Multiple retention policies
                    $justifiedWorkspaces++
                }

                # Compare RBAC assignments
                $rbacDifferent = $false

                $firstWorkspaceAssignments = $rbacAssignments.Values | Select-Object -First 1

                foreach ($assignments in $rbacAssignments.Values) {
                    if ($assignments.Count -ne $firstWorkspaceAssignments.Count) {
                        $rbacDifferent = $true
                        break
                    } else {
                        # Compare the assignments
                        if ($firstWorkspaceAssignments && $assignments) {
                            $diff = Compare-Object -ReferenceObject $firstWorkspaceAssignments -DifferenceObject $assignments -Property RoleDefinitionName, PrincipalId, PrincipalType
                            if ($diff) {
                                $rbacDifferent = $true
                                break
                            }
                        }
                    }
                }

                if ($rbacDifferent) {
                    $justifiedWorkspaces++
                }

                if ($justifiedWorkspaces -gt 0) {
                    $status = [Status]::PartiallyImplemented
                    $estimatedPercentageApplied = [Math]::Round((($totalWorkspaces - $justifiedWorkspaces) / $totalWorkspaces) * 100, 2)
                } else {
                    $status = [Status]::NotImplemented
                    $estimatedPercentageApplied = 0
                }
            }

            $score = ($weight * $estimatedPercentageApplied) / 100
        }
    } catch {
        Write-ErrorLog -QuestionID "F01.01" -QuestionText "Use a single monitor logs workspace to manage platforms centrally except where Azure RBAC, data sovereignty requirements, or data retention policies mandate separate workspaces." -FunctionName "Assess-QuestionF0101" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}
function Test-QuestionF0103 {
    Write-Host "Assessing question: Export logs to Azure Storage if your log retention requirements exceed twelve years. Use immutable storage with a write-once, read-many policy to make data non-erasable and non-modifiable for a user-specified interval."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0

    try {
        # Get all subscriptions
        $subscriptions = Get-AzSubscription

        if ($subscriptions.Count -eq 0) {
            # No subscriptions found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $workspacesExceedingRetention = @()
            $workspacesCompliant = 0
            $workspacesNonCompliant = 0
            $totalWorkspacesChecked = 0

            foreach ($subscription in $subscriptions) {
                Set-AzContext -SubscriptionId $subscription.Id

                # Get all Log Analytics workspaces in the subscription
                $workspaces = Get-AzOperationalInsightsWorkspace

                foreach ($workspace in $workspaces) {
                    $totalWorkspacesChecked++

                    $retentionInDays = $workspace.RetentionInDays
                    $archiveRetentionInDays = $workspace.ArchivedDataRetentionInDays

                    if (-not $archiveRetentionInDays) {
                        $archiveRetentionInDays = 0
                    }

                    $totalRetention = $retentionInDays + $archiveRetentionInDays

                    if ($totalRetention -gt 4380) {
                        # Workspace retention exceeds 12 years
                        $workspacesExceedingRetention += $workspace

                        # Check if workspace has export rules to Azure Storage
                        # Get Data Export rules for the workspace
                        $exportRules = Get-AzOperationalInsightsDataExport -ResourceGroupName $workspace.ResourceGroupName -WorkspaceName $workspace.Name

                        $storageExportConfigured = $false
                        $storageCompliant = $false

                        foreach ($rule in $exportRules) {
                            if ($rule.Destination -like "/subscriptions/*/resourceGroups/*/providers/Microsoft.Storage/storageAccounts/*") {
                                $storageExportConfigured = $true

                                # Get the storage account
                                $storageAccountId = $rule.Destination
                                $storageAccount = Get-AzStorageAccount -ResourceId $storageAccountId

                                # Check if immutable storage with WORM is enabled
                                if ($storageAccount.ImmutableStorageWithVersioning.Enabled -eq $true) {
                                    $storageCompliant = $true
                                    break
                                }
                            }
                        }

                        if ($storageExportConfigured -and $storageCompliant) {
                            $workspacesCompliant++
                        } else {
                            $workspacesNonCompliant++
                        }
                    } else {
                        # Workspace retention does not exceed 12 years
                        # Consider compliant
                        $workspacesCompliant++
                    }
                }
            }

            if ($workspacesExceedingRetention.Count -eq 0) {
                # No workspaces exceeding retention
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } else {
                if ($workspacesNonCompliant -eq 0) {
                    $status = [Status]::Implemented
                    $estimatedPercentageApplied = 100
                } elseif ($workspacesCompliant -eq 0) {
                    $status = [Status]::NotImplemented
                    $estimatedPercentageApplied = 0
                } else {
                    $status = [Status]::PartiallyImplemented
                    $estimatedPercentageApplied = ($workspacesCompliant / $workspacesExceedingRetention.Count) * 100
                    $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                }
            }

            $score = ($weight * $estimatedPercentageApplied) / 100
        }
    } catch {
        Write-ErrorLog -QuestionID "F01.03" -QuestionText "Export logs to Azure Storage if your log retention requirements exceed twelve years. Use immutable storage with a write-once, read-many policy to make data non-erasable and non-modifiable for a user-specified interval." -FunctionName "Test-QuestionF0103" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}
function Test-QuestionF0105 {
    Write-Host "Assessing question: Monitor OS level virtual machine (VM) configuration drift using Azure Policy. Enabling Azure Automanage Machine Configuration audit capabilities through policy helps application team workloads to immediately consume feature capabilities with little effort."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0

    try {
        $subscriptions = $global:AzData.Subscriptions

        if ($subscriptions.Count -eq 0) {
            # No subscriptions found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalVms = 0
            $compliantVms = 0

            foreach ($subscription in $subscriptions) {
                # Filtrar VMs para a subscrição atual
                $vms = $global:AzData.Resources | Where-Object {
                    $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and
                    $_.SubscriptionId -eq $subscription.Id
                }

                $totalVms += $vms.Count

                foreach ($vm in $vms) {
                    $isCompliant = $true

                    # Encontrar estados de conformidade para esta VM
                    $complianceStates = $global:AzData.Policies | Where-Object {
                        $_.ResourceId -eq $vm.Id -and
                        $_.PolicyDefinitionAction -eq 'deployIfNotExists' -and
                        $_.PolicyDefinitionCategory -eq 'Guest Configuration' -and
                        $_.ComplianceState -eq 'NonCompliant'
                    }

                    if ($complianceStates.Count -gt 0) {
                        $isCompliant = $false
                    }

                    if ($isCompliant) {
                        $compliantVms++
                    }
                }
            }

            if ($totalVms -eq 0) {
                # No VMs found
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } else {
                $estimatedPercentageApplied = ($compliantVms / $totalVms) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)

                if ($estimatedPercentageApplied -eq 100) {
                    $status = [Status]::Implemented
                } elseif ($estimatedPercentageApplied -eq 0) {
                    $status = [Status]::NotImplemented
                } else {
                    $status = [Status]::PartiallyImplemented
                }
            }
        }
    } catch {
        Write-ErrorLog -QuestionID "F01.05" -QuestionText "Monitor OS level virtual machine (VM) configuration drift using Azure Policy. Enabling Azure Automanage Machine Configuration audit capabilities through policy helps application team workloads to immediately consume feature capabilities with little effort." -FunctionName "Test-QuestionF0105" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
    }

    Set-EvaluationResultObject -status $status -estimatedPercentageApplied $estimatedPercentageApplied -questionId "F01.05"
}