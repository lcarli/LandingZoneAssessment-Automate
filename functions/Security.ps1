# Security.ps1

<#
.SYNOPSIS
    Functions related to Security assessment.

.DESCRIPTION
    This script contains functions to evaluate the Security area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-SecurityAssessment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )
    Measure-ExecutionTime -ScriptBlock {
        Write-Host "Evaluating the Security design area..."

        $results = @()
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G01.01") }) | Test-QuestionG0101
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G01.02") }) | Test-QuestionG0102
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.01") }) | Test-QuestionG0201
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.02") }) | Test-QuestionG0202
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.03") }) | Test-QuestionG0203
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.04") }) | Test-QuestionG0204
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.05") }) | Test-QuestionG0205
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.06") }) | Test-QuestionG0206
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.07") }) | Test-QuestionG0207
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.08") }) | Test-QuestionG0208
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.09") }) | Test-QuestionG0209
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.10") }) | Test-QuestionG0210
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.11") }) | Test-QuestionG0211
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.12") }) | Test-QuestionG0212
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G02.13") }) | Test-QuestionG0213
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.01") }) | Test-QuestionG0301
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.02") }) | Test-QuestionG0302
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.03") }) | Test-QuestionG0303
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.04") }) | Test-QuestionG0304
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.05") }) | Test-QuestionG0305
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.06") }) | Test-QuestionG0306
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.07") }) | Test-QuestionG0307
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.08") }) | Test-QuestionG0308
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.09") }) | Test-QuestionG0309
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.10") }) | Test-QuestionG0310
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.11") }) | Test-QuestionG0311
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G03.12") }) | Test-QuestionG0312
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G04.01") }) | Test-QuestionG0401
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G04.02") }) | Test-QuestionG0402
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G05.01") }) | Test-QuestionG0501
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G06.01") }) | Test-QuestionG0601
        $results += ($Checklist.items | Where-Object { ($_.id -eq "G06.02") }) | Test-QuestionG0602

        $script:FunctionResult = $results
    } -FunctionName "Invoke-SecurityAssessment"

    return $script:FunctionResult
}

# Function for Security item G01.01
function Test-QuestionG0101 {
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
        # Question: Determine the incident response plan for Azure services before allowing it into production.
        # Reference: https://learn.microsoft.com/security/benchmark/azure/security-control-incident-response

        # This question requires manual verification as it involves planning and documentation.
        $status = [Status]::ManualVerificationRequired
        $rawData = "Incident response plan needs to be documented and verified manually."
        $estimatedPercentageApplied = 0
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    return Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData
}

# Function for Security item G01.02
function Test-QuestionG0102 {
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
        # Question: Apply a zero-trust approach for access to the Azure platform.
        # Reference: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/security-zero-trust
    
        # Retrieve all Conditional Access Policies
        $conditionalAccessPolicies = Get-AzConditionalAccessPolicy
            
        if ($conditionalAccessPolicies.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No Conditional Access Policies are configured."
            $estimatedPercentageApplied = 0
        }
        else {
            $mfaPolicies = $conditionalAccessPolicies | Where-Object { $_.Conditions.Users.IncludeUsers -contains 'All' -and $_.Controls.Mfa } 
            $rbacPolicies = Get-AzRoleAssignment | Where-Object { $_.RoleDefinitionName -match "Owner|Contributor" -and $_.Scope -match "/subscriptions/" }
                
            if ($mfaPolicies.Count -gt 0 -and $rbacPolicies.Count -gt 0) {
                $status = [Status]::Implemented
                $rawData = "Zero Trust approach is enforced with MFA and RBAC policies."
                $estimatedPercentageApplied = 100
            }
            else {
                $status = [Status]::PartiallyImplemented
                $rawData = @{
                    MFA_PoliciesConfigured  = $mfaPolicies.Count
                    RBAC_PoliciesConfigured = $rbacPolicies.Count
                }
                $estimatedPercentageApplied = ($mfaPolicies.Count -gt 0 ? 50 : 0) + ($rbacPolicies.Count -gt 0 ? 50 : 0)
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
    
# Function for Security item G02.01
function Test-QuestionG0201 {
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
        # Question: Use Azure Key Vault to store your secrets and credentials.
        # Reference: https://learn.microsoft.com/azure/key-vault/general/overview

        # Retrieve all Key Vaults in the subscriptions
        $keyVaults = $global:AzData.Resources | Where-Object { $_.Type -eq "Microsoft.KeyVault/vaults" }

        if ($keyVaults.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No Azure Key Vaults are configured in the current subscriptions."
            $estimatedPercentageApplied = 0
        } else {
            $status = [Status]::Implemented
            $rawData = @{
                KeyVaultCount = $keyVaults.Count
                KeyVaultNames = $keyVaults.Name
            }
            $estimatedPercentageApplied = 100
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

# Function for Security item G02.02
function Test-QuestionG0202 {
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
        # Question: Use different Azure Key Vaults for different applications and regions to avoid transaction scale limits and restrict access to secrets.
        # Reference: https://learn.microsoft.com/azure/key-vault/general/overview-throttling

        $keyVaults = $global:AzData.Resources | Where-Object { $_.Type -eq "Microsoft.KeyVault/vaults" }

        if ($keyVaults.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No Azure Key Vaults are configured in the current subscriptions."
            $estimatedPercentageApplied = 0
        } else {
            $uniqueLocations = $keyVaults.Location | Select-Object -Unique
            
            $managementGroupNames = @("landing zone", "landingzone", "zone daccueil", "zone des charges")
            $landingZoneSubscriptions = $global:AzData.ManagementGroups | Where-Object {
                $managementGroupNames -contains $_.Name
            } | ForEach-Object {
                $_.Subscriptions
            } | Select-Object -ExpandProperty SubscriptionId

            $subscriptionsWithKeyVaults = $keyVaults | Group-Object -Property SubscriptionId

            if ($uniqueLocations.Count -gt 1 -or $subscriptionsWithKeyVaults.Count -ge $landingZoneSubscriptions.Count) {
                $status = [Status]::Implemented
                $rawData = @{
                    TotalKeyVaults           = $keyVaults.Count
                    UniqueLocations          = $uniqueLocations
                    SubscriptionsWithKeyVaults = $subscriptionsWithKeyVaults | Select-Object Name, Count
                }
                $estimatedPercentageApplied = 100
            } else {
                $status = [Status]::PartiallyImplemented
                $rawData = "Key Vaults are not sufficiently distributed across regions or subscriptions."
                $estimatedPercentageApplied = 50
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

# Function for Security item G02.03
function Test-QuestionG0203 {
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
        # Question: Provision Azure Key Vault with the soft delete and purge policies enabled to allow retention protection for deleted objects.
        # Reference: https://learn.microsoft.com/azure/key-vault/general/best-practices

        $keyVaults = $global:AzData.Resources | Where-Object { $_.Type -eq "Microsoft.KeyVault/vaults" }

        if ($keyVaults.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No Azure Key Vaults are configured in the current subscriptions."
            $estimatedPercentageApplied = 0
        } else {
            $vaultStatus = $keyVaults | ForEach-Object {
                [PSCustomObject]@{
                    VaultName       = $_.Name
                    SoftDelete      = $_.Properties.enableSoftDelete
                    PurgeProtection = $_.Properties.enablePurgeProtection
                }
            }

            $nonCompliantVaults = $vaultStatus | Where-Object { -not ($_.SoftDelete -and $_.PurgeProtection) }

            if ($nonCompliantVaults.Count -eq 0) {
                $status = [Status]::Implemented
                $rawData = "All Key Vaults have soft delete and purge protection enabled."
                $estimatedPercentageApplied = 100
            } else {
                $status = [Status]::PartiallyImplemented
                $rawData = @{
                    TotalKeyVaults        = $keyVaults.Count
                    NonCompliantVaults    = $nonCompliantVaults
                }
                $estimatedPercentageApplied = [Math]::Round((($keyVaults.Count - $nonCompliantVaults.Count) / $keyVaults.Count) * 100, 2)
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

# Function for Security item G02.04
function Test-QuestionG0204 {
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
        # Question: Use a single Key Vault for certificates, secrets, and keys. Use tags to distinguish different types of secrets.
        # Reference: https://learn.microsoft.com/azure/key-vault/general/best-practices

        # Retrieve all Key Vaults using AzData.Resources
        $keyVaults = $global:AzData.Resources | Where-Object { $_.Type -eq "Microsoft.KeyVault/vaults" }

        if ($keyVaults.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No Azure Key Vaults are configured in the current subscriptions."
            $estimatedPercentageApplied = 0
        } else {
            # Check Key Vault configuration for certificates, secrets, keys, and tags
            $vaultStatus = $keyVaults | ForEach-Object {
                [PSCustomObject]@{
                    VaultName    = $_.Name
                    HasCertificates = ($_ | Get-AzKeyVaultCertificate -ErrorAction SilentlyContinue) -ne $null
                    HasSecrets   = ($_ | Get-AzKeyVaultSecret -ErrorAction SilentlyContinue) -ne $null
                    HasKeys      = ($_ | Get-AzKeyVaultKey -ErrorAction SilentlyContinue) -ne $null
                    HasTags      = ($_.Tags -ne $null -and $_.Tags.Count -gt 0)
                }
            }

            $nonCompliantVaults = $vaultStatus | Where-Object { -not ($_.HasCertificates -and $_.HasSecrets -and $_.HasKeys -and $_.HasTags) }

            if ($nonCompliantVaults.Count -eq 0) {
                $status = [Status]::Implemented
                $rawData = "All Key Vaults are compliant with the requirement."
                $estimatedPercentageApplied = 100
            } else {
                $status = [Status]::PartiallyImplemented
                $rawData = @{
                    TotalKeyVaults       = $keyVaults.Count
                    NonCompliantVaults   = $nonCompliantVaults
                }
                $estimatedPercentageApplied = [Math]::Round((($keyVaults.Count - $nonCompliantVaults.Count) / $keyVaults.Count) * 100, 2)
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


# Function for Security item G02.05
function Test-QuestionG0205 {
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

# Function for Security item G02.06
function Test-QuestionG0206 {
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

# Function for Security item G02.07
function Test-QuestionG0207 {
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

# Function for Security item G02.08
function Test-QuestionG0208 {
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

# Function for Security item G02.09
function Test-QuestionG0209 {
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

# Function for Security item G02.10
function Test-QuestionG0210 {
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

# Function for Security item G02.11
function Test-QuestionG0211 {
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

# Function for Security item G02.12
function Test-QuestionG0212 {
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

# Function for Security item G02.13
function Test-QuestionG0213 {
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

# Function for Security item G03.01
function Test-QuestionG0301 {
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

# Function for Security item G03.02
function Test-QuestionG0302 {
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

# Function for Security item G03.03
function Test-QuestionG0303 {
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

# Function for Security item G03.04
function Test-QuestionG0304 {
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

# Function for Security item G03.05
function Test-QuestionG0305 {
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

# Function for Security item G03.06
function Test-QuestionG0306 {
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

# Function for Security item G03.07
function Test-QuestionG0307 {
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

# Function for Security item G03.08
function Test-QuestionG0308 {
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

# Function for Security item G03.09
function Test-QuestionG0309 {
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

# Function for Security item G03.10
function Test-QuestionG0310 {
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

# Function for Security item G03.11
function Test-QuestionG0311 {
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

# Function for Security item G03.12
function Test-QuestionG0312 {
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

# Function for Security item G04.01
function Test-QuestionG0401 {
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

# Function for Security item G04.02
function Test-QuestionG0402 {
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

# Function for Security item G05.01
function Test-QuestionG0501 {
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

# Function for Security item G06.01
function Test-QuestionG0601 {
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

# Function for Security item G06.02
function Test-QuestionG0602 {
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