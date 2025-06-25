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
        $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.08") }) | Test-QuestionB0308
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
    $rawData = $null

    try {
        # Question: Microsoft recommends that you use roles with the fewest permissions. Global Administrator is a highly privileged role that should be limited to emergency scenarios when you can't use an existing role.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/identity-access-landing-zones#microsoft-entra-id-recommendations

        # Get all role assignments from Graph
        $roleAssignments = $global:GraphData.RoleAssignments
        $roleDefinitions = $global:GraphData.RoleDefinitions
        
        if (-not $roleAssignments -or $roleAssignments.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No role assignments found in Microsoft Entra ID."
            $estimatedPercentageApplied = 0
        } else {
            # Find Global Administrator role definition
            $globalAdminRole = $roleDefinitions | Where-Object { 
                $_.DisplayName -eq "Global Administrator" -or $_.RoleTemplateId -eq "62e90394-69f5-4237-9190-012177145e10" 
            }
            
            if (-not $globalAdminRole) {
                $status = [Status]::Error
                $rawData = "Could not find Global Administrator role definition."
                $estimatedPercentageApplied = 0
            } else {
                # Count Global Administrator assignments
                $globalAdminAssignments = $roleAssignments | Where-Object { 
                    $_.RoleDefinitionId -eq $globalAdminRole.Id 
                }
                
                $totalRoleAssignments = $roleAssignments.Count
                $globalAdminCount = $globalAdminAssignments.Count
                
                # Microsoft recommends limiting Global Admin to 2-4 accounts maximum
                $recommendedMaxGlobalAdmins = 4
                
                if ($globalAdminCount -eq 0) {
                    $status = [Status]::Error
                    $rawData = "No Global Administrator assignments found. At least one emergency access account should have Global Administrator role."
                    $estimatedPercentageApplied = 0
                } elseif ($globalAdminCount -le $recommendedMaxGlobalAdmins) {
                    # Check if percentage of Global Admin assignments is reasonable (should be low)
                    $globalAdminPercentage = ($globalAdminCount / $totalRoleAssignments) * 100
                    
                    if ($globalAdminPercentage -le 5) {  # Less than 5% of all role assignments should be Global Admin
                        $status = [Status]::Implemented
                        $estimatedPercentageApplied = 100
                        $rawData = "Global Administrator role is appropriately limited with $globalAdminCount assignments out of $totalRoleAssignments total role assignments ($([Math]::Round($globalAdminPercentage, 2))%)."
                    } else {
                        $status = [Status]::PartiallyImplemented
                        $estimatedPercentageApplied = 75
                        $rawData = @{
                            GlobalAdminCount = $globalAdminCount
                            TotalRoleAssignments = $totalRoleAssignments
                            GlobalAdminPercentage = [Math]::Round($globalAdminPercentage, 2)
                            Message = "Global Administrator count is within recommended limits but represents a high percentage of total role assignments."
                            GlobalAdminAssignments = $globalAdminAssignments
                        }
                    }
                } else {
                    $status = [Status]::NotImplemented
                    $estimatedPercentageApplied = 25
                    $rawData = @{
                        GlobalAdminCount = $globalAdminCount
                        RecommendedMax = $recommendedMaxGlobalAdmins
                        TotalRoleAssignments = $totalRoleAssignments
                        Message = "Too many Global Administrator assignments. Microsoft recommends limiting to $recommendedMaxGlobalAdmins or fewer accounts."
                        GlobalAdminAssignments = $globalAdminAssignments
                    }
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

function Test-QuestionB0309 {
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
        # Question: When deploying Active Directory Domain Controllers, use a location with Availability Zones and deploy at least two VMs across these zones. If not available, deploy in an Availability Set.
        # Reference: https://learn.microsoft.com/azure/architecture/reference-architectures/identity/adds-extend-domain#vm-recommendations

        # Get all VMs that could be domain controllers
        $domainControllerVMs = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and (
                $_.Name -like "*dc*" -or $_.Name -like "*domain*" -or 
                $_.ResourceGroupName -like "*identity*" -or $_.ResourceGroupName -like "*ad*"
            )
        }

        if ($domainControllerVMs.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No domain controller VMs found in this environment."
        }
        else {
            $totalDCs = $domainControllerVMs.Count
            $dcsProperlyConfigured = 0

            foreach ($vm in $domainControllerVMs) {
                try {
                    $vmDetails = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -ErrorAction SilentlyContinue
                    
                    if ($vmDetails) {
                        # Check for Availability Zones
                        if ($vmDetails.Zones -and $vmDetails.Zones.Count -gt 0) {
                            $dcsProperlyConfigured++
                        }
                        # Check for Availability Set
                        elseif ($vmDetails.AvailabilitySetReference) {
                            $dcsProperlyConfigured++
                        }
                    }
                }
                catch {
                    Write-Verbose "Could not retrieve details for VM: $($vm.Name)"
                }
            }

            if ($dcsProperlyConfigured -eq $totalDCs -and $totalDCs -ge 2) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalDomainControllers = $totalDCs
                    ProperlyConfiguredDCs = $dcsProperlyConfigured
                    Message = "All domain controllers are properly configured for high availability with Availability Zones or Sets."
                }
            }
            elseif ($dcsProperlyConfigured -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($dcsProperlyConfigured / $totalDCs) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalDomainControllers = $totalDCs
                    ProperlyConfiguredDCs = $dcsProperlyConfigured
                    Message = "Some domain controllers are configured for high availability, but not all."
                }
            }
            else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalDomainControllers = $totalDCs
                    ProperlyConfiguredDCs = $dcsProperlyConfigured
                    Message = "Domain controllers are not configured for high availability with Availability Zones or Sets."
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
        # Question: Deploy your Azure landing zone identity resources in multiple regions. If using domain controllers, associate each region with an Active Directory site so that resources can resolve to their local domain controllers.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/regions#identity

        # Get all identity-related resources (domain controllers, identity VMs)
        $identityResources = $global:AzData.Resources | Where-Object {
            ($_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and (
                $_.Name -like "*dc*" -or $_.Name -like "*domain*" -or $_.Name -like "*identity*"
            )) -or 
            ($_.ResourceGroupName -like "*identity*" -or $_.ResourceGroupName -like "*ad*")
        }

        if ($identityResources.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No identity resources found in this environment."
        }
        else {
            # Get unique regions where identity resources are deployed
            $regionsWithIdentity = $identityResources | Select-Object -ExpandProperty Location -Unique
            $totalRegions = $regionsWithIdentity.Count

            if ($totalRegions -eq 1) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 25
                $rawData = @{
                    TotalIdentityResources = $identityResources.Count
                    RegionsWithIdentity = $regionsWithIdentity
                    Message = "Identity resources are deployed in only one region. Consider deploying in multiple regions for better resilience."
                }
            }
            elseif ($totalRegions -eq 2) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = 75
                $rawData = @{
                    TotalIdentityResources = $identityResources.Count
                    RegionsWithIdentity = $regionsWithIdentity
                    Message = "Identity resources are deployed in two regions, which provides good resilience."
                }
            }
            else {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalIdentityResources = $identityResources.Count
                    RegionsWithIdentity = $regionsWithIdentity
                    Message = "Identity resources are deployed across multiple regions, providing excellent resilience."
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

function Test-QuestionB0311 {
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
        # Question: Use Azure custom RBAC roles for the following key roles to provide fine-grain access across your ALZ: Azure platform owner, network management, security operations, subscription owner, application owner. Align these roles to teams and responsibilities within your business.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/identity-access#prerequisites-for-a-landing-zone---design-recommendations

        # Get all custom role definitions
        $customRoles = Get-AzRoleDefinition | Where-Object { $_.IsCustom -eq $true }

        if ($customRoles.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No custom RBAC roles are defined in this environment."
        }
        else {
            # Define key roles that should be present for ALZ
            $recommendedRoleTypes = @(
                "platform", "network", "security", "subscription", "application", "owner", "admin"
            )

            $alignedRoles = 0
            $roleAnalysis = @()

            foreach ($role in $customRoles) {
                $isAligned = $false
                foreach ($roleType in $recommendedRoleTypes) {
                    if ($role.Name -like "*$roleType*" -or $role.Description -like "*$roleType*") {
                        $isAligned = $true
                        break
                    }
                }
                
                if ($isAligned) {
                    $alignedRoles++
                }

                $roleAnalysis += @{
                    RoleName = $role.Name
                    IsAligned = $isAligned
                    Description = $role.Description
                }
            }

            $alignmentPercentage = ($alignedRoles / $customRoles.Count) * 100

            if ($alignmentPercentage -eq 100 -and $customRoles.Count -ge 3) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalCustomRoles = $customRoles.Count
                    AlignedRoles = $alignedRoles
                    AlignmentPercentage = [Math]::Round($alignmentPercentage, 2)
                    Message = "Custom RBAC roles are well-aligned with Azure Landing Zone recommendations."
                    RoleAnalysis = $roleAnalysis
                }
            }
            elseif ($alignedRoles -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round($alignmentPercentage, 2)
                $rawData = @{
                    TotalCustomRoles = $customRoles.Count
                    AlignedRoles = $alignedRoles
                    AlignmentPercentage = [Math]::Round($alignmentPercentage, 2)
                    Message = "Some custom RBAC roles are aligned with ALZ recommendations, but more could be defined."
                    RoleAnalysis = $roleAnalysis
                }
            }
            else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 25
                $rawData = @{
                    TotalCustomRoles = $customRoles.Count
                    AlignedRoles = $alignedRoles
                    AlignmentPercentage = [Math]::Round($alignmentPercentage, 2)
                    Message = "Custom RBAC roles exist but are not aligned with Azure Landing Zone key role recommendations."
                    RoleAnalysis = $roleAnalysis
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
        # Question: If planning to switch from Active Directory Domain Services to Entra domain services, evaluate the compatibility of all workloads.
        # Reference: https://learn.microsoft.com/entra/identity/domain-services/overview

        # Check for Entra Domain Services and on-premises domain controllers
        $entraDomainServices = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.AAD/DomainServices"
        }

        $onPremisesDCs = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and (
                $_.Name -like "*dc*" -or $_.Name -like "*domain*"
            )
        }

        if ($entraDomainServices.Count -eq 0 -and $onPremisesDCs.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Entra Domain Services or on-premises domain controllers found."
        }
        elseif ($entraDomainServices.Count -gt 0 -and $onPremisesDCs.Count -eq 0) {
            # Only Entra Domain Services - assume migration completed
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                EntraDomainServices = $entraDomainServices.Count
                OnPremisesDCs = $onPremisesDCs.Count
                Message = "Entra Domain Services is deployed. If this was a migration from AD DS, workload compatibility should have been evaluated."
            }
        }
        elseif ($entraDomainServices.Count -eq 0 -and $onPremisesDCs.Count -gt 0) {
            # Only on-premises DCs - no migration planned or in progress
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = @{
                EntraDomainServices = $entraDomainServices.Count
                OnPremisesDCs = $onPremisesDCs.Count
                Message = "Only on-premises domain controllers found. No Entra Domain Services migration detected."
            }
        }
        else {
            # Both exist - migration in progress or hybrid setup
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 50
            $rawData = @{
                EntraDomainServices = $entraDomainServices.Count
                OnPremisesDCs = $onPremisesDCs.Count
                Message = "Both Entra Domain Services and on-premises domain controllers detected. Ensure workload compatibility has been evaluated for any migration."
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
        # Question: When using Microsoft Entra Domain Services, use replica sets. Replica sets will improve the resiliency of your managed domain and allow you to deploy to additional regions.
        # Reference: https://learn.microsoft.com/entra/identity/domain-services/overview

        # Check for Entra Domain Services
        $entraDomainServices = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.AAD/DomainServices"
        }

        if ($entraDomainServices.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Microsoft Entra Domain Services found in this environment."
        }
        else {
            $totalDomainServices = $entraDomainServices.Count
            $servicesWithReplicaSets = 0

            foreach ($domainService in $entraDomainServices) {
                try {
                    # For detailed replica set information, we would need to call the specific API
                    # Since we're using cached data, we'll assess based on the presence of centralized logging infrastructure
                    if ($domainService.Peerings -and $domainService.Peerings.Count -gt 0) {
                        $servicesWithReplicaSets++
                    }
                }
                catch {
                    Write-Verbose "Could not analyze replica sets for domain service: $($domainService.Name)"
                }
            }

            if ($servicesWithReplicaSets -eq $totalDomainServices) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalDomainServices = $totalDomainServices
                    ServicesWithReplicaSets = $servicesWithReplicaSets
                    Message = "All Entra Domain Services appear to have replica sets configured for improved resiliency."
                }
            }
            elseif ($servicesWithReplicaSets -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($servicesWithReplicaSets / $totalDomainServices) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalDomainServices = $totalDomainServices
                    ServicesWithReplicaSets = $servicesWithReplicaSets
                    Message = "Some Entra Domain Services have replica sets, but not all."
                }
            }
            else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalDomainServices = $totalDomainServices
                    ServicesWithReplicaSets = $servicesWithReplicaSets
                    Message = "Entra Domain Services found but no replica sets detected. Consider configuring replica sets for improved resiliency."
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
        # Question: Integrate Microsoft Entra ID logs with the platform-central Azure Monitor. Azure Monitor allows for a single source of truth around log and monitoring data in Azure, giving organizations a cloud native options to meet requirements around log collection and retention.
        # Reference: https://learn.microsoft.com/azure/active-directory/reports-monitoring/concept-activity-logs-azure-monitor

        # Check if Graph connection is available for Microsoft Entra ID logs
        if ($global:GraphConnected -eq $false) {
            Write-Warning "Microsoft Graph is not connected. Cannot assess Entra ID log integration."
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "Microsoft Graph connection not available for Entra ID log assessment"
            return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
        }

        # Check for Log Analytics workspaces
        $logAnalyticsWorkspaces = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.OperationalInsights/workspaces"
        }

        # Check for diagnostic settings on Azure resources
        $resourcesWithDiagnostics = $global:AzData.Resources | Where-Object {
            # Look for resources that typically have diagnostic settings configured
            $_.ResourceType -in @(
                "Microsoft.Storage/storageAccounts",
                "Microsoft.KeyVault/vaults",
                "Microsoft.Network/virtualNetworks",
                "Microsoft.Compute/virtualMachines"
            )
        }

        if ($logAnalyticsWorkspaces.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No Log Analytics workspaces found for centralized logging."
        }
        else {
            $totalWorkspaces = $logAnalyticsWorkspaces.Count
            
            # Since we can't directly check Entra ID diagnostic settings from cached resource data,
            # we'll assess based on the presence of centralized logging infrastructure
            if ($totalWorkspaces -ge 1) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = 75
                $rawData = @{
                    LogAnalyticsWorkspaces = $totalWorkspaces
                    ResourcesMonitored = $resourcesWithDiagnostics.Count
                    Message = "Log Analytics workspaces are available for centralized logging. Verify that Entra ID logs are integrated with Azure Monitor."
                }
            }
            else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 25
                $rawData = @{
                    LogAnalyticsWorkspaces = $totalWorkspaces
                    ResourcesMonitored = $resourcesWithDiagnostics.Count
                    Message = "Limited centralized logging infrastructure. Consider integrating Entra ID logs with Azure Monitor."
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
        # Question: Implement an emergency access or break-glass accounts to prevent tenant-wide account lockout. MFA will be turned on by default for all users in Oct 2024. We recommend updating these accounts to use passkey (FIDO2) or configure certificate-based authentication for MFA.
        # Reference: https://learn.microsoft.com/azure/active-directory/roles/security-emergency-access

        # Check if Graph connection is available
        if ($global:GraphConnected -eq $false) {
            Write-Warning "Microsoft Graph is not connected. Cannot assess emergency access accounts."
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "Microsoft Graph connection not available for emergency access account assessment"
            return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
        }

        # Get users from cached data
        if ($global:GraphData -and $global:GraphData.Users) {
            $users = $global:GraphData.Users
        }
        else {
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "User data not available for emergency access account assessment"
            return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
        }

        # Look for potential emergency access accounts
        $emergencyAccounts = $users | Where-Object {
            $_.DisplayName -like "*emergency*" -or 
            $_.DisplayName -like "*break*glass*" -or 
            $_.DisplayName -like "*breakglass*" -or
            $_.UserPrincipalName -like "*emergency*" -or
            $_.UserPrincipalName -like "*break*glass*" -or
            $_.UserPrincipalName -like "*breakglass*"
        }

        # Get Global Admin role assignments
        $globalAdminRole = $global:GraphData.RoleDefinitions | Where-Object { 
            $_.DisplayName -eq "Global Administrator" 
        }

        $globalAdminAssignments = @()
        if ($globalAdminRole -and $global:GraphData.RoleAssignments) {
            $globalAdminAssignments = $global:GraphData.RoleAssignments | Where-Object { 
                $_.RoleDefinitionId -eq $globalAdminRole.Id 
            }
        }

        if ($emergencyAccounts.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = @{
                EmergencyAccounts = 0
                GlobalAdminAccounts = $globalAdminAssignments.Count
                Message = "No emergency access (break-glass) accounts found. Consider implementing emergency access accounts to prevent tenant lockout."
            }
        }
        elseif ($emergencyAccounts.Count -eq 1) {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = 50
            $rawData = @{
                EmergencyAccounts = $emergencyAccounts.Count
                GlobalAdminAccounts = $globalAdminAssignments.Count
                Message = "One emergency access account found. Microsoft recommends having at least two emergency access accounts."
                EmergencyAccountNames = $emergencyAccounts.DisplayName
            }
        }
        else {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                EmergencyAccounts = $emergencyAccounts.Count
                GlobalAdminAccounts = $globalAdminAssignments.Count
                Message = "Multiple emergency access accounts found. Ensure they use strong authentication methods like FIDO2 or certificate-based authentication."
                EmergencyAccountNames = $emergencyAccounts.DisplayName
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
        # Question: When deploying Microsoft Entra Connect, use a staging server for high availability/disaster recovery.
        # Reference: https://learn.microsoft.com/azure/active-directory/hybrid/how-to-connect-sync-staging-server

        # Look for VMs that might be running Entra Connect (formerly Azure AD Connect)
        $entraConnectServers = $global:AzData.Resources | Where-Object {
            $_.ResourceType -eq "Microsoft.Compute/virtualMachines" -and (
                $_.Name -like "*connect*" -or 
                $_.Name -like "*sync*" -or 
                $_.Name -like "*aad*" -or
                $_.Name -like "*entra*"
            )
        }

        if ($entraConnectServers.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Entra Connect servers found in this environment."
        }
        elseif ($entraConnectServers.Count -eq 1) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 25
            $rawData = @{
                EntraConnectServers = $entraConnectServers.Count
                ServerNames = $entraConnectServers.Name
                Message = "Only one Entra Connect server found. Consider deploying a staging server for high availability."
            }
        }
        else {
            # Multiple servers found - assume staging server is configured
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                EntraConnectServers = $entraConnectServers.Count
                ServerNames = $entraConnectServers.Name
                Message = "Multiple Entra Connect servers found, suggesting staging server configuration for high availability."
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
    $rawData = $null

    try {
        # Question: Do not use on-premises synced accounts for Microsoft Entra ID role assignments, unless you have a scenario that specifically requires it.
        # Reference: https://learn.microsoft.com/azure/active-directory/roles/best-practices

        # Check if Graph connection is available
        if ($global:GraphConnected -eq $false) {
            Write-Warning "Microsoft Graph is not connected. Cannot assess synced account role assignments."
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "Microsoft Graph connection not available for synced account assessment"
            return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
        }

        # Get role assignments and users from cached data
        if (-not $global:GraphData.RoleAssignments -or -not $global:GraphData.Users) {
            $status = [Status]::Unknown
            $estimatedPercentageApplied = 0
            $rawData = "Role assignment or user data not available for assessment"
            return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
        }

        $roleAssignments = $global:GraphData.RoleAssignments
        $users = $global:GraphData.Users

        $totalRoleAssignments = $roleAssignments.Count
        $syncedAccountAssignments = 0
        $cloudOnlyAccountAssignments = 0

        foreach ($assignment in $roleAssignments) {
            # Find the user for this assignment
            $user = $users | Where-Object { $_.Id -eq $assignment.PrincipalId }
            
            if ($user) {
                # Check if the user is synced from on-premises
                # OnPremisesSyncEnabled indicates if the account is synced
                if ($user.OnPremisesSyncEnabled -eq $true) {
                    $syncedAccountAssignments++
                }
                else {
                    $cloudOnlyAccountAssignments++
                }
            }
        }

        if ($totalRoleAssignments -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No role assignments found."
        }
        elseif ($syncedAccountAssignments -eq 0) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                TotalRoleAssignments = $totalRoleAssignments
                SyncedAccountAssignments = $syncedAccountAssignments
                CloudOnlyAccountAssignments = $cloudOnlyAccountAssignments
                Message = "All role assignments are to cloud-only accounts. No on-premises synced accounts have role assignments."
            }
        }
        else {
            $syncedPercentage = ($syncedAccountAssignments / $totalRoleAssignments) * 100
            
            if ($syncedPercentage -le 10) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = 75
                $rawData = @{
                    TotalRoleAssignments = $totalRoleAssignments
                    SyncedAccountAssignments = $syncedAccountAssignments
                    CloudOnlyAccountAssignments = $cloudOnlyAccountAssignments
                    SyncedAccountPercentage = [Math]::Round($syncedPercentage, 2)
                    Message = "Low percentage of synced accounts have role assignments. Review if these assignments are necessary."
                }
            }
            else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 25
                $rawData = @{
                    TotalRoleAssignments = $totalRoleAssignments
                    SyncedAccountAssignments = $syncedAccountAssignments
                    CloudOnlyAccountAssignments = $cloudOnlyAccountAssignments
                    SyncedAccountPercentage = [Math]::Round($syncedPercentage, 2)
                    Message = "Significant number of on-premises synced accounts have role assignments. Consider using cloud-only accounts unless specifically required."
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
                $applications = $global:GraphData.Applications | Where-Object { $null -ne $_.onPremisesPublishing.externalUrl }
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