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


#region begin Management Group Hierarchy


# C1.1 - Use Management groups for both policies and management RBAC
function Test-ManagementGroupsForPoliciesAndRBAC {
    Write-Host "Checking if Management Groups are used for both policies and management RBAC..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve management groups
        $managementGroups = Get-AzManagementGroup

        # Check if policies and RBAC are applied at the management group level
        $policiesApplied = $false
        $rbacApplied = $false

        foreach ($mg in $managementGroups) {
            $policies = Get-AzPolicyAssignment -Scope "/providers/Microsoft.Management/managementGroups/$($mg.Name)
            "
            $rbac = Get-AzRoleAssignment -Scope "/providers/Microsoft.Management/managementGroups/$($mg.Name)"

            if ($policies.Count -gt 0) {
                $policiesApplied = $true
            }
            if ($rbac.Count -gt 0) {
                $rbacApplied = $true
            }
        }

        if ($policiesApplied -and $rbacApplied) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($policiesApplied -or $rbacApplied) {
            $status = [Status]::PartialImplemented
            $estimatedPercentageApplied = 50
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "C1.1" -QuestionText "Use Management groups for both policies and management RBAC" -FunctionName "Test-ManagementGroupsForPoliciesAndRBAC" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                    = $status
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                    = $weight
        Score                     = $score
    }
}

#endregion


#region begin Subscription Organization and Governance

# C2.1 - Create separate platform subscriptions for Management (Monitoring), Connectivity and Identity when these are required
function Test-CreateSeparatePlatformSubscriptions {
    Write-Host "Checking if separate platform subscriptions are created for Management (Monitoring), Connectivity, and Identity when required..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 2  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve subscriptions
        $subscriptions = Get-AzSubscription

        # Check if there are separate subscriptions for Management, Connectivity, and Identity
        $managementSubscription = $subscriptions | Where-Object { $_.DisplayName -match "Management" -or $_.DisplayName -match "Monitoring" }
        $connectivitySubscription = $subscriptions | Where-Object { $_.DisplayName -match "Connectivity" }
        $identitySubscription = $subscriptions | Where-Object { $_.DisplayName -match "Identity" }

        if ($managementSubscription.Count -gt 0 -and $connectivitySubscription.Count -gt 0 -and $identitySubscription.Count -gt 0) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($managementSubscription.Count -gt 0 -or $connectivitySubscription.Count -gt 0 -or $identitySubscription.Count -gt 0) {
            $status = [Status]::PartialImplemented
            $estimatedPercentageApplied = 50
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "C2.1" -QuestionText "Create separate platform subscriptions for Management (Monitoring), Connectivity and Identity when these are required" -FunctionName "Test-CreateSeparatePlatformSubscriptions" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                    = $status
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                    = $weight
        Score                     = $score
    }
}


# C2.2 - Use subscriptions as a democratized unit of management and scale
function Test-UseSubscriptionsAsUnitOfManagement {
    Write-Host "Checking if subscriptions are used as a democratized unit of management and scale..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve subscriptions
        $subscriptions = Get-AzSubscription

        # Check if there are multiple subscriptions to facilitate management and scaling
        if ($subscriptions.Count -gt 3) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "C2.2" -QuestionText "Use subscriptions as a democratized unit of management and scale" -FunctionName "Test-UseSubscriptionsAsUnitOfManagement" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                    = $status
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                    = $weight
        Score                     = $score
    }
}


# C2.3 - Group subscriptions under Management groups to align with IT operating model
function Test-GroupSubscriptionsUnderManagementGroups {
    Write-Host "Checking if subscriptions are grouped under Management groups to align with IT operating model..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 2  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve subscriptions and management groups
        $subscriptions = Get-AzSubscription
        $managementGroups = Get-AzManagementGroup

        # Check if subscriptions are grouped under management groups
        $subscriptionsInManagementGroups = 0
        foreach ($sub in $subscriptions) {
            foreach ($mg in $managementGroups) {
                $mgSubscriptions = Get-AzManagementGroupSubscription -GroupName $mg.Name
                if ($mgSubscriptions | Where-Object { $_.SubscriptionId -eq $sub.Id }) {
                    $subscriptionsInManagementGroups++
                }
            }
        }

        if ($subscriptionsInManagementGroups -eq $subscriptions.Count) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($subscriptionsInManagementGroups -gt 0) {
            $status = [Status]::PartialImplemented
            $estimatedPercentageApplied = ($subscriptionsInManagementGroups / $subscriptions.Count) * 100
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "C2.3" -QuestionText "Group subscriptions under Management groups to align with IT operating model" -FunctionName "Test-GroupSubscriptionsUnderManagementGroups" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                    = $status
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                    = $weight
        Score                     = $score
    }
}


# C2.4 - Have new subscription as a service. Automate subscription creation for app dev teams
function Test-AutomateSubscriptionCreation {
    Write-Host "Checking if subscription creation is automated for app dev teams..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1  # Weight from the Excel sheet
    $score = 0

    try {
        # Placeholder logic to check for automated subscription creation
        $automationAccount = Get-AzAutomationAccount
        $runbook = Get-AzAutomationRunbook -ResourceGroupName $automationAccount.ResourceGroupName -AutomationAccountName $automationAccount.AutomationAccountName -Name "New-SubscriptionCreation"

        if ($runbook.Count -gt 0) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "C2.4" -QuestionText "Have new subscription as a service. Automate subscription creation for app dev teams" -FunctionName "Test-AutomateSubscriptionCreation" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                    = $status
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                    = $weight
        Score                     = $score
    }
}

#endregion



#region begin Configure Subscription Quota and Capacity

# C3.1 - Ensure that sufficient capacity and SKUs are available and the attained capacity can be understood and monitored
function Test-EnsureCapacityAndSKUs {
    Write-Host "Checking if sufficient capacity and SKUs are available and the attained capacity can be understood and monitored..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 4  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve all subscriptions
        $subscriptions = Get-AzSubscription -TenantId $tenantId

        $resources = @()
        foreach ($subscription in $subscriptions) {
            Set-AzContext -SubscriptionId $subscription.Id
            $resources += Get-AzResource -ResourceType "Microsoft.Compute/virtualMachines"
        }

        if ($resources.Count -eq 0) {
            Write-Host "No virtual machines found in the subscriptions."
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
            # Take the first virtual machine resource
            $resource = $resources[0]

            # Retrieve usage details for capacity and SKUs
            $capacity = @()
            $metrics = Get-AzMetric -ResourceId $resource.Id -MetricName "Percentage CPU"
            $capacity += $metrics.Data

            # Check if capacity and SKUs are sufficient and monitored
            if ($capacity.Count -gt 0) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "C2.6" -QuestionText "Ensure that sufficient capacity and SKUs are available and the attained capacity can be understood and monitored" -FunctionName "Test-EnsureCapacityAndSKUs" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                    = $status
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                    = $weight
        Score                     = $score
    }
}



#endregion