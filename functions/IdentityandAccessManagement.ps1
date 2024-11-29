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

    $results = @()

    # Call individual assessment functions
    $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.01") }) | Test-QuestionB0301
    $results += ($Checklist.items | Where-Object { ($_.id -eq "B03.02") }) | Test-QuestionB0302
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

    # Return the results
    return $results
}


function Test-QuestionB0301 {
    Write-Host "Assessing question: Enforce a RBAC model that aligns to your cloud operating model. Scope and Assign across Management Groups and Subscriptions."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0

    try {
        $config = Get-Content -Path "$PSScriptRoot/../shared/config.json" | ConvertFrom-Json
        $tenantId = $config.TenantId

        # Get the list of management groups
        $managementGroups = Get-AzManagementGroup | Where-Object { $_.TenantId -eq $tenantId }

        if ($managementGroups.Count -eq 0) {
            # No management groups found
        } else {
            $totalGroups = 0
            $configuredGroups = 0

            # Loop through each management group
            foreach ($managementGroup in $managementGroups) {
                $totalGroups++
                $managementGroupId = $managementGroup.Id

                # Get the role assignments for the management group
                $mgmtGroupRoleAssignments = Get-AzRoleAssignment -Scope "$managementGroupId"

                # Ensure that specific roles are applied across the management group
                $rbacAligned = $false

                # Check if relevant roles such as 'Contributor', 'Owner', or 'Reader' are assigned
                foreach ($roleAssignment in $mgmtGroupRoleAssignments) {
                    if ($roleAssignment.RoleDefinitionName -in @("Contributor", "Owner", "Reader")) {
                        $rbacAligned = $true
                    }
                }

                if ($rbacAligned) {
                    $configuredGroups++
                }
            }

            # Calculate percentage for management groups
            if ($totalGroups -gt 0) {
                $mgmtGroupPercentage = ($configuredGroups / $totalGroups) * 100
            } else {
                $mgmtGroupPercentage = 100
            }

            # Now handle subscriptions
            $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $tenantId }

            $totalSubscriptions = $subscriptions.Count
            $configuredSubscriptions = 0

            # Loop through each subscription
            foreach ($subscription in $subscriptions) {
                $subscriptionId = $subscription.Id
                $subscriptionRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$subscriptionId"

                # Ensure that RBAC roles are appropriately assigned at the subscription level
                $rbacAligned = $false

                foreach ($roleAssignment in $subscriptionRoleAssignments) {
                    if ($roleAssignment.RoleDefinitionName -in @("Contributor", "Owner", "Reader")) {
                        $rbacAligned = $true
                    }
                }

                if ($rbacAligned) {
                    $configuredSubscriptions++
                }
            }

            # Calculate percentage for subscriptions
            if ($totalSubscriptions -gt 0) {
                $subscriptionPercentage = ($configuredSubscriptions / $totalSubscriptions) * 100
            } else {
                $subscriptionPercentage = 100
            }

            # Combine the results from management groups and subscriptions
            $estimatedPercentageApplied = ([Math]::Round(($mgmtGroupPercentage + $subscriptionPercentage) / 2, 2))

            # Determine the status based on the applied percentage
            if ($estimatedPercentageApplied -eq 100) {
                $status = [Status]::Implemented
            } elseif ($estimatedPercentageApplied -eq 0) {
                $status = [Status]::NotImplemented
            } else {
                $status = [Status]::PartiallyImplemented
            }
        }

        $score = ($weight * $estimatedPercentageApplied) / 100

    } catch {
        Log-Error -QuestionID "B03.01" -QuestionText "Enforce a RBAC model that aligns to your cloud operating model. Scope and Assign across Management Groups and Subscriptions." -FunctionName "Assess-QuestionA0501" -ErrorMessage $_.Exception.Message
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

function Test-QuestionB0302 {
    Write-Host "Assessing question: Use managed identities instead of service principals for authentication to Azure services."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0

    try {
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

    } catch {
        Log-Error -QuestionID "B03.02" -QuestionText "Use managed identities instead of service principals for authentication to Azure services." -FunctionName "Assess-QuestionA0601" -ErrorMessage $_.Exception.Message
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

function Test-QuestionB030201 {
    Write-Host "Assessing question: Only use the authentication type Work or school account for all account types. Avoid using the Microsoft account."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust the weight as necessary
    $score = 0

    try {
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
                # A user with a domain not belonging to Microsoft consumer accounts (outlook.com, hotmail.com, live.com) is assumed to be a work or school account
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

    } catch {
        Log-Error -QuestionID "A03.02-01" -QuestionText "Only use the authentication type Work or school account for all account types. Avoid using the Microsoft account." -FunctionName "Assess-QuestionA0602" -ErrorMessage $_.Exception.Message
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

function Test-QuestionB0303 {
    Write-Host "Assessing question: Only use groups to assign permissions across all subscriptions. Add on-premises groups to the Entra ID only group if a group management system is already in place."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust as necessary
    $score = 0

    try {
        # Get all subscriptions in the current tenant
        $config = Get-Content -Path "$PSScriptRoot/../shared/config.json" | ConvertFrom-Json
        $tenantId = $config.TenantId

        $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $tenantId }

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
                Set-AzContext -SubscriptionId $subscriptionId

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
                # If no assignments found at all
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

    } catch {
        Log-Error -QuestionID "B03.03" -QuestionText "Only use groups to assign permissions. Add on-premises groups to the Entra ID only group if a group management system is already in place." -FunctionName "Assess-QuestionA0603" -ErrorMessage $_.Exception.Message
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

function Test-QuestionB0304 {
    Write-Host "Assessing question: Enforce Microsoft Entra ID Conditional Access policies for any user with rights to Azure environments (B03.04)."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0

    try {
        # Connect to Microsoft Graph
        Connect-MgGraph -Scopes "Policy.Read.All", "Directory.Read.All"

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

            # Store user principal names from the role assignments
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

    } catch {
        Log-Error -QuestionID "B03.04" -QuestionText "Enforce Microsoft Entra ID Conditional Access policies for any user with rights to Azure environments." -FunctionName "Assess-QuestionB0304" -ErrorMessage $_.Exception.Message
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
function Test-QuestionB0305 {
    Write-Host "Assessing question: Enforce multi-factor authentication for any user with rights to the Azure environments (B03.05)."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust as necessary
    $score = 0

    try {
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

            # Store user principal names from the role assignments
            foreach ($assignment in $roleAssignments) {
                if ($assignment.ObjectType -eq "User") {
                    $uniqueUsers += $assignment.ObjectId  # Use PrincipalId to pass to Get-MgUserAuthenticationMethod
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
                } catch {
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

    } catch {
        Log-Error -QuestionID "B03.05" -QuestionText "Enforce multi-factor authentication for any user with rights to the Azure environments." -FunctionName "Assess-QuestionB0305" -ErrorMessage $_.Exception.Message
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

function Test-QuestionB0306 {
    Write-Host "Assessing question: Enforce centralized and delegated responsibilities to manage resources deployed inside the landing zone, based on role and security requirements."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Assigning high severity weight
    $score = 0

    try {
        # Retrieve tenant information and current configurations
        $config = Get-Content -Path "$PSScriptRoot/../shared/config.json" | ConvertFrom-Json
        $tenantId = $config.TenantId

        # Assess role assignments across management groups and subscriptions
        $managementGroups = Get-AzManagementGroup | Where-Object { $_.TenantId -eq $tenantId }
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

    } catch {
        Log-Error -QuestionID "B03.06" -QuestionText "Enforce centralized and delegated responsibilities to manage resources deployed inside the landing zone." -FunctionName "Test-QuestionB0306" -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $score = 0
    
    }
}

function Test-QuestionB0307 {
    Write-Host "Assessing question: Enforce Microsoft Entra ID Privileged Identity Management (PIM) to establish zero standing access and least privilege."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Adjust as necessary
    $score = 0

    try {
        # Connect to Microsoft Graph with appropriate scopes for PIM
        Connect-MgGraph -Scopes "PrivilegedAccess.Read.AzureAD"

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

    } catch {
        Log-Error -QuestionID "B03.07" -QuestionText "Enforce Microsoft Entra ID Privileged Identity Management (PIM)." -FunctionName "Test-QuestionB0307" -ErrorMessage $_.Exception.Message
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

function Test-QuestionB0308 {
    Write-Host "Assessing question: When deploying Active Directory Domain Controllers, use a location with Availability Zones and deploy at least two VMs across these zones. If not available, deploy in an Availability Set."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0

    try {
        # Check if Availability Zones are available
        $availabilityZones = Get-AzAvailabilityZone -Location "YourLocation" # Replace "YourLocation" with the relevant Azure region

        if ($availabilityZones.Count -gt 1) {
            # Check if at least two VMs are deployed across Availability Zones
            $vmCount = 0

            # Get all VMs in the subscription
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
                # If at least one Availability Set exists, assume compliant
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }
        }

        # Calculate the score
        $score = ($weight * $estimatedPercentageApplied) / 100

    } catch {
        Log-Error -QuestionID "B03.08" -QuestionText "When deploying Active Directory Domain Controllers, use a location with Availability Zones and deploy at least two VMs across these zones. If not available, deploy in an Availability Set." -FunctionName "Test-QuestionB0309" -ErrorMessage $_.Exception.Message
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

function Test-QuestionB0309 {
    Write-Host "Assessing question: Use Azure custom RBAC roles for key roles to provide fine-grain access across your ALZ: Azure platform owner, network management, security operations, subscription owner, application owner."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5
    $score = 0

    try {
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
        foreach ($role in $requiredRoles) {
            if ($customRoles.Name -contains $role) {
                $rolesFound++
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

    } catch {
        Log-Error -QuestionID "B03.9" -QuestionText "Use Azure custom RBAC roles for the following key roles: Azure platform owner, network management, security operations, subscription owner, application owner." -FunctionName "Test-QuestionB0310" -ErrorMessage $_.Exception.Message
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

# Function for IAM item B03.09
function Test-QuestionB0309 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B03.10
function Test-QuestionB0310 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B03.11
function Test-QuestionB0311 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B03.12
function Test-QuestionB0312 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B03.13
function Test-QuestionB0313 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B03.14
function Test-QuestionB0314 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B03.15
function Test-QuestionB0315 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B03.16
function Test-QuestionB0316 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B03.17
function Test-QuestionB0317 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B04.01
function Test-QuestionB0401 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B04.02
function Test-QuestionB0402 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Function for IAM item B04.03
function Test-QuestionB0403 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $status = [Status]::NotDeveloped
        $rawData = "In development"
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}