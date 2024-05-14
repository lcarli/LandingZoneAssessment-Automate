<#
.SYNOPSIS
    Functions related to Identity and Access Management (IAM) assessment.

.DESCRIPTION
    This script contains functions to evaluate the IAM area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"


#region begin Planning for identity and access management

# B1.1 - Enforce a RBAC model
function Test-EnforceRBACModel {
    Write-Host "Checking if a RBAC model is enforced for management groups, subscriptions, and resource groups..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve role assignments for management groups, subscriptions, and resource groups
        $managementGroupRoles = Get-AzRoleAssignment -Scope "/providers/Microsoft.Management/managementGroups/<YourManagementGroup>"
        $subscriptionRoles = Get-AzRoleAssignment -Scope "/subscriptions/<YourSubscriptionId>"
        $resourceGroupRoles = Get-AzRoleAssignment -Scope "/subscriptions/<YourSubscriptionId>/resourceGroups/<YourResourceGroupName>"

        # Check if there are any role assignments
        if ($managementGroupRoles.Count -gt 0 -and $subscriptionRoles.Count -gt 0 -and $resourceGroupRoles.Count -gt 0) {
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
        Log-Error -QuestionID "B1.1" -QuestionText "Enforce a RBAC model" -FunctionName "Test-EnforceRBACModel" -ErrorMessage $_.Exception.Message
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

# B1.5 - Enforce MFA, Azure AD Conditional Access policies
function Test-EnforceMFAConditionalAccess {
    Write-Host "Checking if MFA and Azure AD Conditional Access policies are enforced..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Weight from the Excel sheet
    $score = 0

    try {
        # Check MFA status
        $mfaEnabled = Get-AzureADMSConditionalAccessPolicy -Filter "state eq 'enabled' and conditions/applications/includeApplications/any(c:c eq 'all') and grantControls/builtInControls/any(b:b eq 'mfa')"
        
        # Check Conditional Access policies status
        $conditionalAccessPolicies = Get-AzureADMSConditionalAccessPolicy -Filter "state eq 'enabled'"

        if ($mfaEnabled.Count -gt 0 -and $conditionalAccessPolicies.Count -gt 0) {
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
        Log-Error -QuestionID "B1.5" -QuestionText "Enforce MFA, Azure AD Conditional Access policies" -FunctionName "Test-EnforceMFAConditionalAccess" -ErrorMessage $_.Exception.Message
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

# B1.6 - "Azure AD only" groups for Azure control plane
function Test-AzureADOnlyGroups {
    Write-Host "Checking if 'Azure AD only' groups are used for Azure control plane..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 4  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve the list of Azure AD groups
        $aadGroups = Get-AzureADGroup

        # Check if there are any Azure AD groups being used for Azure control plane
        $azureControlPlaneGroups = $aadGroups | Where-Object { $_.SecurityEnabled -eq $true }

        if ($azureControlPlaneGroups.Count -gt 0) {
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
        Log-Error -QuestionID "B1.6" -QuestionText "'Azure AD only' groups for Azure control plane" -FunctionName "Test-AzureADOnlyGroups" -ErrorMessage $_.Exception.Message
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

# B1.7 - Custom Role Definitions + AAD PIM for Azure roles
function Test-CustomRoleDefinitionsPIM {
    Write-Host "Checking if Custom Role Definitions and AAD PIM are used for Azure roles..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 2  # Weight from the Excel sheet
    $score = 0

    try {
        # Check custom role definitions
        $customRoles = Get-AzRoleDefinition | Where-Object { $_.IsCustom -eq $true }

        # Check if Azure AD PIM is enabled
        $pimEnabled = Get-AzureADMSPrivilegedRoleAssignment -Filter "resource eq 'AzureResource'"

        if ($customRoles.Count -gt 0 -and $pimEnabled.Count -gt 0) {
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
        Log-Error -QuestionID "B1.7" -QuestionText "Custom Role Definitions + AAD PIM for Azure roles" -FunctionName "Test-CustomRoleDefinitionsPIM" -ErrorMessage $_.Exception.Message
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


# B1.8 - AAD Diagnostic Logs
function Test-AADDiagnosticLogs {
    Write-Host "Checking if AAD Diagnostic Logs are integrated with the platform-centric log solution..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve diagnostic settings for Azure AD
        $aadDiagnosticSettings = Get-AzDiagnosticSetting -ResourceId "/providers/Microsoft.aadiam/diagnosticSettings"

        # Check if diagnostic settings are configured to send logs to a log analytics workspace or other logging solution
        $logsConfigured = $aadDiagnosticSettings | Where-Object { $_.Logs.Category -contains "AuditLogs" -or $_.Logs.Category -contains "SignInLogs" }

        if ($logsConfigured.Count -gt 0) {
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
        Log-Error -QuestionID "B1.8" -QuestionText "AAD Diagnostic Logs" -FunctionName "Test-AADDiagnosticLogs" -ErrorMessage $_.Exception.Message
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


# B1.9 - Custom RBAC Roles and Usage
function Test-CustomRBACRoles {
    Write-Host "Checking if custom RBAC roles are defined and used within the Azure AD environment..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 4  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve custom role definitions
        $customRoles = Get-AzRoleDefinition | Where-Object { $_.IsCustom -eq $true }

        if ($customRoles.Count -gt 0) {
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
        Log-Error -QuestionID "B1.9" -QuestionText "Custom RBAC Roles and Usage" -FunctionName "Test-CustomRBACRoles" -ErrorMessage $_.Exception.Message
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


# B1.10 - Separate privileged admin accounts for Azure administration
function Test-SeparatePrivilegedAdminAccounts {
    Write-Host "Checking if separate privileged admin accounts are used for Azure administration..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 5  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve privileged admin accounts
        $privilegedAdminRoles = Get-AzureADDirectoryRole | Where-Object { $_.RoleTemplateId -eq "62e90394-69f5-4237-9190-012177145e10" }  # This is the template ID for the Global Administrator role
        $privilegedAdminAccounts = Get-AzureADDirectoryRoleMember -ObjectId $privilegedAdminRoles.ObjectId

        # Check if there are separate privileged admin accounts
        $separateAdminAccounts = $privilegedAdminAccounts | Where-Object { $_.UserPrincipalName -match "admin" }  # Assuming admin accounts have "admin" in UPN

        if ($separateAdminAccounts.Count -gt 0) {
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
        Log-Error -QuestionID "B1.10" -QuestionText "Separate privileged admin accounts for Azure administration" -FunctionName "Test-SeparatePrivilegedAdminAccounts" -ErrorMessage $_.Exception.Message
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

#region Authentication Inside the Landing Zone

# B2.1 - Domain Controller in Azure or AADDS services
function Test-DomainControllerInAzure {
    param (
        [string]$ResourceGroupName
    )

    Write-Host "Checking if domain controllers are deployed in Azure or if AADDS services are in use..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3  # Weight from the Excel sheet
    $score = 0

    try {
        # Check for Azure AD Domain Services
        $aadds = Get-AzADDomainService

        # Check for domain controllers in specified resource group or in all resource groups
        if ($PSBoundParameters.ContainsKey('ResourceGroupName')) {
            $domainControllers = Get-AzVM -ResourceGroupName $ResourceGroupName | Where-Object { $_.OsProfile.ComputerName -match "DC" }
        } else {
            $domainControllers = Get-AzVM | Where-Object { $_.OsProfile.ComputerName -match "DC" }
        }

        if ($aadds.Count -gt 0 -or $domainControllers.Count -gt 0) {
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
        Log-Error -QuestionID "B2.1" -QuestionText "Domain Controller in Azure or AADDS services" -FunctionName "Test-DomainControllerInAzure" -ErrorMessage $_.Exception.Message
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


# B2.2 - Use Azure AD Application Proxy for Intranet apps
function Test-AzureADApplicationProxy {
    Write-Host "Checking if Azure AD Application Proxy is used for Intranet apps..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 2  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve Azure AD Application Proxy connectors
        $appProxyConnectors = Get-AzureADApplicationProxyConnector

        # Check if there are any Application Proxy connectors configured
        if ($appProxyConnectors.Count -gt 0) {
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
        Log-Error -QuestionID "B2.2" -QuestionText "Use Azure AD Application Proxy for Intranet apps" -FunctionName "Test-AzureADApplicationProxy" -ErrorMessage $_.Exception.Message
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


# B2.3 - Use Managed Identities to authenticate to Azure resources
function Test-UseManagedIdentities {
    Write-Host "Checking if managed identities are used to authenticate to Azure resources..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3  # Weight from the Excel sheet
    $score = 0

    try {
        # Retrieve managed identities
        $managedIdentities = Get-AzUserAssignedIdentity

        # Check if there are any managed identities configured
        if ($managedIdentities.Count -gt 0) {
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
        Log-Error -QuestionID "B2.3" -QuestionText "Use Managed Identities to authenticate to Azure resources" -FunctionName "Test-UseManagedIdentities" -ErrorMessage $_.Exception.Message
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


# B2.4 - Identity network segmentation and connectivity with AD
function Test-IdentityNetworkSegmentation {
    Write-Host "Checking if identity network segmentation and connectivity with AD is implemented..."

    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $weight = 3  # Weight from the Excel sheet
    $score = 0

    try {
        # Placeholder logic to check network segmentation and connectivity with AD
        # Check if there are separate subscriptions and vNets
        $subscriptions = Get-AzSubscription
        $vNets = Get-AzVirtualNetwork

        if ($subscriptions.Count -gt 1 -and $vNets.Count -gt 1) {
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
        Log-Error -QuestionID "B2.4" -QuestionText "Identity network segmentation and connectivity with AD" -FunctionName "Test-IdentityNetworkSegmentation" -ErrorMessage $_.Exception.Message
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
