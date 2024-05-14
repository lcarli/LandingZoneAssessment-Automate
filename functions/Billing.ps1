<#
.SYNOPSIS
    Functions related to Billing assessment.

.DESCRIPTION
    This script contains functions to evaluate the Billing area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-Billing {
    Write-Host "Evaluating the Billing design area..."

    # Call individual assessment functions
    $resultA1_1 = Test-EANotificationContacts
    $resultA1_2 = Test-NumberOfDepartments

    # Print results (or store them for report generation)
    Write-Host "A1.1 - EA Notification Contacts Assessment:"
    Write-Host $resultA1_1

    Write-Host "A1.2 - Number of Departments Assessment:"
    Write-Host $resultA1_2
}


#region begin A1-A


# A1.1 - EA notification contacts
function Test-EANotificationContacts {
    Write-Host "Checking EA notification contacts..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Weight from the Excel sheet
    $score = 0

    try {
        # Regex pattern for validating email addresses
        $emailPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

        # Retrieve the billing account details
        $billingAccount = Get-AzBillingAccount

        # Access the notification contacts information
        if ($billingAccount.NotificationContacts) {
            $notificationContacts = $billingAccount.NotificationContacts
            $isCorrect = $true

            foreach ($contact in $notificationContacts) {
                if (-not ($contact.Email -match $emailPattern)) {
                    $isCorrect = $false
                }
            }

            if ($isCorrect) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } else {
                $status = [Status]::PartialImplemented
                $estimatedPercentageApplied = 50
            }
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "A1.1" -QuestionText "EA notification contacts" -FunctionName "Test-EANotificationContacts" -ErrorMessage $_.Exception.Message
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


# A1.2 - Number of Departments
function Test-NumberOfDepartments {
    Write-Host "Checking the number of departments..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve the billing account departments details
        $departments = Get-AzBillingAccountDepartment

        # Check if there are any departments
        if ($departments.Count -gt 0) {
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
        Log-Error -QuestionID "A1.2" -QuestionText "Number of Departments" -FunctionName "Test-NumberOfDepartments" -ErrorMessage $_.Exception.Message
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

# A1.3 - Number and type of EA Account
function Test-NumberAndTypeOfEAAccount {
    Write-Host "Checking Number and Type of EA Account..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 4  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve the billing account details
        $billingAccount = Get-AzBillingAccount

        # Check if the account type is "Work and School accounts"
        if ($billingAccount.AuthenticationType -eq "WorkAndSchoolAccounts") {
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
        Log-Error -QuestionID "A1.3" -QuestionText "Number and type of EA Account" -FunctionName "Test-NumberAndTypeOfEAAccount" -ErrorMessage $_.Exception.Message
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


# A1.4 - Audit Interval for the EA Enrolment via Cost management & Billing
function Test-AuditIntervalEAEnrolment {
    Write-Host "Checking Audit Interval for the EA Enrolment via Cost management & Billing..."

    $status = [Status]::CheckManually
    $estimatedPercentageApplied = 0
    $weight = 2  # Weight from the Excel sheet
    $score = 0

    try {
        # As this is not a configurable setting, we will return Check Manually status
        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "A1.4" -QuestionText "Audit Interval for the EA Enrolment via Cost management & Billing" -FunctionName "Test-AuditIntervalEAEnrolment" -ErrorMessage $_.Exception.Message
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


# A1.5 - Make Use of Dev/Test EA subscription cost optimize
function Test-DevTestSubscriptionCostOptimize {
    Write-Host "Checking Dev/Test EA subscription cost optimization..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 1  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve the list of subscriptions
        $subscriptions = Get-AzSubscription

        # Check if there are Dev/Test subscriptions
        $devTestSubscriptions = $subscriptions | Where-Object { $_.SubscriptionPolicies.QuotaId -eq "EnterpriseDevTest" }
        if ($devTestSubscriptions.Count -gt 0) {
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
        Log-Error -QuestionID "A1.5" -QuestionText "Make Use of Dev/Test EA subscription cost optimize" -FunctionName "Test-DevTestSubscriptionCostOptimize" -ErrorMessage $_.Exception.Message
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


# A1.6 - Assign Budget per account / Department to establish alerts
function Test-AssignBudgetPerAccount {
    Write-Host "Checking budget assignments per account/department and alert establishment..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 2  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve the list of budgets
        $budgets = Get-AzConsumptionBudget

        # Check if there are any budgets assigned
        if ($budgets.Count -gt 0) {
            $alertsAssigned = 0
            foreach ($budget in $budgets) {
                if ($budget.Notifications.Count -gt 0) {
                    $alertsAssigned++
                }
            }

            if ($alertsAssigned -eq $budgets.Count) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($alertsAssigned -gt 0) {
                $status = [Status]::PartialImplemented
                $estimatedPercentageApplied = ($alertsAssigned / $budgets.Count) * 100
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "A1.6" -QuestionText "Assign Budget per account / Department to establish alerts" -FunctionName "Test-AssignBudgetPerAccount" -ErrorMessage $_.Exception.Message
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


# A1.7 - Enable both DA View Charges and AO View Charges
function Test-EnableViewCharges {
    Write-Host "Checking if both DA View Charges and AO View Charges are enabled..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve the billing account details
        $billingAccount = Get-AzBillingAccount

        # Check if DA View Charges and AO View Charges are enabled
        $daViewChargesEnabled = $billingAccount.DAViewChargesEnabled
        $aoViewChargesEnabled = $billingAccount.AOViewChargesEnabled

        if ($daViewChargesEnabled -and $aoViewChargesEnabled) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } elseif ($daViewChargesEnabled -or $aoViewChargesEnabled) {
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
        Log-Error -QuestionID "A1.7" -QuestionText "Enable both DA View Charges and AO View Charges" -FunctionName "Test-EnableViewCharges" -ErrorMessage $_.Exception.Message
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

#region begin A1-B

# A1.2 - Map your organization/billing to your agreement billing structure
function Test-MapOrganizationBilling {
    Write-Host "Checking if organization/billing is mapped to your agreement billing structure..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 2  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve the list of departments or similar structure
        $departments = Get-AzBillingAccountDepartment

        # Check if there are any departments mapped to the billing structure
        if ($departments.Count -gt 0) {
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
        Log-Error -QuestionID "A1.2" -QuestionText "Map your organization/billing to your agreement billing structure" -FunctionName "Test-MapOrganizationBilling" -ErrorMessage $_.Exception.Message
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

# A1.6 - Setup cost reporting with Azure Cost Management
function Test-SetupCostReporting {
    Write-Host "Checking if cost reporting is set up with Azure Cost Management..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve cost management views
        $costReports = Get-AzCostManagementReport

        # Check if there are any cost management reports set up
        if ($costReports.Count -gt 0) {
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
        Log-Error -QuestionID "A1.6" -QuestionText "Setup cost reporting with Azure Cost Management" -FunctionName "Test-SetupCostReporting" -ErrorMessage $_.Exception.Message
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

#region begion A1-C

# A1.1 - Ensure that Azure Lighthouse is used for admin control
function Test-EnsureLighthouse {
    Write-Host "Checking if Azure Lighthouse is used for admin control..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 2  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve the list of delegations to verify Azure Lighthouse usage
        $lighthouseDelegations = Get-AzDelegatedResourceManagementAssignment

        # Check if there are any delegations indicating Lighthouse usage
        if ($lighthouseDelegations.Count -gt 0) {
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
        Log-Error -QuestionID "A1.1" -QuestionText "Ensure that Azure Lighthouse is used for admin control" -FunctionName "Test-EnsureLighthouse" -ErrorMessage $_.Exception.Message
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



# A1.2 - Discuss support with CSP partner
function Test-DiscussSupportCSP {
    Write-Host "Checking if support with CSP partner is discussed..."

    $status = [Status]::CheckManually
    $estimatedPercentageApplied = 0
    $weight = 5  # Weight from the Excel sheet
    $score = 0

    try {
        # This is a placeholder for manual verification
        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Log-Error -QuestionID "A1.2" -QuestionText "Discuss support with CSP partner" -FunctionName "Test-DiscussSupportCSP" -ErrorMessage $_.Exception.Message
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
