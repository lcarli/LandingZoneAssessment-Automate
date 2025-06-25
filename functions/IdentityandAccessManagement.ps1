# IdentityandAccessManagement.ps1

<#
.SYNOPSIS
    Functions related to IdentityandAccessManagement assessment.

.DESCRIPTION
    This script contains functions to evaluate the IdentityandAccessManagement area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-IdentityandAccessManagementAssessment {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Object]$Checklist
    )

    Write-AssessmentHeader "Evaluating the Identity and Access Management design area..."
    Measure-ExecutionTime -ScriptBlock {
        $results = @()

        # Call individual assessment functions
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.01") }) | Test-QuestionB0301
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.02" -and ($_.subcategory -eq "Microsoft Entra ID and Hybrid Identity")) }) | Test-QuestionB0302
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.02" -and ($_.subcategory -eq "Identity")) }) | Test-QuestionB030201
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.03") }) | Test-QuestionB0303
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.04") }) | Test-QuestionB0304
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.05") }) | Test-QuestionB0305
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.06") }) | Test-QuestionB0306
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.07") }) | Test-QuestionB0307
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.09") }) | Test-QuestionB0309
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.10") }) | Test-QuestionB0310
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.11") }) | Test-QuestionB0311
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.12") }) | Test-QuestionB0312
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.13") }) | Test-QuestionB0313
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.14") }) | Test-QuestionB0314
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.15") }) | Test-QuestionB0315
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.16") }) | Test-QuestionB0316
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.17") }) | Test-QuestionB0317
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.18") }) | Test-QuestionB0318
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B04.01") }) | Test-QuestionB0401
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B04.02") }) | Test-QuestionB0402
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B04.03") }) | Test-QuestionB0403
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B04.04") }) | Test-QuestionB0404
        
        $script:FunctionResult = $results
    } -FunctionName "Invoke-IdentityandAccessManagementAssessment"

    return $script:FunctionResult
}

function Test-QuestionB0301 {
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

        # Enforce a RBAC model that aligns to your cloud operating model.Scope and Assign across Management Groups and Subscriptions.
        # Reference: https://learn.microsoft.com/azure/role-based-access-control/overview

        # Get management groups
        $managementGroups = $global:AzData.ManagementGroups | Where-Object { $_.TenantId -eq $TenantId }
        $totalGroups = $managementGroups.Count
        $configuredGroups = 0

        foreach ($managementGroup in $managementGroups) {
            $managementGroupId = $managementGroup.Id
            $mgmtGroupRoleAssignments = Get-AzRoleAssignment -Scope "$managementGroupId"

            if ($mgmtGroupRoleAssignments | Where-Object { $_.RoleDefinitionName -in @("Contributor", "Owner", "Reader") }) {
                $configuredGroups++
            }
        }

        $mgmtGroupPercentage = if ($totalGroups -gt 0) {
            ($configuredGroups / $totalGroups) * 100
        }
        else {
            100
        }

        # Get subscriptions
        $subscriptions = $global:AzData.Subscriptions
        $totalSubscriptions = $subscriptions.Count
        $configuredSubscriptions = 0

        foreach ($subscription in $subscriptions) {
            $subscriptionId = $subscription.Id
            $subscriptionRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$subscriptionId"

            if ($subscriptionRoleAssignments | Where-Object { $_.RoleDefinitionName -in @("Contributor", "Owner", "Reader") }) {
                $configuredSubscriptions++
            }
        }

        $subscriptionPercentage = if ($totalSubscriptions -gt 0) {
            ($configuredSubscriptions / $totalSubscriptions) * 100
        }
        else {
            100
        }

        # Calculate overall percentage
        $estimatedPercentageApplied = [Math]::Round(($mgmtGroupPercentage + $subscriptionPercentage) / 2, 2)

        # Determine status
        if ($estimatedPercentageApplied -eq 100) {
            $status = [Status]::Implemented
        }
        elseif ($estimatedPercentageApplied -eq 0) {
            $status = [Status]::NotImplemented
        }
        else {
            $status = [Status]::PartiallyImplemented
        }

        $score = ($weight * $estimatedPercentageApplied) / 100

        $rawData = @{
            ManagementGroups = @{
                Total      = $totalGroups
                Configured = $configuredGroups
                Percentage = $mgmtGroupPercentage
            }
            Subscriptions    = @{
                Total      = $totalSubscriptions
                Configured = $configuredSubscriptions
                Percentage = $subscriptionPercentage
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

function Test-QuestionB0302 {
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
        # Question: Use managed identities instead of service principals for authentication to Azure services.
        # Reference: https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview
        # Get all service principals using Graph data (cached)
        if ($global:GraphData.ServicePrincipals) {
            $servicePrincipals = $global:GraphData.ServicePrincipals
        }
        else {
            # Fallback to direct Graph call if available
            if ($global:GraphConnected) {
                try {
                    $servicePrincipals = Get-MgServicePrincipal -All -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Warning "Could not retrieve service principals: $($_.Exception.Message)"
                    $servicePrincipals = @()
                }
            }
            else {
                $servicePrincipals = @()
            }
        }

        if ($servicePrincipals.Count -eq 0) {
            # No service principals found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            $totalServicePrincipals = $servicePrincipals.Count
            $managedIdentities = 0

            # Check for Managed Identities instead of Service Principals
            foreach ($sp in $servicePrincipals) {
                if ($sp.ServicePrincipalType -eq "ManagedIdentity") {
                    $managedIdentities++
                }
            }

            if ($managedIdentities -eq $totalServicePrincipals) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($managedIdentities -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($managedIdentities / $totalServicePrincipals) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            TotalServicePrincipals = $totalServicePrincipals
            ManagedIdentities      = $managedIdentities
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

function Test-QuestionB030201 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Only use the authentication type Work or school account for all account types. Avoid using the Microsoft account.
        # Reference: https://learn.microsoft.com/learn/modules/explore-basic-services-identity-types/

        # Get all Azure AD users using Graph data (cached)
        if ($global:GraphData.Users) {
            $users = $global:GraphData.Users
        }
        else {
            # Fallback to direct Graph call if available
            if ($global:GraphConnected) {
                try {
                    $users = Get-MgUser -All -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Warning "Could not retrieve users: $($_.Exception.Message)"
                    $users = @()
                }
            }
            else {
                $users = @()
            }
        }

        if ($users.Count -eq 0) {
            # No users found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            $totalUsers = $users.Count
            $validWorkOrSchoolAccounts = 0

            # Check each user account
            foreach ($user in $users) {
                # A user with a domain not belonging to Microsoft consumer accounts (outlook.com, hotmail.com, live.com, gmail.com, yahoo.com) is assumed to be a work or school account
                $userPrincipalName = $user.UserPrincipalName.ToLower()

                if ($userPrincipalName -notmatch "@(outlook.com|hotmail.com|live.com|gmail.com|yahoo.com)$") {
                    $validWorkOrSchoolAccounts++
                }
            }

            # Calculate the percentage of valid Work/School accounts
            if ($validWorkOrSchoolAccounts -eq $totalUsers) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($validWorkOrSchoolAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($validWorkOrSchoolAccounts / $totalUsers) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            TotalUsers                = $totalUsers
            ValidWorkOrSchoolAccounts = $validWorkOrSchoolAccounts
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

function Test-QuestionB0303 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Only use groups to assign permissions across all subscriptions. Add on-premises groups to the Entra ID only group if a group management system is already in place.
        # Reference: https://learn.microsoft.com/azure/role-based-access-control/groups

        # Get all subscriptions in the current tenant
        $subscriptions = $global:AzData.Subscriptions

        if ($subscriptions.Count -eq 0) {
            # No subscriptions found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            $totalAssignments = 0
            $groupAssignments = 0

            # Loop through each subscription
            foreach ($subscription in $subscriptions) {
                $subscriptionId = $subscription.Id

                # Set the context to the current subscription
                Set-AzContext -SubscriptionId $subscriptionId -TenantId $TenantId

                Write-AssessmentInfo "Checking role assignments for Subscription ID: $subscriptionId"

                # Get all role assignments for the current subscription
                $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$subscriptionId"

                # Count total role assignments in this subscription
                $totalAssignments += $roleAssignments.Count

                # Loop through each role assignment and check if it's assigned to a group
                foreach ($assignment in $roleAssignments) {
                    if ($assignment.ObjectType -eq "Group") {
                        $groupAssignments++
                    }
                }
            }

            # Calculate the percentage of group-based assignments
            if ($totalAssignments -eq 0) {
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            }
            elseif ($groupAssignments -eq $totalAssignments) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($groupAssignments -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($groupAssignments / $totalAssignments) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            TotalAssignments = $totalAssignments
            GroupAssignments = $groupAssignments
            Subscriptions    = $subscriptions | ForEach-Object { $_.Id }
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

function Test-QuestionB0304 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Enforce Microsoft Entra ID Conditional Access policies for any user with rights to Azure environments.
        # Reference: https://learn.microsoft.com/azure/active-directory/conditional-access/overview


        # Get all role assignments for Azure resources
        $roleAssignments = Get-AzRoleAssignment

        if ($roleAssignments.Count -eq 0) {
            # No role assignments found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            $totalAssignments = $roleAssignments.Count
            $usersCoveredByPolicies = 0
            $uniqueUsers = @()            # Get all Conditional Access policies - check Graph connectivity first
            if ($global:GraphConnected -eq $false) {
                Write-Warning "Microsoft Graph is not connected. Cannot assess Conditional Access policies."
                $status = [Status]::Unknown
                $estimatedPercentageApplied = 0
                $score = 0
                $rawData = "Microsoft Graph connection not available for Conditional Access assessment"
                return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData            
            }
            # Try to get Conditional Access policies from cached data
            try {
                if ($global:GraphConnected -and $global:GraphData -and $global:GraphData.ConditionalAccessPolicies) {
                    $conditionalAccessPolicies = $global:GraphData.ConditionalAccessPolicies
                }
                else {
                    $conditionalAccessPolicies = $null
                }
            }
            catch {
                Write-Warning "Could not retrieve Conditional Access policies: $($_.Exception.Message)"
                $conditionalAccessPolicies = $null
            }
            
            if (-not $conditionalAccessPolicies) {
                $status = [Status]::Unknown
                $estimatedPercentageApplied = 0
                $score = 0
                $rawData = "Cannot access Conditional Access policies"
                return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
            }

            # Store unique user principal names from role assignments
            foreach ($assignment in $roleAssignments) {
                if ($assignment.ObjectType -eq "User") {
                    $uniqueUsers += $assignment.DisplayName
                }
            }

            $uniqueUsers = $uniqueUsers | Sort-Object -Unique

            # Check if each user is covered by at least one Conditional Access policy
            foreach ($user in $uniqueUsers) {
                $isCovered = $false
                foreach ($policy in $conditionalAccessPolicies) {
                    if ($policy.Conditions.Users.IncludeUsers -contains $user -or $policy.Conditions.Users.IncludeGroups -contains $user) {
                        $isCovered = $true
                        break
                    }
                }
                if ($isCovered) {
                    $usersCoveredByPolicies++
                }
            }

            # Calculate the percentage of users covered by Conditional Access policies
            if ($usersCoveredByPolicies -eq $uniqueUsers.Count) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($usersCoveredByPolicies -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($usersCoveredByPolicies / $uniqueUsers.Count) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            TotalAssignments          = $totalAssignments
            UniqueUsers               = $uniqueUsers
            UsersCoveredByPolicies    = $usersCoveredByPolicies
            ConditionalAccessPolicies = $conditionalAccessPolicies
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

function Test-QuestionB0305 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Enforce multi-factor authentication for any user with rights to the Azure environments.
        # Reference: https://learn.microsoft.com/azure/active-directory/authentication/howto-mfa-getstarted

        # Get all role assignments for Azure resources
        $roleAssignments = Get-AzRoleAssignment

        if ($roleAssignments.Count -eq 0) {
            # No role assignments found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        }
        else {
            $totalAssignments = $roleAssignments.Count
            $usersWithMFA = 0
            $uniqueUsers = @()

            foreach ($assignment in $roleAssignments) {
                if ($assignment.ObjectType -eq "User") {
                    $uniqueUsers += $assignment.ObjectId
                }
            }

            $uniqueUsers = $uniqueUsers | Sort-Object -Unique            # Check Graph connectivity before processing users
            if ($global:GraphConnected -eq $false) {
                Write-Warning "Microsoft Graph is not connected. Cannot assess MFA configuration."
                $status = [Status]::Unknown
                $estimatedPercentageApplied = 0
                $score = 0
                $rawData = "Microsoft Graph connection not available for MFA assessment"
                return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
            }

            foreach ($userId in $uniqueUsers) {
                $isMFAEnabled = $false                  
                try {
                    # Check if the required module is loaded to avoid auto-loading conflicts
                    if (Get-Module -Name "Microsoft.Graph.Users" -ErrorAction SilentlyContinue) {
                        $mfaMethods = Get-MgUserAuthenticationMethod -UserId $userId -ErrorAction SilentlyContinue
                    }
                    else {
                        $mfaMethods = $null
                    }

                    if ($mfaMethods -and $mfaMethods.Count -gt 0) {
                        $isMFAEnabled = $true
                    }
                }
                catch {
                    Write-Verbose "Failed to get MFA methods for user: $userId"
                }if (-not $isMFAEnabled) {
                    # Use cached conditional access policies
                    if ($global:GraphConnected -and $global:GraphData -and $global:GraphData.ConditionalAccessPolicies) {
                        $conditionalAccessPolicies = $global:GraphData.ConditionalAccessPolicies
                    }
                    else {
                        $conditionalAccessPolicies = $null
                    }
                    
                    if ($conditionalAccessPolicies) {
                        foreach ($policy in $conditionalAccessPolicies) {
                            if (($policy.Conditions.Users.IncludeUsers -contains $userId) -and ($policy.GrantControls.BuiltInControls -contains "mfa")) {
                                $isMFAEnabled = $true
                                break
                            }
                        }
                    }
                }

                if ($isMFAEnabled) {
                    $usersWithMFA++
                }
            }

            if ($usersWithMFA -eq $uniqueUsers.Count) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }
            elseif ($usersWithMFA -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($usersWithMFA / $uniqueUsers.Count) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            TotalAssignments = $totalAssignments
            UsersWithMFA     = $usersWithMFA
            UniqueUsers      = $uniqueUsers
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

function Test-QuestionB0306 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Enforce centralized and delegated responsibilities to manage resources deployed inside the landing zone, based on role and security requirements.
        # Reference: https://learn.microsoft.com/azure/role-based-access-control/overview


        # Assess role assignments across management groups
        $managementGroups = $global:AzData.ManagementGroups | Where-Object { $_.TenantId -eq $TenantId }
        $totalGroups = 0
        $configuredGroups = 0
        $delegatedGroups = 0

        foreach ($managementGroup in $managementGroups) {
            $totalGroups++
            $managementGroupId = $managementGroup.Id

            # Retrieve role assignments for the management group
            $mgmtGroupRoleAssignments = Get-AzRoleAssignment -Scope "$managementGroupId"

            # Check for centralized (Owner) and delegated roles (Contributor, Reader)
            $hasOwner = $false
            $hasDelegated = $false

            foreach ($roleAssignment in $mgmtGroupRoleAssignments) {
                if ($roleAssignment.RoleDefinitionName -eq "Owner") {
                    $hasOwner = $true
                }
                elseif ($roleAssignment.RoleDefinitionName -in @("Contributor", "Reader")) {
                    $hasDelegated = $true
                }
            }

            if ($hasOwner) {
                $configuredGroups++
            }
            if ($hasDelegated) {
                $delegatedGroups++
            }
        }

        # Calculate percentage for management groups
        if ($totalGroups -gt 0) {
            $mgmtGroupPercentage = ($configuredGroups / $totalGroups) * 100
            $delegationPercentage = ($delegatedGroups / $totalGroups) * 100
        }
        else {
            $mgmtGroupPercentage = 100
            $delegationPercentage = 100
        }

        # Combine the results to determine the overall applied percentage
        $estimatedPercentageApplied = [Math]::Round(($mgmtGroupPercentage + $delegationPercentage) / 2, 2)

        # Determine status
        if ($estimatedPercentageApplied -eq 100) {
            $status = [Status]::Implemented
        }
        elseif ($estimatedPercentageApplied -eq 0) {
            $status = [Status]::NotImplemented
        }
        else {
            $status = [Status]::PartiallyImplemented
        }

        # Calculate score based on the weight and the percentage applied
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            TotalGroups               = $totalGroups
            ConfiguredGroups          = $configuredGroups
            DelegatedGroups           = $delegatedGroups
            ManagementGroupPercentage = $mgmtGroupPercentage
            DelegationPercentage      = $delegationPercentage
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

function Test-QuestionB0307 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null    
    
    try {
        # Question: Enforce Microsoft Entra ID Privileged Identity Management (PIM) to establish zero standing access and least privilege.
        # Reference: https://learn.microsoft.com/azure/active-directory/privileged-identity-management/pim-configure
        # Note: Using new PIM v3 APIs due to migration from deprecated endpoints        # Get privileged role definitions we want to check
        $privilegedRoleNames = @("Global Administrator", "Privileged Role Administrator", "Security Administrator")        # Get role definitions for the privileged roles from cached data
        try {
            if ($global:GraphConnected -and $global:GraphData -and $global:GraphData.RoleDefinitions) {
                $roleDefinitions = $global:GraphData.RoleDefinitions | Where-Object { 
                    $_.DisplayName -in $privilegedRoleNames 
                }
            }
            else {
                $roleDefinitions = $null
            }
            
            # Check if we got results or if there was a permission error
            if (-not $roleDefinitions -and $Error.Count -gt 0 -and $Error[0].Exception.Message -like "*PermissionScopeNotGranted*") {
                
                $Error.Clear()  # Clear the error to prevent it from showing in transcript
                
                $status = [Status]::Unknown
                $estimatedPercentageApplied = 0
                $rawData = @{
                    Error               = "Insufficient permissions to read role definitions"
                    RequiredPermissions = @("RoleManagement.Read.Directory")
                    Message             = "Cannot assess PIM due to insufficient Microsoft Graph permissions."
                }
                
                $score = ($weight * $estimatedPercentageApplied) / 100
                
                return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
            }        
        }
        catch {
            $errorMessage = $_.Exception.Message
            if ($errorMessage -like "*PermissionScopeNotGranted*" -or 
                $errorMessage -like "*Authorization failed*" -or
                $errorMessage -like "*missing permission scope*" -or
                $_.Exception.Response.StatusCode -eq 403) {
                
                
                $status = [Status]::Unknown
                $estimatedPercentageApplied = 0
                $rawData = @{
                    Error               = "Insufficient permissions to read role definitions"
                    RequiredPermissions = @("RoleManagement.Read.Directory")
                    Message             = "Cannot assess PIM due to insufficient Microsoft Graph permissions."
                }
                
                $score = ($weight * $estimatedPercentageApplied) / 100
                
                return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
            }
            else {
                throw $_
            }
        }

        if ($roleDefinitions.Count -eq 0) {
            # No privileged role definitions found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No privileged role definitions found"        
        }
        else {
            # Get active (permanent) role assignments and eligible assignments for privileged roles
            $activeAssignments = @()
            $eligibleAssignments = @()
            $permissionErrors = @()
            
            foreach ($roleDefinition in $roleDefinitions) {
                try {
                    # Get active role assignment schedule instances (permanent assignments)
                    if (Get-Module -Name "Microsoft.Graph.Identity.Governance" -ErrorAction SilentlyContinue) {
                        $activeRoleAssignments = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -Filter "roleDefinitionId eq '$($roleDefinition.Id)'" -ErrorAction SilentlyContinue
                    }
                    else {
                        $activeRoleAssignments = $null
                    }
                    
                    if ($activeRoleAssignments) {
                        $activeAssignments += $activeRoleAssignments
                    }
                    elseif ($Error.Count -gt 0 -and $Error[0].Exception.Message -like "*PermissionScopeNotGranted*") {
                        $permissionErrors += "Active assignments for role '$($roleDefinition.DisplayName)'"
                        Write-Warning "Insufficient permissions to query active assignments for role '$($roleDefinition.DisplayName)'"
                        $Error.Clear()  # Clear the error to prevent it from showing in transcript
                    }
                }
                catch {
                    # This catch should rarely be hit with SilentlyContinue
                    Write-Warning "Could not retrieve active assignments for role '$($roleDefinition.DisplayName)': $($_.Exception.Message)"
                }                try {
                    # Get eligible role assignment schedule instances (PIM eligibility)
                    if (Get-Module -Name "Microsoft.Graph.Identity.Governance" -ErrorAction SilentlyContinue) {
                        $eligibleRoleAssignments = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "roleDefinitionId eq '$($roleDefinition.Id)'" -ErrorAction SilentlyContinue
                    }
                    else {
                        $eligibleRoleAssignments = $null
                    }
                    
                    if ($eligibleRoleAssignments) {
                        $eligibleAssignments += $eligibleRoleAssignments
                    }
                    elseif ($Error.Count -gt 0 -and $Error[0].Exception.Message -like "*PermissionScopeNotGranted*") {
                        $permissionErrors += "Eligible assignments for role '$($roleDefinition.DisplayName)'"
                        Write-Warning "Insufficient permissions to query eligible assignments for role '$($roleDefinition.DisplayName)'"
                        $Error.Clear()  # Clear the error to prevent it from showing in transcript
                    }
                }
                catch {
                    # This catch should rarely be hit with SilentlyContinue
                    Write-Warning "Could not retrieve eligible assignments for role '$($roleDefinition.DisplayName)': $($_.Exception.Message)"
                }
            }            # Check if we have permission errors
            if ($permissionErrors.Count -gt 0) {
                
                
                # If we have no data at all, return unknown status
                if ($activeAssignments.Count -eq 0 -and $eligibleAssignments.Count -eq 0) {
                    $status = [Status]::Unknown
                    $estimatedPercentageApplied = 0                   
                    $rawData = @{
                        Error               = "Insufficient permissions to assess PIM configuration"
                        RequiredPermissions = @(
                            "RoleAssignmentSchedule.Read.Directory",
                            "RoleEligibilitySchedule.Read.Directory", 
                            "RoleManagement.Read.Directory"
                        )
                        Message             = "Cannot assess PIM due to insufficient Microsoft Graph permissions."
                    }
                    
                    # Calculate score and return early
                    $score = ($weight * $estimatedPercentageApplied) / 100
                    
                    return @{
                        Status                     = $status
                        EstimatedPercentageApplied = $estimatedPercentageApplied
                        Score                      = $score
                        Weight                     = $weight
                        RawData                    = $rawData
                    }
                }
            }

            $totalActiveAssignments = $activeAssignments.Count
            $totalEligibleAssignments = $eligibleAssignments.Count
            $totalAssignments = $totalActiveAssignments + $totalEligibleAssignments

            if ($totalAssignments -eq 0) {
                # No assignments found
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
                $rawData = "No role assignments found for privileged roles"
            }
            elseif ($totalActiveAssignments -eq 0 -and $totalEligibleAssignments -gt 0) {
                # Perfect: Only eligible assignments (PIM), no permanent assignments
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalAssignments    = $totalAssignments
                    ActiveAssignments   = $totalActiveAssignments
                    EligibleAssignments = $totalEligibleAssignments
                    Message             = "All privileged role assignments are properly configured with PIM (no standing access)"
                }
            }
            elseif ($totalActiveAssignments -gt 0 -and $totalEligibleAssignments -eq 0) {
                # Bad: Only permanent assignments, no PIM
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalAssignments    = $totalAssignments
                    ActiveAssignments   = $totalActiveAssignments
                    EligibleAssignments = $totalEligibleAssignments
                    Message             = "All privileged role assignments are permanent (standing access). PIM should be implemented."
                }            
            }
            else {
                # Mixed: Some permanent, some PIM - partially implemented
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($totalEligibleAssignments / $totalAssignments) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalAssignments    = $totalAssignments
                    ActiveAssignments   = $totalActiveAssignments
                    EligibleAssignments = $totalEligibleAssignments
                    Message             = "Mix of permanent and PIM assignments. Consider migrating all to PIM."
                }
            }
        }        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
        $rawData = @{
            Error        = $_.Exception.Message
            ErrorDetails = "Failed to assess PIM configuration using new PIM v3 APIs"
        }
        $rawData = $_.Exception.Message
    }

    # Return result object using Set-EvaluationResultObject
    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionB0308 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: When deploying Active Directory Domain Controllers, use a location with Availability Zones and deploy at least two VMs across these zones. If not available, deploy in an Availability Set.
        # Reference: https://learn.microsoft.com/azure/virtual-machines/availability

        # Get region from global config or use default
        $location = $global:DefaultRegion
        if (-not $location) {
            $location = "eastus2"  # Fallback default
        }

        # Get Domain Controller VMs from global resource data
        # Look for VMs that might be Domain Controllers (by naming convention or resource group naming)
        $dcVMs = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and
            ($_.Name -like "*dc*" -or $_.Name -like "*domain*" -or 
            $_.ResourceGroupName -like "*dc*" -or $_.ResourceGroupName -like "*domain*" -or
            $_.ResourceGroupName -like "*identity*" -or $_.ResourceGroupName -like "*ad*")
        }

        if ($dcVMs.Count -eq 0) {
            # No Domain Controller VMs found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 0
            $rawData = @{
                Message             = "No Domain Controller VMs detected. Assessment not applicable."
                Location            = $location
                DomainControllerVMs = 0
            }
        }
        else {
            # Check availability zones in the region
            # Note: We'll use a simplified approach since Get-AzAvailabilityZone requires specific module imports
            # Known regions with Availability Zones (as of 2024)
            $regionsWithAZ = @(
                "eastus", "eastus2", "westus", "westus2", "westus3", "centralus", "northcentralus", "southcentralus",
                "westcentralus", "canadacentral", "canadaeast", "brazilsouth", "northeurope", "westeurope",
                "uksouth", "ukwest", "francecentral", "francesouth", "germanywestcentral", "norwayeast",
                "switzerlandnorth", "swedencentral", "australiaeast", "australiasoutheast", "southeastasia",
                "eastasia", "japaneast", "japanwest", "koreacentral", "koreasouth", "southafricanorth",
                "centralindia", "southindia", "westindia", "uaenorth"
            )

            $locationHasAZ = $regionsWithAZ -contains $location.ToLower()

            # For detailed VM information including Availability Zones and Sets, we need to make additional calls
            # Since this is challenging with cached data, we'll use a more practical approach
            
            $vmsInAZ = 0
            $vmsInAvailabilitySet = 0
            $totalDCVMs = $dcVMs.Count

            # Get Availability Sets from global data
            $availabilitySets = $global:AzData.Resources | Where-Object {
                $_.ResourceType -eq "Microsoft.Compute/availabilitySets"
            }

            # For a simplified assessment, if the region supports AZ and we have multiple DCs, assume good practice
            if ($locationHasAZ -and $totalDCVMs -ge 2) {
                # If region has AZ and multiple DCs exist, assume best practice is followed
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 85  # High confidence if multiple DCs in AZ-enabled region
                $message = "Multiple Domain Controllers deployed in Availability Zone-enabled region. Assuming best practices."
            }
            elseif ($availabilitySets.Count -gt 0 -and $totalDCVMs -ge 2) {
                # Multiple DCs and Availability Sets exist
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = 70  # Good but not optimal (AZ preferred over AS)
                $message = "Multiple Domain Controllers and Availability Sets found. Consider upgrading to Availability Zones if region supports them."
            }
            elseif ($totalDCVMs -ge 2) {
                # Multiple DCs but unclear about high availability
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = 50
                $message = "Multiple Domain Controllers found but high availability configuration unclear."
            }
            else {
                # Single DC - not following best practices
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $message = "Only single Domain Controller found. Deploy at least two DCs with high availability."
            }

            $rawData = @{
                Location                     = $location
                LocationHasAvailabilityZones = $locationHasAZ
                DomainControllerVMs          = $totalDCVMs
                AvailabilitySets             = $availabilitySets.Count
                Message                      = $message
                DCVMNames                    = $dcVMs.Name -join ", "
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
        $rawData = @{
            Error        = $_.Exception.Message
            ErrorDetails = "Failed to assess Domain Controller availability configuration"
        }
    }

    # Return result object using Set-EvaluationResultObject
    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionB0309 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Use Azure custom RBAC roles for the following key roles to provide fine-grain access across your ALZ: Azure platform owner, network management, security operations, subscription owner, application owner. Align these roles to teams and responsibilities within your business.
        # Reference: https://learn.microsoft.com/azure/role-based-access-control/custom-roles

        # Get all custom roles in the tenant
        $customRoles = Get-AzRoleDefinition | Where-Object { $_.IsCustom -eq $true }

        # Define key roles that should be customized
        $requiredRoles = @(
            "Azure platform owner",
            "Network management",
            "Security operations",
            "Subscription owner",
            "Application owner"
        )

        # Check if each required role is represented in custom roles
        $rolesFound = 0
        $foundRoles = @()

        foreach ($role in $requiredRoles) {
            if ($customRoles.Name -contains $role) {
                $rolesFound++
                $foundRoles += $role
            }
        }

        # Calculate the percentage of required roles found
        if ($rolesFound -eq $requiredRoles.Count) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        }
        elseif ($rolesFound -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }
        else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($rolesFound / $requiredRoles.Count) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            RequiredRoles = $requiredRoles
            FoundRoles    = $foundRoles
            CustomRoles   = $customRoles
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

function Test-QuestionB0310 {
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
        # Question: If planning to switch from Active Directory Domain Services to Entra domain services, evaluate the compatibility of all workloads.
        # Reference: https://learn.microsoft.com/azure/active-directory-domain-services/overview

        # Get all Custom RBAC Roles
        $customRoles = Get-AzRoleDefinition | Where-Object { $_.IsCustom -eq $true }

        # Define the required roles
        $requiredRoles = @(
            "Azure platform owner",
            "Network management",
            "Security operations",
            "Subscription owner",
            "Application owner"
        )

        # Check if each required role exists
        $rolesMatched = @()
        $missingRoles = @()

        foreach ($role in $requiredRoles) {
            if ($customRoles.Name -contains $role) {
                $rolesMatched += $role
            }
            else {
                $missingRoles += $role
            }
        }

        # Determine status and estimated percentage
        $rolesFound = $rolesMatched.Count
        $totalRequiredRoles = $requiredRoles.Count

        if ($rolesFound -eq $totalRequiredRoles) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = "All required custom roles are implemented."
        }
        elseif ($rolesFound -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = @{
                MissingRoles = $missingRoles
                Message      = "None of the required custom roles are implemented."
            }
        }
        else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($rolesFound / $totalRequiredRoles) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            $rawData = @{
                TotalRequiredRoles = $totalRequiredRoles
                RolesMatched       = $rolesMatched
                MissingRoles       = $missingRoles
                Message            = "Some required custom roles are missing."
            }
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

function Test-QuestionB0311 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to evaluate the compatibility of all workloads when planning to switch from Active Directory Domain Services (AD DS) to Entra Domain Services (ED DS)."

    try {
        # Question: When using Microsoft Entra Domain Services use replica sets. Replica sets will improve the resiliency of your managed domain and allow you to deploy to additional regions.
        # Reference: https://learn.microsoft.com/azure/active-directory-domain-services/replica-sets

        # No automated logic is implemented here
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

function Test-QuestionB0312 {
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
        # Question: Integrate Microsoft Entra ID logs with the platform-central Azure Monitor. Azure Monitor allows for a single source of truth around log and monitoring data in Azure, giving organizations a cloud native option to meet requirements around log collection and retention.
        # Reference: https://learn.microsoft.com/azure/active-directory/reports-monitoring/howto-integrate-activity-logs-with-log-analytics        # Get all Entra Domain Services configurations using resource search
        try {
            $entraDomains = Get-AzResource -ResourceType "Microsoft.AAD/DomainServices" -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Could not retrieve Entra Domain Services: $($_.Exception.Message)"
            $entraDomains = $null
        }

        if (-not $entraDomains -or $entraDomains.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Entra Domain Services (ED DS) configurations found in the current environment."
        }
        else {
            $totalDomains = $entraDomains.Count
            $domainsWithReplicaSets = 0

            foreach ($domain in $entraDomains) {
                # Check if replica sets are configured
                if ($domain.ReplicaSets.Count -gt 1) {
                    $domainsWithReplicaSets++
                }
            }

            if ($domainsWithReplicaSets -eq $totalDomains) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = "All Entra Domain Services domains have replica sets configured."
            }
            elseif ($domainsWithReplicaSets -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = "No Entra Domain Services domains have replica sets configured."
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($domainsWithReplicaSets / $totalDomains) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalDomains              = $totalDomains
                    DomainsWithReplicaSets    = $domainsWithReplicaSets
                    DomainsWithoutReplicaSets = $totalDomains - $domainsWithReplicaSets
                    Message                   = "Some Entra Domain Services domains are missing replica sets."
                }
            }
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

function Test-QuestionB0313 {
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
        # Question: When using Microsoft Entra Domain Services, use replica sets.
        # Reference: https://learn.microsoft.com/azure/active-directory-domain-services/replica-sets

        # Try to get Diagnostic Settings for Microsoft Entra ID
        # Note: This requires special permissions and may not be available to all users
        try {
            # Note: Az.Monitor module is imported in Initialize.ps1 for better performance
            # Verify monitor module is available before proceeding
            if (-not (Test-CmdletAvailable -CmdletName 'Get-AzDiagnosticSetting')) {
                throw "Get-AzDiagnosticSetting cmdlet not available"
            }
            
            # Try to get diagnostic settings for Azure AD - using the correct resource ID format
            $diagnosticSettings = Get-AzDiagnosticSetting -ResourceId "/providers/Microsoft.AADIAM/diagnosticSettings" -ErrorAction Stop
        }
        catch {
            # Handle permission errors or missing cmdlet gracefully
            if ($_.Exception.Message -like "*authorization*" -or $_.Exception.Message -like "*permissions*" -or $_.Exception.Message -like "*not recognized*") {
                Write-Warning "Cannot check Microsoft Entra ID diagnostic settings. This may require special permissions or the Az.Monitor module."
                $status = [Status]::Unknown
                $estimatedPercentageApplied = 0
                $rawData = @{
                    Error               = "Cannot assess diagnostic settings"
                    Message             = "Unable to retrieve diagnostic settings: $($_.Exception.Message)"
                    RequiredPermissions = "Global Administrator, Security Administrator, or Monitor Contributor roles may be required"
                }
                
                # Calculate score and return early
                $weight = 5
                $score = ($weight * $estimatedPercentageApplied) / 100
                
                return @{
                    Status                     = $status
                    EstimatedPercentageApplied = $estimatedPercentageApplied
                    Score                      = $score
                    Weight                     = $weight
                    RawData                    = $rawData
                }
            }
            else {
                # Re-throw other errors
                throw
            }
        }

        if (-not $diagnosticSettings -or $diagnosticSettings.Count -eq 0) {
            # No diagnostic settings found
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No diagnostic settings are configured for Microsoft Entra ID."
        }
        else {
            $logsToAzureMonitor = $diagnosticSettings | Where-Object {
                $null -ne $_.WorkspaceId -and $_.Logs | Where-Object { $_.Enabled -eq $true }
            }

            if ($logsToAzureMonitor.Count -eq $diagnosticSettings.Count) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = "All diagnostic settings for Microsoft Entra ID are configured to send logs to Azure Monitor."
            }
            elseif ($logsToAzureMonitor.Count -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = "None of the diagnostic settings for Microsoft Entra ID are configured to send logs to Azure Monitor."
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($logsToAzureMonitor.Count / $diagnosticSettings.Count) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalSettings               = $diagnosticSettings.Count
                    SettingsWithAzureMonitor    = $logsToAzureMonitor.Count
                    SettingsWithoutAzureMonitor = $diagnosticSettings.Count - $logsToAzureMonitor.Count
                    Message                     = "Some diagnostic settings are configured to send logs to Azure Monitor, but not all."
                }
            }
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

function Test-QuestionB0314 {
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
        # Question: When deploying Microsoft Entra Connect, use a staging server for high availability/disaster recovery.
        # Reference: https://learn.microsoft.com/azure/active-directory/hybrid/how-to-connect-sync-staging-server

        # Get all Azure AD users from cached Graph data or direct Graph call
        $users = $null
        if ($global:GraphData -and $global:GraphData.Users) {
            $users = $global:GraphData.Users
        }
        else {
            # Try direct Graph call if global data not available
            try {
                $users = Get-MgUser -All -ErrorAction Stop
            }
            catch {
                Write-Warning "Failed to retrieve users via Graph API: $($_.Exception.Message)"
            }
        }

        if (-not $users -or $users.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No users found in the tenant to verify emergency access accounts."
        }
        else {
            # Define criteria for break-glass accounts
            $breakGlassAccounts = $users | Where-Object {
                ($_.UserPrincipalName -match "breakglass" -or $_.UserPrincipalName -match "emergency") -and
                $_.AccountEnabled -eq $true -and
                $_.UserType -eq "Member"
            }

            if ($breakGlassAccounts.Count -ge 2) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    BreakGlassAccountsFound = $breakGlassAccounts.Count
                    Accounts                = $breakGlassAccounts | Select-Object DisplayName, UserPrincipalName
                    Message                 = "Sufficient emergency access accounts (at least 2) are configured."
                }
            }
            elseif ($breakGlassAccounts.Count -eq 1) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = 50
                $rawData = @{
                    BreakGlassAccountsFound = $breakGlassAccounts.Count
                    Accounts                = $breakGlassAccounts | Select-Object DisplayName, UserPrincipalName
                    Message                 = "Only 1 emergency access account found. At least 2 are recommended."
                }
            }
            else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = "No emergency access or break-glass accounts configured with name containing 'breakglass' or 'emergency'."
            }
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

function Test-QuestionB0315 {
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
        # Question: Do not use on-premises synced accounts for Microsoft Entra ID role assignments, unless you have a scenario that specifically requires it.
        # Reference: https://learn.microsoft.com/azure/active-directory/hybrid/plan-connect-design-concepts        # Check for Entra Connect configuration through Graph API
        if ($global:GraphConnected -eq $false) {
            Write-Warning "Microsoft Graph is not connected. Cannot assess Entra Connect configuration."
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "Microsoft Graph connection not available for Entra Connect assessment"
            return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
        }        # Try to get directory synchronization information from cached data
        try {
            if ($global:GraphConnected -and $global:GraphData -and $global:GraphData.Organization) {
                $organization = $global:GraphData.Organization
                $dirSyncEnabled = $organization.OnPremisesSyncEnabled
            }
            else {
                $organization = $null
                $dirSyncEnabled = $null
            }
        }
        catch {
            Write-Warning "Could not retrieve organization sync status: $($_.Exception.Message)"
            $dirSyncEnabled = $null
        }

        if ($null -eq $dirSyncEnabled) {
            # Could not determine sync status
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "Could not determine directory synchronization status."
        }
        elseif ($dirSyncEnabled -eq $false) {
            # No directory sync enabled
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "Directory synchronization is not enabled in this environment."
        }
        else {
            # Directory sync is enabled, but we can't check for staging servers with current APIs
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = @{
                DirectorySyncEnabled = $dirSyncEnabled
                Message              = "Directory synchronization is enabled, but detailed sync server configuration cannot be assessed with current API capabilities."
            }
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

function Test-QuestionB0316 {
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
        # Question: When using Microsoft Entra ID Application Proxy to give remote users access to applications, manage it as a Platform resource as you can only have one instance per tenant.
        # Reference: https://learn.microsoft.com/azure/active-directory/app-proxy/what-is-application-proxy

        # Get all role assignments in Microsoft Entra ID
        $roleAssignments = Get-AzRoleAssignment

        if (-not $roleAssignments -or $roleAssignments.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No role assignments found in the environment."
        }
        else {
            # Filter role assignments for on-premises synced accounts
            $syncedAccounts = $roleAssignments | Where-Object {
                $_.SignInName -match "@.*" -and $_.PrincipalType -eq "User" -and $_.SignInName -match "\.onmicrosoft\.com"
            }

            $totalAssignments = $roleAssignments.Count
            $syncedAssignments = $syncedAccounts.Count

            if ($syncedAssignments -eq 0) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = "No on-premises synced accounts are being used for Microsoft Entra ID role assignments."
            }
            elseif ($syncedAssignments -eq $totalAssignments) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalAssignments  = $totalAssignments
                    SyncedAssignments = $syncedAssignments
                    Message           = "All role assignments are using on-premises synced accounts. Avoid this practice unless necessary."
                }
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = (($totalAssignments - $syncedAssignments) / $totalAssignments) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalAssignments     = $totalAssignments
                    SyncedAssignments    = $syncedAssignments
                    NonSyncedAssignments = $totalAssignments - $syncedAssignments
                    Message              = "Some role assignments are using on-premises synced accounts. Review these cases to ensure they are necessary."
                }
            }
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

function Test-QuestionB0317 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Configure Identity network segmentation through the use of a virtual network and peer back to the hub. Providing authentication inside application landing zone (legacy).
        # Reference: https://learn.microsoft.com/azure/active-directory/fundamentals/identity-secure-score

        # Check for Microsoft Entra ID Application Proxy through Graph API
        if ($global:GraphConnected -eq $false) {
            Write-Warning "Microsoft Graph is not connected. Cannot assess Application Proxy configuration."
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "Microsoft Graph connection not available for Application Proxy assessment"
            return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
        }        # Try to get application proxy applications from cached data
        try {
            if ($global:GraphConnected -and $global:GraphData -and $global:GraphData.Applications) {
                $applications = $global:GraphData.Applications | Where-Object { $_.onPremisesPublishing.externalUrl -ne $null }
            }
            else {
                $applications = $null
            }
        }
        catch {
            Write-Warning "Could not retrieve Application Proxy applications: $($_.Exception.Message)"
            $applications = $null
        }

        if (-not $applications -or $applications.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Microsoft Entra ID Application Proxy applications are configured in this tenant."
        }
        else {
            # Application Proxy is in use - recommend managing as platform resource
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = @{
                TotalApplications = $applications.Count
                Message           = "Application Proxy applications found. Verify these are managed as platform resources rather than individual app resources."
                Applications      = $applications | Select-Object DisplayName, AppId | ForEach-Object { $_.DisplayName }
            }
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

function Test-QuestionB0401 {
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
        # Question: Configure Identity network segmentation through the use of a virtual network and peer back to the hub. Providing authentication inside application landing zone (legacy).
        # Reference: https://learn.microsoft.com/azure/architecture/example-scenario/shared-services/hub-spoke

        # Retrieve all VNets from global cached data
        $vnets = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.Network/virtualNetworks"
        }

        if (-not $vnets -or $vnets.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No Virtual Networks (VNets) are configured in this environment."
        }
        else {
            $totalVNets = $vnets.Count

            # Identify VNets for identity purposes by naming conventions and tags
            # Since we're using cached resource data, we need to check for naming patterns and available tag info
            $identityVNets = $vnets | Where-Object {
                $_.Name -like "*identity*" -or $_.Name -like "*id*" -or $_.Name -like "*ad*" -or
                $_.ResourceGroupName -like "*identity*" -or $_.ResourceGroupName -like "*id*" -or $_.ResourceGroupName -like "*ad*"
            }

            # Note: Detailed peering information requires additional API calls that aren't in cached resource data
            # We'll use a simplified assessment based on what we can determine from the resource information
            
            if ($identityVNets.Count -eq 0) {
                # Check for hub-spoke pattern by looking for hub VNets
                $hubVNets = $vnets | Where-Object {
                    $_.Name -like "*hub*" -or $_.Name -like "*core*" -or $_.Name -like "*shared*"
                }
                
                if ($hubVNets.Count -gt 0) {
                    # Hub VNets exist but no clearly identified identity VNets
                    $status = [Status]::PartiallyImplemented
                    $estimatedPercentageApplied = 25
                    $rawData = @{
                        TotalVNets    = $totalVNets
                        HubVNets      = $hubVNets.Count
                        IdentityVNets = 0
                        Message       = "Hub VNets found but no clearly identified identity VNets. Identity services may be integrated within hub or other VNets."
                    }
                }
                else {
                    $status = [Status]::NotImplemented
                    $estimatedPercentageApplied = 0
                    $rawData = "No VNets tagged or named for identity purposes are configured in the environment."
                }
            }
            else {
                # Identity VNets found - check for hub-spoke architecture
                $hubVNets = $vnets | Where-Object {
                    $_.Name -like "*hub*" -or $_.Name -like "*core*" -or $_.Name -like "*shared*"
                }

                if ($hubVNets.Count -gt 0) {
                    # Both identity and hub VNets exist - assume proper segmentation
                    $status = [Status]::Implemented
                    $estimatedPercentageApplied = 90  # High confidence but can't verify actual peering without additional calls
                    $rawData = @{
                        TotalVNets        = $totalVNets
                        IdentityVNets     = $identityVNets.Count
                        HubVNets          = $hubVNets.Count
                        Message           = "Identity VNets and hub VNets found. Network segmentation appears to be implemented."
                        IdentityVNetNames = $identityVNets.Name -join ", "
                        HubVNetNames      = $hubVNets.Name -join ", "
                    }
                }
                else {
                    # Identity VNets exist but no clear hub architecture
                    $status = [Status]::PartiallyImplemented
                    $estimatedPercentageApplied = 60
                    $rawData = @{
                        TotalVNets        = $totalVNets
                        IdentityVNets     = $identityVNets.Count
                        HubVNets          = 0
                        Message           = "Identity VNets found but no clear hub VNet architecture. Consider implementing hub-spoke model."
                        IdentityVNetNames = $identityVNets.Name -join ", "
                    }
                }
            }
        }

        # Calculate the score
        $weight = 5
        $score = ($weight * $estimatedPercentageApplied) / 100
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
        $rawData = @{
            Error        = $_.Exception.Message
            ErrorDetails = "Failed to assess identity network segmentation"
        }
    }

    # Return result object using Set-EvaluationResultObject
    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

function Test-QuestionB0402 {
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
        # Question: Use Azure RBAC to manage data plane access to resources, if possible. E.g., Data Operations across Key Vault, Storage Account and Database Services.
        # Reference: https://learn.microsoft.com/azure/role-based-access-control/role-assignments-data-plane

        # Define the resource types to check for RBAC usage
        $resourceTypes = @("Microsoft.KeyVault/vaults", "Microsoft.Storage/storageAccounts", "Microsoft.Sql/servers")

        # Filter resources by type
        $resources = $global:AzData.Resources | Where-Object {
            $_.ResourceType -in $resourceTypes
        }

        if (-not $resources -or $resources.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No resources of the specified types (Key Vault, Storage Account, Database Services) are configured in this environment."
        }
        else {
            $totalResources = $resources.Count
            $resourcesUsingRBAC = 0

            foreach ($resource in $resources) {
                try {
                    switch ($resource.ResourceType) {
                        "Microsoft.KeyVault/vaults" {
                            # Check if RBAC is enabled for Key Vault
                            $keyVault = Invoke-AzCmdletSafely -ScriptBlock {
                                Get-AzKeyVault -VaultName $resource.Name -ResourceGroupName $resource.ResourceGroupName -ErrorAction Stop
                            } -CmdletName "Get-AzKeyVault" -ModuleName "Az.KeyVault" -WarningMessage "Could not check Key Vault RBAC for $($resource.Name)"
                            
                            if ($keyVault -and $keyVault.EnableRbacAuthorization -eq $true) {
                                $resourcesUsingRBAC++
                            }
                        }
                        "Microsoft.Storage/storageAccounts" {
                            # Check if RBAC is enabled for Storage Account
                            $storageAccount = Invoke-AzCmdletSafely -ScriptBlock {
                                Get-AzStorageAccount -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -ErrorAction Stop
                            } -CmdletName "Get-AzStorageAccount" -ModuleName "Az.Storage" -WarningMessage "Could not check Storage Account RBAC for $($resource.Name)"
                            
                            if ($storageAccount -and ($storageAccount.EnableAzureActiveDirectoryDomainServicesForFile -or 
                                $storageAccount.EnableAzureActiveDirectoryKerberosForFile -or 
                                $storageAccount.EnableHierarchicalNamespace)) {
                                $resourcesUsingRBAC++
                            }
                        }
                        "Microsoft.Sql/servers" {
                            # Check if Azure AD authentication is enabled for SQL
                            $sqlServer = Invoke-AzCmdletSafely -ScriptBlock {
                                Get-AzSqlServer -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.Name -ErrorAction Stop
                            } -CmdletName "Get-AzSqlServer" -ModuleName "Az.Sql" -WarningMessage "Could not check SQL Server for $($resource.Name)"
                            
                            if ($sqlServer) {
                                $adAdmins = Invoke-AzCmdletSafely -ScriptBlock {
                                    Get-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.Name -ErrorAction SilentlyContinue
                                } -CmdletName "Get-AzSqlServerActiveDirectoryAdministrator" -ModuleName "Az.Sql"
                                
                                if ($adAdmins) {
                                    $resourcesUsingRBAC++
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "Error processing resource $($resource.Name): $($_.Exception.Message)"
                }
            }

            # Determine the status based on the count of resources using RBAC
            if ($resourcesUsingRBAC -eq $totalResources) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalResources     = $totalResources
                    ResourcesUsingRBAC = $resourcesUsingRBAC
                    Message            = "All resources of specified types are configured to use Azure RBAC for data plane access."
                }
            }
            elseif ($resourcesUsingRBAC -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalResources     = $totalResources
                    ResourcesUsingRBAC = $resourcesUsingRBAC
                    Message            = "None of the specified resources are configured to use Azure RBAC for data plane access."
                }
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($resourcesUsingRBAC / $totalResources) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalResources       = $totalResources
                    ResourcesUsingRBAC   = $resourcesUsingRBAC
                    ResourcesWithoutRBAC = $totalResources - $resourcesUsingRBAC
                    Message              = "Some resources are configured to use Azure RBAC for data plane access, but not all."
                }
            }
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

function Test-QuestionB0403 {
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
        # Question: Use Microsoft Entra ID PIM access reviews to periodically validate resource entitlements.
        # Reference: https://learn.microsoft.com/azure/active-directory/privileged-identity-management/pim-how-to-start-security-review

        # Check if Microsoft Graph is connected
        if ($global:GraphConnected -eq $false) {
            Write-Warning "Microsoft Graph is not connected. Cannot assess PIM access reviews."
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "Microsoft Graph connection not available for PIM access reviews assessment"
            return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
        }        # Try to get active Access Reviews in PIM from cached data
        try {
            if ($global:GraphConnected -and $global:GraphData -and $global:GraphData.AccessReviews) {
                $accessReviews = $global:GraphData.AccessReviews
            }
            else {
                $accessReviews = $null
            }
        }
        catch {
            Write-Warning "Could not retrieve PIM access reviews: $($_.Exception.Message)"
            $accessReviews = $null
        }

        if (-not $accessReviews -or $accessReviews.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No active access reviews are configured in Microsoft Entra ID PIM."
        }
        else {
            $totalAccessReviews = $accessReviews.Count

            # Filter access reviews related to resource entitlements (Azure AD roles, Groups, or Resources)
            $resourceReviews = $accessReviews | Where-Object {
                $_.ReviewScope -in @("DirectoryRole", "Group", "Resource")
            }

            if ($resourceReviews.Count -eq $totalAccessReviews) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalAccessReviews = $totalAccessReviews
                    ResourceReviews    = $resourceReviews.Count
                    Message            = "All active access reviews are configured for resource entitlements."
                }
            }
            elseif ($resourceReviews.Count -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalAccessReviews = $totalAccessReviews
                    ResourceReviews    = $resourceReviews.Count
                    Message            = "None of the active access reviews are related to resource entitlements."
                }
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($resourceReviews.Count / $totalAccessReviews) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalAccessReviews = $totalAccessReviews
                    ResourceReviews    = $resourceReviews.Count
                    NonResourceReviews = $totalAccessReviews - $resourceReviews.Count
                    Message            = "Some active access reviews are configured for resource entitlements, but not all."
                }
            }
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

function Test-QuestionB0318 {
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
        # Question: When using Microsoft Entra ID Application Proxy to give remote users access to applications, manage it as a Platform resource.
        # Reference: https://learn.microsoft.com/azure/active-directory/app-proxy/what-is-application-proxy

        # Check for Microsoft Entra ID Application Proxy through Graph API
        if ($global:GraphConnected -eq $false) {
            Write-Warning "Microsoft Graph is not connected. Cannot assess Application Proxy configuration."
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "Microsoft Graph connection not available for Application Proxy assessment"
            return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
        }        # Try to get application proxy applications from cached data
        try {
            if ($global:GraphConnected -and $global:GraphData -and $global:GraphData.Applications) {
                $applications = $global:GraphData.Applications | Where-Object { $_.onPremisesPublishing.externalUrl -ne $null }
            }
            else {
                $applications = $null
            }
        }
        catch {
            Write-Warning "Could not retrieve Application Proxy applications: $($_.Exception.Message)"
            $applications = $null
        }

        if (-not $applications -or $applications.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Microsoft Entra ID Application Proxy applications are configured in this tenant."
        }
        else {
            # Application Proxy is in use - recommend managing as platform resource
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = @{
                TotalApplications = $applications.Count
                Message           = "Application Proxy applications found. Verify these are managed as platform resources rather than individual app resources."
                Applications      = $applications | Select-Object DisplayName, AppId | ForEach-Object { $_.DisplayName }
            }
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

function Test-QuestionB0404 {
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
        # Question: Restrict and minimize the number of account owners within the enrollment to limit administrator access to subscriptions and associated Azure resources.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-enterprise-agreement

        # Get billing accounts to check for account owners
        $billingAccounts = Get-AzBillingAccount

        if (-not $billingAccounts -or $billingAccounts.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No billing accounts found in this environment."
        }
        else {
            $totalOwners = 0
            $enrollmentDetails = @()

            foreach ($billingAccount in $billingAccounts) {
                $billingAccountName = $billingAccount.Name
                $billingScope = "/providers/Microsoft.Billing/billingAccounts/$billingAccountName"

                # Get role assignments for the billing account to count account owners
                $roleAssignments = Get-AzRoleAssignment -Scope $billingScope

                # Count Account Owners or Enrollment Administrators
                $accountOwners = $roleAssignments | Where-Object { 
                    $_.RoleDefinitionName -in @("Billing account owner", "Enrollment administrator", "Account owner") 
                }

                $totalOwners += $accountOwners.Count

                $enrollmentDetails += @{
                    BillingAccountName = $billingAccountName
                    AccountType        = $billingAccount.AccountType
                    OwnerCount         = $accountOwners.Count
                    Owners             = $accountOwners | Select-Object DisplayName, SignInName, RoleDefinitionName
                }
            }

            # Define a threshold for "minimal" number of owners (e.g., 3 or fewer per enrollment)
            $maxRecommendedOwnersPerAccount = 3
            $totalAccounts = $billingAccounts.Count
            $accountsWithMinimalOwners = ($enrollmentDetails | Where-Object { $_.OwnerCount -le $maxRecommendedOwnersPerAccount }).Count

            if ($accountsWithMinimalOwners -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalBillingAccounts           = $totalAccounts
                    TotalAccountOwners             = $totalOwners
                    AccountsWithMinimalOwners      = $accountsWithMinimalOwners
                    MaxRecommendedOwnersPerAccount = $maxRecommendedOwnersPerAccount
                    EnrollmentDetails              = $enrollmentDetails
                    Message                        = "All billing accounts have a minimal number of account owners (≤$maxRecommendedOwnersPerAccount per account)."
                }
            }
            elseif ($accountsWithMinimalOwners -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalBillingAccounts           = $totalAccounts
                    TotalAccountOwners             = $totalOwners
                    AccountsWithMinimalOwners      = $accountsWithMinimalOwners
                    MaxRecommendedOwnersPerAccount = $maxRecommendedOwnersPerAccount
                    EnrollmentDetails              = $enrollmentDetails
                    Message                        = "None of the billing accounts have a minimal number of account owners. Consider reducing the number of account owners."
                }
            }
            else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($accountsWithMinimalOwners / $totalAccounts) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalBillingAccounts           = $totalAccounts
                    TotalAccountOwners             = $totalOwners
                    AccountsWithMinimalOwners      = $accountsWithMinimalOwners
                    AccountsWithExcessiveOwners    = $totalAccounts - $accountsWithMinimalOwners
                    MaxRecommendedOwnersPerAccount = $maxRecommendedOwnersPerAccount
                    EnrollmentDetails              = $enrollmentDetails
                    Message                        = "Some billing accounts have a minimal number of account owners, but not all. Consider reducing the number of account owners."
                }
            }
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
