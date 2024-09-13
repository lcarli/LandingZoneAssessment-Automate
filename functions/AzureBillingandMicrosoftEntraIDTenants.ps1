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
    Write-Host "Evaluating the AzureBillingandMicrosoftEntraIDTenants design area..."

    $results = @()
    # Load configuration from config.json
    $config = Get-Content -Path "$PSScriptRoot/../config.json" | ConvertFrom-Json

    if ($config.ContractType -eq "MicrosoftEntraIDTenants") {
        $results += Test-QuestionA0101
        $results += Test-QuestionA0102
        $results += Test-QuestionA0103
    }
    elseif ($config.ContractType -eq "CloudSolutionProvider") {
        $results += Test-QuestionA0201
        $results += Test-QuestionA0202
        $results += Test-QuestionA0203
    }
    elseif ($config.ContractType -eq "EnterpriseAgreement") {
        $results += Test-QuestionA0301
        $results += Test-QuestionA0302
        $results += Test-QuestionA0304
        $results += Test-QuestionA0305
    }
    #MicrosoftCustomerAgreement
    else { 
        $results += Test-QuestionA0401
        $results += Test-QuestionA0402
        $results += Test-QuestionA0403
        $results += Test-QuestionA0404
    }

    return $results
}


function Test-QuestionA0101 {
    Write-Host "Assessing question: Use one Entra tenant for managing your Azure resources, unless you have a clear regulatory or business requirement for multi-tenants."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0

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

        # Total number of subscriptions
        $totalSubscriptions = $subscriptions.Count

        if ($numberOfTenants -eq 1) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        }
        else {
            # Calculate the percentage of subscriptions in the most common tenant
            $tenantIdCounts = $tenantIds | Group-Object | Select-Object Name, Count
            $mostCommonTenant = $tenantIdCounts | Sort-Object -Property Count -Descending | Select-Object -First 1
            $percentageInMostCommonTenant = ($mostCommonTenant.Count / $totalSubscriptions) * 100
            $estimatedPercentageApplied = [Math]::Round($percentageInMostCommonTenant, 2)

            if ($estimatedPercentageApplied -eq 0) {
                $status = [Status]::NotImplemented
            }
            else {
                $status = [Status]::PartiallyImplemented
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Write-ErrorLog -QuestionID "A01.01" -QuestionText "Use one Entra tenant for managing your Azure resources, unless you have a clear regulatory or business requirement for multi-tenants." -FunctionName "Test-QuestionA0101" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}


function Test-QuestionA0102 {
    Write-Host "Assessing question: Use Multi-Tenant Automation approach to managing your Microsoft Entra ID Tenants."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0

    try {

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

        
    }
    catch {
        Write-ErrorLog -QuestionID "A01.02" -QuestionText "Use Multi-Tenant Automation approach to managing your Microsoft Entra ID Tenants." -FunctionName "Test-QuestionA0102" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}

function Test-QuestionA0103 {
    Write-Host "Assessing question: Use Azure Lighthouse for Multi-Tenant Management with the same IDs."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0

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
    }
    catch {
        Write-ErrorLog -QuestionID "A01.03" -QuestionText "Use Azure Lighthouse for Multi-Tenant Management with the same IDs." -FunctionName "Test-QuestionA0103" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}


function Test-QuestionA0201 {
    Write-Host "Assessing question: If you give a partner access to administer your tenant, use Azure Lighthouse."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0

    try {
        # Verify if a partner has access to administer the tenant and ensure Azure Lighthouse is used
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

        # Import the Microsoft Graph module
        if (-not (Get-Module -ListAvailable -Name 'Microsoft.Graph.Identity.DirectoryManagement')) {
            Install-Module -Name 'Microsoft.Graph' -Scope CurrentUser -Force
        }
        Import-Module Microsoft.Graph.Identity.DirectoryManagement

        # Connect to Microsoft Graph with necessary scopes
        $scopes = @('DelegatedAdminRelationship.Read.All', 'Directory.Read.All')
        Connect-MgGraph -Scopes $scopes

        # Get all delegated admin relationships (partners with admin access)
        $delegatedAdmins = Get-MgTenantRelationshipDelegatedAdminRelationship

        if ($delegatedAdmins.Count -eq 0) {
            # No partners have admin access to the tenant
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            # Partners have admin access; check if Azure Lighthouse is used
            # Import the Az.ManagedServices module
            if (-not (Get-Module -ListAvailable -Name 'Az.ManagedServices')) {
                Install-Module -Name 'Az.ManagedServices' -Scope CurrentUser -Force
            }
            Import-Module Az.ManagedServices

            # Get Azure Lighthouse assignments (resource delegations)
            $lighthouseAssignments = Get-AzManagedServicesAssignment

            if ($lighthouseAssignments.Count -gt 0) {
                # Azure Lighthouse is being used
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            else {
                # Azure Lighthouse is not being used
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Write-ErrorLog -QuestionID "A02.01" -QuestionText "If you give a partner access to administer your tenant, use Azure Lighthouse." -FunctionName "Test-QuestionA0201" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }
    finally {
        Disconnect-MgGraph
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}

function Test-QuestionA0202 {
    Write-Host "Assessing question: If you have a CSP partner, define and document your support request and escalation process."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0

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
    }
    catch {
        Write-ErrorLog -QuestionID "A02.02" -QuestionText "If you have a CSP partner, define and document your support request and escalation process." -FunctionName "Test-QuestionA0202" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}


function Test-QuestionA0203 {
    Write-Host "Assessing question: Setup Cost Reporting and Views with Azure Cost Management."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0

    try {
        # Set up cost reporting and views with Azure Cost Management
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

        # Initialize flags
        $hasExports = $false
        $hasBudgets = $false

        # Check for Cost Management Exports at the subscription level
        $subscriptions = Get-AzSubscription

        foreach ($subscription in $subscriptions) {
            $exports = Get-AzCostManagementExport -Scope "/subscriptions/$($subscription.Id)" -ErrorAction SilentlyContinue
            if ($exports) {
                $hasExports = $true
                break
            }
        }

        # Check for Budgets at the subscription level
        foreach ($subscription in $subscriptions) {
            $budgets = Get-AzConsumptionBudget -ErrorAction SilentlyContinue
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
    }
    catch {
        Write-ErrorLog -QuestionID "A02.03" -QuestionText "Setup Cost Reporting and Views with Azure Cost Management." -FunctionName "Test-QuestionA0203" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}


function Test-QuestionA0301 {
    Write-Host "Assessing question: Configure Notification Contacts to a group mailbox."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0

    try {
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
    }
    catch {
        Write-ErrorLog -QuestionID "A03.01" -QuestionText "Configure Notification Contacts to a group mailbox." -FunctionName "Test-QuestionA0301" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}


function Test-QuestionA0302 {
    Write-Host "Assessing question: Use departments and accounts to map your organization's structure to your enrollment hierarchy which can help with separating billing."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0

    try {
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
 
                     # Get billing profiles for the billing account
                     $billingProfiles = Get-AzBillingProfile -BillingAccountName $billingAccountName
 
                     if ($billingProfiles.Count -gt 0) {
                         $structuredProfiles = 0
                         $totalProfiles = $billingProfiles.Count
 
                         foreach ($billingProfile in $billingProfiles) {
                             # Get invoice sections under each billing profile
                             $invoiceSections = Get-AzInvoiceSection -BillingAccountName $billingAccountName -BillingProfileName $billingProfile.Name
 
                             if ($invoiceSections.Count -gt 0) {
                                 # We consider the billing profile to be mapped/structured if invoice sections exist
                                 $structuredProfiles++
                             }
                         }
 
                         if ($structuredProfiles -eq $totalProfiles) {
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
    }
    catch {
        Write-ErrorLog -QuestionID "A03.02" -QuestionText "Use departments and accounts to map your organization's structure to your enrollment hierarchy which can help with separating billing." -FunctionName "Test-QuestionA0302" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}

function Test-QuestionA0304 {
    Write-Host "Assessing question: Enable both DA View Charges and AO View Charges on your EA Enrollments to allow users with the correct perms review Cost and Billing Data."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0

    try {
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
    }
    catch {
        Write-ErrorLog -QuestionID "A03.04" -QuestionText "Enable both DA View Charges and AO View Charges on your EA Enrollments to allow users with the correct perms review Cost and Billing Data." -FunctionName "Test-QuestionA0304" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}

function Test-QuestionA0305 {
    Write-Host "Assessing question: Use of Enterprise Dev/Test Subscriptions to reduce costs for non-production workloads."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0

    try {
        # Ensure use of Enterprise Dev/Test subscriptions for non-production workloads to reduce costs
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-enterprise-agreement#design-considerations

        # Get all Azure subscriptions
        $subscriptions = Get-AzSubscription

        # Initialize counters
        $totalSubscriptions = $subscriptions.Count
        $devTestSubscriptions = 0

        # List of Dev/Test offer IDs
        $devTestOfferIds = @(
            'MS-AZR-DEVDTEST-WS'          # Visual Studio Enterprise Subscription
            'MS-AZR-0062P'                # Enterprise Dev/Test
            'MS-AZR-0148P'                # Pay-As-You-Go Dev/Test
            'MS-AZR-0023P'                # Visual Studio Professional Subscription
            'MS-AZR-0029P'                # Visual Studio Test Professional Subscription
            'MS-AZR-0036P'                # MSDN Platforms
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

            $offerId = $response.properties.authorizationSource

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
    }
    catch {
        Write-ErrorLog -QuestionID "A03.05" -QuestionText "Use of Enterprise Dev/Test Subscriptions to reduce costs for non-production workloads." -FunctionName "Test-QuestionA0305" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}

function Test-QuestionA0401 {
    Write-Host "Assessing question: Configure Agreement billing account notification contact email."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0

    try {
        # Configure Microsoft Customer Agreement billing account notification contacts
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

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

                # For MCA, billing account has 'AccountType' as 'MicrosoftCustomerAgreement'
                if ($billingAccount.AccountType -eq 'MicrosoftCustomerAgreement') {
                    $totalAccounts++

                    # Get billing profiles
                    $billingProfiles = Get-AzBillingProfile -BillingAccountName $billingAccountName

                    $configuredProfiles = 0
                    $totalProfiles = $billingProfiles.Count

                    foreach ($billingProfile in $billingProfiles) {
                        # Check the notification email settings

                        if ($billingProfile.InvoiceEmailOptIn -eq $true -and $billingProfile.InvoiceEmails -ne $null -and $billingProfile.InvoiceEmails.Count -gt 0) {
                            # Assume configured
                            $configuredProfiles++
                        }
                    }

                    if ($configuredProfiles -eq $totalProfiles -and $totalProfiles -gt 0) {
                        $configuredAccounts++
                    }
                }
            }

            if ($totalAccounts -eq 0) {
                # No MCA billing accounts
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

    }
    catch {
        Write-ErrorLog -QuestionID "A04.01" -QuestionText "Configure Agreement billing account notification contact email." -FunctionName "Test-QuestionA0401" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}


function Test-QuestionA0402 {
    Write-Host "Assessing question: Use Billing Profiles and Invoice sections to structure your agreements billing for effective cost management."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0

    try {
        # Use billing profiles and invoice sections to structure agreements for effective cost management
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

                    # Get billing profiles
                    $billingProfiles = Get-AzBillingProfile -BillingAccountName $billingAccountName

                    if ($billingProfiles.Count -gt 0) {
                        $structuredProfiles = 0
                        $totalProfiles = $billingProfiles.Count

                        foreach ($billingProfile in $billingProfiles) {
                            # Get invoice sections
                            $invoiceSections = Get-AzInvoiceSection -BillingAccountName $billingAccountName -BillingProfileName $billingProfile.Name

                            if ($invoiceSections.Count -gt 0) {
                                $structuredProfiles++
                            }
                        }

                        if ($structuredProfiles -eq $totalProfiles) {
                            $structuredAccounts++
                        }
                    }
                }
            }

            if ($totalAccounts -eq 0) {
                # No MCA billing accounts
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

    }
    catch {
        Write-ErrorLog -QuestionID "A04.02" -QuestionText "Use Billing Profiles and Invoice sections to structure your agreements billing for effective cost management." -FunctionName "Test-QuestionA0402" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}


function Test-QuestionA0403 {
    Write-Host "Assessing question: Make use of Microsoft Azure plan for dev/test offer to reduce costs for non-production workloads."
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1
    $score = 0

    try {
        # Make use of the Microsoft Azure plan for dev/test offers
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

        # Get all Azure subscriptions
        $subscriptions = Get-AzSubscription

        # Initialize counters
        $totalSubscriptions = $subscriptions.Count
        $devTestSubscriptions = 0

        # List of Dev/Test quota IDs for Microsoft Customer Agreement
        $devTestQuotaIds = @(
            'AzurePlan_DevTest'   # Quota ID for Microsoft Azure Plan for Dev/Test
        )

        foreach ($subscription in $subscriptions) {
            # Get subscription details via REST API to get the quotaId
            $subscriptionId = $subscription.Id

            $accessToken = (Get-AzAccessToken).Token

            $uri = "https://management.azure.com/subscriptions/$subscriptionId?api-version=2020-01-01"

            $headers = @{
                Authorization = "Bearer $accessToken"
            }

            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

            $quotaId = $response.properties.subscriptionPolicies.quotaId

            if ($devTestQuotaIds -contains $quotaId) {
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
    }
    catch {
        Write-ErrorLog -QuestionID "A04.03" -QuestionText "Make use of Microsoft Azure plan for dev/test offer to reduce costs for non-production workloads." -FunctionName "Test-QuestionA0403" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}


function Test-QuestionA0404 {
    Write-Host "Assessing question: Define and document a process to periodically audit the agreement billing RBAC role assignments to review who has access to your MCA billing account."
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3
    $score = 0

    try {
        # Define and document a process to periodically audit RBAC role assignments in billing account
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement#design-recommendations

        # Since defining and documenting a process is a manual task that cannot be programmatically verified,
        # we will set the status to ManualVerificationRequired.

        $status = [Status]::ManualVerificationRequired
        $estimatedPercentageApplied = 0
        $score = 0
    }
    catch {
        Write-ErrorLog -QuestionID "A04.04" -QuestionText "Define and document a process to periodically audit the agreement billing RBAC role assignments to review who has access to your MCA billing account." -FunctionName "Test-QuestionA0404" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    }

    # Return result object
    return [PSCustomObject]@{
        Status                     = $status.ToString()
        EstimatedPercentageApplied = $estimatedPercentageApplied
        Weight                     = $weight
        Score                      = $score
    }
}