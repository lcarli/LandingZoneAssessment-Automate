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

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-ResourceOrganizationAssessment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )

    Write-Host "Evaluating the Resource Organization design area..."
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

# Function for Management item C01.01
function Test-QuestionC0101 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure that processes and policies are aligned."

    try {
        # Question: Use a well defined naming scheme for resources, such as Microsoft Best Practice Naming Standards.
        $status = [Status]::ManualVerificationRequired
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item C02.01
function Test-QuestionC0201 {
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
        # Question: Enforce reasonably flat management group hierarchy with no more than four levels.
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

        if ($maxDepth -le 5) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        }
        else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        $rawData = @{
            MaxDepth = $maxDepth
            Limit    = 4
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

# Function for Management item C02.02
function Test-QuestionC0202 {
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

# Function for Management item C02.03
function Test-QuestionC0203 {
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
        # Question: Enforce a platform management group under the root management group to support common platform policy and Azure role assignment.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org-management-groups#management-group-recommendations

        $platformMG = $global:AzData.ManagementGroups | Where-Object { $_.Name -eq "Platform" }

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

# Function for Management item C02.04
function Test-QuestionC0204 {
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

# Function for Management item C02.05
function Test-QuestionC0205 {
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

# Function for Management item C02.06
function Test-QuestionC0206 {
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

# Function for Management item C02.07
function Test-QuestionC0207 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure that management groups under the root are categorized based on workload needs (security, compliance, connectivity, and features)."

    try {
        # Question: Enforce management groups under the root-level management group to represent the types of workloads, based on their security, compliance, connectivity, and feature needs.
        # Reference: https://learn.microsoft.com/azure/governance/management-groups/overview

        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item C02.08
function Test-QuestionC0208 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure that resource owners are informed of their roles and responsibilities, access reviews are conducted, budgets are reviewed, and policy compliance is remediated as necessary."

    try {
        # Question: Enforce a process to make resource owners aware of their roles and responsibilities, access review, budget review, policy compliance and remediate when necessary.
        # Reference: https://learn.microsoft.com/entra/id-governance/access-reviews-overview

        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item C02.09
function Test-QuestionC0209 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure all subscription owners and IT core team members are informed about subscription quotas and their impact on resource provisioning."

    try {
        # Question: Ensure that all subscription owners and IT core team are aware of subscription quotas and the impact they have on provision resources for a given subscription.
        # Reference: https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits

        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item C02.10
function Test-QuestionC0210 {
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
        # Question: Use Reserved Instances where appropriate to optimize cost and ensure available capacity in target regions.
        # Reference: https://learn.microsoft.com/azure/cost-management-billing/reservations/save-compute-costs-reservations

        $subscriptions = $global:AzData.Subscriptions
        $reservedInstancesUsed = 0
        $totalSubscriptions = $subscriptions.Count

        foreach ($subscription in $subscriptions) {
            Set-AzContext -SubscriptionId $subscription.Id | Out-Null

            $reservations = Get-AzReservationOrder -ErrorAction SilentlyContinue
            if ($reservations) {
                $reservedInstancesUsed++
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

# Function for Management item C02.11
function Test-QuestionC0211 {
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
        # Question: Establish dashboards and/or visualizations to monitor compute and storage capacity metrics. (i.e. CPU, memory, disk space).
        # Reference: https://learn.microsoft.com/azure/azure-portal/azure-portal-dashboards

        $dashboards = $global:AzData.Resources | Where-Object { $_.ResourceType -eq "Microsoft.Portal/dashboards" }
        $dashboardMetrics = @("CPU", "Memory", "Disk Space")
        $validDashboards = @()

        foreach ($dashboard in $dashboards) {
            if ($dashboard.Properties -join " " -match ($dashboardMetrics -join "|")) {
                $validDashboards += $dashboard.Name
            }
        }

        if ($validDashboards.Count -eq $dashboards.Count) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                TotalDashboards    = $dashboards.Count
                ValidDashboards    = $validDashboards
                Status             = "All dashboards monitor compute and storage capacity metrics."
            }
        } elseif ($validDashboards.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No dashboards were found monitoring compute and storage capacity metrics."
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($validDashboards.Count / $dashboards.Count) * 100
            $rawData = @{
                TotalDashboards    = $dashboards.Count
                ValidDashboards    = $validDashboards
                Status             = "Some dashboards monitor compute and storage capacity metrics."
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

# Function for Management item C02.12
function Test-QuestionC0212 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to confirm if a detailed cost management plan has been implemented using the 'Managed cloud costs' process."

    try {
        # Question: As part of your cloud adoption, implement a detailed cost management plan using the 'Managed cloud costs' process.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/get-started/manage-costs

        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Resource Organization item C02.13
function Test-QuestionC0213 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to confirm if a detailed cost management plan has been implemented using the 'Managed cloud costs' process."

    try {
        # Question: If servers will be used for Identity services, like domain controllers, establish a dedicated identity subscription in the identity management group, to host these services. Make sure that resources are set to use the domain controllers available in their region.
        # Reference: https://learn.microsoft.com/azure/governance/management-groups/overview

        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item C02.14
function Test-QuestionC0214 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to confirm that tags are consistently used across resources for cost management and reporting."

    try {
        # Question: Ensure that tags are consistently used across all resources for cost management and reporting.
        # Reference: https://learn.microsoft.com/azure/azure-resource-manager/management/tag-resources

        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item C02.16
function Test-QuestionC0216 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure that cost management processes are aligned with organizational policies and procedures."

    try {
        # Question: Align cost management processes with organizational policies and procedures to ensure accountability.
        # Reference: https://learn.microsoft.com/azure/cost-management-billing/costs/tutorial-cost-management-policies

        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item C03.01
function Test-QuestionC0301 {
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
        # Question: Define and apply security baselines to ensure consistent security standards across all environments.
        # Reference: https://learn.microsoft.com/azure/security/fundamentals/security-baseline

        # Check for Microsoft Security Baseline policy assignments
        $securityBaselineInitiatives = @(
            "SecurityBaseline", # Common Microsoft Security Baseline Initiative name
            "MSCB"              # Alternate abbreviation for Microsoft Security Compliance Baseline
        )
        $assignedPolicies = $global:AzData.Policies | Where-Object {
            $_.Properties.DisplayName -match ($securityBaselineInitiatives -join "|")
        }

        if ($assignedPolicies) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                AssignedPolicies = $assignedPolicies | Select-Object -ExpandProperty DisplayName
                Status           = "Microsoft Security Baseline is implemented."
            }
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "Microsoft Security Baseline is not implemented."
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Management item C03.02
function Test-QuestionC0302 {
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

# Function for Management item C03.03
function Test-QuestionC0303 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::ManualVerificationRequired
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to ensure that a threat detection strategy is defined and applied across all environments."

    try {
        # Question: Define and apply a threat detection strategy to monitor and respond to security threats across all environments.
        # Reference: https://learn.microsoft.com/azure/security/fundamentals/threat-detection-strategies

        $status = [Status]::ManualVerificationRequired
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}