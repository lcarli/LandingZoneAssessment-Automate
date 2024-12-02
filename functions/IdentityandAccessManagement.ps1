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

    Write-Host "Evaluating the Identity and Access Management design area..."
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {

        # Enforce a RBAC model that aligns to your cloud operating model. Scope and Assign across Management Groups and Subscriptions.
        # Reference: https://learn.microsoft.com/azure/role-based-access-control/overview

        # Get management groups
        $managementGroups = Get-AzManagementGroup | Where-Object { $_.TenantId -eq $TenantId }
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
        } else {
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
        } else {
            100
        }

        # Calculate overall percentage
        $estimatedPercentageApplied = [Math]::Round(($mgmtGroupPercentage + $subscriptionPercentage) / 2, 2)

        # Determine status
        if ($estimatedPercentageApplied -eq 100) {
            $status = [Status]::Implemented
        } elseif ($estimatedPercentageApplied -eq 0) {
            $status = [Status]::NotImplemented
        } else {
            $status = [Status]::PartiallyImplemented
        }

        $score = ($weight * $estimatedPercentageApplied) / 100

        $rawData = @{
            ManagementGroups = @{
                Total       = $totalGroups
                Configured  = $configuredGroups
                Percentage  = $mgmtGroupPercentage
            }
            Subscriptions = @{
                Total       = $totalSubscriptions
                Configured  = $configuredSubscriptions
                Percentage  = $subscriptionPercentage
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Use managed identities instead of service principals for authentication to Azure services.
        # Reference: https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview
        
        # Get all service principals
        $servicePrincipals = Get-AzADServicePrincipal

        if ($servicePrincipals.Count -eq 0) {
            # No service principals found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
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
            } elseif ($managedIdentities -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
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
    } catch {
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Only use the authentication type Work or school account for all account types. Avoid using the Microsoft account.
        # Reference: https://learn.microsoft.com/learn/modules/explore-basic-services-identity-types/

        # Get all Azure AD users
        $users = Get-AzADUser

        if ($users.Count -eq 0) {
            # No users found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
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
            } elseif ($validWorkOrSchoolAccounts -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
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
    } catch {
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

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
        } else {
            $totalAssignments = 0
            $groupAssignments = 0

            # Loop through each subscription
            foreach ($subscription in $subscriptions) {
                $subscriptionId = $subscription.Id

                # Set the context to the current subscription
                Set-AzContext -SubscriptionId $subscriptionId -TenantId $TenantId

                Write-Host "Checking role assignments for Subscription ID: $subscriptionId"

                # Get all role assignments for the current subscription
                $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$subscriptionId"

                # Count total role assignments in this subscription
                $totalAssignments += $roleAssignments.Count

                # Loop through each role assignment and check if it's assigned to a group
                foreach ($assignment in $roleAssignments) {
                    if ($assignment.PrincipalType -eq "Group") {
                        $groupAssignments++
                    }
                }
            }

            # Calculate the percentage of group-based assignments
            if ($totalAssignments -eq 0) {
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
            } elseif ($groupAssignments -eq $totalAssignments) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($groupAssignments -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
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
    } catch {
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Enforce Microsoft Entra ID Conditional Access policies for any user with rights to Azure environments.
        # Reference: https://learn.microsoft.com/azure/active-directory/conditional-access/overview


        # Connect to Microsoft Graph
        Connect-MgGraph -Scopes "Policy.Read.All", "Directory.Read.All" -TenantId $TenantId

        # Get all role assignments for Azure resources
        $roleAssignments = Get-AzRoleAssignment

        if ($roleAssignments.Count -eq 0) {
            # No role assignments found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalAssignments = $roleAssignments.Count
            $usersCoveredByPolicies = 0
            $uniqueUsers = @()

            # Get all Conditional Access policies
            $conditionalAccessPolicies = Get-MgConditionalAccessPolicy

            # Store unique user principal names from role assignments
            foreach ($assignment in $roleAssignments) {
                if ($assignment.PrincipalType -eq "User") {
                    $uniqueUsers += $assignment.PrincipalName
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
            } elseif ($usersCoveredByPolicies -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($usersCoveredByPolicies / $uniqueUsers.Count) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            TotalAssignments         = $totalAssignments
            UniqueUsers              = $uniqueUsers
            UsersCoveredByPolicies   = $usersCoveredByPolicies
            ConditionalAccessPolicies = $conditionalAccessPolicies
        }
    } catch {
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

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
        } else {
            $totalAssignments = $roleAssignments.Count
            $usersWithMFA = 0
            $uniqueUsers = @()

            # Store unique user principal IDs from role assignments
            foreach ($assignment in $roleAssignments) {
                if ($assignment.ObjectType -eq "User") {
                    $uniqueUsers += $assignment.ObjectId  # Use ObjectId to check MFA methods
                }
            }

            $uniqueUsers = $uniqueUsers | Sort-Object -Unique

            # Iterate through each user and check if MFA is enabled
            foreach ($userId in $uniqueUsers) {
                $isMFAEnabled = $false

                try {
                    # Check MFA methods for the user
                    $mfaMethods = Get-MgUserAuthenticationMethod -UserId $userId

                    if ($mfaMethods.Count -gt 0) {
                        $isMFAEnabled = $true
                    }
                }
                catch {
                    Write-Host "Failed to get MFA methods for user: $userId" -ForegroundColor Yellow
                }

                # Check if Conditional Access policy enforcing MFA exists for the user
                if (-not $isMFAEnabled) {
                    $conditionalAccessPolicies = Get-MgConditionalAccessPolicy
                    foreach ($policy in $conditionalAccessPolicies) {
                        if (($policy.Conditions.Users.IncludeUsers -contains $userId) -and ($policy.GrantControls.BuiltInControls -contains "mfa")) {
                            $isMFAEnabled = $true
                            break
                        }
                    }
                }

                if ($isMFAEnabled) {
                    $usersWithMFA++
                }
            }

            # Calculate the percentage of users with MFA enabled
            if ($usersWithMFA -eq $uniqueUsers.Count) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($usersWithMFA -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
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
    } catch {
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Enforce centralized and delegated responsibilities to manage resources deployed inside the landing zone, based on role and security requirements.
        # Reference: https://learn.microsoft.com/azure/role-based-access-control/overview


        # Assess role assignments across management groups
        $managementGroups = Get-AzManagementGroup | Where-Object { $_.TenantId -eq $TenantId }
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
                } elseif ($roleAssignment.RoleDefinitionName -in @("Contributor", "Reader")) {
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
        } else {
            $mgmtGroupPercentage = 100
            $delegationPercentage = 100
        }

        # Combine the results to determine the overall applied percentage
        $estimatedPercentageApplied = [Math]::Round(($mgmtGroupPercentage + $delegationPercentage) / 2, 2)

        # Determine status
        if ($estimatedPercentageApplied -eq 100) {
            $status = [Status]::Implemented
        } elseif ($estimatedPercentageApplied -eq 0) {
            $status = [Status]::NotImplemented
        } else {
            $status = [Status]::PartiallyImplemented
        }

        # Calculate score based on the weight and the percentage applied
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            TotalGroups          = $totalGroups
            ConfiguredGroups     = $configuredGroups
            DelegatedGroups      = $delegatedGroups
            ManagementGroupPercentage = $mgmtGroupPercentage
            DelegationPercentage = $delegationPercentage
        }
    } catch {
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: Enforce Microsoft Entra ID Privileged Identity Management (PIM) to establish zero standing access and least privilege.
        # Reference: https://learn.microsoft.com/azure/active-directory/privileged-identity-management/pim-configure


        # Connect to Microsoft Graph with appropriate scopes for PIM
        Connect-MgGraph -Scopes "PrivilegedAccess.Read.AzureAD" -TenantId $TenantId

        # Get all PIM roles and check for standing access
        $pimRoles = Get-MgPrivilegedRoleAssignment | Where-Object { $_.RoleDefinitionName -in @("Global Administrator", "Privileged Role Administrator", "Security Administrator") }

        if ($pimRoles.Count -eq 0) {
            # No privileged roles found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
        } else {
            $totalRoles = $pimRoles.Count
            $rolesWithNoStandingAccess = 0

            foreach ($role in $pimRoles) {
                # Check if the role assignment is configured for Just-In-Time (JIT) access
                if ($role.IsElevated -eq $false) {
                    $rolesWithNoStandingAccess++
                }
            }

            # Calculate the percentage of roles with no standing access
            if ($rolesWithNoStandingAccess -eq $totalRoles) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($rolesWithNoStandingAccess -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($rolesWithNoStandingAccess / $totalRoles) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            TotalRoles                = $totalRoles
            RolesWithNoStandingAccess = $rolesWithNoStandingAccess
            PrivilegedRoles           = $pimRoles
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0
    $rawData = $null

    try {
        # Question: When deploying Active Directory Domain Controllers, use a location with Availability Zones and deploy at least two VMs across these zones. If not available, deploy in an Availability Set.
        # Reference: https://learn.microsoft.com/azure/virtual-machines/availability


        # Check if Availability Zones are available
        $location = "YourLocation" # Replace "YourLocation" with the relevant Azure region
        $availabilityZones = Get-AzAvailabilityZone -Location $location

        if ($availabilityZones.Count -gt 1) {
            # Check if at least two VMs are deployed across Availability Zones
            $vmCount = 0
            $vms = Get-AzVM

            foreach ($vm in $vms) {
                if ($vm.AvailabilityZone) {
                    $vmCount++
                }
            }

            if ($vmCount -ge 2) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
        } else {
            # If no Availability Zones, check for Availability Set
            $availabilitySets = Get-AzAvailabilitySet

            if ($availabilitySets.Count -gt 0) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

        # Prepare raw data
        $rawData = @{
            Location              = $location
            AvailabilityZones     = $availabilityZones.Count
            VirtualMachinesInZones = $vmCount
            AvailabilitySets      = $availabilitySets.Count
        }
    } catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
        $rawData = $_.Exception.Message
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

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
        } elseif ($rolesFound -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        } else {
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
    } catch {
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
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
            } else {
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
        } elseif ($rolesFound -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = @{
                MissingRoles = $missingRoles
                Message      = "None of the required custom roles are implemented."
            }
        } else {
            $status = [Status]::PartiallyImplemented
            $estimatedPercentageApplied = ($rolesFound / $totalRequiredRoles) * 100
            $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
            $rawData = @{
                TotalRequiredRoles = $totalRequiredRoles
                RolesMatched        = $rolesMatched
                MissingRoles        = $missingRoles
                Message             = "Some required custom roles are missing."
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

function Test-QuestionB0311 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = "This question requires manual verification to evaluate the compatibility of all workloads when planning to switch from Active Directory Domain Services (AD DS) to Entra Domain Services (ED DS)."

    try {
        # Question: When using Microsoft Entra Domain Services use replica sets. Replica sets will improve the resiliency of your managed domain and allow you to deploy to additional regions.
        # Reference: https://learn.microsoft.com/azure/active-directory-domain-services/replica-sets

        # No automated logic is implemented here
        $status = [Status]::ManualVerificationRequired
    } catch {
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Integrate Microsoft Entra ID logs with the platform-central Azure Monitor. Azure Monitor allows for a single source of truth around log and monitoring data in Azure, giving organizations a cloud native option to meet requirements around log collection and retention.
        # Reference: https://learn.microsoft.com/azure/active-directory/reports-monitoring/howto-integrate-activity-logs-with-log-analytics

        # Get all Entra Domain Services configurations
        $entraDomains = Get-AzADDomainService

        if (-not $entraDomains -or $entraDomains.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Entra Domain Services (ED DS) configurations found in the current environment."
        } else {
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
            } elseif ($domainsWithReplicaSets -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = "No Entra Domain Services domains have replica sets configured."
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($domainsWithReplicaSets / $totalDomains) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalDomains         = $totalDomains
                    DomainsWithReplicaSets = $domainsWithReplicaSets
                    DomainsWithoutReplicaSets = $totalDomains - $domainsWithReplicaSets
                    Message              = "Some Entra Domain Services domains are missing replica sets."
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

function Test-QuestionB0313 {
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
        # Question: Implement an emergency access or break-glass account to prevent tenant-wide account lockout.
        # Reference: https://learn.microsoft.com/azure/active-directory/roles/security-emergency-access

        # Get Diagnostic Settings for Microsoft Entra ID
        $diagnosticSettings = Get-AzDiagnosticSetting -ResourceId "/providers/microsoft.aadiam/diagnosticSettings"

        if (-not $diagnosticSettings -or $diagnosticSettings.Count -eq 0) {
            # No diagnostic settings found
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No diagnostic settings are configured for Microsoft Entra ID."
        } else {
            $logsToAzureMonitor = $diagnosticSettings | Where-Object {
                $_.WorkspaceId -ne $null -and $_.Logs | Where-Object { $_.Enabled -eq $true }
            }

            if ($logsToAzureMonitor.Count -eq $diagnosticSettings.Count) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = "All diagnostic settings for Microsoft Entra ID are configured to send logs to Azure Monitor."
            } elseif ($logsToAzureMonitor.Count -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = "None of the diagnostic settings for Microsoft Entra ID are configured to send logs to Azure Monitor."
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($logsToAzureMonitor.Count / $diagnosticSettings.Count) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalSettings          = $diagnosticSettings.Count
                    SettingsWithAzureMonitor = $logsToAzureMonitor.Count
                    SettingsWithoutAzureMonitor = $diagnosticSettings.Count - $logsToAzureMonitor.Count
                    Message               = "Some diagnostic settings are configured to send logs to Azure Monitor, but not all."
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

function Test-QuestionB0314 {
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
        # Question: When deploying Microsoft Entra Connect, use a staging server for high availability/disaster recovery.
        # Reference: https://learn.microsoft.com/azure/active-directory/hybrid/how-to-connect-sync-staging-server

        # Get all Azure AD users
        $users = Get-AzADUser

        if (-not $users -or $users.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No users found in the tenant to verify emergency access accounts."
        } else {
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
            } elseif ($breakGlassAccounts.Count -eq 1) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = 50
                $rawData = @{
                    BreakGlassAccountsFound = $breakGlassAccounts.Count
                    Accounts                = $breakGlassAccounts | Select-Object DisplayName, UserPrincipalName
                    Message                 = "Only 1 emergency access account found. At least 2 are recommended."
                }
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = "No emergency access or break-glass accounts configured with name containing 'breakglass' or 'emergency'."
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

function Test-QuestionB0315 {
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
        # Question: Do not use on-premises synced accounts for Microsoft Entra ID role assignments, unless you have a scenario that specifically requires it.
        # Reference: https://learn.microsoft.com/azure/active-directory/hybrid/plan-connect-design-concepts

        # Get all Entra Connect servers
        $connectServers = Get-AzADConnectSyncServer

        if (-not $connectServers -or $connectServers.Count -eq 0) {
            # No Entra Connect servers found
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Microsoft Entra Connect servers are configured in this environment."
        } else {
            # Check for staging servers
            $stagingServers = $connectServers | Where-Object { $_.StagingModeEnabled -eq $true }
            $totalServers = $connectServers.Count
            $stagingServerCount = $stagingServers.Count

            if ($stagingServerCount -ge 1) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalServers       = $totalServers
                    StagingServers     = $stagingServerCount
                    StagingServerDetails = $stagingServers | Select-Object DisplayName, StagingModeEnabled, LastSyncTime
                    Message            = "At least one staging server is configured for high availability/disaster recovery."
                }
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalServers   = $totalServers
                    StagingServers = $stagingServerCount
                    Message        = "No staging servers are configured. Consider adding one for high availability/disaster recovery."
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

function Test-QuestionB0316 {
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
        # Question: When using Microsoft Entra ID Application Proxy to give remote users access to applications, manage it as a Platform resource as you can only have one instance per tenant.
        # Reference: https://learn.microsoft.com/azure/active-directory/app-proxy/what-is-application-proxy

        # Get all role assignments in Microsoft Entra ID
        $roleAssignments = Get-AzRoleAssignment

        if (-not $roleAssignments -or $roleAssignments.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No role assignments found in the environment."
        } else {
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
            } elseif ($syncedAssignments -eq $totalAssignments) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalAssignments = $totalAssignments
                    SyncedAssignments = $syncedAssignments
                    Message = "All role assignments are using on-premises synced accounts. Avoid this practice unless necessary."
                }
            } else {
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
    } catch {
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

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Configure Identity network segmentation through the use of a virtual network and peer back to the hub. Providing authentication inside application landing zone (legacy).
        # Reference: https://learn.microsoft.com/azure/active-directory/fundamentals/identity-secure-score

        # Check for Microsoft Entra ID Application Proxy connectors
        $appProxyConnectors = Get-AzADApplicationProxyConnectorGroup

        if (-not $appProxyConnectors -or $appProxyConnectors.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No Microsoft Entra ID Application Proxy connectors are configured in this tenant."
        } else {
            # Ensure the Application Proxy is managed as a platform resource
            $managedAsPlatform = $appProxyConnectors | Where-Object {
                $_.DisplayName -match "Platform" -or $_.Tags -contains "PlatformResource"
            }

            if ($managedAsPlatform.Count -eq $appProxyConnectors.Count) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalConnectors       = $appProxyConnectors.Count
                    ManagedAsPlatform     = $managedAsPlatform.Count
                    ConnectorDetails      = $appProxyConnectors | Select-Object DisplayName, ConnectorGroupType, Tags
                    Message               = "All Microsoft Entra ID Application Proxy connectors are managed as platform resources."
                }
            } elseif ($managedAsPlatform.Count -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalConnectors   = $appProxyConnectors.Count
                    ManagedAsPlatform = $managedAsPlatform.Count
                    Message           = "No Microsoft Entra ID Application Proxy connectors are managed as platform resources. Consider tagging them appropriately. We recommend using 'PlatformResource' tag."
                }
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($managedAsPlatform.Count / $appProxyConnectors.Count) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalConnectors       = $appProxyConnectors.Count
                    ManagedAsPlatform     = $managedAsPlatform.Count
                    NotManagedAsPlatform  = $appProxyConnectors.Count - $managedAsPlatform.Count
                    Message               = "Some Application Proxy connectors are managed as platform resources, but not all."
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

function Test-QuestionB0401 {
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
        # Question: Configure Identity network segmentation through the use of a virtual network and peer back to the hub. Providing authentication inside application landing zone (legacy).
        # Reference: https://learn.microsoft.com/azure/architecture/example-scenario/shared-services/hub-spoke

        # Retrieve all VNets in the environment
        $vnets = Get-AzVirtualNetwork

        if (-not $vnets -or $vnets.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No Virtual Networks (VNets) are configured in this environment."
        } else {
            $totalVNets = $vnets.Count

            # Identify VNets tagged for identity purposes by checking all tags
            $identityVNets = $vnets | Where-Object {
                $_.Tags.Values -match "identity"
            }

            $peeredVNets = 0

            foreach ($vnet in $identityVNets) {
                # Check if the VNet is peered to a hub network
                $peerings = Get-AzVirtualNetworkPeering -ResourceGroupName $vnet.ResourceGroupName -VirtualNetworkName $vnet.Name
                if ($peerings | Where-Object { $_.RemoteVirtualNetwork.Id -match "hub" -and $_.PeeringState -eq "Connected" }) {
                    $peeredVNets++
                }
            }

            if ($identityVNets.Count -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = "No VNets tagged for identity purposes are configured in the environment."
            } elseif ($peeredVNets -eq $identityVNets.Count) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalVNets        = $totalVNets
                    IdentityVNets     = $identityVNets.Count
                    PeeredVNets       = $peeredVNets
                    Message           = "All identity VNets are peered to the hub network."
                }
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($peeredVNets / $identityVNets.Count) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalVNets        = $totalVNets
                    IdentityVNets     = $identityVNets.Count
                    PeeredVNets       = $peeredVNets
                    NotPeeredVNets    = $identityVNets.Count - $peeredVNets
                    Message           = "Some identity VNets are not peered to the hub network."
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

function Test-QuestionB0402 {
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
        } else {
            $totalResources = $resources.Count
            $resourcesUsingRBAC = 0

            foreach ($resource in $resources) {
                switch ($resource.ResourceType) {
                    "Microsoft.KeyVault/vaults" {
                        # Check if RBAC is enabled for Key Vault
                        $keyVault = Get-AzKeyVault -VaultName $resource.Name -ResourceGroupName $resource.ResourceGroupName
                        if ($keyVault.Properties.EnableRbacAuthorization -eq $true) {
                            $resourcesUsingRBAC++
                        }
                    }
                    "Microsoft.Storage/storageAccounts" {
                        # Check if RBAC is enabled for Storage Account
                        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
                        if ($storageAccount.EnableAzureActiveDirectoryDomainServicesForFile -or $storageAccount.EnableAzureActiveDirectoryKerberosForFile -or $storageAccount.EnableAzureActiveDirectoryDomainServicesForBlob) {
                            $resourcesUsingRBAC++
                        }
                    }
                    "Microsoft.Sql/servers" {
                        # Check if Azure AD authentication is enabled for SQL
                        $sqlServer = Get-AzSqlServer -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.Name
                        $adAdmins = Get-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.Name
                        if ($adAdmins) {
                            $resourcesUsingRBAC++
                        }
                    }
                }
            }

            # Determine the status based on the count of resources using RBAC
            if ($resourcesUsingRBAC -eq $totalResources) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalResources      = $totalResources
                    ResourcesUsingRBAC  = $resourcesUsingRBAC
                    Message             = "All resources of specified types are configured to use Azure RBAC for data plane access."
                }
            } elseif ($resourcesUsingRBAC -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalResources      = $totalResources
                    ResourcesUsingRBAC  = $resourcesUsingRBAC
                    Message             = "None of the specified resources are configured to use Azure RBAC for data plane access."
                }
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($resourcesUsingRBAC / $totalResources) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalResources      = $totalResources
                    ResourcesUsingRBAC  = $resourcesUsingRBAC
                    ResourcesWithoutRBAC = $totalResources - $resourcesUsingRBAC
                    Message             = "Some resources are configured to use Azure RBAC for data plane access, but not all."
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

function Test-QuestionB0403 {
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
        # Question: Use Microsoft Entra ID PIM access reviews to periodically validate resource entitlements.
        # Reference: https://learn.microsoft.com/azure/active-directory/privileged-identity-management/pim-how-to-start-security-review

        # Connect to Microsoft Graph with appropriate permissions
        Connect-MgGraph -Scopes "AccessReview.Read.All"

        # Get all active Access Reviews in PIM
        $accessReviews = Get-MgAccessReviewScheduleDefinition -Filter "status eq 'active'" -All

        if (-not $accessReviews -or $accessReviews.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No active access reviews are configured in Microsoft Entra ID PIM."
        } else {
            $totalAccessReviews = $accessReviews.Count

            # Filter access reviews related to resource entitlements (Azure AD roles, Groups, or Resources)
            $resourceReviews = $accessReviews | Where-Object {
                $_.ReviewScope -in @("DirectoryRole", "Group", "Resource")
            }

            if ($resourceReviews.Count -eq $totalAccessReviews) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    TotalAccessReviews  = $totalAccessReviews
                    ResourceReviews     = $resourceReviews.Count
                    Message             = "All active access reviews are configured for resource entitlements."
                }
            } elseif ($resourceReviews.Count -eq 0) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalAccessReviews  = $totalAccessReviews
                    ResourceReviews     = $resourceReviews.Count
                    Message             = "None of the active access reviews are related to resource entitlements."
                }
            } else {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = ($resourceReviews.Count / $totalAccessReviews) * 100
                $estimatedPercentageApplied = [Math]::Round($estimatedPercentageApplied, 2)
                $rawData = @{
                    TotalAccessReviews      = $totalAccessReviews
                    ResourceReviews         = $resourceReviews.Count
                    NonResourceReviews      = $totalAccessReviews - $resourceReviews.Count
                    Message                 = "Some active access reviews are configured for resource entitlements, but not all."
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