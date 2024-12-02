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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
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
        $status = [Status]::Error
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
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
        $status = [Status]::Error
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
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
        $status = [Status]::Error
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
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
        $status = [Status]::Error
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
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
        $status = [Status]::Error
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
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
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
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