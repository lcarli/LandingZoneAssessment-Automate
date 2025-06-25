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

# Helper function to get budgets via REST API since Get-AzConsumptionBudget is not available
function Get-BudgetsViaRestApi {
    param(
        [string]$SubscriptionId,
        [string]$FunctionName = "Unknown"
    )
    
    try {
        # Get access token
        $accessTokenResult = Get-AzAccessToken
        if ($accessTokenResult.Token -is [SecureString]) {
            $plainAccessToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($accessTokenResult.Token)
            )
        } else {
            $plainAccessToken = $accessTokenResult.Token
        }
        
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Consumption/budgets?api-version=2021-10-01"
        $headers = @{
            Authorization = "Bearer $plainAccessToken"
            'Content-Type' = 'application/json'
        }
        
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction SilentlyContinue
        
        return $response.value
    }
    catch {
        Write-Verbose "Failed to get budgets via REST API for subscription $SubscriptionId : $($_.Exception.Message)"
        return $null
    }
}

function Invoke-AzureBillingandMicrosoftEntraIDTenantsAssessment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ContractType,
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )
    
    Write-AssessmentHeader "Evaluating the AzureBillingandMicrosoftEntraIDTenants design area..."
    
    # Note: Az.Billing module is imported in Initialize.ps1 for better performance
    # Verify billing module is available before proceeding
    if (-not (Test-CmdletAvailable -CmdletName 'Get-AzBillingAccount')) {
        Write-Warning "Az.Billing module not properly loaded. Some billing assessments may not work correctly."
    }

    Measure-ExecutionTime -ScriptBlock {
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
            $results += ($Checklist.items | Where-Object { ($_.id -eq "A03.03") }) | Test-QuestionA0303
            $results += ($Checklist.items | Where-Object { ($_.id -eq "A03.04") }) | Test-QuestionA0304
            $results += ($Checklist.items | Where-Object { ($_.id -eq "A03.05") }) | Test-QuestionA0305
        }
        else { 
            $results += ($Checklist.items | Where-Object { ($_.id -eq "A04.01") }) | Test-QuestionA0401
            $results += ($Checklist.items | Where-Object { ($_.id -eq "A04.02") }) | Test-QuestionA0402
            $results += ($Checklist.items | Where-Object { ($_.id -eq "A04.03") }) | Test-QuestionA0403
            $results += ($Checklist.items | Where-Object { ($_.id -eq "A04.04") }) | Test-QuestionA0404
        }

        $script:FunctionResult = $results
    } -FunctionName "Invoke-AzureBillingandMicrosoftEntraIDTenantsAssessment"

    return $script:FunctionResult
}


function Test-QuestionA0101 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0
    $rawData = $null

    try {
        # Check if only one Entra tenant is being used for managing Azure resources
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/multi-tenant/considerations-recommendations

        # Get all Azure subscriptions using cached data
        $subscriptions = $global:AzData.Subscriptions

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
            Subscriptions   = $subscriptions
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0
    $rawData = $null

    try {
        # Use Multi-Tenant Automation approach to managing your Microsoft Entra ID Tenants
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/multi-tenant/lighthouse

        $subscriptions = $global:AzData.Subscriptions

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
            Subscriptions   = $subscriptions
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
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
            SameIdAssignments     = $sameIdAssignments
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Verify if a partner has access to administer the tenant and ensure Azure Lighthouse is used
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

        # Import the Microsoft Graph module        # Check if Microsoft Graph is connected
        if ($global:GraphConnected -eq $false) {
            Write-Warning "Microsoft Graph is not connected. Cannot assess partner directory roles."
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "Microsoft Graph connection not available for partner assessment"
            return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
        }        # Try to get the list of service principals (partners) with directory roles from cached data
        try {
            if ($global:GraphConnected -and $global:GraphData -and $global:GraphData.ServicePrincipals) {
                $servicePrincipals = $global:GraphData.ServicePrincipals | Where-Object { $_.servicePrincipalType -eq 'Partner' }
            } else {
                $servicePrincipals = $null
            }
        }
        catch {
            Write-Warning "Could not retrieve partner service principals: $($_.Exception.Message)"
            $servicePrincipals = $null
        }

        if (-not $servicePrincipals -or $servicePrincipals.Count -eq 0) {
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
            ServicePrincipals     = $servicePrincipals
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0
    $rawData = $null

    try {
        # Verify if you have a CSP partner
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-cloud-solution-provider#design-recommendations

        # Get all Azure subscriptions
        $subscriptions = $global:AzData.Subscriptions

        # Initialize flag to indicate presence of CSP subscriptions
        $hasCspSubscription = $false

        foreach ($subscription in $subscriptions) {
            # Check the SubscriptionPolicies for the SubscriptionType
            $subscriptionContext = $subscriptions | Where-Object { ($_.id -eq $subscription.Id) 
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
                Subscriptions      = $subscriptions
                HasCspSubscription = $hasCspSubscription
            }
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
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
        $subscriptions = $global:AzData.Subscriptions

        # Check for Cost Management Exports at the subscription level
        foreach ($subscription in $subscriptions) {
            $exports = Get-AzCostManagementExport -Scope "/subscriptions/$($subscription.Id)" -ErrorAction SilentlyContinue
            if ($exports) {
                $hasExports = $true
                break
            }        }        # Check for Budgets at the subscription level
        foreach ($subscription in $subscriptions) {
            $budgets = $null
            try {
                # Use REST API to get budgets since Get-AzConsumptionBudget is not available
                $budgets = Get-BudgetsViaRestApi -SubscriptionId $subscription.Id -FunctionName "Test-QuestionA0203"
            }
            catch {
                Write-Verbose "Could not retrieve budgets for subscription $($subscription.Id): $($_.Exception.Message)"
            }
            
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
            HasExports    = $hasExports
            HasBudgets    = $hasBudgets
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0
    $rawData = $null   

    try {
        # Set up a Notification Contact email address to ensure notifications are sent to an appropriate group mailbox
        # Reference: https://learn.microsoft.com/azure/cost-management-billing/manage/direct-ea-administration#manage-notification-contacts

        # Get the billing accounts
        $billingAccounts = Get-AzBillingAccount

        if ($billingAccounts.Count -eq 0) {
            # No billing accounts found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
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
            }
            elseif ($configuredAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($configuredAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($configuredAccounts / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            BillingAccounts    = $billingAccounts
            ConfiguredAccounts = $configuredAccounts
            TotalAccounts      = $totalAccounts
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
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
        }
        else {
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
            }
            elseif ($structuredAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($structuredAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($structuredAccounts / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            BillingAccounts    = $billingAccounts
            StructuredAccounts = $structuredAccounts
            TotalAccounts      = $totalAccounts
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

function Test-QuestionA0303 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotImplemented
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0
    $rawData = $null
    try {
        # Assign a budget for each department and account, and establish an alert associated with the budget
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-enterprise-agreement#design-considerations

        $departmentBudgets = @()
        $accountBudgets = @()
        $budgetsWithAlerts = 0
        $totalBudgets = 0

        # Get Enterprise Agreement billing accounts if available
        $billingAccounts = Get-AzBillingAccount

        if ($billingAccounts) {
            foreach ($billingAccount in $billingAccounts) {
                # Check for department-level budgets
                try {
                    $departments = Get-AzBillingProfile -BillingAccountName $billingAccount.Name -ErrorAction SilentlyContinue    
                    foreach ($department in $departments) {
                        $departmentScope = "/providers/Microsoft.Billing/billingAccounts/$($billingAccount.Name)/billingProfiles/$($department.Name)"
                        $budgets = $null                          
                        try {
                            # Department-level budgets are complex and require different API endpoints
                            # Skipping for now to focus on subscription-level budgets
                            # Department-level budget checks require complex EA enrollment API calls
                            # if (Get-Command Get-AzConsumptionBudget -ErrorAction SilentlyContinue) {
                            #     $budgets = Get-AzConsumptionBudget -Scope $departmentScope -ErrorAction SilentlyContinue
                            # } else {
                            #     Write-Verbose "Get-AzConsumptionBudget cmdlet not available. Skipping department budget check for scope $departmentScope"
                            # }
                        }
                        catch {
                            Write-Verbose "Could not retrieve department budgets for scope $departmentScope"
                        }
                        
                        if ($budgets) {
                            $departmentBudgets += $budgets
                            $totalBudgets += $budgets.Count
                            
                            # Check for alerts on each budget
                            foreach ($budget in $budgets) {
                                if ($budget.Notification -and $budget.Notification.Count -gt 0) {
                                    $budgetsWithAlerts++
                                }
                            }
                        }
                    }
                } catch {
                    Write-Verbose "Could not retrieve department budgets: $($_.Exception.Message)"
                }

                # Check for account-level budgets within billing profiles
                try {
                    $billingProfiles = Get-AzBillingProfile -BillingAccountName $billingAccount.Name -ErrorAction SilentlyContinue
                    foreach ($profile in $billingProfiles) {
                        $invoiceSections = Get-AzInvoiceSection -BillingAccountName $billingAccount.Name -BillingProfileName $profile.Name -ErrorAction SilentlyContinue                        
                        foreach ($section in $invoiceSections) {
                            $accountScope = "/providers/Microsoft.Billing/billingAccounts/$($billingAccount.Name)/billingProfiles/$($profile.Name)/invoiceSections/$($section.Name)"
                            $budgets = $null                              
                            try {
                                # Account-level budgets are complex and require different API endpoints
                                # Skipping for now to focus on subscription-level budgets
                                # Account-level budget checks require complex EA enrollment API calls
                                # if (Get-Command Get-AzConsumptionBudget -ErrorAction SilentlyContinue) {
                                #     $budgets = Get-AzConsumptionBudget -Scope $accountScope -ErrorAction SilentlyContinue
                                # } else {
                                #     Write-Verbose "Get-AzConsumptionBudget cmdlet not available. Skipping account budget check for scope $accountScope"
                                # }
                            }
                            catch {
                                Write-Verbose "Could not retrieve account budgets for scope $accountScope"
                            }
                            
                            if ($budgets) {
                                $accountBudgets += $budgets
                                $totalBudgets += $budgets.Count
                                
                                # Check for alerts on each budget
                                foreach ($budget in $budgets) {
                                    if ($budget.Notification -and $budget.Notification.Count -gt 0) {
                                        $budgetsWithAlerts++
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    Write-Verbose "Could not retrieve account budgets: $($_.Exception.Message)"
                }
            }
        }

        # Also check subscription-level budgets as fallback for Enterprise Agreement scenarios
        $subscriptions = $global:AzData.Subscriptions
        $subscriptionBudgets = @()          
        foreach ($subscription in $subscriptions) {
            $budgets = $null
            try {
                # Use REST API to get budgets since Get-AzConsumptionBudget is not available
                $budgets = Get-BudgetsViaRestApi -SubscriptionId $subscription.Id -FunctionName "Test-QuestionA0303"
            }
            catch {
                Write-Verbose "Could not retrieve budgets for subscription $($subscription.Id): $($_.Exception.Message)"
            }
            
            if ($budgets) {
                $subscriptionBudgets += $budgets
                $totalBudgets += $budgets.Count
                
                # Check for alerts on each budget
                foreach ($budget in $budgets) {
                    if ($budget.Notification -and $budget.Notification.Count -gt 0) {
                        $budgetsWithAlerts++
                    }
                }
            }
        }

        # Determine status based on findings
        if ($totalBudgets -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } elseif ($budgetsWithAlerts -eq $totalBudgets) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($budgetsWithAlerts -gt 0) {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = [Math]::Round(($budgetsWithAlerts / $totalBudgets) * 100, 2)
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            DepartmentBudgets    = $departmentBudgets
            AccountBudgets       = $accountBudgets
            SubscriptionBudgets  = $subscriptionBudgets
            TotalBudgets         = $totalBudgets
            BudgetsWithAlerts    = $budgetsWithAlerts
            BudgetsWithoutAlerts = $totalBudgets - $budgetsWithAlerts
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0
    $rawData = $null    
    try {
        # Enable both DA View Charges and AO View Charges on your EA Enrollments to allow users with the correct permissions to review Cost Management Data
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-enterprise-agreement#design-recommendations

        # Get the billing accounts (EA Enrollment) and relevant scopes
        $billingAccounts = Get-AzBillingAccount

        if ($billingAccounts.Count -eq 0) {
            # No billing accounts found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
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
            }
            elseif ($configuredAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($configuredAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($configuredAccounts / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            BillingAccounts    = $billingAccounts
            ConfiguredAccounts = $configuredAccounts
            TotalAccounts      = $totalAccounts
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0
    $rawData = $null    
    
    try {
        # Use of Enterprise Dev/Test Subscriptions to reduce costs for non-production workloads
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-enterprise-agreement#design-recommendations

        # Get all Azure subscriptions
        $subscriptions = $global:AzData.Subscriptions

        # Initialize counters
        $totalSubscriptions = $subscriptions.Count
        $devTestSubscriptions = 0

        # List of Dev/Test quota IDs for Enterprise Agreement
        $devTestOfferIds = @(
            "MS-AZR-0148P", # Enterprise Dev/Test
            "MS-AZR-0149P"   # Enterprise Dev/Test Pay-As-You-Go
        )          
        foreach ($subscription in $subscriptions) {
            try {
                # Get subscription details via REST API to get the OfferType
                $subscriptionId = $subscription.Id
            
                # Get the access token - handling both old and new Az module versions
                $accessTokenResult = Get-AzAccessToken
                if ($accessTokenResult.Token -is [SecureString]) {
                    # New Az module version - Token is SecureString
                    $plainAccessToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($accessTokenResult.Token)
                    )
                } else {
                    # Old Az module version - Token is String
                    $plainAccessToken = $accessTokenResult.Token
                }
            
                $uri = "https://management.azure.com/subscriptions/$subscriptionId?api-version=2022-12-01"
                $headers = @{
                    Authorization = "Bearer $plainAccessToken"
                    'Content-Type' = 'application/json'
                }
            
                $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction SilentlyContinue                
            
                if ($response -and $response.properties -and $response.properties.subscriptionPolicies) {
                    $quotaId = $response.properties.subscriptionPolicies.quotaId
                    if ($devTestOfferIds -contains $quotaId) {
                        $devTestSubscriptions++
                    }
                }
            }
            catch {
                Write-Verbose "Failed to retrieve subscription details for $subscriptionId : $($_.Exception.Message)"
                # Continue with next subscription - don't fail the entire assessment
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
            Subscriptions        = $subscriptions
            DevTestSubscriptions = $devTestSubscriptions
            TotalSubscriptions   = $totalSubscriptions
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
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
        }
        else {
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
            }
            elseif ($configuredAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($configuredAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($configuredAccounts / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            BillingAccounts    = $billingAccounts
            ConfiguredAccounts = $configuredAccounts
            TotalAccounts      = $totalAccounts
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
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
        }
        else {
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
            }
            elseif ($structuredAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($structuredAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($structuredAccounts / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
        $rawData = @{
            BillingAccounts    = $billingAccounts
            StructuredAccounts = $structuredAccounts
            TotalAccounts      = $totalAccounts
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0
    $rawData = $null

    try {
        # Make use of Microsoft Azure plan for dev/test offer to reduce costs for non-production workloads
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

        # Get all Azure subscriptions
        $subscriptions = $global:AzData.Subscriptions

        # Initialize counters
        $totalSubscriptions = $subscriptions.Count
        $devTestSubscriptions = 0

        # List of Dev/Test quota IDs for Microsoft Customer Agreement
        $devTestQuotaIds = @(
            "MS-AZR-0148P", # Enterprise Dev/Test
            "MS-AZR-0149P"   # Enterprise Dev/Test Pay-As-You-Go
        )          
        foreach ($subscription in $subscriptions) {
            try {
                # Get subscription details via REST API to get the OfferType
                $subscriptionId = $subscription.Id
                
                # Get the access token - handling both old and new Az module versions
                $accessTokenResult = Get-AzAccessToken
                if ($accessTokenResult.Token -is [SecureString]) {
                    # New Az module version - Token is SecureString
                    $plainAccessToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($accessTokenResult.Token)
                    )
                } else {
                    # Old Az module version - Token is String
                    $plainAccessToken = $accessTokenResult.Token
                }
                
                $uri = "https://management.azure.com/subscriptions/$subscriptionId?api-version=2022-12-01"
                $headers = @{
                    Authorization = "Bearer $plainAccessToken"
                    'Content-Type' = 'application/json'
                }
                $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction SilentlyContinue

                if ($response -and $response.properties -and $response.properties.subscriptionPolicies) {
                    $quotaId = $response.properties.subscriptionPolicies.quotaId
                    if ($devTestQuotaIds -contains $quotaId) {
                        $devTestSubscriptions++
                    }
                }
            }
            catch {
                Write-Verbose "Could not retrieve subscription details for $subscriptionId`: $($_.Exception.Message)"
                # Continue with next subscription - don't fail the entire assessment
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
            Subscriptions        = $subscriptions
            DevTestSubscriptions = $devTestSubscriptions
            TotalSubscriptions   = $totalSubscriptions
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::NotApplicable
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
