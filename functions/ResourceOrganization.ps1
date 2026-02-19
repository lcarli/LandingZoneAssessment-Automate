# ResourceOrganization.ps1

<#
.SYNOPSIS
    Functions related to ResourceOrganization assessment.

.DESCRIPTION
    This script contains functions to evaluate the ResourceOrganization area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Dot-source shared modules
. "$PSScriptRoot/../shared/Enums.ps1"
. "$PSScriptRoot/../shared/ErrorHandling.ps1"
. "$PSScriptRoot/../shared/SharedFunctions.ps1"

function Invoke-ResourceOrganizationAssessment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )

    Write-AssessmentHeader "Evaluating the Resource Organization design area..."
    
    Measure-ExecutionTime -ScriptBlock {
        $results = @()
        
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C01.01") }) | Test-QuestionC0101
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.01") }) | Test-QuestionC0201
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.02") }) | Test-QuestionC0202
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.03") }) | Test-QuestionC0203
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.04") }) | Test-QuestionC0204
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.05") }) | Test-QuestionC0205
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.06") }) | Test-QuestionC0206
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.07") }) | Test-QuestionC0207
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.08") }) | Test-QuestionC0208
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.09") }) | Test-QuestionC0209
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.10") }) | Test-QuestionC0210
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.11") }) | Test-QuestionC0211
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.12") }) | Test-QuestionC0212
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.13") }) | Test-QuestionC0213        
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.14") }) | Test-QuestionC0214
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C02.15") }) | Test-QuestionC0215
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C03.01") }) | Test-QuestionC0301
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C03.02") }) | Test-QuestionC0302
        $results += ($Checklist.items | Where-Object { ($_.id -eq "C03.03") }) | Test-QuestionC0303

        $script:FunctionResult = $results
    } -FunctionName "Invoke-ResourceOrganizationAssessment"

    return $script:FunctionResult
}

function Test-QuestionC0101 {
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
        # Question: Use a well defined naming scheme for resources, such as Microsoft Best Practice Naming Standards.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

        # Microsoft recommended prefixes for common resource types
        $namingPrefixes = @{
            'Microsoft.Compute/virtualMachines' = @('vm-')
            'Microsoft.Network/virtualNetworks' = @('vnet-')
            'Microsoft.Network/networkSecurityGroups' = @('nsg-')
            'Microsoft.Storage/storageAccounts' = @('st', 'stvm', 'stdiag')
            'Microsoft.KeyVault/vaults' = @('kv-')
            'Microsoft.Network/publicIPAddresses' = @('pip-')
            'Microsoft.Network/loadBalancers' = @('lbi-', 'lbe-')
            'Microsoft.ContainerService/managedClusters' = @('aks-')
            'Microsoft.Sql/servers' = @('sql-')
            'Microsoft.Web/sites' = @('app-', 'func-')
            'Microsoft.Network/applicationGateways' = @('agw-')
            'Microsoft.ManagedIdentity/userAssignedIdentities' = @('id-')
        }

        if ($global:AzData -and $global:AzData.Resources -and $global:AzData.Resources.Count -gt 0) {
            $totalChecked = 0
            $compliant = 0
            $nonCompliant = @()

            foreach ($resourceType in $namingPrefixes.Keys) {
                $resources = @($global:AzData.Resources | Where-Object { $_.ResourceType -eq $resourceType })
                foreach ($resource in $resources) {
                    $totalChecked++
                    $name = $resource.Name.ToLower()
                    $prefixes = $namingPrefixes[$resourceType]
                    $hasPrefix = $false
                    foreach ($prefix in $prefixes) {
                        if ($name.StartsWith($prefix.ToLower())) {
                            $hasPrefix = $true
                            break
                        }
                    }
                    if ($hasPrefix) {
                        $compliant++
                    } else {
                        if ($nonCompliant.Count -lt 20) {
                            $nonCompliant += @{ Name = $resource.Name; Type = $resourceType; ExpectedPrefixes = $prefixes -join ', ' }
                        }
                    }
                }
            }

            if ($totalChecked -eq 0) {
                $status = [Status]::ManualVerificationRequired
                $rawData = @{
                    Note = "No resources of checkable types found. Manual verification of naming conventions required."
                }
            } elseif ($compliant -eq $totalChecked) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalChecked = $totalChecked
                    Compliant = $compliant
                    ComplianceRate = "100%"
                    Note = "All checked resources follow Microsoft naming conventions."
                }
            } elseif ($compliant -gt 0) {
                $complianceRate = [Math]::Round(($compliant / $totalChecked) * 100, 1)
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [int]$complianceRate
                $rawData = @{
                    TotalChecked = $totalChecked
                    Compliant = $compliant
                    NonCompliant = $totalChecked - $compliant
                    ComplianceRate = "$complianceRate%"
                    SampleNonCompliant = $nonCompliant
                    Note = "Some resources follow naming conventions but not all."
                }
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalChecked = $totalChecked
                    Compliant = 0
                    SampleNonCompliant = $nonCompliant
                    Note = "No checked resources follow Microsoft recommended naming conventions."
                }
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = "Unable to retrieve resources for naming convention analysis."
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

function Test-QuestionC0201 {
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
        # Question: Enforce reasonably flat management group hierarchy with no more than six levels.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org-management-groups

        $rootMG = $global:AzData.ManagementGroups | Where-Object { $_.Name -eq "Tenant Root Group" }

        function Get-MGDepth($mg, $currentDepth) {
            $maxDepth = $currentDepth
            if ($mg.Children) {
                foreach ($child in $mg.Children) {
                    $childMG = Get-AzManagementGroup -GroupName $child.Name -Expand -ErrorAction SilentlyContinue
                    if ($childMG) {
                        $childDepth = Get-MGDepth $childMG ($currentDepth + 1)
                        if ($childDepth -gt $maxDepth) {
                            $maxDepth = $childDepth
                        }
                    }
                }
            }
            return $maxDepth
        }
        $maxDepth = Get-MGDepth -mg $rootMG -currentDepth 1

        if ($maxDepth -le 6) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        }
        else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        $rawData = @{
            MaxDepth = $maxDepth
            Limit    = 6
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

function Test-QuestionC0202 {
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
        # Question: Enforce a sandbox management group to allow users to immediately experiment with Azure.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org-management-groups#management-group-recommendations

        $searchTerms = @("sandbox", "lab", "laboratoire", "carredesable", "labo")
        $sandboxGroup = $global:AzData.ManagementGroups | Where-Object {
            $groupName = $_.DisplayName.ToLower()
            $searchTerms | ForEach-Object { $groupName -like "*$_*" }
        }

        if ($sandboxGroup) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                MatchingGroups = $sandboxGroup.DisplayName
                Status         = "Sandbox management group exists"
            }
        }
        else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No management group with the specified names found."
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

function Test-QuestionC0203 {
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
        # Question: Enforce a platform management group under the root management group to support common platform policy and Azure role assignment.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org-management-groups#management-group-recommendations

        $searchTerms = @("platform", "plateforme")
        $platformMG = $global:AzData.ManagementGroups | Where-Object {
            $groupName = $_.DisplayName.ToLower()
            $searchTerms | ForEach-Object { $groupName -like "*$_*" }
        }

        if ($platformMG) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                ManagementGroupName = $platformMG.Name
                Status              = "Platform management group exists"
            }
        }
        else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "Platform management group does not exist."
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

function Test-QuestionC0204 {
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
        # Question: Enforce a dedicated connectivity subscription in the Connectivity management group to host an Azure Virtual WAN hub, private non-AD Domain Name System (DNS), ExpressRoute circuit, and other networking resources.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org-management-groups#management-group-recommendations

        
        
        $searchTerms = @("Connectivity", "Network", "Reseau", "connectivite", "Hub")
        $connectivityMG = $global:AzData.ManagementGroups | Where-Object {
            $groupName = $_.DisplayName.ToLower()
            $searchTerms | ForEach-Object { $groupName -like "*$_*" }
        }

        if ($connectivityMG) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                connectivityMG        = $connectivityMG.DisplayName
                Status                = "Dedicated connectivity subscription exists"
            }
        }
        else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No dedicated connectivity subscription found in the Connectivity management group."
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

function Test-QuestionC0205 {
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
        # Question: Enforce no subscriptions are placed under the root management group.
        # Reference: https://learn.microsoft.com/azure/governance/management-groups/how-to/protect-resource-hierarchy#setting---default-management-group

        $rootMG = $global:AzData.ManagementGroups | Where-Object { $_.Name -eq "Tenant Root Group" }
        $subscriptionsUnderRoot = $rootMG |
            Select-Object -ExpandProperty Children |
            Where-Object { $_.Type -eq "Microsoft.Resources/subscriptions" }

        if ($subscriptionsUnderRoot) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = @{
                SubscriptionsUnderRoot = $subscriptionsUnderRoot | Select-Object -ExpandProperty DisplayName
                Status                 = "Subscriptions are directly placed under the root management group."
            }
        } else {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = "No subscriptions are directly placed under the root management group."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionC0206 {
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
        # Question: Enforce that only privileged users can operate management groups in the tenant by enabling Azure RBAC authorization in the management group hierarchy settings.
        # Reference: https://learn.microsoft.com/azure/governance/management-groups/how-to/protect-resource-hierarchy#setting---require-authorization

        $rootMG = $global:AzData.ManagementGroups | Where-Object { $_.Name -eq "Tenant Root Group" }

        if ($rootMG) {
            $authorizationEnabled = $rootMG.Properties.Details.RequiresAuthorization
            if ($authorizationEnabled -eq $true) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    RequiresAuthorization = $authorizationEnabled
                    Status                = "Authorization requirement is enabled for management groups."
                }
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = "Authorization requirement is not enabled for management groups."
            }
        } else {
            $status = [Status]::Error
            $rawData = "Root management group not found or accessible."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionC0207 {
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
        # Question: Enforce management groups under the root-level management group to represent the types of workloads, based on their security, compliance, connectivity, and feature needs.
        # Reference: https://learn.microsoft.com/azure/governance/management-groups/overview

        if ($global:AzData -and $global:AzData.ManagementGroups -and $global:AzData.ManagementGroups.Count -gt 0) {
            # Expected ALZ workload-type MG categories
            $expectedCategories = @{
                'Platform'     = @('platform', 'plateforme')
                'LandingZones' = @('landing zone', 'landingzone', 'workload')
                'Sandbox'      = @('sandbox', 'lab', 'dev')
                'Decommissioned' = @('decommissioned', 'retired', 'deprecated')
            }

            $foundCategories = @{}
            $allMGNames = @($global:AzData.ManagementGroups | ForEach-Object {
                if ($_.DisplayName) { $_.DisplayName } else { $_.Name }
            })

            foreach ($category in $expectedCategories.Keys) {
                $keywords = $expectedCategories[$category]
                $match = @($allMGNames | Where-Object {
                    $mgName = $_.ToLower()
                    ($keywords | Where-Object { $mgName -ilike "*$_*" }).Count -gt 0
                })
                if ($match.Count -gt 0) {
                    $foundCategories[$category] = $match
                }
            }

            $categoriesFound = $foundCategories.Keys.Count
            $totalExpected = $expectedCategories.Keys.Count

            if ($categoriesFound -ge 3) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = [Math]::Min(100, [Math]::Round(($categoriesFound / $totalExpected) * 100))
                $rawData = @{
                    FoundCategories = $foundCategories
                    CategoriesFound = $categoriesFound
                    TotalExpected = $totalExpected
                    AllManagementGroups = $allMGNames
                    Note = "Management groups are categorized by workload type: $categoriesFound of $totalExpected expected categories found."
                }
            } elseif ($categoriesFound -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($categoriesFound / $totalExpected) * 100)
                $rawData = @{
                    FoundCategories = $foundCategories
                    CategoriesFound = $categoriesFound
                    TotalExpected = $totalExpected
                    AllManagementGroups = $allMGNames
                    Note = "Some workload type MG categories found but not all. Found $categoriesFound of $totalExpected."
                }
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    AllManagementGroups = $allMGNames
                    Note = "No management groups with workload-type categorization found."
                }
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = "Unable to retrieve management group data for workload categorization analysis."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionC0208 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure resource owners are informed of their roles and responsibilities."

    try {
        # Question: Enforce a process to make resource owners aware of their roles and responsibilities, access review, budget review, policy compliance and remediate when necessary.
        # Reference: https://learn.microsoft.com/entra/id-governance/access-reviews-overview

        $evidence = @{
            AccessReviewsConfigured = $false
            BudgetAlertsConfigured = $false
            PolicyComplianceCount = 0
        }

        # Check for access reviews in Graph data
        if ($global:GraphData -and $global:GraphData.AccessReviews) {
            $evidence.AccessReviewsConfigured = @($global:GraphData.AccessReviews).Count -gt 0
        }

        # Check for budget alerts/cost alerts
        if ($global:AzData -and $global:AzData.Resources) {
            $budgetResources = @($global:AzData.Resources | Where-Object {
                $_.ResourceType -eq "Microsoft.Consumption/budgets" -or
                $_.ResourceType -eq "Microsoft.CostManagement/budgets"
            })
            $evidence.BudgetAlertsConfigured = $budgetResources.Count -gt 0
        }

        # Check for policy compliance data
        if ($global:AzData -and $global:AzData.Policies) {
            $evidence.PolicyComplianceCount = @($global:AzData.Policies).Count
        }

        $indicators = 0
        if ($evidence.AccessReviewsConfigured) { $indicators++ }
        if ($evidence.BudgetAlertsConfigured) { $indicators++ }
        if ($evidence.PolicyComplianceCount -gt 0) { $indicators++ }

        if ($indicators -ge 2) {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = [Math]::Min(70, $indicators * 25)
            $rawData = @{
                Evidence = $evidence
                IndicatorsFound = $indicators
                Note = "Found $indicators of 3 governance indicators: access reviews, budgets, policies. Manual verification needed to confirm resource owner awareness processes."
            }
        } elseif ($indicators -eq 1) {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 15
            $rawData = @{
                Evidence = $evidence
                IndicatorsFound = $indicators
                Note = "Limited governance indicators found. Manual verification required to assess resource owner awareness processes."
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = @{
                Evidence = $evidence
                Note = "No governance indicators found for access reviews, budgets, or policies. Manual verification required."
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

function Test-QuestionC0209 {
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
        # Question: Ensure that all subscription owners and IT core team are aware of subscription quotas and the impact they have on provision resources for a given subscription.
        # Reference: https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits

        # Check resource usage relative to known limits as a proxy for quota awareness
        $evidence = @{
            SubscriptionCount = 0
            ResourceCountPerSubscription = @{}
            HighUsageSubscriptions = @()
        }

        if ($global:AzData -and $global:AzData.Resources -and $global:AzData.Subscriptions) {
            $evidence.SubscriptionCount = $global:AzData.Subscriptions.Count

            # Group resources by subscription to identify potential quota concerns
            $resourcesBySubscription = $global:AzData.Resources | Group-Object -Property @{
                Expression = { 
                    if ($_.ResourceId) {
                        ($_.ResourceId -split '/')[2]
                    } else { 'unknown' }
                }
            }

            foreach ($group in $resourcesBySubscription) {
                $evidence.ResourceCountPerSubscription[$group.Name] = $group.Count
                # Flag subscriptions with high resource count as potential quota concerns
                if ($group.Count -gt 500) {
                    $evidence.HighUsageSubscriptions += @{
                        SubscriptionId = $group.Name
                        ResourceCount = $group.Count
                    }
                }
            }

            if ($evidence.HighUsageSubscriptions.Count -gt 0) {
                $status = [Status]::ManualVerificationRequired
                $estimatedPercentageApplied = 10
                $rawData = @{
                    Evidence = $evidence
                    Note = "Found $($evidence.HighUsageSubscriptions.Count) subscriptions with high resource counts (500+). Verify that subscription owners are aware of quotas and limits."
                }
            } else {
                $status = [Status]::ManualVerificationRequired
                $estimatedPercentageApplied = 0
                $rawData = @{
                    Evidence = $evidence
                    Note = "No subscriptions with high resource usage detected. Manual verification required to confirm quota awareness among subscription owners."
                }
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = "Unable to retrieve subscription and resource data. Manual verification required."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionC0210 {
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
        # Question: Use Reserved Instances where appropriate to optimize cost and ensure available capacity in target regions.
        # Reference: https://learn.microsoft.com/azure/cost-management-billing/reservations/save-compute-costs-reservations

        $subscriptions = $global:AzData.Subscriptions
        $reservedInstancesUsed = 0
        $totalSubscriptions = $subscriptions.Count

        foreach ($subscription in $subscriptions) {
            try {
                # Use cached data or get reservations without changing context
                $reservations = Get-AzReservationOrder -SubscriptionId $subscription.Id -ErrorAction SilentlyContinue
                if ($reservations -and $reservations.Count -gt 0) {
                    $reservedInstancesUsed++
                }
            }
            catch {
                # Skip this subscription if we can't check reservations
                continue
            }
        }

        if ($reservedInstancesUsed -eq $totalSubscriptions) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                SubscriptionsChecked     = $totalSubscriptions
                SubscriptionsWithRI      = $reservedInstancesUsed
                Status                   = "Reserved Instances are used in all subscriptions."
            }
        } elseif ($reservedInstancesUsed -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No Reserved Instances are used in any subscription."
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($reservedInstancesUsed / $totalSubscriptions) * 100
            $rawData = @{
                SubscriptionsChecked     = $totalSubscriptions
                SubscriptionsWithRI      = $reservedInstancesUsed
                Status                   = "Reserved Instances are used in some subscriptions."
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

function Test-QuestionC0211 {
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
        # Question: Establish dashboards and/or visualizations to monitor compute and storage capacity metrics. (i.e. CPU, memory, disk space).
        # Reference: https://learn.microsoft.com/azure/azure-portal/azure-portal-dashboards

        $dashboards = $global:AzData.Resources | Where-Object { $_.ResourceType -eq "Microsoft.Portal/dashboards" }
        $monitoringResources = $global:AzData.Resources | Where-Object { 
            $_.ResourceType -in @(
                "Microsoft.OperationalInsights/workspaces",
                "Microsoft.Insights/metricAlerts",
                "Microsoft.Insights/components"
            )
        }

        $totalMonitoringResources = $dashboards.Count + $monitoringResources.Count

        if ($totalMonitoringResources -gt 0) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                Dashboards         = $dashboards.Count
                MonitoringResources = $monitoringResources.Count
                TotalResources     = $totalMonitoringResources
                Status             = "Monitoring infrastructure found for capacity metrics."
            }
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No dashboards or monitoring infrastructure found for capacity metrics."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionC0212 {
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
        # Question: As part of your cloud adoption, implement a detailed cost management plan using the 'Managed cloud costs' process.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/get-started/manage-costs

        if ($global:AzData -and $global:AzData.Resources) {
            $evidence = @{
                BudgetResources = @()
                CostAlerts = @()
                CostExports = @()
                ActionGroups = @()
            }

            # Check for budget resources
            $evidence.BudgetResources = @($global:AzData.Resources | Where-Object {
                $_.ResourceType -eq "Microsoft.Consumption/budgets" -or
                $_.ResourceType -eq "Microsoft.CostManagement/budgets"
            } | Select-Object -Property Name, ResourceGroupName, Location)

            # Check for cost management exports
            $evidence.CostExports = @($global:AzData.Resources | Where-Object {
                $_.ResourceType -eq "Microsoft.CostManagement/exports"
            } | Select-Object -Property Name, ResourceGroupName, Location)

            # Check for action groups that might be cost-related alerts
            $evidence.ActionGroups = @($global:AzData.Resources | Where-Object {
                $_.ResourceType -eq "Microsoft.Insights/actionGroups"
            } | Select-Object -Property Name, ResourceGroupName)

            $indicators = 0
            if ($evidence.BudgetResources.Count -gt 0) { $indicators++ }
            if ($evidence.CostExports.Count -gt 0) { $indicators++ }
            if ($evidence.ActionGroups.Count -gt 0) { $indicators++ }

            if ($indicators -ge 2) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = [Math]::Min(100, $indicators * 35)
                $rawData = @{
                    Evidence = $evidence
                    IndicatorsFound = $indicators
                    Note = "Cost management infrastructure found: $($evidence.BudgetResources.Count) budgets, $($evidence.CostExports.Count) exports, $($evidence.ActionGroups.Count) action groups."
                }
            } elseif ($indicators -eq 1) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = 30
                $rawData = @{
                    Evidence = $evidence
                    IndicatorsFound = $indicators
                    Note = "Limited cost management infrastructure found. Consider adding budgets, cost exports, and alert action groups."
                }
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    Evidence = $evidence
                    Note = "No cost management resources found. No budgets, cost exports, or cost-related action groups detected."
                }
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = "Unable to retrieve resource data for cost management analysis."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionC0213 {
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
        # Question: If servers will be used for Identity services, like domain controllers, establish a dedicated identity subscription in the identity management group, to host these services.
        # Reference: https://learn.microsoft.com/azure/governance/management-groups/overview

        $identityMGFound = $false
        $identitySubscriptions = @()
        $domainControllerVMs = @()

        if ($global:AzData -and $global:AzData.ManagementGroups) {
            # Look for an Identity management group
            $identityMGs = @($global:AzData.ManagementGroups | Where-Object {
                $displayName = if ($_.DisplayName) { $_.DisplayName } else { $_.Name }
                $displayName -imatch 'identity|identidade'
            })

            $identityMGFound = $identityMGs.Count -gt 0
        }

        if ($global:AzData -and $global:AzData.Resources) {
            # Check for domain controller indicators: VMs with DC-related names or extensions
            $domainControllerVMs = @($global:AzData.Resources | Where-Object {
                ($_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and
                 $_.Name -imatch 'dc|domain|adds|addc|ad-|ad[0-9]') -or
                ($_.ResourceType -eq "Microsoft.AAD/domainServices")
            } | Select-Object -Property Name, ResourceGroupName, Location, ResourceType)
        }

        # Determine status based on findings
        if ($domainControllerVMs.Count -eq 0 -and -not $identityMGFound) {
            # No domain controllers and no identity MG - might not need one
            $status = [Status]::ManualVerificationRequired
            $rawData = @{
                IdentityMGFound = $identityMGFound
                DomainControllerVMs = $domainControllerVMs
                Note = "No domain controllers or AD Domain Services found. If identity servers are not needed, this check may not apply. Manual verification required."
            }
        } elseif ($identityMGFound -and $domainControllerVMs.Count -gt 0) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 80
            $rawData = @{
                IdentityMGFound = $identityMGFound
                IdentityMGNames = @($identityMGs | ForEach-Object { if ($_.DisplayName) { $_.DisplayName } else { $_.Name } })
                DomainControllerVMs = $domainControllerVMs
                Note = "Identity management group found with domain controller resources present."
            }
        } elseif ($domainControllerVMs.Count -gt 0 -and -not $identityMGFound) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 20
            $rawData = @{
                IdentityMGFound = $identityMGFound
                DomainControllerVMs = $domainControllerVMs
                Note = "Domain controllers found but no dedicated Identity management group exists. Consider creating an Identity MG with dedicated subscriptions."
            }
        } elseif ($identityMGFound -and $domainControllerVMs.Count -eq 0) {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = 50
            $rawData = @{
                IdentityMGFound = $identityMGFound
                IdentityMGNames = @($identityMGs | ForEach-Object { if ($_.DisplayName) { $_.DisplayName } else { $_.Name } })
                Note = "Identity management group found but no domain controller VMs detected in current scope."
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

function Test-QuestionC0214 {
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
        # Question: Ensure that tags are consistently used across all resources for cost management and reporting.
        # Reference: https://learn.microsoft.com/azure/azure-resource-manager/management/tag-resources

        if ($global:AzData -and $global:AzData.Resources -and $global:AzData.Resources.Count -gt 0) {
            $totalResources = $global:AzData.Resources.Count
            $taggedResources = @($global:AzData.Resources | Where-Object {
                $_.Tags -and $_.Tags.Count -gt 0
            })
            $untaggedResources = @($global:AzData.Resources | Where-Object {
                -not $_.Tags -or $_.Tags.Count -eq 0
            })

            $taggedCount = $taggedResources.Count
            $complianceRate = [Math]::Round(($taggedCount / $totalResources) * 100, 2)

            # Analyze common tags
            $tagFrequency = @{}
            foreach ($resource in $taggedResources) {
                if ($resource.Tags -is [System.Collections.IDictionary]) {
                    foreach ($key in $resource.Tags.Keys) {
                        if ($tagFrequency.ContainsKey($key)) {
                            $tagFrequency[$key]++
                        } else {
                            $tagFrequency[$key] = 1
                        }
                    }
                }
            }

            # Get top 10 most used tags
            $topTags = @($tagFrequency.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10)

            # Sample of untagged resources for reporting
            $untaggedSample = @($untaggedResources | Select-Object -First 20 -Property Name, ResourceType, ResourceGroupName)

            if ($complianceRate -ge 90) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = [Math]::Min(100, [int]$complianceRate)
            } elseif ($complianceRate -ge 50) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [int]$complianceRate
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = [int]$complianceRate
            }

            $rawData = @{
                TotalResources = $totalResources
                TaggedResources = $taggedCount
                UntaggedResources = $untaggedResources.Count
                ComplianceRate = "$complianceRate%"
                TopTags = $topTags
                UntaggedSample = $untaggedSample
                Note = "Tag compliance: $taggedCount of $totalResources resources have tags ($complianceRate%)."
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = "Unable to retrieve resource data for tag compliance analysis."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionC0215 {
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
        # Question: For Sovereign Landing Zone, have a 'confidential corp' and 'confidential online' management group directly under the 'landing zones' MG.
        # Reference: https://github.com/Azure/sovereign-landing-zone/blob/main/docs/02-Architecture.md

        # Look for landing zones management group first
        $landingZonesMG = $global:AzData.ManagementGroups | Where-Object {
            $_.DisplayName.ToLower() -like "*landing zones*" -or
            $_.DisplayName.ToLower() -like "*landingzones*" -or
            $_.Name.ToLower() -like "*landingzones*"
        }

        if (-not $landingZonesMG) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No 'landing zones' management group found."
        } else {
            # Look for confidential corp and confidential online management groups under landing zones
            $confidentialCorpMG = $global:AzData.ManagementGroups | Where-Object {
                ($_.DisplayName.ToLower() -like "*confidential corp*" -or
                 $_.DisplayName.ToLower() -like "*confidentialcorp*" -or
                 $_.Name.ToLower() -like "*confidentialcorp*") -and
                $_.Properties.Details.Parent.Id -eq $landingZonesMG.Id
            }

            $confidentialOnlineMG = $global:AzData.ManagementGroups | Where-Object {
                ($_.DisplayName.ToLower() -like "*confidential online*" -or
                 $_.DisplayName.ToLower() -like "*confidentialonline*" -or
                 $_.Name.ToLower() -like "*confidentialonline*") -and
                $_.Properties.Details.Parent.Id -eq $landingZonesMG.Id
            }

            $foundGroups = @()
            if ($confidentialCorpMG) { $foundGroups += "Confidential Corp" }
            if ($confidentialOnlineMG) { $foundGroups += "Confidential Online" }

            if ($confidentialCorpMG -and $confidentialOnlineMG) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    LandingZonesMG = $landingZonesMG.DisplayName
                    FoundGroups = $foundGroups
                    Status = "Both 'confidential corp' and 'confidential online' management groups found under landing zones."
                }
            } elseif ($confidentialCorpMG -or $confidentialOnlineMG) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = 50
                $rawData = @{
                    LandingZonesMG = $landingZonesMG.DisplayName
                    FoundGroups = $foundGroups
                    Status = "Only some of the required confidential management groups found."
                }
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    LandingZonesMG = $landingZonesMG.DisplayName
                    FoundGroups = @()
                    Status = "No confidential management groups found under landing zones."
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

function Test-QuestionC0301 {
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
        # Question: Define and apply security baselines to ensure consistent security standards across all environments.
        # Reference: https://learn.microsoft.com/azure/security/fundamentals/security-baseline

        # Check for Microsoft Security Baseline policy assignments
        $securityBaselineInitiatives = @(
            "Security Baseline",
            "Azure Security Benchmark",
            "Microsoft Security Compliance",
            "MSCB",
            "ASB"
        )
        $assignedPolicies = $global:AzData.Policies | Where-Object {
            $policyName = $_.Properties.DisplayName
            $matched = $false
            foreach ($baseline in $securityBaselineInitiatives) {
                if ($policyName -match $baseline) { $matched = $true; break }
            }
            $matched
        }

        if ($assignedPolicies -and $assignedPolicies.Count -gt 0) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                AssignedPolicies = $assignedPolicies | Select-Object -ExpandProperty @{Name="DisplayName"; Expression={$_.Properties.DisplayName}}
                Status           = "Security baselines are implemented."
            }
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No security baseline policies found."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionC0302 {
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
        # Question: Deploy your Azure landing zone in a multi-region deployment.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-setup-guide/regions#operate-in-multiple-geographic-regions

        $regions = $global:AzData.Resources | Where-Object { $_.ResourceType -notmatch "Microsoft.Network/networkWatchers" } |
                   Select-Object -ExpandProperty Location -Unique

        if ($regions.Count -gt 1) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                DeployedRegions = $regions
                Status          = "Resources are deployed in multiple regions."
            }
        } elseif ($regions.Count -eq 1) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = @{
                DeployedRegions = $regions
                Status          = "Resources are deployed in a single region."
            }
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No resources are deployed."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionC0303 {
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
        # Question: Ensure required services and features are available within the chosen deployment regions.
        # Reference: https://azure.microsoft.com/explore/global-infrastructure/products-by-region/

        if ($global:AzData -and $global:AzData.Resources -and $global:AzData.Resources.Count -gt 0) {
            # Identify deployed regions
            $deployedRegions = @($global:AzData.Resources |
                Where-Object { $_.Location -and $_.Location -ne 'global' } |
                Select-Object -ExpandProperty Location -Unique)

            # Identify deployed resource types per region
            $resourceTypesByRegion = @{}
            foreach ($region in $deployedRegions) {
                $typesInRegion = @($global:AzData.Resources |
                    Where-Object { $_.Location -eq $region } |
                    Select-Object -ExpandProperty ResourceType -Unique)
                $resourceTypesByRegion[$region] = $typesInRegion
            }

            # Check for critical resource types deployed across multiple regions
            $allResourceTypes = @($global:AzData.Resources |
                Select-Object -ExpandProperty ResourceType -Unique)

            # Critical services that should ideally be available in all deployment regions
            $criticalTypes = @(
                'Microsoft.Compute/virtualMachines',
                'Microsoft.Network/virtualNetworks',
                'Microsoft.Storage/storageAccounts',
                'Microsoft.KeyVault/vaults'
            )

            $criticalAvailability = @{}
            foreach ($cType in $criticalTypes) {
                $regionsWithType = @($resourceTypesByRegion.Keys | Where-Object {
                    $resourceTypesByRegion[$_] -contains $cType
                })
                if ($regionsWithType.Count -gt 0) {
                    $criticalAvailability[$cType] = $regionsWithType
                }
            }

            if ($deployedRegions.Count -gt 1 -and $criticalAvailability.Count -gt 0) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 90
                $rawData = @{
                    DeployedRegions = $deployedRegions
                    RegionCount = $deployedRegions.Count
                    UniqueResourceTypes = $allResourceTypes.Count
                    ResourceTypesByRegion = $resourceTypesByRegion
                    CriticalServiceAvailability = $criticalAvailability
                    Note = "Services deployed across $($deployedRegions.Count) regions with $($allResourceTypes.Count) unique resource types."
                }
            } elseif ($deployedRegions.Count -eq 1) {
                $status = [Status]::ManualVerificationRequired
                $estimatedPercentageApplied = 50
                $rawData = @{
                    DeployedRegions = $deployedRegions
                    RegionCount = 1
                    UniqueResourceTypes = $allResourceTypes.Count
                    ResourceTypesByRegion = $resourceTypesByRegion
                    Note = "Resources deployed in a single region. Verify that required services are available in this region: $($deployedRegions[0])."
                }
            } else {
                $status = [Status]::ManualVerificationRequired
                $estimatedPercentageApplied = 0
                $rawData = @{
                    DeployedRegions = $deployedRegions
                    Note = "Unable to determine deployed regions. Manual verification required."
                }
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $rawData = "Unable to retrieve resource data for region availability analysis."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

