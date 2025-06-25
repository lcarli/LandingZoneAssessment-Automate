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

    Write-AssessmentHeader "Evaluating the Management design area..."
    Measure-ExecutionTime -ScriptBlock {
        $results = @()
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.01") }) | Test-QuestionF0101
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.02") }) | Test-QuestionF0102
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.03") }) | Test-QuestionF0103
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.04") }) | Test-QuestionF0104
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.05") }) | Test-QuestionF0105
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.06") }) | Test-QuestionF0106
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.07") }) | Test-QuestionF0107
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.08") }) | Test-QuestionF0108
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.09") }) | Test-QuestionF0109
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.10") }) | Test-QuestionF0110
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.11") }) | Test-QuestionF0111
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.12") }) | Test-QuestionF0112
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.13") }) | Test-QuestionF0113
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.14") }) | Test-QuestionF0114
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.15") }) | Test-QuestionF0115
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.16") }) | Test-QuestionF0116
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.17") }) | Test-QuestionF0117        
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F01.18") }) | Test-QuestionF0118
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F02.01") }) | Test-QuestionF0201
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F02.02") }) | Test-QuestionF0202
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F03.01") }) | Test-QuestionF0301
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F03.02") }) | Test-QuestionF0302
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F04.01") }) | Test-QuestionF0401        
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F04.02") }) | Test-QuestionF0402
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F06.01") }) | Test-QuestionF0601
        $results += ($Checklist.items | Where-Object { ($_.id -eq "F06.02") }) | Test-QuestionF0602

        $script:FunctionResult = $results
    } -FunctionName "Invoke-ManagementAssessment"

    return $script:FunctionResult
}

function Test-QuestionF0101 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $rawData = $null

    try {
        # Question: Use a single monitor logs workspace to manage platforms centrally except where Azure role-based access control (Azure RBAC), data sovereignty requirements, or data retention policies mandate separate workspaces.
        # Reference: https://learn.microsoft.com/azure/azure-monitor/logs/workspace-design#azure-regions

        $subscriptions = $global:AzData.Subscriptions

        if ($subscriptions.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalWorkspaces = 0
            $justifiedWorkspaces = 0
            $allWorkspaces = @()

            foreach ($subscription in $subscriptions) {
                $workspaces = Invoke-AzCmdletSafely -ScriptBlock {
                    Get-AzOperationalInsightsWorkspace -SubscriptionId $subscription.Id -ErrorAction Stop
                } -CmdletName "Get-AzOperationalInsightsWorkspace" -ModuleName "Az.OperationalInsights" -FallbackValue @() -WarningMessage "Could not get workspaces for subscription $($subscription.Id)"

                $allWorkspaces += $workspaces
            }

            $totalWorkspaces = $allWorkspaces.Count

            if ($totalWorkspaces -eq 0) {
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } elseif ($totalWorkspaces -eq 1) {
                # Single workspace - compliant with recommendation
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } else {
                # Multiple workspaces - check if they are justified by RBAC, data sovereignty, or retention policies
                
                # Group workspaces by region (data sovereignty)
                $regions = $allWorkspaces | Select-Object -ExpandProperty Location -Unique

                # Check data retention settings
                $retentionValues = $allWorkspaces | Select-Object -ExpandProperty RetentionInDays -Unique

                # For RBAC, collect role assignments per workspace
                $rbacAssignments = @{}
                $rbacJustified = $false

                foreach ($workspace in $allWorkspaces) {
                    $workspaceId = $workspace.ResourceId
                    $roleAssignments = Invoke-AzCmdletSafely -ScriptBlock {
                        Get-AzRoleAssignment -Scope $workspaceId -ErrorAction Stop
                    } -CmdletName "Get-AzRoleAssignment" -ModuleName "Az.Resources" -FallbackValue @() -WarningMessage "Could not get role assignments for workspace $($workspace.Name)"
                    
                    $rbacAssignments[$workspaceId] = $roleAssignments
                }

                # Check if multiple workspaces are justified
                $dataSovereigntyJustified = $regions.Count -gt 1
                $retentionJustified = $retentionValues.Count -gt 1
                
                # Check RBAC differences
                if ($rbacAssignments.Count -gt 1) {
                    $firstWorkspaceAssignments = $rbacAssignments.Values | Select-Object -First 1
                    foreach ($assignments in $rbacAssignments.Values) {
                        if ($assignments.Count -ne $firstWorkspaceAssignments.Count) {
                            $rbacJustified = $true
                            break
                        } else {
                            if ($firstWorkspaceAssignments -and $assignments) {
                                $diff = Compare-Object -ReferenceObject $firstWorkspaceAssignments -DifferenceObject $assignments -Property RoleDefinitionName, PrincipalId, PrincipalType -ErrorAction SilentlyContinue
                                if ($diff) {
                                    $rbacJustified = $true
                                    break
                                }
                            }
                        }
                    }
                }

                # Calculate compliance based on justification
                $justificationReasons = @()
                if ($dataSovereigntyJustified) { $justificationReasons += "Data Sovereignty" }
                if ($retentionJustified) { $justificationReasons += "Retention Policies" }
                if ($rbacJustified) { $justificationReasons += "RBAC Requirements" }

                if ($justificationReasons.Count -gt 0) {
                    $status = [Status]::Implemented
                    $estimatedPercentageApplied = 100
                } else {
                    # Multiple workspaces without clear justification
                    $status = [Status]::PartiallyImplemented
                    $estimatedPercentageApplied = 40
                }

                $rawData = @{
                    TotalWorkspaces = $totalWorkspaces
                    UniqueRegions = $regions.Count
                    UniqueRetentionPolicies = $retentionValues.Count
                    JustificationReasons = $justificationReasons
                    WorkspaceDetails = $allWorkspaces | Select-Object Name, Location, RetentionInDays, ResourceGroupName
                }
            }
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Unknown
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionF0103 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $rawData = $null

    try {
        # Question: Export logs to Azure Storage if your log retention requirements exceed twelve years. Use immutable storage with a write-once, read-many policy to make data non-erasable and non-modifiable for a user-specified interval.
        # Reference: https://learn.microsoft.com/azure/azure-monitor/logs/data-retention-archive?tabs=portal-1%2Cportal-2#how-retention-and-archiving-work

        $subscriptions = $global:AzData.Subscriptions

        if ($subscriptions.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $workspacesExceedingRetention = @()
            $workspacesCompliant = 0
            $workspacesNonCompliant = 0
            $totalWorkspacesChecked = 0

            foreach ($subscription in $subscriptions) {
                $workspaces = Invoke-AzCmdletSafely -ScriptBlock {
                    Get-AzOperationalInsightsWorkspace -SubscriptionId $subscription.Id -ErrorAction Stop
                } -CmdletName "Get-AzOperationalInsightsWorkspace" -ModuleName "Az.OperationalInsights" -FallbackValue @() -WarningMessage "Could not get workspaces for subscription $($subscription.Id)"

                foreach ($workspace in $workspaces) {
                    $totalWorkspacesChecked++

                    $retentionInDays = $workspace.RetentionInDays
                    $archiveRetentionInDays = if ($workspace.ArchivedDataRetentionInDays) { $workspace.ArchivedDataRetentionInDays } else { 0 }
                    $totalRetention = $retentionInDays + $archiveRetentionInDays

                    if ($totalRetention -gt 4380) { # 12 years = 4380 days
                        $workspacesExceedingRetention += $workspace

                        # Check if workspace has export rules to Azure Storage
                        $exportRules = Invoke-AzCmdletSafely -ScriptBlock {
                            Get-AzOperationalInsightsDataExport -ResourceGroupName $workspace.ResourceGroupName -WorkspaceName $workspace.Name -ErrorAction Stop
                        } -CmdletName "Get-AzOperationalInsightsDataExport" -ModuleName "Az.OperationalInsights" -FallbackValue @() -WarningMessage "Could not check data export rules for workspace $($workspace.Name)"

                        $storageExportConfigured = $false
                        $storageCompliant = $false

                        foreach ($rule in $exportRules) {
                            if ($rule.Destination -like "/subscriptions/*/resourceGroups/*/providers/Microsoft.Storage/storageAccounts/*") {
                                $storageExportConfigured = $true

                                # Get the storage account to check for immutable storage (WORM)
                                $storageAccountId = $rule.Destination
                                $storageAccount = Invoke-AzCmdletSafely -ScriptBlock {
                                    Get-AzStorageAccount -ResourceId $storageAccountId -ErrorAction Stop
                                } -CmdletName "Get-AzStorageAccount" -ModuleName "Az.Storage" -WarningMessage "Could not check Storage Account for WORM: $storageAccountId"

                                if ($storageAccount) {
                                    # Check for immutable storage policies (WORM)
                                    $immutablePolicies = Invoke-AzCmdletSafely -ScriptBlock {
                                        Get-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName $storageAccount.ResourceGroupName -StorageAccountName $storageAccount.StorageAccountName -ErrorAction Stop
                                    } -CmdletName "Get-AzRmStorageContainerImmutabilityPolicy" -ModuleName "Az.Storage" -FallbackValue @() -WarningMessage "Could not check immutability policies for storage account $($storageAccount.StorageAccountName)"

                                    if ($immutablePolicies.Count -gt 0) {
                                        $storageCompliant = $true
                                        break
                                    }
                                }
                            }
                        }

                        if ($storageExportConfigured -and $storageCompliant) {
                            $workspacesCompliant++
                        } else {
                            $workspacesNonCompliant++
                        }
                    } else {
                        # Workspace retention does not exceed 12 years - compliant by default
                        $workspacesCompliant++
                    }
                }
            }

            if ($workspacesExceedingRetention.Count -eq 0) {
                # No workspaces exceeding 12-year retention
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
                $rawData = "No Log Analytics workspaces have retention requirements exceeding 12 years"
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

                $rawData = @{
                    TotalWorkspacesChecked = $totalWorkspacesChecked
                    WorkspacesExceedingRetention = $workspacesExceedingRetention.Count
                    WorkspacesCompliant = $workspacesCompliant
                    WorkspacesNonCompliant = $workspacesNonCompliant
                    WorkspaceDetails = $workspacesExceedingRetention | Select-Object Name, Location, RetentionInDays, ArchivedDataRetentionInDays, ResourceGroupName
                }
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
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
    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0

    try {
        # Question: Use Azure Update Manager as a patching mechanism for Windows and Linux VMs in Azure.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/management-operational-compliance#update-management-considerations

        $subscriptions = $global:AzData.Subscriptions

        if ($subscriptions.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalVms = 0
            $vmsWithUpdateManager = 0
            $vmsDetails = @()

            foreach ($subscription in $subscriptions) {
                $vms = $global:AzData.Resources | Where-Object {
                    $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and
                    $_.SubscriptionId -eq $subscription.Id
                }

                $totalVms += $vms.Count

                foreach ($vm in $vms) {
                    $vmDetails = @{
                        Name = $vm.Name
                        ResourceGroup = $vm.ResourceGroupName
                        Location = $vm.Location
                        HasUpdateManager = $false
                        PatchMode = "Unknown"
                    }

                    # Check for Update Manager configuration via policies or extensions
                    $updatePolicies = $global:AzData.Policies | Where-Object {
                        $_.ResourceId -eq $vm.Id -and
                        ($_.PolicyDefinitionDisplayName -like "*Update Manager*" -or
                         $_.PolicyDefinitionDisplayName -like "*Patch Management*" -or
                         $_.PolicyDefinitionDisplayName -like "*Automatic VM guest patching*") -and
                        $_.ComplianceState -eq 'Compliant'
                    }

                    # Check for Azure Update Manager extension or automatic patch settings
                    if ($updatePolicies.Count -gt 0) {
                        $vmDetails.HasUpdateManager = $true
                        $vmDetails.PatchMode = "Managed"
                        $vmsWithUpdateManager++
                    } else {
                        # Check if VM has automatic patching enabled (this is a basic check)
                        # In real implementation, this would require more detailed VM configuration checks
                        $vmDetails.PatchMode = "Manual"
                    }

                    $vmsDetails += $vmDetails
                }
            }

            if ($totalVms -eq 0) {
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
                $rawData = "No virtual machines found"
            } else {
                $estimatedPercentageApplied = ($vmsWithUpdateManager / $totalVms) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)

                if ($estimatedPercentageApplied -eq 100) {
                    $status = [Status]::Implemented
                } elseif ($estimatedPercentageApplied -eq 0) {
                    $status = [Status]::NotImplemented
                } else {
                    $status = [Status]::PartiallyImplemented
                }

                $rawData = @{
                    TotalVMs = $totalVms
                    VMsWithUpdateManager = $vmsWithUpdateManager
                    VMsWithoutUpdateManager = $totalVms - $vmsWithUpdateManager
                    VMDetails = $vmsDetails
                }
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionF0106 {
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
        # Question: Use Azure Update Manager as a patching mechanism for Windows and Linux VMs outside of Azure using Azure Arc.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/management-operational-compliance#update-management-considerations

        $subscriptions = $global:AzData.Subscriptions

        if ($subscriptions.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalArcVms = 0
            $arcVmsWithUpdateManager = 0
            $arcVmDetails = @()

            foreach ($subscription in $subscriptions) {
                # Look for Azure Arc-enabled servers (hybrid machines)
                $arcVms = $global:AzData.Resources | Where-Object {
                    $_.ResourceType -eq "Microsoft.HybridCompute/machines" -and
                    $_.SubscriptionId -eq $subscription.Id
                }

                $totalArcVms += $arcVms.Count

                foreach ($arcVm in $arcVms) {
                    $vmDetails = @{
                        Name = $arcVm.Name
                        ResourceGroup = $arcVm.ResourceGroupName
                        Location = $arcVm.Location
                        HasUpdateManager = $false
                        PatchMode = "Unknown"
                        OSType = "Unknown"
                    }

                    # Check for Update Manager configuration via policies on Arc machines
                    $updatePolicies = $global:AzData.Policies | Where-Object {
                        $_.ResourceId -eq $arcVm.Id -and
                        ($_.PolicyDefinitionDisplayName -like "*Update Manager*" -or
                         $_.PolicyDefinitionDisplayName -like "*Patch Management*" -or
                         $_.PolicyDefinitionDisplayName -like "*Arc machine*" -or
                         $_.PolicyDefinitionDisplayName -like "*Hybrid*") -and
                        $_.ComplianceState -eq 'Compliant'
                    }

                    # Check for Azure Update Manager extension on Arc machines
                    if ($updatePolicies.Count -gt 0) {
                        $vmDetails.HasUpdateManager = $true
                        $vmDetails.PatchMode = "Managed"
                        $arcVmsWithUpdateManager++
                    } else {
                        $vmDetails.PatchMode = "Manual"
                    }

                    $arcVmDetails += $vmDetails
                }
            }

            if ($totalArcVms -eq 0) {
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
                $rawData = "No Azure Arc-enabled servers found"
            } else {
                $estimatedPercentageApplied = ($arcVmsWithUpdateManager / $totalArcVms) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)

                if ($estimatedPercentageApplied -eq 100) {
                    $status = [Status]::Implemented
                } elseif ($estimatedPercentageApplied -eq 0) {
                    $status = [Status]::NotImplemented
                } else {
                    $status = [Status]::PartiallyImplemented
                }

                $rawData = @{
                    TotalArcVMs = $totalArcVms
                    ArcVMsWithUpdateManager = $arcVmsWithUpdateManager
                    ArcVMsWithoutUpdateManager = $totalArcVms - $arcVmsWithUpdateManager
                    ArcVMDetails = $arcVmDetails
                }
            }
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionF0107 {
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
        # Question: Encrypt sensitive data in transit using TLS 1.2 or higher.
        # Reference: https://learn.microsoft.com/azure/security/fundamentals/data-encryption-best-practices

        $resourcesChecked = 0
        $resourcesCompliant = 0

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in @("Microsoft.Sql/servers", "Microsoft.Web/sites", "Microsoft.Storage/storageAccounts")
        }

        if (-not $resources -or $resources.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No resources of the specified types are configured in this environment."
        } else {
            foreach ($resource in $resources) {
                $resourcesChecked++

                try {
                    switch ($resource.ResourceType) {
                        "Microsoft.Sql/servers" {
                            $sqlServer = Invoke-AzCmdletSafely -ScriptBlock {
                                Get-AzSqlServer -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.Name -ErrorAction Stop
                            } -CmdletName "Get-AzSqlServer" -ModuleName "Az.Sql" -WarningMessage "Could not check SQL Server TLS for $($resource.Name)"
                            
                            if ($sqlServer -and $sqlServer.MinimalTlsVersion -ge "1.2") {
                                $resourcesCompliant++
                            }
                        }
                        "Microsoft.Web/sites" {
                            $webApp = Invoke-AzCmdletSafely -ScriptBlock {
                                Get-AzWebApp -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -ErrorAction Stop
                            } -CmdletName "Get-AzWebApp" -ModuleName "Az.Websites" -WarningMessage "Could not check Web App HTTPS for $($resource.Name)"
                            
                            if ($webApp -and $webApp.HttpsOnly -eq $true) {
                                $resourcesCompliant++
                            }
                        }
                        "Microsoft.Storage/storageAccounts" {
                            $storageAccount = Invoke-AzCmdletSafely -ScriptBlock {
                                Get-AzStorageAccount -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -ErrorAction Stop
                            } -CmdletName "Get-AzStorageAccount" -ModuleName "Az.Storage" -WarningMessage "Could not check Storage Account TLS for $($resource.Name)"
                            
                            if ($storageAccount -and $storageAccount.MinimumTlsVersion -eq "TLS1_2") {
                                $resourcesCompliant++
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "  Warning: Error processing resource $($resource.Name): $($_.Exception.Message)"
                }
            }

            if ($resourcesCompliant -eq $resourcesChecked) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($resourcesCompliant -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($resourcesCompliant / $resourcesChecked) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }

            $rawData = @{
                ResourcesChecked     = $resourcesChecked
                ResourcesCompliant   = $resourcesCompliant
                ResourcesNonCompliant = $resourcesChecked - $resourcesCompliant
            }
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionF0108 {
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
        # Question: Use Azure Key Vault to store and manage access to secrets, keys, and certificates securely.
        # Reference: https://learn.microsoft.com/azure/key-vault/general/basic-concepts

        $keyVaults = $global:AzData.Resources | Where-Object { $_.ResourceType -eq "Microsoft.KeyVault/vaults" }
        $compliantVaults = 0

        foreach ($keyVault in $keyVaults) {
            $properties = Get-AzKeyVault -VaultName $keyVault.Name -ResourceGroupName $keyVault.ResourceGroupName
            if ($properties.EnableSoftDelete -and $properties.EnablePurgeProtection) {
                $compliantVaults++
            }
        }

        if ($compliantVaults -eq $keyVaults.Count) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($compliantVaults -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($compliantVaults / $keyVaults.Count) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalVaults    = $keyVaults.Count
            CompliantVaults = $compliantVaults
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionF0109 {
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
        # Question: Regularly rotate secrets, keys, and certificates stored in Azure Key Vault.
        # Reference: https://learn.microsoft.com/azure/key-vault/general/overview

        $keyVaults = $global:AzData.Resources | Where-Object { $_.ResourceType -eq "Microsoft.KeyVault/vaults" }
        $vaultsWithRotationPolicy = 0

        foreach ($keyVault in $keyVaults) {
            $keys = Invoke-AzCmdletSafely -ScriptBlock {
                Get-AzKeyVaultKey -VaultName $keyVault.Name -ErrorAction SilentlyContinue
            } -CmdletName "Get-AzKeyVaultKey" -ModuleName "Az.KeyVault" -FallbackValue @() -WarningMessage "Could not check Key Vault keys for $($keyVault.Name)"
            
            foreach ($key in $keys) {
                if ($key.Attributes.Expires -and ($key.Attributes.Expires -gt (Get-Date))) {
                    $vaultsWithRotationPolicy++
                    break
                }
            }
        }

        if ($vaultsWithRotationPolicy -eq $keyVaults.Count) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($vaultsWithRotationPolicy -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($vaultsWithRotationPolicy / $keyVaults.Count) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalVaults         = $keyVaults.Count
            VaultsWithRotation  = $vaultsWithRotationPolicy
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionF0110 {
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
        # Question: Ensure proper backup of sensitive data stored in Azure resources.
        # Reference: https://learn.microsoft.com/azure/backup/backup-overview

        $resourcesWithBackup = 0
        $totalResources = 0

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in @("Microsoft.Sql/servers", "Microsoft.Storage/storageAccounts", "Microsoft.KeyVault/vaults")
        }

        foreach ($resource in $resources) {
            $totalResources++
            if ($resource.Tags["backup"] -eq "enabled") {
                $resourcesWithBackup++
            }
        }

        if ($resourcesWithBackup -eq $totalResources) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($resourcesWithBackup -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($resourcesWithBackup / $totalResources) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalResources         = $totalResources
            ResourcesWithBackup    = $resourcesWithBackup
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F01.11
function Test-QuestionF0111 {
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
        # Question: Include service and resource health events as part of the overall platform monitoring solution.
        # Reference: https://learn.microsoft.com/azure/azure-monitor/

        $servicesWithHealthMonitoring = 0
        $totalServices = 0

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -notmatch "Microsoft.Network/networkWatchers"
        }

        foreach ($resource in $resources) {
            $totalServices++
            $diagnosticSettings = Get-AzDiagnosticSetting -ResourceId $resource.Id -ErrorAction SilentlyContinue

            if ($diagnosticSettings) {
                $hasServiceHealth = $diagnosticSettings.Logs | Where-Object {
                    $_.Category -eq "ServiceHealth" -and $_.Enabled -eq $true
                }

                if ($hasServiceHealth) {
                    $servicesWithHealthMonitoring++
                }
            }
        }

        if ($servicesWithHealthMonitoring -eq $totalServices) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($servicesWithHealthMonitoring -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($servicesWithHealthMonitoring / $totalServices) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalServices                    = $totalServices
            ServicesWithHealthMonitoring     = $servicesWithHealthMonitoring
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F01.12
function Test-QuestionF0112 {
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
        # Question: Document a standard for monitoring and alerting configuration for each landing zone component.
        # Reference: https://learn.microsoft.com/azure/azure-monitor/

        $resourcesWithMonitoring = 0
        $totalResources = 0

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -notmatch "Microsoft.Network/networkWatchers"
        }

        foreach ($resource in $resources) {
            $totalResources++
            $diagnosticSettings = Get-AzDiagnosticSetting -ResourceId $resource.Id -ErrorAction SilentlyContinue

            if ($diagnosticSettings) {
                $hasLogsAndMetrics = $diagnosticSettings.Logs | Where-Object {
                    $_.Category -in @("AuditLogs", "Administrative", "Security", "Performance") -and $_.Enabled -eq $true
                }

                $hasAlerts = (Get-AzMetricAlertRuleV2 -ResourceGroupName $resource.ResourceGroupName -ErrorAction SilentlyContinue |
                              Where-Object { $_.TargetResourceId -eq $resource.Id })

                if ($hasLogsAndMetrics -and $hasAlerts) {
                    $resourcesWithMonitoring++
                }
            }
        }

        if ($resourcesWithMonitoring -eq $totalResources) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($resourcesWithMonitoring -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($resourcesWithMonitoring / $totalResources) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalResources              = $totalResources
            ResourcesWithMonitoring     = $resourcesWithMonitoring
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F01.13
function Test-QuestionF0113 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    # Since this question involves organizational practices and policies,
    # it cannot be fully automated or analyzed purely via code.

    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This requires a manual review of organizational policies and configurations."

    try {
        $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied 0 -checklistItem $checklistItem -rawData $_.Exception.Message
    }

    return $result
}

# Function for Management item F01.15
function Test-QuestionF0115 {
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
        # Question: Use Azure Monitor Logs for insights and reporting.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-setup-guide/monitoring-reporting?tabs=AzureMonitor

        $resourcesWithMonitorLogs = 0
        $totalResources = 0

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -notmatch "Microsoft.Network/networkWatchers"
        }

        foreach ($resource in $resources) {
            $totalResources++
            $diagnosticSettings = Get-AzDiagnosticSetting -ResourceId $resource.Id -ErrorAction SilentlyContinue

            if ($diagnosticSettings) {
                $logsConfigured = $diagnosticSettings.Logs | Where-Object {
                    $_.Enabled -eq $true
                }

                if ($logsConfigured) {
                    $resourcesWithMonitorLogs++
                }
            }
        }

        if ($resourcesWithMonitorLogs -eq $totalResources) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($resourcesWithMonitorLogs -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($resourcesWithMonitorLogs / $totalResources) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalResources              = $totalResources
            ResourcesWithMonitorLogs    = $resourcesWithMonitorLogs
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F01.16
function Test-QuestionF0116 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    # Since this question involves a decision-making process ("WHEN necessary"),
    # it cannot be fully automated or analyzed purely via code.

    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This requires a review of governance and organizational policies to determine necessity."

    try {
        $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied 0 -checklistItem $checklistItem -rawData $_.Exception.Message
    }

    return $result
}

# Function for Management item F01.17
function Test-QuestionF0117 {
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
        # Question: Use Azure Monitor alerts for the generation of operational alerts.
        # Reference: https://learn.microsoft.com/azure/azure-monitor/alerts/alerts-overview

        $resourcesWithAlerts = 0
        $totalResources = 0

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -notmatch "Microsoft.Network/networkWatchers"
        }

        foreach ($resource in $resources) {
            $totalResources++
            $alerts = Get-AzMetricAlertRuleV2 -ResourceGroupName $resource.ResourceGroupName -ErrorAction SilentlyContinue |
                      Where-Object { $_.TargetResourceId -eq $resource.Id }

            if ($alerts) {
                $resourcesWithAlerts++
            }
        }

        if ($resourcesWithAlerts -eq $totalResources) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($resourcesWithAlerts -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($resourcesWithAlerts / $totalResources) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalResources          = $totalResources
            ResourcesWithAlerts     = $resourcesWithAlerts
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F01.18
function Test-QuestionF0118 {
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
        # Question: Ensure that monitoring requirements have been assessed and that appropriate data collection and alerting configurations are applied.
        # Reference: https://learn.microsoft.com/azure/architecture/best-practices/monitoring

        $resourcesWithMonitoring = 0
        $totalResources = 0

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -notmatch "Microsoft.Network/networkWatchers"
        }

        foreach ($resource in $resources) {
            $totalResources++
            $diagnosticSettings = Get-AzDiagnosticSetting -ResourceId $resource.Id -ErrorAction SilentlyContinue

            if ($diagnosticSettings) {
                $logsConfigured = $diagnosticSettings.Logs | Where-Object {
                    $_.Enabled -eq $true
                }

                $alerts = Get-AzMetricAlertRuleV2 -ResourceGroupName $resource.ResourceGroupName -ErrorAction SilentlyContinue |
                          Where-Object { $_.TargetResourceId -eq $resource.Id }

                if ($logsConfigured -and $alerts) {
                    $resourcesWithMonitoring++
                }
            }
        }

        if ($resourcesWithMonitoring -eq $totalResources) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($resourcesWithMonitoring -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($resourcesWithMonitoring / $totalResources) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalResources             = $totalResources
            ResourcesWithMonitoring    = $resourcesWithMonitoring
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F02.01
function Test-QuestionF0201 {
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
        # Question: Enable cross-region replication in Azure for BCDR with paired regions.
        # Reference: https://learn.microsoft.com/azure/reliability/cross-region-replication-azure

        $totalStorageAccounts = 0
        $storageWithReplication = 0

        $storageAccounts = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.Storage/storageAccounts"
        }

        foreach ($account in $storageAccounts) {
            $totalStorageAccounts++

            if ($account.Sku.Name -in @("Standard_GRS", "Standard_RAGRS", "Premium_GZRS", "Premium_RAGZRS")) {
                $storageWithReplication++
            }
        }

        if ($storageWithReplication -eq $totalStorageAccounts) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($storageWithReplication -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($storageWithReplication / $totalStorageAccounts) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalStorageAccounts         = $totalStorageAccounts
            StorageWithReplication       = $storageWithReplication
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F03.01
function Test-QuestionF0301 {
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
        # Question: Use Azure guest policies to automatically deploy software configurations through VM extensions and enforce a compliant baseline VM configuration.
        # Reference: https://learn.microsoft.com/azure/governance/policy/concepts/guest-configuration

        $totalVMs = 0
        $compliantVMs = 0

        $vmResourceTypes = @("Microsoft.Compute/virtualMachines", "Microsoft.Compute/virtualMachineScaleSets")

        $vms = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in $vmResourceTypes
        }

        foreach ($vm in $vms) {
            $totalVMs++

            # Check if guest policies are applied via Azure Policy
            $policies = Get-AzPolicyAssignment -Scope $vm.Id -ErrorAction SilentlyContinue |
                        Where-Object { $_.Properties.DisplayName -like "*Guest Configuration*" }

            if ($policies) {
                $compliantVMs++
            }
        }

        if ($compliantVMs -eq $totalVMs) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($compliantVMs -eq 0) {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($compliantVMs / $totalVMs) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalVMs        = $totalVMs
            CompliantVMs    = $compliantVMs
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F03.02
function Test-QuestionF0302 {
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
        # Question: Monitor VM security configuration drift via Azure Policy.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/management-operational-compliance#monitoring-for-configuration-drift

        $totalVMs = 0
        $vmsCompliantWithPolicy = 0
        $vmsWithUpdateManagement = 0

        $vmResourceTypes = @("Microsoft.Compute/virtualMachines", "Microsoft.Compute/virtualMachineScaleSets")

        $vms = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in $vmResourceTypes
        }

        foreach ($vm in $vms) {
            $totalVMs++

            # Check for guest configuration policy
            $policies = Get-AzPolicyAssignment -Scope $vm.Id -ErrorAction SilentlyContinue |
                        Where-Object { $_.Properties.DisplayName -like "*Security Configuration*" -or $_.Properties.DisplayName -like "*Configuration Drift*" }

            if ($policies) {
                $vmsCompliantWithPolicy++
            }

            # Check for Update Management
            $updateManagement = Get-AzAutomationAccount -ResourceGroupName $vm.ResourceGroupName -ErrorAction SilentlyContinue |
                                Where-Object { $_.Name -like "*Update Management*" }

            if ($updateManagement) {
                $vmsWithUpdateManagement++
            }
        }

        if ($vmsCompliantWithPolicy -eq $totalVMs -and $vmsWithUpdateManagement -eq $totalVMs) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($vmsCompliantWithPolicy -eq 0 -and $vmsWithUpdateManagement -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = (($vmsCompliantWithPolicy + $vmsWithUpdateManagement) / (2 * $totalVMs)) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalVMs                  = $totalVMs
            VMsCompliantWithPolicy    = $vmsCompliantWithPolicy
            VMsWithUpdateManagement   = $vmsWithUpdateManagement
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F04.01
function Test-QuestionF0401 {
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
        # Question: Use Azure Site Recovery for Azure-to-Azure Virtual Machines disaster recovery scenarios.
        # Reference: https://learn.microsoft.com/azure/site-recovery/site-recovery-overview

        $totalVMs = 0
        $vmsWithASRConfigured = 0

        $vmResourceTypes = @("Microsoft.Compute/virtualMachines")

        $vms = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in $vmResourceTypes
        }

        foreach ($vm in $vms) {
            $totalVMs++

            # Check if Azure Site Recovery is enabled for the VM
            $asrConfig = Get-AzRecoveryServicesAsrProtectionContainerMapping -ResourceGroupName $vm.ResourceGroupName -ErrorAction SilentlyContinue |
                         Where-Object { $_.SourceContainerId -eq $vm.Id }

            if ($asrConfig) {
                $vmsWithASRConfigured++
            }
        }

        if ($vmsWithASRConfigured -eq $totalVMs) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($vmsWithASRConfigured -eq 0) {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($vmsWithASRConfigured / $totalVMs) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalVMs                = $totalVMs
            VMsWithASRConfigured    = $vmsWithASRConfigured
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F04.02
function Test-QuestionF0402 {
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
        # Question: Use native PaaS service disaster recovery capabilities. Perform failover testing with these capabilities.
        # Reference: https://learn.microsoft.com/azure/architecture/framework/resiliency/backup-and-recovery

        $totalPaaSResources = 0
        $resourcesWithDRConfigured = 0

        $paasResourceTypes = @(
            "Microsoft.Sql/servers",
            "Microsoft.DocumentDB/databaseAccounts",
            "Microsoft.Web/sites"
        )

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in $paasResourceTypes
        }

        foreach ($resource in $resources) {
            $totalPaaSResources++

            # Check for disaster recovery configuration (e.g., failover groups, geo-replication)
            if ($resource.ResourceType -eq "Microsoft.Sql/servers") {
                $failoverGroups = Get-AzSqlDatabaseFailoverGroup -ServerName $resource.Name -ResourceGroupName $resource.ResourceGroupName -ErrorAction SilentlyContinue
                if ($failoverGroups) {
                    $resourcesWithDRConfigured++
                }
            } elseif ($resource.ResourceType -eq "Microsoft.DocumentDB/databaseAccounts") {
                $account = Get-AzCosmosDBAccount -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName -ErrorAction SilentlyContinue
                if ($account.ConsistencyPolicy.DefaultConsistencyLevel -ne "Strong") {
                    $resourcesWithDRConfigured++
                }
            } elseif ($resource.ResourceType -eq "Microsoft.Web/sites") {
                $siteConfig = Get-AzWebAppSlot -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -ErrorAction SilentlyContinue
                if ($siteConfig.Location -ne $resource.Location) {
                    $resourcesWithDRConfigured++
                }
            }
        }

        if ($resourcesWithDRConfigured -eq $totalPaaSResources) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($resourcesWithDRConfigured -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($resourcesWithDRConfigured / $totalPaaSResources) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalPaaSResources       = $totalPaaSResources
            ResourcesWithDRConfigured = $resourcesWithDRConfigured
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F06.01
function Test-QuestionF0601 {
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
        # Question: Add diagnostic settings to save WAF logs from application delivery services like Azure Front Door and Azure Application Gateway.
        # Reference: https://learn.microsoft.com/azure/web-application-firewall/afds/waf-front-door-best-practices#add-diagnostic-settings-to-save-your-wafs-logs

        $totalWAFServices = 0
        $servicesWithDiagnostics = 0

        $wafResourceTypes = @(
            "Microsoft.Network/applicationGateways",
            "Microsoft.Cdn/profiles"
        )

        $wafServices = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in $wafResourceTypes
        }

        foreach ($service in $wafServices) {
            $totalWAFServices++

            # Check for diagnostic settings
            $diagnosticSettings = Get-AzDiagnosticSetting -ResourceId $service.Id -ErrorAction SilentlyContinue |
                                  Where-Object { $_.Logs.Category -contains "ApplicationGatewayAccessLog" -or $_.Logs.Category -contains "FrontDoorAccessLog" }

            if ($diagnosticSettings) {
                $servicesWithDiagnostics++
            }
        }

        if ($servicesWithDiagnostics -eq $totalWAFServices) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($servicesWithDiagnostics -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($servicesWithDiagnostics / $totalWAFServices) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalWAFServices          = $totalWAFServices
            ServicesWithDiagnostics   = $servicesWithDiagnostics
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F06.02
function Test-QuestionF0602 {
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
        # Question: Send WAF logs from your application delivery services like Azure Front Door and Azure Application Gateway to Microsoft Sentinel.
        # Reference: https://learn.microsoft.com/azure/web-application-firewall/afds/waf-front-door-best-practices#send-logs-to-microsoft-sentinel

        $totalWAFServices = 0
        $servicesWithSentinelIntegration = 0

        $wafResourceTypes = @(
            "Microsoft.Network/applicationGateways",
            "Microsoft.Cdn/profiles"
        )

        $wafServices = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in $wafResourceTypes
        }

        foreach ($service in $wafServices) {
            $totalWAFServices++

            # Check for diagnostic settings sending logs to Microsoft Sentinel
            $diagnosticSettings = Get-AzDiagnosticSetting -ResourceId $service.Id -ErrorAction SilentlyContinue |
                                  Where-Object {
                                      $null -ne $_.WorkspaceId -and $_.WorkspaceId -match "Microsoft Sentinel"
                                  }

            if ($diagnosticSettings) {
                $servicesWithSentinelIntegration++
            }
        }

        if ($servicesWithSentinelIntegration -eq $totalWAFServices) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($servicesWithSentinelIntegration -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($servicesWithSentinelIntegration / $totalWAFServices) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalWAFServices               = $totalWAFServices
            ServicesWithSentinelIntegration = $servicesWithSentinelIntegration
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F01.02
function Test-QuestionF0102 {
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
        # Question: Decide whether to use a single Azure Monitor Logs workspace for all regions or to create multiple workspaces to cover various geographical regions.
        # Reference: https://learn.microsoft.com/azure/azure-monitor/logs/design-logs-deployment

        $subscriptions = $global:AzData.Subscriptions

        if ($subscriptions.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $allWorkspaces = @()
            $totalWorkspaces = 0

            foreach ($subscription in $subscriptions) {
                $workspaces = Invoke-AzCmdletSafely -ScriptBlock {
                    Get-AzOperationalInsightsWorkspace -SubscriptionId $subscription.Id -ErrorAction Stop
                } -CmdletName "Get-AzOperationalInsightsWorkspace" -ModuleName "Az.OperationalInsights" -FallbackValue @() -WarningMessage "Could not get workspaces for subscription $($subscription.Id)"
                
                $allWorkspaces += $workspaces
            }

            $totalWorkspaces = $allWorkspaces.Count

            if ($totalWorkspaces -eq 0) {
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } else {
                # Group workspaces by region
                $regions = $allWorkspaces | Group-Object Location
                $regionCount = $regions.Count

                # Check for cross-region networking charges considerations
                $hasMultiRegionWorkspaces = $regionCount -gt 1
                $hasRegionalDistribution = $false

                if ($hasMultiRegionWorkspaces) {
                    # Check if workspaces are properly distributed across regions
                    $maxWorkspacesPerRegion = ($regions | Measure-Object -Property Count -Maximum).Maximum
                    $minWorkspacesPerRegion = ($regions | Measure-Object -Property Count -Minimum).Minimum
                    
                    # Consider well-distributed if difference is not too large
                    $hasRegionalDistribution = ($maxWorkspacesPerRegion - $minWorkspacesPerRegion) -le 2
                }

                if ($totalWorkspaces -eq 1) {
                    # Single workspace strategy - check if it covers multiple regions appropriately
                    $status = [Status]::Implemented
                    $estimatedPercentageApplied = 100
                } elseif ($hasMultiRegionWorkspaces -and $hasRegionalDistribution) {
                    # Multiple workspaces with good regional distribution
                    $status = [Status]::Implemented
                    $estimatedPercentageApplied = 100
                } elseif ($hasMultiRegionWorkspaces) {
                    # Multiple workspaces but poor distribution
                    $status = [Status]::PartiallyImplemented
                    $estimatedPercentageApplied = 60
                } else {
                    # Multiple workspaces in same region - may not be optimal
                    $status = [Status]::PartiallyImplemented
                    $estimatedPercentageApplied = 40
                }

                $rawData = @{
                    TotalWorkspaces = $totalWorkspaces
                    UniqueRegions = $regionCount
                    WorkspacesByRegion = $regions | ForEach-Object { @{ Region = $_.Name; Count = $_.Count } }
                }
            }
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F01.04
function Test-QuestionF0104 {
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
        # Question: Monitor OS level virtual machine (VM) configuration drift using Azure Policy. Enabling Azure Automanage Machine Configuration audit capabilities.
        # Reference: https://learn.microsoft.com/azure/governance/machine-configuration/overview

        $totalVMs = 0
        $vmsWithGuestConfiguration = 0

        $virtualMachines = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.Compute/virtualMachines"
        }

        $totalVMs = $virtualMachines.Count

        if ($totalVMs -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            foreach ($vm in $virtualMachines) {
                # Check for Azure Policy guest configuration compliance
                $guestConfigPolicies = $global:AzData.Policies | Where-Object {
                    $_.ResourceId -eq $vm.Id -and
                    $_.PolicyDefinitionCategory -eq "Guest Configuration" -and
                    $_.ComplianceState -eq "Compliant"
                }

                # Check for VM extensions related to guest configuration
                $extensions = Invoke-AzCmdletSafely -ScriptBlock {
                    Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ErrorAction Stop
                } -CmdletName "Get-AzVMExtension" -ModuleName "Az.Compute" -FallbackValue @() -WarningMessage "Could not check VM extensions for $($vm.Name)"

                $hasGuestConfigExtension = $extensions | Where-Object {
                    $_.ExtensionType -in @("ConfigurationForLinux", "ConfigurationForWindows", "GuestConfiguration")
                }

                if ($guestConfigPolicies.Count -gt 0 -or $hasGuestConfigExtension) {
                    $vmsWithGuestConfiguration++
                }
            }

            $estimatedPercentageApplied = ($vmsWithGuestConfiguration / $totalVMs) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)

            if ($estimatedPercentageApplied -eq 100) {
                $status = [Status]::Implemented
            } elseif ($estimatedPercentageApplied -eq 0) {
                $status = [Status]::NotImplemented
            } else {
                $status = [Status]::PartiallyImplemented
            }

            $rawData = @{
                TotalVMs = $totalVMs
                VMsWithGuestConfiguration = $vmsWithGuestConfiguration
                VMsWithoutGuestConfiguration = $totalVMs - $vmsWithGuestConfiguration
            }
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F01.14
function Test-QuestionF0114 {
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
        # Question: When necessary, use shared storage accounts within the landing zone for Azure diagnostic extension log storage.
        # Reference: https://learn.microsoft.com/azure/azure-monitor/agents/diagnostics-extension-overview

        $totalVMs = 0
        $vmsWithDiagnosticExtension = 0
        $sharedStorageAccounts = 0

        $virtualMachines = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.Compute/virtualMachines"
        }

        $storageAccounts = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.Storage/storageAccounts"
        }

        $totalVMs = $virtualMachines.Count

        if ($totalVMs -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            # Check for diagnostic storage accounts with appropriate tags or naming convention
            foreach ($storage in $storageAccounts) {
                if ($storage.Name -like "*diag*" -or 
                    $storage.Name -like "*diagnostic*" -or 
                    $storage.Tags["purpose"] -eq "diagnostics" -or
                    $storage.Tags["usage"] -eq "logging") {
                    $sharedStorageAccounts++
                }
            }

            foreach ($vm in $virtualMachines) {
                $extensions = Invoke-AzCmdletSafely -ScriptBlock {
                    Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ErrorAction Stop
                } -CmdletName "Get-AzVMExtension" -ModuleName "Az.Compute" -FallbackValue @() -WarningMessage "Could not check VM extensions for $($vm.Name)"

                $hasDiagnosticExtension = $extensions | Where-Object {
                    $_.ExtensionType -in @("IaaSDiagnostics", "LinuxDiagnostic", "Microsoft.Azure.Diagnostics")
                }

                if ($hasDiagnosticExtension) {
                    $vmsWithDiagnosticExtension++
                }
            }

            # Evaluate based on presence of shared storage and diagnostic extensions
            if ($sharedStorageAccounts -gt 0 -and $vmsWithDiagnosticExtension -gt 0) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($sharedStorageAccounts -gt 0 -or $vmsWithDiagnosticExtension -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = 50
            } else {
                # This might be acceptable if not necessary for the environment
                $status = [Status]::ManualVerificationRequired
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalVMs = $totalVMs
                VMsWithDiagnosticExtension = $vmsWithDiagnosticExtension
                SharedStorageAccounts = $sharedStorageAccounts
                TotalStorageAccounts = $storageAccounts.Count
            }
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F02.02
function Test-QuestionF0202 {
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
        # Question: When using Azure Backup, use the correct backup types (GRS, ZRS & LRS) for your backup, as the default setting is GRS.
        # Reference: https://learn.microsoft.com/azure/storage/common/storage-redundancy

        $totalBackupVaults = 0
        $vaultsWithAppropriateSku = 0

        $backupVaults = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in @("Microsoft.RecoveryServices/vaults", "Microsoft.DataProtection/backupVaults")
        }

        $totalBackupVaults = $backupVaults.Count

        if ($totalBackupVaults -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            foreach ($vault in $backupVaults) {
                $vaultProperties = $null
                
                if ($vault.ResourceType -eq "Microsoft.RecoveryServices/vaults") {
                    $vaultProperties = Invoke-AzCmdletSafely -ScriptBlock {
                        Get-AzRecoveryServicesVault -ResourceGroupName $vault.ResourceGroupName -Name $vault.Name -ErrorAction Stop
                    } -CmdletName "Get-AzRecoveryServicesVault" -ModuleName "Az.RecoveryServices" -WarningMessage "Could not check Recovery Services Vault $($vault.Name)"
                    
                    if ($vaultProperties) {
                        # Get backup storage redundancy
                        $backupStorageRedundancy = Invoke-AzCmdletSafely -ScriptBlock {
                            Get-AzRecoveryServicesBackupProperty -Vault $vaultProperties -ErrorAction Stop
                        } -CmdletName "Get-AzRecoveryServicesBackupProperty" -ModuleName "Az.RecoveryServices" -WarningMessage "Could not check backup properties for $($vault.Name)"
                        
                        if ($backupStorageRedundancy) {
                            # Check if storage redundancy is set appropriately (not default GRS if not needed)
                            $redundancyType = $backupStorageRedundancy.BackupStorageRedundancy
                            
                            # Consider appropriate if it's been explicitly configured (not default)
                            # or if it matches regional requirements
                            if ($redundancyType -in @("LocallyRedundant", "ZoneRedundant", "GeoRedundant")) {
                                # Check if the choice is appropriate for the region and requirements
                                # For simplicity, we'll consider any explicit setting as appropriate
                                $vaultsWithAppropriateSku++
                            }
                        }
                    }
                } elseif ($vault.ResourceType -eq "Microsoft.DataProtection/backupVaults") {
                    # For DataProtection backup vaults, check storage settings
                    $vaultProperties = Invoke-AzCmdletSafely -ScriptBlock {
                        Get-AzDataProtectionBackupVault -ResourceGroupName $vault.ResourceGroupName -VaultName $vault.Name -ErrorAction Stop
                    } -CmdletName "Get-AzDataProtectionBackupVault" -ModuleName "Az.DataProtection" -WarningMessage "Could not check Data Protection Vault $($vault.Name)"
                    
                    if ($vaultProperties -and $vaultProperties.StorageSetting) {
                        $redundancyType = $vaultProperties.StorageSetting.Type
                        if ($redundancyType -in @("LocallyRedundant", "ZoneRedundant", "GeoRedundant")) {
                            $vaultsWithAppropriateSku++
                        }
                    }
                }
            }

            $estimatedPercentageApplied = ($vaultsWithAppropriateSku / $totalBackupVaults) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)

            if ($estimatedPercentageApplied -eq 100) {
                $status = [Status]::Implemented
            } elseif ($estimatedPercentageApplied -eq 0) {
                $status = [Status]::NotImplemented
            } else {
                $status = [Status]::PartiallyImplemented
            }

            $rawData = @{
                TotalBackupVaults = $totalBackupVaults
                VaultsWithAppropriateSku = $vaultsWithAppropriateSku
                VaultsWithDefaultSku = $totalBackupVaults - $vaultsWithAppropriateSku
            }
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}
