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
. "$PSScriptRoot/../shared/Enums.ps1"
. "$PSScriptRoot/../shared/SharedFunctions.ps1"
. "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-ManagementAssessment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )

    Write-Host "Evaluating the Management design area..."

    $results = @()
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.01") }) | Test-QuestionF0101
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.03") }) | Test-QuestionF0103
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.05") }) | Test-QuestionF0105
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.06") }) | Test-QuestionF0106
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.07") }) | Test-QuestionF0107
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.08") }) | Test-QuestionF0108
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.09") }) | Test-QuestionF0109
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.10") }) | Test-QuestionF0110
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.11") }) | Test-QuestionF0111
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.12") }) | Test-QuestionF0112
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.13") }) | Test-QuestionF0113
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.15") }) | Test-QuestionF0115
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.16") }) | Test-QuestionF0116
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.17") }) | Test-QuestionF0117
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.18") }) | Test-QuestionF0118
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.19") }) | Test-QuestionF0119
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.20") }) | Test-QuestionF0120
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.21") }) | Test-QuestionF0121
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F02.01") }) | Test-QuestionF0201
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F03.01") }) | Test-QuestionF0301
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F03.02") }) | Test-QuestionF0302
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F04.01") }) | Test-QuestionF0401
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F04.02") }) | Test-QuestionF0402
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F04.03") }) | Test-QuestionF0403
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F06.01") }) | Test-QuestionF0601
    $results += ($Checklist.items | Where-Object { ($_.id -eq "F06.02") }) | Test-QuestionF0602

    return $results
}

function Test-QuestionF0101 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0
    $rawData = $null

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

            $rawData = $justifiedWorkspaces

            $score = ($weight * $estimatedPercentageApplied) / 100
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
        $rawData = $_.Exception.Message
    }

    # Return result object using Set-EvaluationResultObject
    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionF0103 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0
    $rawData = $null

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

            $rawData = $workspacesExceedingRetention

            $score = ($weight * $estimatedPercentageApplied) / 100
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
        $rawData = $_.Exception.Message
    }

    # Return result object using Set-EvaluationResultObject
    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionF0105 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )
    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

            $rawData = $totalVms
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.06
function Test-QuestionF0106 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.07
function Test-QuestionF0107 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.08
function Test-QuestionF0108 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.09
function Test-QuestionF0109 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.10
function Test-QuestionF0110 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.11
function Test-QuestionF0111 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.12
function Test-QuestionF0112 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.13
function Test-QuestionF0113 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.15
function Test-QuestionF0115 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.16
function Test-QuestionF0116 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.17
function Test-QuestionF0117 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.18
function Test-QuestionF0118 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.19
function Test-QuestionF0119 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.20
function Test-QuestionF0120 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F01.21
function Test-QuestionF0121 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F02.01
function Test-QuestionF0201 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F03.01
function Test-QuestionF0301 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F03.02
function Test-QuestionF0302 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F04.01
function Test-QuestionF0401 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F04.02
function Test-QuestionF0402 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F04.03
function Test-QuestionF0403 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F06.01
function Test-QuestionF0601 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for Management item F06.02
function Test-QuestionF0602 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}