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
    
        # Check for Conditional Access policies using safe cmdlet execution
        $conditionalAccessPolicies = Invoke-AzCmdletSafely -ScriptBlock {
            Get-AzConditionalAccessPolicy
        } -CmdletName "Get-AzConditionalAccessPolicy" -ModuleName "Microsoft.Graph.Identity.SignIns" -FallbackValue @()
        
        $rbacPolicies = Invoke-AzCmdletSafely -ScriptBlock {
            Get-AzRoleAssignment | Where-Object { $_.RoleDefinitionName -match "Owner|Contributor" -and $_.Scope -match "/subscriptions/" }
        } -CmdletName "Get-AzRoleAssignment" -ModuleName "Az.Resources" -FallbackValue @()
            
        if ($conditionalAccessPolicies.Count -eq 0 -and $rbacPolicies.Count -eq 0) {
            $status = [Status]::ManualVerificationRequired
            $rawData = @{
                Message = "Unable to assess Zero Trust implementation automatically."
                Recommendation = "Manually verify that Conditional Access policies with MFA are configured and RBAC is properly implemented."
                ConditionalAccessPolicies = $conditionalAccessPolicies.Count
                RBACPolicies = $rbacPolicies.Count
            }
            $estimatedPercentageApplied = 0
        }
        elseif ($conditionalAccessPolicies.Count -eq 0) {
            $status = [Status]::PartiallyImplemented
            $rawData = @{
                Message = "RBAC policies found but Conditional Access policies not detected."
                Recommendation = "Implement Conditional Access policies with MFA requirements for Zero Trust approach."
                ConditionalAccessPolicies = $conditionalAccessPolicies.Count
                RBACPolicies = $rbacPolicies.Count
            }
            $estimatedPercentageApplied = 50
        }
        else {
            # Check for MFA-enabled policies
            $mfaPolicies = $conditionalAccessPolicies | Where-Object { 
                $_.Conditions.Users.IncludeUsers -contains 'All' -and $_.Controls.Mfa 
            }
            
            if ($mfaPolicies.Count -gt 0 -and $rbacPolicies.Count -gt 0) {
                $status = [Status]::Implemented
                $rawData = @{
                    Message = "Zero Trust approach is enforced with MFA and RBAC policies."
                    ConditionalAccessPolicies = $conditionalAccessPolicies.Count
                    MFAPolicies = $mfaPolicies.Count
                    RBACPolicies = $rbacPolicies.Count
                }
                $estimatedPercentageApplied = 100
            }
            else {
                $status = [Status]::PartiallyImplemented
                $rawData = @{
                    Message = "Conditional Access policies found but may not fully implement Zero Trust approach."
                    ConditionalAccessPolicies = $conditionalAccessPolicies.Count
                    MFAPolicies = if ($mfaPolicies) { $mfaPolicies.Count } else { 0 }
                    RBACPolicies = $rbacPolicies.Count
                    Recommendation = "Review Conditional Access policies to ensure MFA is required for all users."
                }
                $estimatedPercentageApplied = 75
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
        $keyVaults = $global:AzData.Resources | Where-Object { $_.Type -eq "Microsoft.KeyVault/vaults" }        
        if ($keyVaults.Count -eq 0) {
            $status = [Status]::NotImplemented
            $rawData = "No Azure Key Vaults are configured in the current subscriptions."
            $estimatedPercentageApplied = 0
        } else {
            # Check Key Vault configuration for certificates, secrets, keys, and tags
            $vaultStatus = $keyVaults | ForEach-Object {
                $vault = $_
                
                # Ensure we're in the correct subscription context for this Key Vault
                try {
                    Set-AzContext -Subscription $vault.SubscriptionId -Tenant $global:TenantId | Out-Null
                } catch {
                    Write-AssessmentWarning "Failed to set context for subscription $($vault.SubscriptionId): $($_.Exception.Message)"
                }
                
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
                try {
                    # Set the context to the subscription containing the Key Vault with explicit tenant
                    Set-AzContext -Subscription $keyVault.SubscriptionId -Tenant $global:TenantId | Out-Null
                    
                    # Get all certificates in the Key Vault using cached context
                    # The global data should already be in the correct subscription context
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
                    Write-Warning "Error accessing certificates in Key Vault $($keyVault.Name): $($_.Exception.Message)"
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

function Test-QuestionG0206 {
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
        # Question: Establish an automated process for key and certificate rotation.
        # Check Key Vault keys/secrets for rotation policies
        $keyVaults = $global:AzData.Resources | Where-Object { $_.Type -eq "Microsoft.KeyVault/vaults" }

        if (-not $keyVaults -or $keyVaults.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Azure Key Vaults found in the environment."
        } else {
            $totalKeys = 0
            $keysWithRotation = 0
            $rotationDetails = @()

            foreach ($kv in $keyVaults) {
                try {
                    Set-AzContext -Subscription $kv.SubscriptionId -Tenant $global:TenantId | Out-Null
                    $keys = Invoke-AzCmdletSafely -ScriptBlock {
                        Get-AzKeyVaultKey -VaultName $kv.Name -ErrorAction SilentlyContinue
                    } -CmdletName "Get-AzKeyVaultKey" -ModuleName "Az.KeyVault" -FallbackValue @()

                    foreach ($key in $keys) {
                        $totalKeys++
                        $rotationPolicy = Invoke-AzCmdletSafely -ScriptBlock {
                            Get-AzKeyVaultKeyRotationPolicy -VaultName $kv.Name -Name $key.Name -ErrorAction SilentlyContinue
                        } -CmdletName "Get-AzKeyVaultKeyRotationPolicy" -ModuleName "Az.KeyVault"

                        $hasRotation = $false
                        if ($rotationPolicy -and $rotationPolicy.LifetimeActions -and $rotationPolicy.LifetimeActions.Count -gt 0) {
                            $hasRotation = $true
                            $keysWithRotation++
                        }
                        $rotationDetails += [PSCustomObject]@{
                            KeyVaultName    = $kv.Name
                            KeyName         = $key.Name
                            HasRotationPolicy = $hasRotation
                        }
                    }
                } catch {
                    Write-Warning "Error accessing keys in Key Vault $($kv.Name): $($_.Exception.Message)"
                }
            }

            if ($totalKeys -eq 0) {
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
                $rawData = "No keys found in any Key Vaults."
            } elseif ($keysWithRotation -eq $totalKeys) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($keysWithRotation -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($keysWithRotation / $totalKeys) * 100, 2)
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            if ($totalKeys -gt 0) {
                $rawData = @{
                    TotalKeyVaults       = $keyVaults.Count
                    TotalKeys            = $totalKeys
                    KeysWithRotation     = $keysWithRotation
                    RotationPercentage   = $estimatedPercentageApplied
                    KeyDetails           = $rotationDetails
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

function Test-QuestionG0207 {
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
        # Question: Enable firewall and virtual network service endpoint or private endpoint on the vault.
        # Use ARG to check Key Vault network rules
        $query = @"
resources
| where type == 'microsoft.keyvault/vaults'
| extend networkAcls = properties.networkAcls
| extend defaultAction = tostring(networkAcls.defaultAction)
| extend virtualNetworkRules = networkAcls.virtualNetworkRules
| extend privateEndpointConnections = properties.privateEndpointConnections
| extend hasVnetRules = (array_length(virtualNetworkRules) > 0)
| extend hasPrivateEndpoints = (array_length(privateEndpointConnections) > 0)
| extend compliant = (defaultAction =~ 'Deny' or hasPrivateEndpoints == true)
| project name, id, subscriptionId, resourceGroup, defaultAction, hasVnetRules, hasPrivateEndpoints, compliant
"@

        $results = Invoke-AzGraphQueryWithPagination -Query $query

        if (-not $results -or $results.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Azure Key Vaults found in the environment."
        } else {
            $totalVaults = $results.Count
            $compliantVaults = ($results | Where-Object { $_.compliant -eq $true }).Count

            if ($compliantVaults -eq $totalVaults) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($compliantVaults -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($compliantVaults / $totalVaults) * 100, 2)
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalKeyVaults    = $totalVaults
                CompliantVaults   = $compliantVaults
                VaultDetails      = $results
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

function Test-QuestionG0208 {
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
        # Question: Use the platform-central Azure Monitor Log Analytics workspace to audit key, certificate, and secret usage within each instance of Key Vault.
        # Check diagnostic settings on Key Vaults
        $keyVaults = $global:AzData.Resources | Where-Object { $_.Type -eq "Microsoft.KeyVault/vaults" }

        if (-not $keyVaults -or $keyVaults.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No Azure Key Vaults found in the environment."
        } else {
            $totalVaults = $keyVaults.Count
            $vaultsWithDiagnostics = 0
            $diagnosticDetails = @()

            foreach ($kv in $keyVaults) {
                try {
                    Set-AzContext -Subscription $kv.SubscriptionId -Tenant $global:TenantId | Out-Null
                    $diagSettings = Invoke-AzCmdletSafely -ScriptBlock {
                        Get-AzDiagnosticSetting -ResourceId $kv.ResourceId -ErrorAction SilentlyContinue
                    } -CmdletName "Get-AzDiagnosticSetting" -ModuleName "Az.Monitor" -FallbackValue @()

                    $hasLogAnalytics = $false
                    if ($diagSettings) {
                        foreach ($ds in $diagSettings) {
                            if ($ds.WorkspaceId) {
                                $hasLogAnalytics = $true
                                break
                            }
                        }
                    }

                    if ($hasLogAnalytics) { $vaultsWithDiagnostics++ }

                    $diagnosticDetails += [PSCustomObject]@{
                        KeyVaultName       = $kv.Name
                        HasLogAnalytics    = $hasLogAnalytics
                        DiagnosticSettings = if ($diagSettings) { $diagSettings.Count } else { 0 }
                    }
                } catch {
                    Write-Warning "Error checking diagnostics for Key Vault $($kv.Name): $($_.Exception.Message)"
                }
            }

            if ($vaultsWithDiagnostics -eq $totalVaults) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($vaultsWithDiagnostics -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($vaultsWithDiagnostics / $totalVaults) * 100, 2)
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalKeyVaults         = $totalVaults
                VaultsWithDiagnostics  = $vaultsWithDiagnostics
                DiagnosticDetails      = $diagnosticDetails
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

function Test-QuestionG0209 {
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
        # Question: Delegate Key Vault instantiation and privileged access and use Azure Policy to enforce a consistent compliant configuration.
        # Check if there are Azure Policy assignments related to Key Vault
        $policies = $global:AzData.Policies

        if (-not $policies) {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
            $rawData = "Unable to retrieve policy assignments. Manual verification required."
        } else {
            $keyVaultPolicyKeywords = @("keyvault", "key vault", "key-vault")
            $kvPolicies = $policies | Where-Object {
                $displayName = if ($_.Properties.displayName) { $_.Properties.displayName } else { $_.DisplayName }
                $policyId = if ($_.Properties.policyDefinitionId) { $_.Properties.policyDefinitionId } else { $_.PolicyDefinitionId }
                $matched = $false
                foreach ($keyword in $keyVaultPolicyKeywords) {
                    if ($displayName -match $keyword -or $policyId -match $keyword) {
                        $matched = $true
                        break
                    }
                }
                $matched
            }

            if ($kvPolicies -and $kvPolicies.Count -gt 0) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
                $rawData = @{
                    KeyVaultPoliciesFound = $kvPolicies.Count
                    PolicyDetails         = $kvPolicies | ForEach-Object {
                        @{
                            Name  = if ($_.Properties.displayName) { $_.Properties.displayName } else { $_.DisplayName }
                            Scope = if ($_.Properties.scope) { $_.Properties.scope } else { $_.Scope }
                        }
                    }
                }
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    Message              = "No Azure Policy assignments related to Key Vault found."
                    TotalPoliciesChecked = $policies.Count
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

function Test-QuestionG0210 {
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
        # Question: Default to Microsoft-managed keys for principal encryption functionality and use customer-managed keys when required.
        # Check encryption configuration via ARG — look for resources using CMK
        $query = @"
resources
| where type in~ ('microsoft.storage/storageaccounts', 'microsoft.sql/servers/databases', 'microsoft.compute/disks')
| extend encryptionType = case(
    type =~ 'microsoft.storage/storageaccounts', tostring(properties.encryption.keySource),
    type =~ 'microsoft.compute/disks', tostring(properties.encryption.type),
    'Unknown')
| extend usesCMK = (encryptionType has 'Vault' or encryptionType has 'Customer')
| project name, type, subscriptionId, encryptionType, usesCMK
"@

        $results = Invoke-AzGraphQueryWithPagination -Query $query

        if (-not $results -or $results.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No encryption-relevant resources found."
        } else {
            # Default to Microsoft-managed keys is the recommendation; CMK is optional when required
            # Having resources = good, using Microsoft-managed keys = default compliant
            $totalResources = $results.Count
            $cmkResources = ($results | Where-Object { $_.usesCMK -eq $true }).Count
            $mmkResources = $totalResources - $cmkResources

            # All resources using some form of encryption is compliant
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100

            $rawData = @{
                TotalResources            = $totalResources
                MicrosoftManagedKeys      = $mmkResources
                CustomerManagedKeys       = $cmkResources
                Message                   = "Resources are using encryption. $mmkResources use Microsoft-managed keys (default), $cmkResources use customer-managed keys."
                ResourceDetails           = $results
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

function Test-QuestionG0212 {
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
        # Question: If you want to bring your own keys, this might not be supported across all considered services.
        # This requires organizational context and service-specific validation — mark as ManualVerificationRequired
        $status = [Status]::ManualVerificationRequired
        $estimatedPercentageApplied = 0
        $rawData = @{
            Message = "BYOK (Bring Your Own Key) support varies across Azure services. Manual review is required to validate that BYOK is supported for all services in use and that appropriate region pairs and disaster recovery regions are configured."
            Link    = "https://learn.microsoft.com/azure/key-vault/general/best-practices"
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

function Test-QuestionG0213 {
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
        # Question: For Sovereign Landing Zone, use Azure Key Vault managed HSM to store your secrets and credentials.
        # Check for Managed HSM resources
        $managedHsms = $global:AzData.Resources | Where-Object { $_.Type -eq "Microsoft.KeyVault/managedHSMs" }

        if ($managedHsms -and $managedHsms.Count -gt 0) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                ManagedHSMCount = $managedHsms.Count
                ManagedHSMs     = $managedHsms | ForEach-Object { @{ Name = $_.Name; Location = $_.Location; ResourceGroup = $_.ResourceGroupName } }
                Message         = "Managed HSM instances found. Sovereign Landing Zone key management requirement met."
            }
        } else {
            # Sovereign-specific — may not be applicable
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
            $rawData = @{
                Message = "No Managed HSM instances found. This check is specific to Sovereign Landing Zone deployments. Verify if Managed HSM is required for your scenario."
                Link    = "https://learn.microsoft.com/industry/sovereignty/key-management"
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

function Test-QuestionG0301 {
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
        # Question: Use Microsoft Entra ID reporting capabilities to generate access control audit reports.
        # Check if Access Reviews are configured in Entra ID
        $accessReviews = $global:GraphData.AccessReviews

        if ($accessReviews -and $accessReviews.Count -gt 0) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                AccessReviewCount = $accessReviews.Count
                AccessReviews     = $accessReviews | ForEach-Object {
                    @{
                        DisplayName = $_.displayName
                        Status      = $_.status
                        Id          = $_.id
                    }
                }
                Message           = "Microsoft Entra ID Access Reviews are configured for access control auditing."
            }
        } else {
            # Check if we have Graph data at all to differentiate no-data vs no-access
            if ($global:GraphData -and $global:GraphData.RoleAssignments) {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
                $rawData = @{
                    Message = "No Access Review definitions found in Microsoft Entra ID. Consider configuring Access Reviews for periodic access control auditing."
                }
            } else {
                $status = [Status]::ManualVerificationRequired
                $estimatedPercentageApplied = 0
                $rawData = "Unable to retrieve Entra ID reporting data. Manual verification required."
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

function Test-QuestionG0302 {
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
        # Question: Export Azure activity logs to Azure Monitor Logs for long-term data retention.
        # Check diagnostic settings on subscriptions for activity log export
        $subscriptions = $global:AzData.Subscriptions

        if (-not $subscriptions -or $subscriptions.Count -eq 0) {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
            $rawData = "No subscriptions available to check."
        } else {
            $totalSubs = $subscriptions.Count
            $subsWithExport = 0
            $exportDetails = @()

            foreach ($sub in $subscriptions) {
                try {
                    Set-AzContext -Subscription $sub.Id -Tenant $global:TenantId | Out-Null
                    $diagSettings = Invoke-AzCmdletSafely -ScriptBlock {
                        Get-AzDiagnosticSetting -ResourceId "/subscriptions/$($sub.Id)" -ErrorAction SilentlyContinue
                    } -CmdletName "Get-AzDiagnosticSetting" -ModuleName "Az.Monitor" -FallbackValue @()

                    $hasExport = $false
                    if ($diagSettings) {
                        foreach ($ds in $diagSettings) {
                            if ($ds.WorkspaceId -or $ds.StorageAccountId) {
                                $hasExport = $true
                                break
                            }
                        }
                    }

                    if ($hasExport) { $subsWithExport++ }

                    $exportDetails += [PSCustomObject]@{
                        SubscriptionName = $sub.Name
                        SubscriptionId   = $sub.Id
                        HasActivityLogExport = $hasExport
                    }
                } catch {
                    Write-Warning "Error checking diagnostic settings for subscription $($sub.Name): $($_.Exception.Message)"
                }
            }

            if ($subsWithExport -eq $totalSubs) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($subsWithExport -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($subsWithExport / $totalSubs) * 100, 2)
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalSubscriptions       = $totalSubs
                SubscriptionsWithExport  = $subsWithExport
                ExportDetails            = $exportDetails
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

function Test-QuestionG0303 {
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
        # Question: Enable Defender Cloud Security Posture Management (CSPM) plan for all resources.
        # Check Microsoft Defender for Cloud pricing tiers via ARG
        $query = @"
securityresources
| where type == 'microsoft.security/pricings'
| where name =~ 'CloudPosture'
| extend pricingTier = tostring(properties.pricingTier)
| extend subPlan = tostring(properties.subPlan)
| project subscriptionId, name, pricingTier, subPlan
"@

        $results = Invoke-AzGraphQueryWithPagination -Query $query
        $subscriptions = $global:AzData.Subscriptions

        if (-not $results -or $results.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "Defender CSPM plan not found on any subscription."
        } else {
            $totalSubs = if ($subscriptions) { $subscriptions.Count } else { $results.Count }
            $enabledSubs = ($results | Where-Object { $_.pricingTier -eq 'Standard' }).Count

            if ($enabledSubs -ge $totalSubs) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($enabledSubs -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($enabledSubs / $totalSubs) * 100, 2)
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalSubscriptions = $totalSubs
                CSPMEnabled        = $enabledSubs
                PricingDetails     = $results
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

function Test-QuestionG0304 {
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
        # Question: Enable a Microsoft Defender for Servers plan for all cloud servers.
        $query = @"
securityresources
| where type == 'microsoft.security/pricings'
| where name =~ 'VirtualMachines'
| extend pricingTier = tostring(properties.pricingTier)
| extend subPlan = tostring(properties.subPlan)
| project subscriptionId, name, pricingTier, subPlan
"@

        $results = Invoke-AzGraphQueryWithPagination -Query $query
        $subscriptions = $global:AzData.Subscriptions

        if (-not $results -or $results.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "Defender for Servers plan not found on any subscription."
        } else {
            $totalSubs = if ($subscriptions) { $subscriptions.Count } else { $results.Count }
            $enabledSubs = ($results | Where-Object { $_.pricingTier -eq 'Standard' }).Count

            if ($enabledSubs -ge $totalSubs) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($enabledSubs -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($enabledSubs / $totalSubs) * 100, 2)
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalSubscriptions     = $totalSubs
                DefenderServersEnabled = $enabledSubs
                PricingDetails         = $results
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

function Test-QuestionG0305 {
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
        # Question: Enable Defender Cloud Workload Protection Plans for Azure Resources on all subscriptions.
        # Check all Defender plans across subscriptions
        $query = @"
securityresources
| where type == 'microsoft.security/pricings'
| extend pricingTier = tostring(properties.pricingTier)
| project subscriptionId, planName = name, pricingTier
| summarize totalPlans = count(), enabledPlans = countif(pricingTier == 'Standard') by subscriptionId
"@

        $results = Invoke-AzGraphQueryWithPagination -Query $query
        $subscriptions = $global:AzData.Subscriptions

        if (-not $results -or $results.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No Defender pricing information found."
        } else {
            $totalSubs = if ($subscriptions) { $subscriptions.Count } else { $results.Count }
            # A subscription is compliant if it has at least some plans enabled
            $subsWithDefender = ($results | Where-Object { $_.enabledPlans -gt 0 }).Count

            if ($subsWithDefender -ge $totalSubs) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($subsWithDefender -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($subsWithDefender / $totalSubs) * 100, 2)
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalSubscriptions        = $totalSubs
                SubscriptionsWithDefender = $subsWithDefender
                PlanSummary               = $results
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

function Test-QuestionG0306 {
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
        # Question: Enable Endpoint Protection on IaaS Servers.
        # Check for VMs and their extensions for endpoint protection
        $query = @"
resources
| where type =~ 'microsoft.compute/virtualmachines'
| extend vmId = tolower(id)
| join kind=leftouter (
    resources
    | where type =~ 'microsoft.compute/virtualmachines/extensions'
    | extend vmId = tolower(tostring(split(id, '/extensions/')[0]))
    | where properties.type in~ ('MDE.Linux', 'MDE.Windows', 'MicrosoftMonitoringAgent', 'OmsAgentForLinux', 'AzureMonitorLinuxAgent', 'AzureMonitorWindowsAgent', 'EndpointSecurity', 'IaaSAntimalware')
    | project vmId, extensionName = name, extensionType = tostring(properties.type)
    | summarize extensions = make_list(extensionType) by vmId
) on vmId
| extend hasEndpointProtection = isnotnull(extensions) and array_length(extensions) > 0
| project name, vmId, subscriptionId, resourceGroup, hasEndpointProtection
"@

        $results = Invoke-AzGraphQueryWithPagination -Query $query

        if (-not $results -or $results.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No IaaS virtual machines found in the environment."
        } else {
            $totalVMs = $results.Count
            $protectedVMs = ($results | Where-Object { $_.hasEndpointProtection -eq $true }).Count

            if ($protectedVMs -eq $totalVMs) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($protectedVMs -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($protectedVMs / $totalVMs) * 100, 2)
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalVMs      = $totalVMs
                ProtectedVMs  = $protectedVMs
                VMDetails     = $results
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

function Test-QuestionG0307 {
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
        # Question: Monitor base operating system patching drift via Azure Monitor Logs and Defender for Cloud.
        # Check for Azure Update Manager / Update Management configurations
        $query = @"
resources
| where type =~ 'microsoft.compute/virtualmachines'
| extend osType = tostring(properties.storageProfile.osDisk.osType)
| project vmName = name, vmId = tolower(id), subscriptionId, resourceGroup, osType
| join kind=leftouter (
    patchassessmentresources
    | where type =~ 'microsoft.compute/virtualmachines/patchassessmentresults/latest'
    | extend vmId = tolower(tostring(split(id, '/patchAssessmentResults')[0]))
    | extend lastAssessment = tostring(properties.lastModifiedDateTime)
    | extend status = tostring(properties.status)
    | project vmId, lastAssessment, assessmentStatus = status
) on vmId
| extend hasPatching = isnotnull(lastAssessment)
| project vmName, subscriptionId, osType, hasPatching, lastAssessment, assessmentStatus
"@

        $results = Invoke-AzGraphQueryWithPagination -Query $query

        if (-not $results -or $results.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No virtual machines found in the environment."
        } else {
            $totalVMs = $results.Count
            $monitoredVMs = ($results | Where-Object { $_.hasPatching -eq $true }).Count

            if ($monitoredVMs -eq $totalVMs) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($monitoredVMs -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($monitoredVMs / $totalVMs) * 100, 2)
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalVMs      = $totalVMs
                MonitoredVMs  = $monitoredVMs
                VMDetails     = $results
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

function Test-QuestionG0308 {
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
        # Question: Connect default resource configurations to a centralized Azure Monitor Log Analytics workspace.
        # Check for Log Analytics workspaces and resources connected to them
        $query = @"
resources
| where type =~ 'microsoft.operationalinsights/workspaces'
| project workspaceName = name, workspaceId = id, subscriptionId, resourceGroup, location,
    sku = tostring(properties.sku.name),
    retentionDays = toint(properties.retentionInDays)
"@

        $results = Invoke-AzGraphQueryWithPagination -Query $query

        if (-not $results -or $results.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No Log Analytics workspaces found in the environment. A centralized workspace should be configured."
        } else {
            # Having at least one workspace is a good sign
            $totalWorkspaces = $results.Count

            if ($totalWorkspaces -ge 1) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            }

            $rawData = @{
                TotalWorkspaces  = $totalWorkspaces
                WorkspaceDetails = $results
                Message          = "Found $totalWorkspaces Log Analytics workspace(s). Verify that resources are connected to the centralized workspace."
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

function Test-QuestionG0309 {
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
        # Question: Centralized threat detection with correlated logs — SIEM (SecurityInsights / Sentinel)
        # Uses the ARG query from the checklist
        $query = @"
resources
| where type == 'microsoft.operationalinsights/workspaces'
| extend wsid = properties.customerId
| project workspaceResourceId = tolower(id), name, wsid
| join kind=leftouter (
    resources
    | where type == 'microsoft.operationsmanagement/solutions'
    | where name has 'SecurityInsights'
    | extend workspaceResourceId = tostring(tolower(properties.workspaceResourceId))
    | project workspaceResourceId
    | summarize ResourceCount = count() by workspaceResourceId
) on workspaceResourceId
| extend RCount = iff(isnull(ResourceCount), 0, ResourceCount)
| project-away ResourceCount
| extend compliant = (RCount <> 0)
"@

        $results = Invoke-AzGraphQueryWithPagination -Query $query

        if (-not $results -or $results.Count -eq 0) {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = "No Log Analytics workspaces found. A SIEM solution (e.g., Microsoft Sentinel) should be deployed."
        } else {
            $totalWorkspaces = $results.Count
            $compliantWorkspaces = ($results | Where-Object { $_.compliant -eq $true }).Count

            if ($compliantWorkspaces -gt 0) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalWorkspaces     = $totalWorkspaces
                SentinelWorkspaces  = $compliantWorkspaces
                WorkspaceDetails    = $results
                Message             = "$compliantWorkspaces of $totalWorkspaces workspace(s) have Microsoft Sentinel (SecurityInsights) enabled."
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

function Test-QuestionG0310 {
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
        # Question: For Sovereign Landing Zone, enable transparency logs on the Entra ID tenant.
        # Sovereign-specific — cannot be automated, requires manual verification
        $status = [Status]::ManualVerificationRequired
        $estimatedPercentageApplied = 0
        $rawData = @{
            Message = "Transparency logs are a Sovereign Landing Zone requirement. Manual verification is needed to confirm they are enabled on the Entra ID tenant."
            Link    = "https://learn.microsoft.com/industry/sovereignty/transparency-logs"
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

function Test-QuestionG0311 {
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
        # Question: For Sovereign Landing Zone, enable customer Lockbox on the Entra ID tenant.
        # Sovereign-specific — cannot be automated, requires manual verification
        $status = [Status]::ManualVerificationRequired
        $estimatedPercentageApplied = 0
        $rawData = @{
            Message = "Customer Lockbox is a Sovereign Landing Zone requirement. Manual verification is needed to confirm it is enabled on the Entra ID tenant."
            Link    = "https://learn.microsoft.com/azure/security/fundamentals/customer-lockbox-overview"
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

function Test-QuestionG0312 {
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
        # Question: Use an Azure Event Grid-based solution for log-oriented, real-time alerts.
        # Check for Event Grid resources
        $eventGridResources = $global:AzData.Resources | Where-Object {
            $_.Type -like "Microsoft.EventGrid/*"
        }

        if ($eventGridResources -and $eventGridResources.Count -gt 0) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
            $rawData = @{
                EventGridResourceCount = $eventGridResources.Count
                Resources              = $eventGridResources | ForEach-Object {
                    @{ Name = $_.Name; Type = $_.Type; Location = $_.Location }
                }
                Message                = "Event Grid resources found for real-time alert processing."
            }
        } else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
            $rawData = @{
                Message = "No Azure Event Grid resources found. Consider implementing Event Grid for log-oriented, real-time alerts."
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

function Test-QuestionG0402 {
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
        # Question: Enable container soft delete for the storage account to recover a deleted container and its contents.
        $storageAccounts = $global:AzData.Resources | Where-Object { $_.ResourceType -eq "Microsoft.Storage/storageAccounts" }

        if (-not $storageAccounts -or $storageAccounts.Count -eq 0) {
            $status = [Status]::NotApplicable
            $estimatedPercentageApplied = 100
            $rawData = "No storage accounts found in the environment."
        } else {
            $totalAccounts = $storageAccounts.Count
            $compliantAccounts = 0
            $accountDetails = @()

            foreach ($sa in $storageAccounts) {
                try {
                    Set-AzContext -Subscription $sa.SubscriptionId -Tenant $global:TenantId | Out-Null
                    $saDetail = Invoke-AzCmdletSafely -ScriptBlock {
                        Get-AzStorageAccount -ResourceGroupName $sa.ResourceGroupName -Name $sa.Name -ErrorAction SilentlyContinue
                    } -CmdletName "Get-AzStorageAccount" -ModuleName "Az.Storage"

                    $containerSoftDelete = $false
                    if ($saDetail) {
                        $blobServiceProps = Invoke-AzCmdletSafely -ScriptBlock {
                            Get-AzStorageBlobServiceProperty -ResourceGroupName $sa.ResourceGroupName -StorageAccountName $sa.Name -ErrorAction SilentlyContinue
                        } -CmdletName "Get-AzStorageBlobServiceProperty" -ModuleName "Az.Storage"

                        if ($blobServiceProps -and $blobServiceProps.ContainerDeleteRetentionPolicy -and $blobServiceProps.ContainerDeleteRetentionPolicy.Enabled) {
                            $containerSoftDelete = $true
                            $compliantAccounts++
                        }
                    }

                    $accountDetails += [PSCustomObject]@{
                        StorageAccountName     = $sa.Name
                        ResourceGroup          = $sa.ResourceGroupName
                        ContainerSoftDelete    = $containerSoftDelete
                    }
                } catch {
                    Write-Warning "Error checking storage account $($sa.Name): $($_.Exception.Message)"
                }
            }

            if ($compliantAccounts -eq $totalAccounts) {
                $status = [Status]::Implemented
                $estimatedPercentageApplied = 100
            } elseif ($compliantAccounts -gt 0) {
                $status = [Status]::PartiallyImplemented
                $estimatedPercentageApplied = [Math]::Round(($compliantAccounts / $totalAccounts) * 100, 2)
            } else {
                $status = [Status]::NotImplemented
                $estimatedPercentageApplied = 0
            }

            $rawData = @{
                TotalStorageAccounts  = $totalAccounts
                CompliantAccounts     = $compliantAccounts
                AccountDetails        = $accountDetails
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

function Test-QuestionG0501 {
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
        # Question: Separate privileged admin accounts for Azure administrative tasks.
        # Check Entra ID role assignments — look for users with privileged roles that also have regular accounts
        $roleAssignments = $global:GraphData.RoleAssignments
        $roleDefinitions = $global:GraphData.RoleDefinitions

        if (-not $roleAssignments -or -not $roleDefinitions) {
            $status = [Status]::ManualVerificationRequired
            $estimatedPercentageApplied = 0
            $rawData = "Unable to retrieve Entra ID role data. Manual verification required to confirm separate privileged admin accounts."
        } else {
            # Get privileged role IDs (Global Admin, Privileged Role Admin, Security Admin, etc.)
            $privilegedRoleNames = @(
                "Global Administrator",
                "Privileged Role Administrator",
                "Security Administrator",
                "Exchange Administrator",
                "SharePoint Administrator",
                "User Administrator",
                "Billing Administrator"
            )

            $privilegedRoleIds = $roleDefinitions | Where-Object {
                $_.displayName -in $privilegedRoleNames
            } | ForEach-Object { $_.id }

            $privilegedAssignments = $roleAssignments | Where-Object {
                $_.roleDefinitionId -in $privilegedRoleIds
            }

            if ($privilegedAssignments.Count -eq 0) {
                $status = [Status]::NotApplicable
                $estimatedPercentageApplied = 100
                $rawData = "No privileged role assignments found."
            } else {
                # Get unique principal IDs with privileged roles
                $privilegedPrincipals = $privilegedAssignments.principalId | Select-Object -Unique
                $users = $global:GraphData.Users

                if ($users) {
                    # Check if privileged users have admin-style naming (e.g., contains 'admin', 'adm', 'priv')
                    $adminPatterns = @('admin', 'adm\.', 'adm-', 'priv', 'elevated', '-a@', '.a@', '_a@')
                    $usersWithPrivRoles = $users | Where-Object { $_.id -in $privilegedPrincipals }
                    $totalPrivUsers = $usersWithPrivRoles.Count
                    $separateAccounts = 0

                    $userDetails = @()
                    foreach ($user in $usersWithPrivRoles) {
                        $isSeparateAccount = $false
                        foreach ($pattern in $adminPatterns) {
                            if ($user.userPrincipalName -match $pattern -or $user.displayName -match $pattern) {
                                $isSeparateAccount = $true
                                break
                            }
                        }
                        if ($isSeparateAccount) { $separateAccounts++ }

                        $userDetails += [PSCustomObject]@{
                            DisplayName       = $user.displayName
                            UPN               = $user.userPrincipalName
                            IsSeparateAdmin   = $isSeparateAccount
                        }
                    }

                    if ($totalPrivUsers -eq 0) {
                        $status = [Status]::NotApplicable
                        $estimatedPercentageApplied = 100
                    } elseif ($separateAccounts -eq $totalPrivUsers) {
                        $status = [Status]::Implemented
                        $estimatedPercentageApplied = 100
                    } elseif ($separateAccounts -gt 0) {
                        $status = [Status]::PartiallyImplemented
                        $estimatedPercentageApplied = [Math]::Round(($separateAccounts / $totalPrivUsers) * 100, 2)
                    } else {
                        $status = [Status]::NotImplemented
                        $estimatedPercentageApplied = 0
                    }

                    $rawData = @{
                        TotalPrivilegedUsers  = $totalPrivUsers
                        SeparateAdminAccounts = $separateAccounts
                        UserDetails           = $userDetails
                        Message               = "$separateAccounts of $totalPrivUsers privileged users appear to use separate admin accounts (based on naming conventions)."
                    }
                } else {
                    $status = [Status]::ManualVerificationRequired
                    $estimatedPercentageApplied = 0
                    $rawData = "User data not available. Manual verification required."
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

function Test-QuestionG0601 {
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
        # Question: Plan how new Azure services will be implemented.
        # This is an organizational process/planning check — cannot be automated
        $status = [Status]::ManualVerificationRequired
        $estimatedPercentageApplied = 0
        $rawData = @{
            Message = "Service enablement framework planning is an organizational process. Manual verification is required to confirm that a plan exists for implementing new Azure services."
            Link    = "https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/service-enablement-framework"
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

function Test-QuestionG0602 {
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
        # Question: Plan how service request will be fulfilled for Azure services.
        # This is an organizational process/planning check — cannot be automated
        $status = [Status]::ManualVerificationRequired
        $estimatedPercentageApplied = 0
        $rawData = @{
            Message = "Service request fulfillment planning is an organizational process. Manual verification is required to confirm that a plan exists for fulfilling Azure service requests."
            Link    = "https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/service-enablement-framework"
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
