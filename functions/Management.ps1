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

    Write-Output "Evaluating the Management design area..."
    Measure-ExecutionTime -ScriptBlock {
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0
    $rawData = $null

    try {
        # Question: Use tagging to define data classification and retention policies for sensitive data in Azure resources.
        # Reference: https://learn.microsoft.com/azure/governance/policy/concepts/definition-structure#tags

        # Get all subscriptions
        $subscriptions = $global:AzData.Subscriptions

        if ($subscriptions.Count -eq 0) {
            # No subscriptions found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            $totalWorkspaces = 0
            $justifiedWorkspaces = 0
            $allWorkspaces = @()

            foreach ($subscription in $subscriptions) {
                Set-AzContext -SubscriptionId $subscription.Id -TenantId $TenantId

                # Get all Log Analytics workspaces in the subscription
                $workspaces = Get-AzOperationalInsightsWorkspace

                $allWorkspaces += $workspaces
            }

            $totalWorkspaces = $allWorkspaces.Count

            if ($totalWorkspaces -eq 0) {
                # No workspaces found
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            }
            elseif ($totalWorkspaces -eq 1) {
                # Only one workspace exists
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            else {
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
                    }
                    else {
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
                }
                else {
                    $status = [Status]::NotImplemented
                    $estimatedPercentageApplied = 0
                }
            }

            $rawData = $justifiedWorkspaces

            $score = ($weight * $estimatedPercentageApplied) / 100
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0
    $rawData = $null

    try {
        # Question: Configure logging and auditing for data plane and management plane operations for sensitive data and resources.
        # Reference: https://learn.microsoft.com/azure/azure-monitor/essentials/logs-overview

        # Get all subscriptions
        $subscriptions = $global:AzData.Subscriptions

        if ($subscriptions.Count -eq 0) {
            # No subscriptions found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            $workspacesExceedingRetention = @()
            $workspacesCompliant = 0
            $workspacesNonCompliant = 0
            $totalWorkspacesChecked = 0

            foreach ($subscription in $subscriptions) {
                Set-AzContext -SubscriptionId $subscription.Id -TenantId $TenantId

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
                        }
                        else {
                            $workspacesNonCompliant++
                        }
                    }
                    else {
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
            }
            else {
                if ($workspacesNonCompliant -eq 0) {
                    $status = [Status]::Implemented
                    $estimatedPercentageApplied = 100
                }
                elseif ($workspacesCompliant -eq 0) {
                    $status = [Status]::NotImplemented
                    $estimatedPercentageApplied = 0
                }
                else {
                    $status = [Status]::PartiallyImplemented
                    $estimatedPercentageApplied = ($workspacesCompliant / $workspacesExceedingRetention.Count) * 100
                    $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                }
            }

            $rawData = $workspacesExceedingRetention

            $score = ($weight * $estimatedPercentageApplied) / 100
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
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
    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0

    try {
        # Question: Enable Microsoft Defender for Cloud to protect sensitive data and resources by detecting potential threats.
        # Reference: https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction

        $subscriptions = $global:AzData.Subscriptions

        if ($subscriptions.Count -eq 0) {
            # No subscriptions found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            $totalVms = 0
            $compliantVms = 0

            foreach ($subscription in $subscriptions) {
                $vms = $global:AzData.Resources | Where-Object {
                    $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and
                    $_.SubscriptionId -eq $subscription.Id
                }

                $totalVms += $vms.Count

                foreach ($vm in $vms) {
                    $isCompliant = $true

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
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            }
            else {
                $estimatedPercentageApplied = ($compliantVms / $totalVms) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)

                if ($estimatedPercentageApplied -eq 100) {
                    $status = [Status]::Implemented
                }
                elseif ($estimatedPercentageApplied -eq 0) {
                    $status = [Status]::NotImplemented
                }
                else {
                    $status = [Status]::PartiallyImplemented
                }
            }

            $rawData = $totalVms
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Encrypt sensitive data at rest using customer-managed keys (CMK).
        # Reference: https://learn.microsoft.com/azure/security/fundamentals/encryption-atrest

        $resourcesWithCMK = 0
        $totalResources = 0

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in @("Microsoft.Storage/storageAccounts", "Microsoft.Sql/servers", "Microsoft.KeyVault/vaults")
        }

        if (-not $resources -or $resources.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No resources of the specified types are configured in this environment."
        } else {
            $totalResources = $resources.Count

            foreach ($resource in $resources) {
                switch ($resource.ResourceType) {
                    "Microsoft.Storage/storageAccounts" {
                        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
                        if ($storageAccount.EnableEncryptionService && $storageAccount.KeyVaultProperties) {
                            $resourcesWithCMK++
                        }
                    }
                    "Microsoft.Sql/servers" {
                        $sqlServer = Get-AzSqlServer -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.Name
                        if ($sqlServer.EncryptionProtector -and $sqlServer.EncryptionProtector.ServerKeyType -eq "AzureKeyVault") {
                            $resourcesWithCMK++
                        }
                    }
                    "Microsoft.KeyVault/vaults" {
                        $keyVault = Get-AzKeyVault -VaultName $resource.Name -ResourceGroupName $resource.ResourceGroupName
                        if ($keyVault.Properties.EnablePurgeProtection -and $keyVault.Properties.VaultUri) {
                            $resourcesWithCMK++
                        }
                    }
                }
            }

            if ($resourcesWithCMK -eq $totalResources) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($resourcesWithCMK -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($resourcesWithCMK / $totalResources) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }

            $rawData = @{
                TotalResources      = $totalResources
                ResourcesWithCMK    = $resourcesWithCMK
                ResourcesWithoutCMK = $totalResources - $resourcesWithCMK
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
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

                switch ($resource.ResourceType) {
                    "Microsoft.Sql/servers" {
                        $sqlServer = Get-AzSqlServer -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.Name
                        if ($sqlServer.MinimalTlsVersion -ge "1.2") {
                            $resourcesCompliant++
                        }
                    }
                    "Microsoft.Web/sites" {
                        $webApp = Get-AzWebApp -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
                        if ($webApp.HttpsOnly -eq $true) {
                            $resourcesCompliant++
                        }
                    }
                    "Microsoft.Storage/storageAccounts" {
                        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
                        if ($storageAccount.MinimumTlsVersion -eq "TLS1_2") {
                            $resourcesCompliant++
                        }
                    }
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Regularly rotate secrets, keys, and certificates stored in Azure Key Vault.
        # Reference: https://learn.microsoft.com/azure/key-vault/general/overview

        $keyVaults = $global:AzData.Resources | Where-Object { $_.ResourceType -eq "Microsoft.KeyVault/vaults" }
        $vaultsWithRotationPolicy = 0

        foreach ($keyVault in $keyVaults) {
            $keys = Get-AzKeyVaultKey -VaultName $keyVault.Name
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F01.19
function Test-QuestionF0119 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    # Since this question involves implementing a specific framework (AMBA),
    # it requires a manual decision and implementation verification.

    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This requires verification that AMBA has been implemented and configured correctly."

    try {
        $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied 0 -checklistItem $checklistItem -rawData $_.Exception.Message
    }

    return $result
}

# Function for Management item F01.20
function Test-QuestionF0120 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Use Azure Monitoring Agent (AMA). The Log Analytics agent is deprecated since August 31, 2024.
        # Reference: https://learn.microsoft.com/azure/azure-monitor/agents/azure-monitor-agent-overview

        $resourcesWithAMA = 0
        $totalResources = 0

        $vmResourceTypes = @(
            "Microsoft.Compute/virtualMachines",
            "Microsoft.Compute/virtualMachineScaleSets",
            "Microsoft.DesktopVirtualization/applicationGroups",
            "Microsoft.DesktopVirtualization/hostPools"
        )

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in $vmResourceTypes
        }

        foreach ($resource in $resources) {
            $totalResources++

            # Check for Azure Monitor Agent (AMA) extension
            $extensions = Get-AzVMExtension -ResourceGroupName $resource.ResourceGroupName -VMName $resource.Name -ErrorAction SilentlyContinue |
                          Where-Object { $_.Type -eq "AzureMonitorWindowsAgent" -or $_.Type -eq "AzureMonitorLinuxAgent" }

            if ($extensions) {
                $resourcesWithAMA++
            }
        }

        if ($resourcesWithAMA -eq $totalResources) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($resourcesWithAMA -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($resourcesWithAMA / $totalResources) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalResources       = $totalResources
            ResourcesWithAMA     = $resourcesWithAMA
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F01.21
function Test-QuestionF0121 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Ensure that storage accounts are zone or region redundant.
        # Reference: https://learn.microsoft.com/en-gb/azure/storage/common/redundancy-migration?tabs=portal

        $totalStorageAccounts = 0
        $compliantStorageAccounts = 0

        $storageAccounts = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.Storage/storageAccounts"
        }

        foreach ($storageAccount in $storageAccounts) {
            $totalStorageAccounts++
            if ($storageAccount.Sku.Name -notin @("Standard_LRS", "Premium_LRS")) {
                $compliantStorageAccounts++
            }
        }

        if ($compliantStorageAccounts -eq $totalStorageAccounts) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($compliantStorageAccounts -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($compliantStorageAccounts / $totalStorageAccounts) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalStorageAccounts      = $totalStorageAccounts
            CompliantStorageAccounts  = $compliantStorageAccounts
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F02.01
function Test-QuestionF0201 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F04.03
function Test-QuestionF0403 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Use Azure-native backup capabilities, or an Azure-compatible, 3rd-party backup solution.
        # Reference: https://learn.microsoft.com/azure/backup/backup-center-overview

        $totalResources = 0
        $resourcesWithBackup = 0

        $backupEligibleResources = @("Microsoft.Compute/virtualMachines", "Microsoft.Sql/servers/databases", "Microsoft.Storage/storageAccounts")

        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in $backupEligibleResources
        }

        foreach ($resource in $resources) {
            $totalResources++

            # Check for backup configuration in Azure Backup Center
            $backupItems = Get-AzRecoveryServicesBackupItem -ResourceGroupName $resource.ResourceGroupName -WorkloadType AzureVM -ErrorAction SilentlyContinue |
                           Where-Object { $_.SourceResourceId -eq $resource.Id }

            if ($backupItems) {
                $resourcesWithBackup++
            }
        }

        if ($resourcesWithBackup -eq $totalResources) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($resourcesWithBackup -eq 0) {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($resourcesWithBackup / $totalResources) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $rawData = @{
            TotalResources       = $totalResources
            ResourcesWithBackup  = $resourcesWithBackup
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = $status
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item F06.01
function Test-QuestionF0601 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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

    Write-Output "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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
                                      $_.WorkspaceId -ne $null -and $_.WorkspaceId -match "Microsoft Sentinel"
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
