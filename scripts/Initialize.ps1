<#
.SYNOPSIS
    Initialization and configuration script.

.DESCRIPTION
    This script contains initialization functions, such as Azure authentication.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

function Get-AzModules {
    # -----------------------------------------------------------------------
    # Step 0: Detect and clean up multiple versions of Az modules
    #         Multiple versions cause .NET assembly loading conflicts that
    #         cannot be resolved within a running PowerShell process.
    # -----------------------------------------------------------------------
    Write-Output ""
    Write-Output "Checking for module version conflicts..."
    
    $conflictModules = Get-Module -ListAvailable -Name Az.* -ErrorAction SilentlyContinue |
        Group-Object Name |
        Where-Object { $_.Count -gt 1 }
    
    if ($conflictModules.Count -gt 0) {
        Write-Warning "MULTIPLE VERSIONS DETECTED for $($conflictModules.Count) module(s):"
        $needsCleanup = $false
        foreach ($conflict in $conflictModules) {
            $versions = $conflict.Group | Sort-Object Version -Descending
            $latest = $versions[0].Version
            $oldVersions = $versions | Where-Object { $_.Version -ne $latest }
            Write-Warning "  $($conflict.Name): $($versions.Version -join ', ') (keeping $latest)"
            if ($oldVersions.Count -gt 0) {
                $needsCleanup = $true
            }
        }
        
        if ($needsCleanup) {
            Write-Output ""
            Write-Output "Removing old module versions to prevent assembly conflicts..."
            foreach ($conflict in $conflictModules) {
                $versions = $conflict.Group | Sort-Object Version -Descending
                $latest = $versions[0].Version
                $oldVersions = $versions | Where-Object { $_.Version -ne $latest }
                foreach ($old in $oldVersions) {
                    try {
                        Write-Output "  Removing $($conflict.Name) v$($old.Version)..."
                        # Uninstall if possible
                        Uninstall-Module -Name $conflict.Name -RequiredVersion $old.Version -Force -ErrorAction SilentlyContinue
                        # Also try to remove the folder if Uninstall didn't work
                        if (Test-Path $old.ModuleBase) {
                            Remove-Item -Path $old.ModuleBase -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    }
                    catch {
                        Write-Warning "    Could not remove $($conflict.Name) v$($old.Version): $($_.Exception.Message)"
                    }
                }
            }
            Write-Output "  Cleanup complete."
            Write-Warning ""
            Write-Warning "========================================================================"
            Write-Warning "  Old module versions were removed. You MUST restart PowerShell"
            Write-Warning "  for changes to take effect (assemblies cannot be unloaded at runtime)."
            Write-Warning "  Please close this terminal, open a new one, and run Main.ps1 again."
            Write-Warning "========================================================================"
            Write-Warning ""
            return $false
        }
    }
    else {
        Write-Output "  No version conflicts found."
    }

    # -----------------------------------------------------------------------
    # Step 1: Check required modules and versions
    # -----------------------------------------------------------------------
    # NOTE: Az.Consumption does not exist as a standalone module — its cmdlets (Get-AzConsumptionBudget etc.) are part of Az.Billing
    # NOTE: Az.Profile was renamed to Az.Accounts in Az 6.x and no longer exists
    # NOTE: Az.CostManagement latest on PSGallery is 0.4.x — do not require higher
    $requiredModuleVersions = [ordered]@{
        'Az.Accounts'        = '2.12.0'
        'Az.Resources'       = '6.0.0'
        'Az.Monitor'         = '4.0.0'
        'Az.Billing'         = '2.0.0'   # Also provides Get-AzConsumptionBudget
        'Az.Network'         = '5.0.0'
        'Az.Storage'         = '4.0.0'
        'Az.Sql'             = '3.0.0'
        'Az.KeyVault'        = '4.0.0'
        'Az.Websites'        = '2.0.0'
        'Az.ResourceGraph'   = '0.13.0'
        'Az.Automation'      = '1.9.0'
        'Az.CostManagement'  = '0.3.0'
        'Az.RecoveryServices' = '5.0.0'
        'Az.OperationalInsights' = '2.0.0'
        'Az.ManagedServices' = '1.0.0'
        'Az.Compute'         = '5.0.0'
        'Az.DataProtection'  = '1.0.0'
        'Microsoft.Graph.Authentication'              = '2.0.0'
        'Microsoft.Graph.Identity.DirectoryManagement' = '2.0.0'
        'Microsoft.Graph.Users'                       = '2.0.0'
        'Microsoft.Graph.Groups'                      = '2.0.0'
        'Microsoft.Graph.Applications'                = '2.0.0'
        'Microsoft.Graph.Identity.Governance'         = '2.0.0'
        'Microsoft.Graph.Identity.SignIns'             = '2.0.0'
    }

    $totalModules = $requiredModuleVersions.Count
    $currentIndex = 0
    $modulesToInstall = @()

    Write-Output ""
    Write-Output "Checking $totalModules required modules..."
    Write-Output "-----------------------------------------"

    foreach ($moduleName in $requiredModuleVersions.Keys) {
        $currentIndex++
        $requiredVersion = [version]$requiredModuleVersions[$moduleName]
        Write-Output "  [$currentIndex/$totalModules] Checking $moduleName (>= $requiredVersion)..."

        $available = Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue | Sort-Object Version -Descending
        if (-not $available) {
            Write-Warning "    -> NOT INSTALLED"
            $modulesToInstall += [PSCustomObject]@{
                Name = $moduleName
                MinVersion = $requiredVersion
                InstalledVersion = $null
            }
        }
        elseif ($available[0].Version -lt $requiredVersion) {
            Write-Warning "    -> OUTDATED (installed: $($available[0].Version), required: >= $requiredVersion)"
            $modulesToInstall += [PSCustomObject]@{
                Name = $moduleName
                MinVersion = $requiredVersion
                InstalledVersion = $available[0].Version
            }
        }
        else {
            Write-Output "    -> OK (v$($available[0].Version))"
        }
    }

    Write-Output "-----------------------------------------"

    if ($modulesToInstall.Count -eq 0) {
        Write-Output "All $totalModules modules are installed with compatible versions."
        Write-Output ""
    }
    else {
        Write-Output ""
        Write-Warning "$($modulesToInstall.Count) module(s) need to be installed or updated:"
        $modulesToInstall | ForEach-Object {
            $installedText = if ($_.InstalledVersion) { "installed: $($_.InstalledVersion)" } else { "not installed" }
            Write-Warning "  - $($_.Name) ($installedText, required: >= $($_.MinVersion))"
        }
        Write-Output ""

        if (-not (Get-Command Install-Module -ErrorAction SilentlyContinue)) {
            Write-Warning "Install-Module not available. Install modules manually:"
            $modulesToInstall | ForEach-Object {
                Write-Warning "  Install-Module -Name $($_.Name) -Scope CurrentUser -Force -AllowClobber -MinimumVersion $($_.MinVersion)"
            }
            return $false
        }

        try {
            if (Get-Command Set-PSRepository -ErrorAction SilentlyContinue) {
                $psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
                if ($psGallery -and $psGallery.InstallationPolicy -ne 'Trusted') {
                    Write-Output "Setting PSGallery as Trusted repository..."
                    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
                }
            }
        }
        catch {
            Write-Warning "Unable to set PSGallery as trusted: $($_.Exception.Message)"
        }

        $installFailures = @()
        $installIndex = 0
        foreach ($module in $modulesToInstall) {
            $installIndex++
            try {
                Write-Output "  [$installIndex/$($modulesToInstall.Count)] Installing $($module.Name) (>= $($module.MinVersion))..."
                Install-Module -Name $module.Name -Scope CurrentUser -Force -AllowClobber -MinimumVersion $module.MinVersion -ErrorAction Stop
                $validated = Get-Module -ListAvailable -Name $module.Name -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
                if ($validated -and $validated.Version -ge $module.MinVersion) {
                    Write-Output "    -> Installed successfully (v$($validated.Version))"
                }
                else {
                    $installFailures += $module.Name
                    Write-Warning "    -> Install verification FAILED"
                }
            }
            catch {
                $installFailures += $module.Name
                Write-Warning "    -> FAILED: $($_.Exception.Message)"
            }
        }

        Write-Output ""
        if ($installFailures.Count -gt 0) {
            Write-Warning "Module installation incomplete. Failed: $($installFailures -join ', ')"
            return $false
        }

        Write-Output "All modules installed successfully."
    }

    try {
        Write-Output "Cleaning up loaded Graph modules for fresh import..."
        Get-Module Microsoft.Graph* | Remove-Module -Force -ErrorAction SilentlyContinue
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
    catch {
    }

    return $true
}

function Initialize-Connect {
    [CmdletBinding()]
    param(
        [ValidateSet('Interactive', 'ManagedIdentity', 'ServicePrincipal')]
        [string]$AuthMode = 'Interactive'
    )

    $configPath = "$PSScriptRoot/../shared/config.json"
    
    try {
        $config = Get-Content -Path $configPath | ConvertFrom-Json
        $global:TenantId = $config.TenantId
        $global:DefaultRegion = $config.DefaultRegion
        if (-not $global:DefaultRegion) {
            $global:DefaultRegion = "eastus2"  # Fallback default
        }
    }
    catch {
        Write-Error "Failed to read config file: $($_.Exception.Message)"
        return
    }

    if ($env:LZA_AUTH_MODE) {
        $requestedMode = $env:LZA_AUTH_MODE.Trim()
        if ($requestedMode -in @('Interactive', 'ManagedIdentity', 'ServicePrincipal')) {
            $AuthMode = $requestedMode
        }
    }

    try {
        $azAccountsModule = Get-Module -Name Az.Accounts -ErrorAction SilentlyContinue
        if (-not $azAccountsModule) {
            Write-Output "Importing Az.Accounts module..."
            Import-Module Az.Accounts -Force -ErrorAction Stop
        }
        else {
            Write-Output "Az.Accounts already loaded (version: $($azAccountsModule.Version))"
        }

        $azContext = Get-AzContext -ErrorAction SilentlyContinue

        if ($null -ne $azContext -and $azContext.Tenant.Id -eq $global:TenantId) {
            Write-Output "Azure: Already connected to tenant $($azContext.Tenant.Id)"
        }
        else {
            Write-Output "Connecting to Azure using mode: $AuthMode"
            $Env:AZURE_TENANT_ID = $global:TenantId

            switch ($AuthMode) {
                'ManagedIdentity' {
                    Connect-AzAccount -Identity -Tenant $global:TenantId -ErrorAction Stop | Out-Null
                }
                'ServicePrincipal' {
                    $clientId = $env:AZURE_CLIENT_ID
                    $clientSecret = $env:AZURE_CLIENT_SECRET
                    if (-not $clientId -or -not $clientSecret) {
                        throw "AZURE_CLIENT_ID and AZURE_CLIENT_SECRET are required for ServicePrincipal mode"
                    }
                    $secureSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
                    $spCredential = New-Object System.Management.Automation.PSCredential($clientId, $secureSecret)
                    Connect-AzAccount -ServicePrincipal -Tenant $global:TenantId -Credential $spCredential -ErrorAction Stop | Out-Null
                }
                default {
                    Connect-AzAccount -Tenant $global:TenantId -ErrorAction Stop | Out-Null
                }
            }

            $validatedContext = Get-AzContext -ErrorAction SilentlyContinue
            if ($null -eq $validatedContext -or $validatedContext.Tenant.Id -ne $global:TenantId) {
                throw "Connected Azure context tenant does not match configured tenant $($global:TenantId)"
            }
        }

        $Env:AZURE_TENANT_ID = $global:TenantId
        Write-Output "Azure: Connected"
    }
    catch {
        Write-Error "Azure connection failed: $($_.Exception.Message)"
        return
    }

    $global:GraphConnected = $false

    try {
        try {
            $context = Get-MgContext -ErrorAction SilentlyContinue
            if ($context -and $context.TenantId -eq $global:TenantId) {
                $global:GraphConnected = $true
                Write-Output "Graph: Already connected to tenant $($context.TenantId)"
                return
            }
        }
        catch {
        }

        $authModule = Get-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
        if (-not $authModule) {
            Write-Output "Importing Microsoft.Graph.Authentication module..."
            try {
                Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
                Write-Output "Microsoft.Graph.Authentication imported successfully"
            }
            catch {
                Write-Warning "Graph module import failed: $($_.Exception.Message)"
                return
            }
        }

        $scopes = @(
            "Directory.Read.All", "Policy.Read.All", "Reports.Read.All",
            "UserAuthenticationMethod.Read.All", "RoleAssignmentSchedule.Read.Directory",
            "RoleEligibilitySchedule.Read.Directory", "RoleManagement.Read.Directory"
        )

        switch ($AuthMode) {
            'ManagedIdentity' {
                Connect-MgGraph -TenantId $global:TenantId -Identity -NoWelcome -ErrorAction Stop | Out-Null
            }
            'ServicePrincipal' {
                $clientId = $env:AZURE_CLIENT_ID
                $clientSecret = $env:AZURE_CLIENT_SECRET
                if (-not $clientId -or -not $clientSecret) {
                    throw "AZURE_CLIENT_ID and AZURE_CLIENT_SECRET are required for Graph ServicePrincipal mode"
                }
                $secureSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
                $spCredential = New-Object System.Management.Automation.PSCredential($clientId, $secureSecret)
                Connect-MgGraph -TenantId $global:TenantId -ClientSecretCredential $spCredential -NoWelcome -ErrorAction Stop | Out-Null
            }
            default {
                Connect-MgGraph -TenantId $global:TenantId -Scopes $scopes -NoWelcome -ErrorAction Stop | Out-Null
            }
        }

        $mgContext = Get-MgContext -ErrorAction SilentlyContinue
        if ($null -eq $mgContext -or $mgContext.TenantId -ne $global:TenantId) {
            throw "Connected Graph context tenant does not match configured tenant $($global:TenantId)"
        }

        $global:GraphConnected = $true
        Write-Output "Graph: Connected"
    }
    catch {
        Write-Output "Graph: Connection failed - $($_.Exception.Message)"
    }
}

function Import-RequiredModules {
    Write-Output ""
    Write-Output "Importing required modules..."
    Write-Output "-----------------------------------------"

    # Import Az modules - comprehensive list based on actual function usage
    $azSubModules = @(
        'Az.Accounts', 'Az.Resources', 'Az.Monitor', 'Az.Billing', 'Az.Network', 'Az.Storage', 
        'Az.Sql', 'Az.KeyVault', 'Az.Websites', 'Az.ResourceGraph', 'Az.Automation',
        'Az.CostManagement', 'Az.RecoveryServices', 'Az.OperationalInsights',
        'Az.ManagedServices', 'Az.Compute', 'Az.DataProtection'
    )
    
    # Check which Az modules are already loaded to avoid unnecessary imports
    $azModulesToImport = @()
    $azAlreadyLoaded = @()
    
    foreach ($module in $azSubModules) {
        $loadedModule = Get-Module -Name $module -ErrorAction SilentlyContinue
        if ($loadedModule) {
            $azAlreadyLoaded += $module
        } else {
            $azModulesToImport += $module
        }
    }
    
    if ($azAlreadyLoaded.Count -gt 0) {
        Write-Output "  Az modules already loaded: $($azAlreadyLoaded.Count)/$($azSubModules.Count) (skipping)"
    }
    
    if ($azModulesToImport.Count -gt 0) {
        $successCount = 0
        $failureCount = 0
        $importIndex = 0
        
        foreach ($module in $azModulesToImport) {
            $importIndex++
            try {
                Write-Output "  [$importIndex/$($azModulesToImport.Count)] Importing $module..."
                Import-Module $module -Force -ErrorAction Stop
                $loadedVer = (Get-Module -Name $module -ErrorAction SilentlyContinue).Version
                Write-Output "    -> Loaded (v$loadedVer)"
                $successCount++
            }
            catch {
                Write-Warning "    -> FAILED: $($_.Exception.Message)"
                $failureCount++
                
                if ($module -in @('Az.Accounts', 'Az.Resources', 'Az.ResourceGraph')) {
                    Write-Warning "       $module is CRITICAL for assessment functionality"
                }
            }
        }
        
        Write-Output ""
        Write-Output "  Az import summary: $successCount loaded, $failureCount failed (of $($azModulesToImport.Count))"
        
        if ($failureCount -gt 0) {
            Write-Warning "  Some modules failed to import. Run: Update-Module Az -Force"
        }
    } else {
        Write-Output "  All $($azSubModules.Count) Az modules already loaded."
    }

    # Import Graph modules (only if Graph is connected)
    if ($global:GraphConnected) {
        $graphModules = @(
            'Microsoft.Graph.Identity.DirectoryManagement', 'Microsoft.Graph.Users',
            'Microsoft.Graph.Groups', 'Microsoft.Graph.Applications',
            'Microsoft.Graph.Identity.Governance', 'Microsoft.Graph.Identity.SignIns'
        )

        # Check which Graph modules are already loaded
        $graphModulesToImport = @()
        $graphAlreadyLoaded = @()
        
        foreach ($module in $graphModules) {
            $loadedModule = Get-Module -Name $module -ErrorAction SilentlyContinue
            if ($loadedModule) {
                $graphAlreadyLoaded += $module
            } else {
                $graphModulesToImport += $module
            }
        }
        
        if ($graphAlreadyLoaded.Count -gt 0) {
            Write-Output "  Graph modules already loaded: $($graphAlreadyLoaded.Count)/$($graphModules.Count) (skipping)"
        }

        if ($graphModulesToImport.Count -gt 0) {
            try {
                $gIndex = 0
                foreach ($gModule in $graphModulesToImport) {
                    $gIndex++
                    Write-Output "  [$gIndex/$($graphModulesToImport.Count)] Importing $gModule..."
                    Import-Module $gModule -Force -ErrorAction Stop
                    $gVer = (Get-Module -Name $gModule -ErrorAction SilentlyContinue).Version
                    Write-Output "    -> Loaded (v$gVer)"
                }
                Write-Output "  All Graph modules imported successfully."
            }
            catch {
                Write-Warning "Failed to import Graph modules: $($_.Exception.Message)"
                $global:GraphConnected = $false
            }
        } else {
            Write-Output "  All required Graph modules already loaded - skipping import"
        }
    } else {
        Write-Output "  Graph not connected - skipping Graph module import"
    }
}

function Collect-AzData {
    # Collect Azure data (modules should already be imported at this point)
    $global:AzCache = @{}  # Lazy-load cache for on-demand API calls during assessment
    $global:AzData = [PSCustomObject]@{
        Tenant                = Get-AzTenant -TenantId $global:TenantId
        ManagementGroups      = @()
        Subscriptions         = Get-AzSubscription -TenantId $global:TenantId
        Resources             = @()
        Policies              = @()
        RoleAssignments       = @{}   # hashtable: subscriptionId -> @(role assignments)
        CustomRoleDefinitions = @()   # Azure RBAC custom role definitions (tenant-wide)
        Budgets               = @{}   # hashtable: subscriptionId -> @(budgets)
        KeyVaults             = @()   # Get-AzKeyVault full details (includes EnableRbacAuthorization, SoftDelete, PurgeProtection)
        KeyVaultKeys          = @{}   # hashtable: vaultName -> @(keys)
        KeyVaultCertificates  = @{}   # hashtable: vaultName -> @(certificates)
        StorageAccounts       = @()   # Get-AzStorageAccount full details
        SqlServers            = @()   # Get-AzSqlServer full details
        SqlAdministrators     = @{}   # hashtable: "rg/serverName" -> AD admin object
        VirtualNetworks       = @()   # Get-AzVirtualNetwork full details (includes subnets, peerings)
        Workspaces            = @()   # Get-AzOperationalInsightsWorkspace full details
    }

    # Get Management Groups
    try {
        # Get Management Groups for the specific tenant only
        $context = Get-AzContext
        if ($context -and $context.Tenant.Id -eq $global:TenantId) {
            $mgs = Get-AzManagementGroup -ErrorAction SilentlyContinue
            foreach ($mg in $mgs) {
                $detailed = Get-AzManagementGroup -GroupName $mg.Name -ErrorAction SilentlyContinue
                if ($detailed) { $global:AzData.ManagementGroups += $detailed }
            }
        }
    }
    catch {
        Write-Warning "Management Groups: $($_.Exception.Message)"
    }

    # Get Policy Assignments
    try {
        # Only get policies for the specific tenant context
        $context = Get-AzContext
        if ($context -and $context.Tenant.Id -eq $global:TenantId) {
            $global:AzData.Policies = Get-AzPolicyAssignment -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Warning "Policies: $($_.Exception.Message)"
    }

    # Get Resources from all subscriptions
    $subCount = $global:AzData.Subscriptions.Count
    for ($i = 0; $i -lt $subCount; $i++) {
        $sub = $global:AzData.Subscriptions[$i]
        Write-Output "  Subscription [$($i+1)/$subCount]: $($sub.Name)"
        
        try {
            Set-AzContext -Subscription $sub.Id -Tenant $global:TenantId -ErrorAction Stop | Out-Null
            $resources = Get-AzResource -ErrorAction SilentlyContinue
            if ($resources) { $global:AzData.Resources += $resources }

            # RBAC Role Assignments (used by B03.03)
            try {
                $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($sub.Id)" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
                $global:AzData.RoleAssignments[$sub.Id] = if ($roleAssignments) { @($roleAssignments) } else { @() }
            } catch { $global:AzData.RoleAssignments[$sub.Id] = @() }

            # Budget Alerts (used by E02.02)
            try {
                $budgets = Get-AzConsumptionBudget -ErrorAction SilentlyContinue
                $global:AzData.Budgets[$sub.Id] = if ($budgets) { @($budgets) } else { @() }
            } catch { $global:AzData.Budgets[$sub.Id] = @() }

            # Key Vaults with full config (used by B04.02, F01.08, F01.09)
            try {
                $kvList = Get-AzKeyVault -ErrorAction SilentlyContinue
                foreach ($kv in $kvList) {
                    try {
                        $kvDetail = Get-AzKeyVault -VaultName $kv.VaultName -ResourceGroupName $kv.ResourceGroupName -ErrorAction SilentlyContinue
                        if ($kvDetail) { $global:AzData.KeyVaults += $kvDetail }
                    } catch { $global:AzData.KeyVaults += $kv }

                    # Key Vault Keys (used by F01.09)
                    try {
                        $keys = Get-AzKeyVaultKey -VaultName $kv.VaultName -ErrorAction SilentlyContinue
                        $global:AzData.KeyVaultKeys[$kv.VaultName] = if ($keys) { @($keys) } else { @() }
                    } catch { $global:AzData.KeyVaultKeys[$kv.VaultName] = @() }

                    # Key Vault Certificates (used by G02.04, G02.11)
                    try {
                        $certs = Get-AzKeyVaultCertificate -VaultName $kv.VaultName -ErrorAction SilentlyContinue
                        $global:AzData.KeyVaultCertificates[$kv.VaultName] = if ($certs) { @($certs) } else { @() }
                    } catch { $global:AzData.KeyVaultCertificates[$kv.VaultName] = @() }
                }
            } catch { Write-Warning "  KeyVaults [$($sub.Name)]: $($_.Exception.Message)" }

            # Storage Accounts with full config (used by B04.02 — AAD/RBAC properties)
            try {
                $sas = Get-AzStorageAccount -ErrorAction SilentlyContinue
                if ($sas) { $global:AzData.StorageAccounts += $sas }
            } catch { Write-Warning "  StorageAccounts [$($sub.Name)]: $($_.Exception.Message)" }

            # SQL Servers + AD Administrators (used by B04.02)
            try {
                $sqls = Get-AzSqlServer -ErrorAction SilentlyContinue
                if ($sqls) {
                    $global:AzData.SqlServers += $sqls
                    foreach ($sql in $sqls) {
                        $admin = Get-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $sql.ResourceGroupName -ServerName $sql.ServerName -ErrorAction SilentlyContinue
                        if ($admin) {
                            $global:AzData.SqlAdministrators["$($sql.ResourceGroupName)/$($sql.ServerName)"] = $admin
                        }
                    }
                }
            } catch { Write-Warning "  SqlServers [$($sub.Name)]: $($_.Exception.Message)" }

            # Virtual Networks with full details — subnets, peerings, etc. (used by Network functions)
            try {
                $vnets = Get-AzVirtualNetwork -ErrorAction SilentlyContinue
                if ($vnets) { $global:AzData.VirtualNetworks += $vnets }
            } catch { Write-Warning "  VirtualNetworks [$($sub.Name)]: $($_.Exception.Message)" }

            # Log Analytics Workspaces (used by F01.01, F01.02, F01.03, F01.13)
            try {
                $ws = Get-AzOperationalInsightsWorkspace -ErrorAction SilentlyContinue
                if ($ws) { $global:AzData.Workspaces += $ws }
            } catch { Write-Warning "  Workspaces [$($sub.Name)]: $($_.Exception.Message)" }
        }
        catch {
            Write-Warning "  Failed: $($_.Exception.Message)"
        }
    }
    
    # Custom Azure RBAC Role Definitions — tenant-wide, collected once (used by B03.11)
    try {
        $customRoles = Get-AzRoleDefinition -Scope "/" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Where-Object { $_.IsCustom -eq $true }
        $global:AzData.CustomRoleDefinitions = if ($customRoles) { @($customRoles) } else { @() }
    }
    catch {
        Write-Warning "Custom role definitions: $($_.Exception.Message)"
    }

    Write-Output "Azure data: $($global:AzData.Resources.Count) resources, $($global:AzData.Subscriptions.Count) subscriptions"
}

function Set-GlobalChecklist {
    $configPath = "$PSScriptRoot/../shared/config.json"
    $config = Get-Content -Path $configPath | ConvertFrom-Json
    $checklistPath = "$PSScriptRoot/../shared/$($config.AlzChecklist)"
    $global:Checklist = Get-Content -Path $checklistPath | ConvertFrom-Json
    $global:ChecklistPath = $checklistPath
}

function New-ReportFolder {
    $reportsDirectory = "$PSScriptRoot/../reports"
    
    if (!(Test-Path -Path $reportsDirectory)) {
        New-Item -ItemType Directory -Path $reportsDirectory -Force | Out-Null
    }

    @("ErrorLog.json", "report.json") | ForEach-Object {
        $filePath = Join-Path -Path $reportsDirectory -ChildPath $_
        if (Test-Path -Path $filePath) {
            Remove-Item -Path $filePath -Force
        }
    }
}



function Test-ModulesFunctionality {
    Write-Output "Verifying module functionality..."
    
    $criticalCmdlets = @{
        'Get-AzContext' = 'Az.Accounts'
        'Get-AzResourceGroup' = 'Az.Resources'
        'Search-AzGraph' = 'Az.ResourceGraph'
        'Get-MgContext' = 'Microsoft.Graph.Authentication'
    }
    
    $workingCmdlets = 0
    $totalCmdlets = $criticalCmdlets.Count
    
    foreach ($cmdlet in $criticalCmdlets.Keys) {
        $module = $criticalCmdlets[$cmdlet]
        try {
            $cmd = Get-Command $cmdlet -ErrorAction Stop
            Write-Output "  ✓ $cmdlet is available from $module"
            $workingCmdlets++
        }
        catch {
            Write-Warning "  ✗ $cmdlet not available (expected from $module)"
        }
    }
    
    $functionalityPercentage = [math]::Round(($workingCmdlets / $totalCmdlets) * 100, 1)
    Write-Output "Module functionality check: $workingCmdlets/$totalCmdlets cmdlets available ($functionalityPercentage%)"
    
    if ($functionalityPercentage -lt 75) {
        Write-Warning "Less than 75% of critical cmdlets are available. Assessment may fail."
        Write-Warning "Consider running: Install-Module Az -Force -AllowClobber"
    }
    
    return $functionalityPercentage -ge 75
}

function Initialize-Environment {
    Write-Output "=== Azure Landing Zone Assessment Initialization ==="
    $startTime = Get-Date
    
    # Check for potential conflicts early with clear guidance
    $hasConflicts = Test-ModuleConflicts
    
    Write-Output "Step 1/8: Checking and installing modules..."
    $modulesReady = Get-AzModules
    if (-not $modulesReady) {
        throw "Required modules are missing or failed to install"
    }
    
    Write-Output "Step 2/8: Loading checklist..."
    Set-GlobalChecklist
    
    Write-Output "Step 3/8: Connecting to Azure and Graph..."
    Initialize-Connect
    
    Write-Output "Step 4/8: Importing required modules..."
    Import-RequiredModules
    
    Write-Output "Step 5/8: Verifying module functionality..."
    $modulesWorking = Test-ModulesFunctionality
    
    Write-Output "Step 6/8: Collecting Azure data..."
    Collect-AzData
    
    Write-Output "Step 7/8: Collecting Graph data..."
    Collect-GraphData
    
    Write-Output "Step 8/8: Preparing reports..."
    New-ReportFolder
    
    $duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
    Write-Output "=== Initialization completed in $duration seconds ==="
    
    # Final status summary
    if ($global:GraphConnected -and $modulesWorking) {
        Write-Output "  Status: Full assessment ready (Azure + Graph data, all modules functional)"
    } elseif ($global:GraphConnected) {
        Write-Output "  Status: Partial assessment ready (Azure + Graph data, some module issues)"
    } elseif ($modulesWorking) {
        Write-Output "  Status: Limited assessment ready (Azure data only, modules functional)"
    } else {
        Write-Output "  Status: Basic assessment only (limited functionality due to module issues)"
        if ($hasConflicts) {
            Write-Output "   → For complete assessment: restart PowerShell and try again"
        }
    }
}

function Test-ModuleConflicts {
    $loadedGraphModules = Get-Module Microsoft.Graph* -ErrorAction SilentlyContinue
    if ($loadedGraphModules) {
        return $true
    }
    return $false
}

function Collect-GraphData {
    if (-not $global:GraphConnected) {
        Write-Output "Graph: Not connected, skipping data collection"
        $global:GraphData = @{}
        return
    }

    $global:GraphData = @{}

    # Collect data with detailed progress logging
    $dataTypes = @{
        'Organization' = { Get-MgOrganization -ErrorAction SilentlyContinue }
        'Users' = { Get-MgUser -All -ErrorAction SilentlyContinue }
        'Groups' = { Get-MgGroup -All -ErrorAction SilentlyContinue }
        'Applications' = { Get-MgApplication -All -ErrorAction SilentlyContinue }
        'ServicePrincipals' = { Get-MgServicePrincipal -All -ErrorAction SilentlyContinue }
        'DirectoryRoles' = { Get-MgDirectoryRole -All -ErrorAction SilentlyContinue }
        'Domains' = { Get-MgDomain -All -ErrorAction SilentlyContinue }
        'RoleDefinitions' = { Get-MgRoleManagementDirectoryRoleDefinition -All -ErrorAction SilentlyContinue }
        'RoleAssignments' = { Get-MgRoleManagementDirectoryRoleAssignment -All -ErrorAction SilentlyContinue }
        'ConditionalAccessPolicies' = { Get-MgIdentityConditionalAccessPolicy -All -ErrorAction SilentlyContinue }
        'NamedLocations' = { Get-MgIdentityConditionalAccessNamedLocation -All -ErrorAction SilentlyContinue }
        'AuthenticationMethodPolicies' = { Get-MgPolicyAuthenticationMethodPolicy -ErrorAction SilentlyContinue }
        'SecurityDefaultsPolicy' = { Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy -ErrorAction SilentlyContinue }
        'AccessReviews' = { Get-MgIdentityGovernanceAccessReviewDefinition -All -ErrorAction SilentlyContinue }
    }

    $totalTypes = $dataTypes.Count
    $currentType = 0
    $totalCollected = 0
    
    Write-Output "  Collecting Graph data from $totalTypes sources..."
    
    $dataTypes.GetEnumerator() | ForEach-Object {
        $currentType++
        $typeName = $_.Key
        
        Write-Output "  [$currentType/$totalTypes] Collecting $typeName..."
        
        try {
            $startTime = Get-Date
            $data = & $_.Value
            $duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
            
            $global:GraphData[$typeName] = $data
            
            $count = 0
            if ($data -is [Array]) { 
                $count = $data.Count
                $totalCollected += $count
            }
            elseif ($null -ne $data) { 
                $count = 1
                $totalCollected++
            }            Write-Output "    > ${typeName}: $count items (${duration}s)"
        }
        catch {
            Write-Warning "    > ${typeName}: Failed - $($_.Exception.Message)"
            $global:GraphData[$typeName] = if ($typeName -in @('Organization', 'AuthenticationMethodPolicies', 'SecurityDefaultsPolicy')) { $null } else { @() }
        }
    }

    Write-Output "Graph data: $totalCollected items collected from $totalTypes sources"
}