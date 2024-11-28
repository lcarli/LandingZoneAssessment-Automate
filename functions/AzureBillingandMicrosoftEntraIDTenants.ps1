# AzureBillingandMicrosoftEntraIDTenants.ps1

<#
.SYNOPSIS
    Functions related to AzureBillingandMicrosoftEntraIDTenants assessment.

.DESCRIPTION
    This script contains functions to evaluate the AzureBillingandMicrosoftEntraIDTenants area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-AzureBillingandMicrosoftEntraIDTenantsAssessment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ContractType,
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )

    Write-Host "Evaluating the AzureBillingandMicrosoftEntraIDTenants design area..."

    $results = @()

    if ($ContractType -eq "MicrosoftEntraIDTenants") {
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A01.01") }) | Test-QuestionA0101
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A01.02") }) | Test-QuestionA0102
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A01.03") }) | Test-QuestionA0103
    }
    elseif ($ContractType -eq "CloudSolutionProvider") {
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A02.01") }) | Test-QuestionA0201
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A02.02") }) | Test-QuestionA0202
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A02.03") }) | Test-QuestionA0203
    }
    elseif ($ContractType -eq "EnterpriseAgreement") {
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A03.01") }) | Test-QuestionA0301
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A03.02") }) | Test-QuestionA0302
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A03.04") }) | Test-QuestionA0304
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A03.05") }) | Test-QuestionA0305
    }
    else { 
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A04.01") }) | Test-QuestionA0401
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A04.02") }) | Test-QuestionA0402
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A04.03") }) | Test-QuestionA0403
        $results += ($Checklist.items | Where-Object { ($_.id -eq "A04.04") }) | Test-QuestionA0404
    }

    return $results
}


function Test-QuestionA0101 {
    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0
    $rawData = $null

    try {
        # Check if only one Entra tenant is being used for managing Azure resources
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/multi-tenant/considerations-recommendations

        # Get all Azure subscriptions
        $subscriptions = Get-AzSubscription

        # Extract tenant IDs from the subscriptions
        $tenantIds = $subscriptions.TenantId

        # Get unique tenant IDs
        $uniqueTenantIds = $tenantIds | Select-Object -Unique
        $numberOfTenants = $uniqueTenantIds.Count

        if ($numberOfTenants -gt 1) {
            $status = [Status]::ManualVerificationRequired
        }
        else {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $score = ($weight * $estimatedPercentageApplied) / 100
        }

        $rawData = @{
            Subscriptions = $subscriptions
            UniqueTenantIds = $uniqueTenantIds
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
    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $_ -rawData $rawData
}

function Test-QuestionA0102 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0
    $rawData = $null

    try {
        # Use Multi-Tenant Automation approach to managing your Microsoft Entra ID Tenants
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/multi-tenant/lighthouse

        $subscriptions = Get-AzSubscription

        # Extract tenant IDs from the subscriptions
        $tenantIds = $subscriptions.TenantId

        # Get unique tenant IDs
        $uniqueTenantIds = $tenantIds | Select-Object -Unique
        $numberOfTenants = $uniqueTenantIds.Count

        if ($numberOfTenants -gt 1) {
            $status = [Status]::ManualVerificationRequired
        }
        else {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $score = ($weight * $estimatedPercentageApplied) / 100
        }

        $rawData = @{
            Subscriptions = $subscriptions
            UniqueTenantIds = $uniqueTenantIds
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

function Test-QuestionA0103 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Check if Azure Lighthouse is used for multi-tenant management with the same IDs
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/multi-tenant/lighthouse

        # Get managed services definitions for Azure Lighthouse
        $lighthouseDefinitions = Get-AzManagedServicesDefinition

        # Get managed services assignments for Azure Lighthouse
        $lighthouseAssignments = Get-AzManagedServicesAssignment

        if ($lighthouseDefinitions.Count -eq 0 -or $lighthouseAssignments.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }
        else {
            # Initialize counters
            $totalAssignments = $lighthouseAssignments.Count
            $sameIdAssignments = 0

            # Get the current tenant ID
            $currentTenantId = (Get-AzContext).Tenant.Id

            foreach ($assignment in $lighthouseAssignments) {
                # Check if the managing tenant ID matches the current tenant ID
                if ($assignment.PrincipalId -eq $currentTenantId) {
                    $sameIdAssignments++
                }
            }

            if ($sameIdAssignments -eq $totalAssignments) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($sameIdAssignments -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($sameIdAssignments / $totalAssignments) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            LighthouseDefinitions = $lighthouseDefinitions
            LighthouseAssignments = $lighthouseAssignments
            SameIdAssignments = $sameIdAssignments
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

function Test-QuestionA0201 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Verify if a partner has access to administer the tenant and ensure Azure Lighthouse is used
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

        # Import the Microsoft Graph module
        if (-not (Get-Module -ListAvailable -Name 'Microsoft.Graph.Identity.DirectoryManagement')) {
            Install-Module -Name 'Microsoft.Graph' -Scope CurrentUser -Force
        }
        Import-Module Microsoft.Graph.Identity.DirectoryManagement

        # Get the list of service principals (partners) with directory roles
        $servicePrincipals = Get-MgServicePrincipal -Filter "servicePrincipalType eq 'Partner'"

        if ($servicePrincipals.Count -eq 0) {
            # No partners found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            # Check if Azure Lighthouse is used for partner access
            $lighthouseAssignments = Get-AzManagedServicesAssignment

            if ($lighthouseAssignments.Count -eq 0) {
                # Azure Lighthouse is not used
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                # Azure Lighthouse is used
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            ServicePrincipals = $servicePrincipals
            LighthouseAssignments = $lighthouseAssignments
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

function Test-QuestionA0202 {
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
        # Verify if you have a CSP partner
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-cloud-solution-provider#design-recommendations

        # Get all Azure subscriptions
        $subscriptions = Get-AzSubscription

        # Initialize flag to indicate presence of CSP subscriptions
        $hasCspSubscription = $false

        foreach ($subscription in $subscriptions) {
            # Check the SubscriptionPolicies for the SubscriptionType
            $subscriptionContext = Get-AzSubscription -SubscriptionId $subscription.Id
            $subscriptionPolicies = $subscriptionContext.SubscriptionPolicies

            if ($subscriptionPolicies -and $subscriptionPolicies.SubscriptionType -eq 'CSP') {
                $hasCspSubscription = $true
                break
            }
        }

        if (-not $hasCspSubscription) {
            # No CSP subscriptions found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            # CSP subscriptions are present
            # Since we cannot programmatically verify documentation of support request and escalation process,
            # we will assume that this needs to be manually verified.

            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            Subscriptions = $subscriptions
            HasCspSubscription = $hasCspSubscription
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

function Test-QuestionA0203 {
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
        # Setup Cost Reporting and Views with Azure Cost Management
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

        # Initialize flags
        $hasExports = $false
        $hasBudgets = $false

        # Get all Azure subscriptions
        $subscriptions = Get-AzSubscription

        # Check for Cost Management Exports at the subscription level
        foreach ($subscription in $subscriptions) {
            $exports = Get-AzCostManagementExport -Scope "/subscriptions/$($subscription.Id)" -ErrorAction SilentlyContinue
            if ($exports) {
                $hasExports = $true
                break
            }
        }

        # Check for Budgets at the subscription level
        foreach ($subscription in $subscriptions) {
            $budgets = Get-AzConsumptionBudget -Scope "/subscriptions/$($subscription.Id)" -ErrorAction SilentlyContinue
            if ($budgets) {
                $hasBudgets = $true
                break
            }
        }

        if ($hasExports -or $hasBudgets) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        }
        else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            Subscriptions = $subscriptions
            HasExports = $hasExports
            HasBudgets = $hasBudgets
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

function Test-QuestionA0301 {
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
        # Configure Notification Contacts to a group mailbox
        # Reference: https://learn.microsoft.com/azure/cost-management-billing/manage/direct-ea-administration#manage-notification-contacts

        # Get the billing accounts
        $billingAccounts = Get-AzBillingAccount

        if ($billingAccounts.Count -eq 0) {
            # No billing accounts found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalAccounts = 0
            $configuredAccounts = 0

            foreach ($billingAccount in $billingAccounts) {
                $billingAccountName = $billingAccount.Name

                # Get billing profiles associated with this billing account
                $billingProfiles = Get-AzBillingProfile -BillingAccountName $billingAccountName

                foreach ($billingProfile in $billingProfiles) {
                    # Check for notification email addresses in the billing profile
                    $notificationEmails = $billingProfile.InvoiceEmails

                    if ($notificationEmails.Count -gt 0) {
                        # Check if any of the email addresses are group mailboxes (you can define a naming pattern)
                        $groupMailboxPatterns = @('group', 'team', 'dept')
                        $isGroupMailbox = $false

                        foreach ($email in $notificationEmails) {
                            foreach ($pattern in $groupMailboxPatterns) {
                                if ($email -like "*$pattern*") {
                                    $isGroupMailbox = $true
                                    break
                                }
                            }
                        }

                        if ($isGroupMailbox) {
                            $configuredAccounts++
                        }
                    }
                }
                $totalAccounts++
            }

            if ($totalAccounts -eq 0) {
                # No billing accounts found
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } elseif ($configuredAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($configuredAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($configuredAccounts / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            BillingAccounts = $billingAccounts
            ConfiguredAccounts = $configuredAccounts
            TotalAccounts = $totalAccounts
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

function Test-QuestionA0302 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0
    $rawData = $null

    try {
        # Use departments and accounts to map your organization's structure to your enrollment hierarchy which can help with separating billing
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-enterprise-agreement#design-considerations

        # Get the billing accounts
        $billingAccounts = Get-AzBillingAccount

        if ($billingAccounts.Count -eq 0) {
            # No billing accounts found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalAccounts = 0
            $structuredAccounts = 0

            foreach ($billingAccount in $billingAccounts) {
                $billingAccountName = $billingAccount.Name

                # Get billing profiles associated with this billing account
                $billingProfiles = Get-AzBillingProfile -BillingAccountName $billingAccountName

                foreach ($billingProfile in $billingProfiles) {
                    # Check for departments and accounts in the billing profile
                    $departments = $billingProfile.Departments
                    $accounts = $billingProfile.Accounts

                    if ($departments.Count -gt 0 -and $accounts.Count -gt 0) {
                        $structuredAccounts++
                    }
                }
                $totalAccounts++
            }

            if ($totalAccounts -eq 0) {
                # No billing accounts found
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } elseif ($structuredAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($structuredAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($structuredAccounts / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            BillingAccounts = $billingAccounts
            StructuredAccounts = $structuredAccounts
            TotalAccounts = $totalAccounts
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

function Test-QuestionA0304 {
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
        # Enable both DA View Charges and AO View Charges on your EA Enrollments to allow users with the correct perms review Cost and Billing Data
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-enterprise-agreement#design-recommendations

        # Get the billing accounts (EA Enrollment) and relevant scopes
        $billingAccounts = Get-AzBillingAccount

        if ($billingAccounts.Count -eq 0) {
            # No billing accounts found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalAccounts = 0
            $configuredAccounts = 0

            foreach ($billingAccount in $billingAccounts) {
                $billingAccountName = $billingAccount.Name

                # For EA billing accounts, AccountType is "EnterpriseAgreement"
                if ($billingAccount.AccountType -eq 'EnterpriseAgreement') {
                    $totalAccounts++
                    $billingScope = "/providers/Microsoft.Billing/billingAccounts/$billingAccountName"

                    # Get role assignments for the billing account
                    $roleAssignments = Get-AzRoleAssignment -Scope $billingScope

                    # Initialize flags to check if both DA and AO have the View Charges role
                    $daViewChargesEnabled = $false
                    $aoViewChargesEnabled = $false

                    foreach ($role in $roleAssignments) {
                        if ($role.RoleDefinitionName -eq "Billing Reader") {
                            if ($role.PrincipalType -eq "DepartmentAdministrator") {
                                $daViewChargesEnabled = $true
                            }
                            if ($role.PrincipalType -eq "AccountOwner") {
                                $aoViewChargesEnabled = $true
                            }
                        }
                    }

                    # Check if both DA and AO have View Charges permissions
                    if ($daViewChargesEnabled -and $aoViewChargesEnabled) {
                        $configuredAccounts++
                    }
                }
            }

            if ($totalAccounts -eq 0) {
                # No EA billing accounts found
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } elseif ($configuredAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($configuredAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($configuredAccounts / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            BillingAccounts = $billingAccounts
            ConfiguredAccounts = $configuredAccounts
            TotalAccounts = $totalAccounts
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

function Test-QuestionA0305 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0
    $rawData = $null

    try {
        # Ensure use of Enterprise Dev/Test subscriptions for non-production workloads to reduce costs
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-enterprise-agreement#design-recommendations

        # Get all Azure subscriptions
        $subscriptions = Get-AzSubscription

        # Initialize counters
        $totalSubscriptions = $subscriptions.Count
        $devTestSubscriptions = 0

        # List of Dev/Test quota IDs for Enterprise Agreement
        $devTestOfferIds = @(
            "MS-AZR-0148P",  # Enterprise Dev/Test
            "MS-AZR-0149P"   # Enterprise Dev/Test Pay-As-You-Go
        )

        foreach ($subscription in $subscriptions) {
            # Get subscription details via REST API to get the OfferType
            $subscriptionId = $subscription.Id
            $accessToken = (Get-AzAccessToken).Token
            $uri = "https://management.azure.com/subscriptions/$subscriptionId?api-version=2020-01-01"
            $headers = @{
                Authorization = "Bearer $accessToken"
            }
            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

            if ($devTestOfferIds -contains $response.properties.subscriptionPolicies.quotaId) {
                $devTestSubscriptions++
            }
        }

        if ($devTestSubscriptions -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }
        elseif ($devTestSubscriptions -eq $totalSubscriptions) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        }
        else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($devTestSubscriptions / $totalSubscriptions) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            Subscriptions = $subscriptions
            DevTestSubscriptions = $devTestSubscriptions
            TotalSubscriptions = $totalSubscriptions
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

function Test-QuestionA0401 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0
    $rawData = $null

    try {
        # Configure Agreement billing account notification contact email
        # Reference: https://learn.microsoft.com/azure/cost-management-billing/manage/mca-setup-account

        # Get the billing accounts
        $billingAccounts = Get-AzBillingAccount

        if ($billingAccounts.Count -eq 0) {
            # No billing accounts found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalAccounts = 0
            $configuredAccounts = 0

            foreach ($billingAccount in $billingAccounts) {
                $billingAccountName = $billingAccount.Name

                # Get billing profiles associated with this billing account
                $billingProfiles = Get-AzBillingProfile -BillingAccountName $billingAccountName

                foreach ($billingProfile in $billingProfiles) {
                    # Check for notification email addresses in the billing profile
                    $notificationEmails = $billingProfile.InvoiceEmails

                    if ($notificationEmails.Count -gt 0) {
                        $configuredAccounts++
                    }
                }
                $totalAccounts++
            }

            if ($totalAccounts -eq 0) {
                # No billing accounts found
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } elseif ($configuredAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($configuredAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($configuredAccounts / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            BillingAccounts = $billingAccounts
            ConfiguredAccounts = $configuredAccounts
            TotalAccounts = $totalAccounts
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

function Test-QuestionA0402 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0
    $rawData = $null

    try {
        # Use Billing Profiles and Invoice sections to structure your agreements billing for effective cost management
        # Reference: https://learn.microsoft.com/azure/cost-management-billing/manage/mca-section-invoice

        # Get the billing accounts
        $billingAccounts = Get-AzBillingAccount

        if ($billingAccounts.Count -eq 0) {
            # No billing accounts found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalAccounts = 0
            $structuredAccounts = 0

            foreach ($billingAccount in $billingAccounts) {
                $billingAccountName = $billingAccount.Name

                # For MCA, billing account has 'AccountType' as 'MicrosoftCustomerAgreement'
                if ($billingAccount.AccountType -eq 'MicrosoftCustomerAgreement') {
                    $totalAccounts++

                    # Get billing profiles associated with this billing account
                    $billingProfiles = Get-AzBillingProfile -BillingAccountName $billingAccountName

                    foreach ($billingProfile in $billingProfiles) {
                        # Check for invoice sections in the billing profile
                        $invoiceSections = Get-AzBillingInvoiceSection -BillingAccountName $billingAccountName -BillingProfileName $billingProfile.Name

                        if ($invoiceSections.Count -gt 0) {
                            $structuredAccounts++
                        }
                    }
                }
            }

            if ($totalAccounts -eq 0) {
                # No MCA billing accounts found
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } elseif ($structuredAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($structuredAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($structuredAccounts / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            BillingAccounts = $billingAccounts
            StructuredAccounts = $structuredAccounts
            TotalAccounts = $totalAccounts
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

function Test-QuestionA0403 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0
    $rawData = $null

    try {
        # Make use of Microsoft Azure plan for dev/test offer to reduce costs for non-production workloads
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

        # Get all Azure subscriptions
        $subscriptions = Get-AzSubscription

        # Initialize counters
        $totalSubscriptions = $subscriptions.Count
        $devTestSubscriptions = 0

        # List of Dev/Test quota IDs for Microsoft Customer Agreement
        $devTestQuotaIds = @(
            "MS-AZR-0148P",  # Enterprise Dev/Test
            "MS-AZR-0149P"   # Enterprise Dev/Test Pay-As-You-Go
        )

        foreach ($subscription in $subscriptions) {
            # Get subscription details via REST API to get the OfferType
            $subscriptionId = $subscription.Id
            $accessToken = (Get-AzAccessToken).Token
            $uri = "https://management.azure.com/subscriptions/$subscriptionId?api-version=2020-01-01"
            $headers = @{
                Authorization = "Bearer $accessToken"
            }
            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

            if ($devTestQuotaIds -contains $response.properties.subscriptionPolicies.quotaId) {
                $devTestSubscriptions++
            }
        }

        if ($devTestSubscriptions -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }
        elseif ($devTestSubscriptions -eq $totalSubscriptions) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        }
        else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($devTestSubscriptions / $totalSubscriptions) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            Subscriptions = $subscriptions
            DevTestSubscriptions = $devTestSubscriptions
            TotalSubscriptions = $totalSubscriptions
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

function Test-QuestionA0404 {
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
        # Define and document a process to periodically audit the agreement billing RBAC role assignments to review who has access to your MCA billing account
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

        # Since defining and documenting a process is a manual task that cannot be programmatically verified,
        # we will set the status to ManualVerificationRequired.

        $status = [Status]::ManualVerificationRequired
        $estimatedPercentageApplied = 0
        $score = 0
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