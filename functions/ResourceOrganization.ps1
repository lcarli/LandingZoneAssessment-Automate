<#
.SYNOPSIS
    Functions related to Resource Organization assessment.

.DESCRIPTION
    This script contains functions to evaluate the Resource Organization area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
. "$PSScriptRoot/../shared/Enums.ps1"
. "$PSScriptRoot/../shared/ErrorHandling.ps1"



function Invoke-ResourceOrganizationAssessment {
    Write-Host "Evaluating the IAM design area..."

    $results = @()

    # Call individual assessment functions
    $results += Assess-NamingStandards
    $results += Assess-FlatManagementGroupHierarchy
    $results += Assess-SandboxManagementGroup
    $results += Assess-PlatformManagementGroup
    $results += Assess-ConnectivitySubscription
    $results += Assess-NoSubscriptionsUnderRoot
    $results += Assess-ManagementGroupRBACAuthorization
    $results += Assess-ResourceOwnerAwareness

    # Return the results
    return $results
}


# C01.01 - It is recommended to follow Microsoft Best Practice Naming Standards
function Assess-NamingStandards {
    Write-Host "Checking if resources follow Microsoft Best Practice Naming Standards..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust the weight as necessary
    $score = 0

    try {
        # Retrieve all subscriptions
        $subscriptions = Get-AzSubscription -TenantId $TenandId

        # Initialize a list to hold all resources
        $allResources = @()

        # Iterate over each subscription and retrieve resources
        foreach ($subscription in $subscriptions) {
            Write-Host "Processing subscription: $($subscription.Name)"
            Set-AzContext -SubscriptionId $subscription.Id

            # Retrieve resources for the current subscription
            $resources = Get-AzResource

            # Add the retrieved resources to the list
            $allResources += $resources
        }

        $totalResources = $allResources.Count
        $compliantResources = 0


        #placeholder - HOW TO VALIDATE?


        if ($totalResources -gt 0) {
            $estimatedPercentageApplied = ($compliantResources / $totalResources) * 100

            if ($estimatedPercentageApplied -eq 100) {
                $status = [Status]::Implemented
            }
            elseif ($estimatedPercentageApplied -ge 50) {
                $status = [Status]::PartialImplemented
            }
            else {
                $status = [Status]::NotImplemented
            }

            # Calculate the score
            $score = ($weight * $estimatedPercentageApplied) / 100
        }
        else {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 0
            $score = 0
        }
    }
    catch {
        Log-Error -QuestionID "C01.01" -QuestionText "Follow Microsoft Best Practice Naming Standards" -FunctionName "Assess-NamingStandards" -ErrorMessage $_.Exception.Message
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


# C02.01 - Enforce reasonably flat management group hierarchy with no more than four levels.
function Assess-FlatManagementGroupHierarchy {
    Write-Host "Checking if management group hierarchy is reasonably flat with no more than four levels..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust the weight as necessary
    $score = 0

    try {
        # Retrieve all management groups
        $managementGroups = Get-AzManagementGroup

        # Initialize a counter for compliant management groups
        $compliantManagementGroups = 0
        $totalManagementGroups = $managementGroups.Count

        # Iterate through each management group to check its hierarchy level
        foreach ($mg in $managementGroups) {
            $mgDetails = Get-AzManagementGroup -GroupName $mg.Name

            # Check if the management group has more than one level and no more than four levels
            if ($mgDetails.Properties.Hierarchy.Count -le 4 -and $mgDetails.Properties.Hierarchy.Count -gt 1) {
                $compliantManagementGroups++
            }
        }

        if ($totalManagementGroups -gt 0) {
            $estimatedPercentageApplied = ($compliantManagementGroups / $totalManagementGroups) * 100

            if ($estimatedPercentageApplied -eq 100) {
                $status = [Status]::Implemented
            }
            elseif ($estimatedPercentageApplied -ge 50) {
                $status = [Status]::PartialImplemented
            }
            else {
                $status = [Status]::NotImplemented
            }

            # Calculate the score
            $score = ($weight * $estimatedPercentageApplied) / 100
        }
        else {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 0
            $score = 0
        }
    }
    catch {
        Log-Error -QuestionID "C02.01" -QuestionText "Enforce reasonably flat management group hierarchy with no more than four levels" -FunctionName "Assess-FlatManagementGroupHierarchy" -ErrorMessage $_.Exception.Message
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

# C02.02 - Enforce a sandbox management group to allow users to immediately experiment with Azure
function Assess-SandboxManagementGroup {
    Write-Host "Checking if a sandbox management group exists to allow users to immediately experiment with Azure..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust the weight as necessary
    $score = 0

    try {
        # Retrieve all management groups
        $managementGroups = Get-AzManagementGroup

        # Check if there is a management group named 'sandbox' or similar
        $sandboxGroup = $managementGroups | Where-Object { $_.DisplayName -match 'sandbox' }

        if ($sandboxGroup) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        }
        else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "C02.02" -QuestionText "Enforce a sandbox management group to allow users to immediately experiment with Azure" -FunctionName "Assess-SandboxManagementGroup" -ErrorMessage $_.Exception.Message
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

# C02.03 - Enforce a platform management group under the root management group to support common platform policy and Azure role assignment
function Assess-PlatformManagementGroup {
    Write-Host "Checking if a platform management group exists under the root management group to support common platform policy and Azure role assignment..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust the weight as necessary
    $score = 0

    try {
        # Retrieve all management groups
        $managementGroups = Get-AzManagementGroup

        # Check if there is a management group named 'platform' or similar
        $platformGroup = $childManagementGroups | Where-Object { $_.DisplayName -match 'platform' }

        if ($platformGroup) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        }
        else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "C02.03" -QuestionText "Enforce a platform management group under the root management group to support common platform policy and Azure role assignment" -FunctionName "Assess-PlatformManagementGroup" -ErrorMessage $_.Exception.Message
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


# C02.04 - Enforce a dedicated connectivity subscription in the Connectivity management group
function Assess-ConnectivitySubscription {
    Write-Host "Checking if a dedicated connectivity subscription exists in the Connectivity management group..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust the weight as necessary
    $score = 0

    try {
        # Retrieve all management groups
        $managementGroups = Get-AzManagementGroup

        # Find the Connectivity management group
        $connectivityGroup = $managementGroups | Where-Object { $_.DisplayName -match 'connectivity' }

        if ($connectivityGroup) {
            # Retrieve all subscriptions under the Connectivity management group
            $subscriptions = Get-AzSubscription

            $connectivitySubscriptions = @()

            foreach ($subscription in $subscriptions) {
                $subscriptionDetails = Get-AzSubscription -SubscriptionId $subscription.Id

                if ($subscriptionDetails.Tags["managementGroup"] -eq $connectivityGroup.Id) {
                    $connectivitySubscriptions += $subscriptionDetails
                }
            }

            if ($connectivitySubscriptions.Count -gt 0) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
        }
        else {
            Write-Host "Connectivity management group not found."
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 0
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "C02.04" -QuestionText "Enforce a dedicated connectivity subscription in the Connectivity management group" -FunctionName "Assess-ConnectivitySubscription" -ErrorMessage $_.Exception.Message
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


# C02.05 - Enforce no subscriptions are placed under the root management group
function Assess-NoSubscriptionsUnderRoot {
    Write-Host "Checking if no subscriptions are placed under the root management group..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust the weight as necessary
    $score = 0

    try {
        # Retrieve all management groups and identify the root group dynamically
        $managementGroups = Get-AzManagementGroup
        $rootManagementGroup = $managementGroups | Where-Object { $_.ParentId -eq $null }

        if (-not $rootManagementGroup) {
            throw "Root management group not found."
        }

        $rootManagementGroupId = $rootManagementGroup.Id

        # Retrieve all subscriptions
        $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $TenantId }

        # Initialize a counter for compliant subscriptions
        $compliantSubscriptions = 0
        $totalSubscriptions = $subscriptions.Count

        # Query to get the management group chain for each subscription
        $query = @"
        resourcecontainers
        | where type == 'microsoft.resources/subscriptions'
        | extend mgmtChain = properties.managementGroupAncestorsChain
        | project subscriptionId = id, mgmtChain
"@

        $mgmtChains = Search-AzGraph -Query $query

        # Iterate through each subscription to check its management group
        foreach ($subscription in $subscriptions) {
            $mgmtChain = $mgmtChains | Where-Object { $_.subscriptionId -eq "/subscriptions/"+$subscription.Id }

            # Check if the subscription is not directly under the root management group
            if ($mgmtChain.mgmtChain.Count -gt 1) {
                $compliantSubscriptions++
            }
        }

        if ($totalSubscriptions -gt 0) {
            $estimatedPercentageApplied = ($compliantSubscriptions / $totalSubscriptions) * 100

            if ($estimatedPercentageApplied -eq 100) {
                $status = [Status]::Implemented
            }
            elseif ($estimatedPercentageApplied -ge 50) {
                $status = [Status]::PartialImplemented
            }
            else {
                $status = [Status]::NotImplemented
            }

            # Calculate the score
            $score = ($weight * $estimatedPercentageApplied) / 100
        }
        else {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 0
            $score = 0
        }
    }
    catch {
        Log-Error -QuestionID "C02.05" -QuestionText "Enforce no subscriptions are placed under the root management group" -FunctionName "Assess-NoSubscriptionsUnderRoot" -ErrorMessage $_.Exception.Message
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


# C02.06 - Enforce that only privileged users can operate management groups in the tenant by enabling Azure RBAC authorization in the management group hierarchy settings
function Assess-ManagementGroupRBACAuthorization {
    Write-Host "Checking if only privileged users can operate management groups by enabling Azure RBAC authorization..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust the weight as necessary
    $score = 0

    try {
        # Retrieve all management groups
        $managementGroups = Get-AzManagementGroup

        # Initialize a counter for compliant management groups
        $compliantManagementGroups = 0
        $totalManagementGroups = $managementGroups.Count

        # Iterate through each management group to check its RBAC authorization setting
        foreach ($mg in $managementGroups) {
            $mgDetails = Get-AzManagementGroup -GroupName $mg.Name

            # Check if RBAC authorization is enabled
            if ($mgDetails.Properties.RequireAuthorization) {
                $compliantManagementGroups++
            }
        }

        if ($totalManagementGroups -gt 0) {
            $estimatedPercentageApplied = ($compliantManagementGroups / $totalManagementGroups) * 100

            if ($estimatedPercentageApplied -eq 100) {
                $status = [Status]::Implemented
            } elseif ($estimatedPercentageApplied -ge 50) {
                $status = [Status]::PartialImplemented
            } else {
                $status = [Status]::NotImplemented
            }

            # Calculate the score
            $score = ($weight * $estimatedPercentageApplied) / 100
        } else {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 0
            $score = 0
        }
    }
    catch {
        Log-Error -QuestionID "C02.06" -QuestionText "Enforce that only privileged users can operate management groups in the tenant by enabling Azure RBAC authorization" -FunctionName "Assess-ManagementGroupRBACAuthorization" -ErrorMessage $_.Exception.Message
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

# C02.08 - Enforce a process to make resource owners aware of their roles and responsibilities, access review, budget review, policy compliance and remediate when necessary.
function Assess-ResourceOwnerAwareness {
    Write-Host "Checking if a process exists to make resource owners aware of their roles and responsibilities, access review, budget review, policy compliance and remediate when necessary..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust the weight as necessary
    $score = 0

    try {
        # Retrieve all subscriptions
        $subscriptions = Get-AzSubscription -TenantId $TenantId

        # Initialize a counter for compliant subscriptions
        $compliantSubscriptions = 0
        $totalSubscriptions = $subscriptions.Count

        # Iterate through each subscription to check for compliance
        foreach ($subscription in $subscriptions) {
            Write-Host "Processing subscription: $($subscription.Name)"
            Set-AzContext -SubscriptionId $subscription.Id

            # Placeholder for actual checks
            # Check if the subscription has processes for roles and responsibilities, access review, budget review, policy compliance, and remediation
            $hasProcess = $true  # Replace with actual logic to determine if the process exists

            if ($hasProcess) {
                $compliantSubscriptions++
            }
        }

        if ($totalSubscriptions -gt 0) {
            $estimatedPercentageApplied = ($compliantSubscriptions / $totalSubscriptions) * 100

            if ($estimatedPercentageApplied -eq 100) {
                $status = [Status]::Implemented
            }
            elseif ($estimatedPercentageApplied -ge 50) {
                $status = [Status]::PartialImplemented
            }
            else {
                $status = [Status]::NotImplemented
            }

            # Calculate the score
            $score = ($weight * $estimatedPercentageApplied) / 100
        }
        else {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 0
            $score = 0
        }
    }
    catch {
        Log-Error -QuestionID "C02.08" -QuestionText "Enforce a process to make resource owners aware of their roles and responsibilities, access review, budget review, policy compliance and remediate when necessary" -FunctionName "Assess-ResourceOwnerAwareness" -ErrorMessage $_.Exception.Message
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