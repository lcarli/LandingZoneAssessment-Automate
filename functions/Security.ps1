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

# Dot-source shared modules
. "$PSScriptRoot/../shared/Enums.ps1"
. "$PSScriptRoot/../shared/ErrorHandling.ps1"
. "$PSScriptRoot/../shared/SharedFunctions.ps1"

function Invoke-SecurityAssessment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )
    Measure-ExecutionTime -ScriptBlock {
        Write-AssessmentHeader "Evaluating the Security design area..."

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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Determine the incident response plan for Azure services before allowing it into production.
        # Reference: https://learn.microsoft.com/security/benchmark/azure/security-control-incident-response

        # This Security item requires manual verification as it involves planning and documentation.
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
    
    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
        
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Use Azure Key Vault to store your secrets and credentials.
        # Reference: https://learn.microsoft.com/azure/key-vault/general/overview

        # Check if Key Vaults exist in the environment
        if ($global:AzData -and $global:AzData.Resources) {
            $keyVaults = $global:AzData.Resources | Where-Object { $_.ResourceType -eq "Microsoft.KeyVault/vaults" }
            
            if ($keyVaults -and $keyVaults.Count -gt 0) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 90 # High score as Key Vaults are present
                $rawData = @{
                    KeyVaultCount = $keyVaults.Count
                    KeyVaultNames = $keyVaults.Name
                    Note = "Key Vaults found in environment. Manual verification recommended to confirm proper usage for secrets and credentials."
                }
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = "No Key Vaults found in the environment. Consider implementing Key Vault to store secrets and credentials securely."
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
            $rawData = "Unable to check Key Vault existence automatically. Manual verification required."
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
    
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
    
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
    
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Use a single Key Vault for certificates, secrets, and keys. Use tags to distinguish different types of secrets.
        # Reference: https://learn.microsoft.com/azure/key-vault/general/best-practices

        # Retrieve all Key Vaults using AzData.Resources
        $keyVaults = $global:AzData.Resources | Where-Object { $_.Type -eq "Microsoft.KeyVault/vaults" }        if ($keyVaults.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No Azure Key Vaults are configured in the current subscriptions."
            $estimatedPercentageApplied = 0
        } else {
            # Check Key Vault configuration for certificates, secrets, keys, and tags
            $vaultStatus = $keyVaults | ForEach-Object {
                $vault = $_
                [PSCustomObject]@{
                    VaultName       = $vault.Name
                    HasCertificates = Invoke-AzCmdletSafely -ScriptBlock {
                        $certs = Get-AzKeyVaultCertificate -VaultName $vault.Name -ErrorAction SilentlyContinue
                        return $null -ne $certs -and $certs.Count -gt 0
                    } -CmdletName "Get-AzKeyVaultCertificate" -ModuleName "Az.KeyVault" -FallbackValue $false
                    HasSecrets      = Invoke-AzCmdletSafely -ScriptBlock {
                        $secrets = Get-AzKeyVaultSecret -VaultName $vault.Name -ErrorAction SilentlyContinue
                        return $null -ne $secrets -and $secrets.Count -gt 0
                    } -CmdletName "Get-AzKeyVaultSecret" -ModuleName "Az.KeyVault" -FallbackValue $false
                    HasKeys         = Invoke-AzCmdletSafely -ScriptBlock {
                        $keys = Get-AzKeyVaultKey -VaultName $vault.Name -ErrorAction SilentlyContinue
                        return $null -ne $keys -and $keys.Count -gt 0
                    } -CmdletName "Get-AzKeyVaultKey" -ModuleName "Az.KeyVault" -FallbackValue $false
                    HasTags         = ($null -ne $vault.Tags -and $vault.Tags.Count -gt 0)
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
    $status = [Status]::Unknown
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        # Question: Automate the certificate management and renewal process with public certificate authorities to ease administration.
        # Reference: https://learn.microsoft.com/azure/key-vault/general/best-practices
        
        # Get all Key Vaults in the environment
        $keyVaults = $global:AzData.Resources | Where-Object { $_.Type -eq "Microsoft.KeyVault/vaults" }
        
        if ($keyVaults.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No Azure Key Vaults are configured in the current subscriptions."
            $estimatedPercentageApplied = 0
        } else {
            # Initialize counters
            $totalCertificates = 0
            $automatedCertificates = 0
            $automationDetails = @()
            
            # Loop through each Key Vault to check certificates
            foreach ($keyVault in $keyVaults) {
                # Set the context to the subscription containing the Key Vault
                Set-AzContext -Subscription $keyVault.SubscriptionId | Out-Null
                
                try {
                    # Get all certificates in the Key Vault
                    $certificates = Invoke-AzCmdletSafely -ScriptBlock {
                        Get-AzKeyVaultCertificate -VaultName $keyVault.Name -ErrorAction SilentlyContinue
                    } -CmdletName "Get-AzKeyVaultCertificate" -ModuleName "Az.KeyVault" -FallbackValue @()
                    
                    if ($certificates.Count -gt 0) {
                        foreach ($cert in $certificates) {
                            $totalCertificates++
                            $isAutomated = $false
                            $issuerInfo = $null
                            
                            # Get the certificate issuer - this indicates if it's using a public CA
                            try {
                                $issuerName = if ($cert.Certificate.Issuer -and $cert.Certificate.Issuer.Contains("=")) {
                                    $cert.Certificate.Issuer.Split("=")[1].Split(",")[0]
                                } else {
                                    "Unknown"
                                }
                                
                                $issuer = Invoke-AzCmdletSafely -ScriptBlock {
                                    Get-AzKeyVaultCertificateIssuer -VaultName $keyVault.Name -Name $issuerName -ErrorAction SilentlyContinue
                                } -CmdletName "Get-AzKeyVaultCertificateIssuer" -ModuleName "Az.KeyVault"
                                
                                $issuerInfo = $issuer
                                
                                # Check if certificate uses automated renewal
                                # Automated certificates typically have an IssuerProvider set and policy with auto-renewal settings
                                $policy = Invoke-AzCmdletSafely -ScriptBlock {
                                    Get-AzKeyVaultCertificatePolicy -VaultName $keyVault.Name -Name $cert.Name -ErrorAction SilentlyContinue
                                } -CmdletName "Get-AzKeyVaultCertificatePolicy" -ModuleName "Az.KeyVault"
                                
                                if ($issuer -and $issuer.IssuerProvider -and 
                                    $policy -and $policy.LifetimeActions -and 
                                    $policy.LifetimeActions.Count -gt 0) {
                                    $isAutomated = $true
                                    $automatedCertificates++
                                }
                            }
                            catch {
                                # If we can't get the issuer details, default to not automated
                                $issuerInfo = "Unknown"
                            }
                            
                            $automationDetails += [PSCustomObject]@{
                                KeyVaultName = $keyVault.Name
                                CertificateName = $cert.Name
                                Issuer = $cert.Certificate.Issuer
                                IssuerProvider = $issuerInfo.IssuerProvider
                                ExpiresOn = $cert.Expires
                                IsAutomated = $isAutomated
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "Error accessing certificates in Key Vault $($keyVault.Name): $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            # Determine the status based on findings
            if ($totalCertificates -eq 0) {
                $status = [Status]::NotImplemented
                $rawData = "No certificates found in any Key Vaults."
                $estimatedPercentageApplied = 0
            }
            else {
                if ($automatedCertificates -eq $totalCertificates) {
                    $status = [Status]::Implemented
                    $estimatedPercentageApplied = 100
                }
                elseif ($automatedCertificates -gt 0) {
                    $status = [Status]::PartiallyImplemented
                    $estimatedPercentageApplied = [Math]::Round(($automatedCertificates / $totalCertificates) * 100, 2)
                }
                else {
                    $status = [Status]::NotImplemented
                    $estimatedPercentageApplied = 0
                }
                
                $rawData = @{
                    TotalKeyVaults = $keyVaults.Count
                    TotalCertificates = $totalCertificates
                    AutomatedCertificates = $automatedCertificates
                    AutomationPercentage = $estimatedPercentageApplied
                    CertificateDetails = $automationDetails
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
    $status = [Status]::Unknown

    try {
        # Question: Enable secure transfer to storage accounts.
        # Reference: https://learn.microsoft.com/azure/storage/common/storage-require-secure-transfer
        
        if ($global:AzData -and $global:AzData.Resources) {
            $storageAccounts = $global:AzData.Resources | Where-Object { $_.ResourceType -eq "Microsoft.Storage/storageAccounts" }
            
            if ($storageAccounts -and $storageAccounts.Count -gt 0) {
                $totalAccounts = $storageAccounts.Count
                $accountDetails = @()
                
                foreach ($storageAccount in $storageAccounts) {
                    # This would require additional API calls to check supportsHttpsTrafficOnly property
                    # For now, we'll recommend manual verification
                    $accountDetails += @{
                        Name = $storageAccount.Name
                        ResourceGroup = $storageAccount.ResourceGroupName
                        Note = "Manual verification required for HTTPS-only setting"
                    }
                }
                
                $status = [Status]::ManualVerificationRequired
                $estimatedPercentageApplied = 0
                $rawData = @{
                    TotalStorageAccounts = $totalAccounts
                    StorageAccountDetails = $accountDetails
                    Note = "Found $totalAccounts storage account(s). Manual verification required to confirm secure transfer (HTTPS-only) is enabled."
                }
            } else {
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
                $rawData = "No storage accounts found in the environment."
            }
        } else {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
            $rawData = "Unable to check storage accounts automatically. Manual verification required."
        }
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)" 
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
