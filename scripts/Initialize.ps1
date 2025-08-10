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
    # Disable module auto-loading to prevent conflicts
    $global:PSModuleAutoLoadingPreference = 'None'    
    
    # Required modules: Only Az meta-module and specific Graph modules
    $requiredModules = @(
        'Az', 'Az.ResourceGraph', 'Az.Automation', 'Az.Consumption', 'Az.CostManagement',
        'Az.RecoveryServices', 'Az.OperationalInsights', 'Az.ManagedServices', 'Az.Compute',
        'Az.DataProtection'
    )
    
    # Microsoft Graph modules (install individually as they're not part of Az)
    $graphModules = @(
        'Microsoft.Graph.Authentication', 'Microsoft.Graph.Identity.DirectoryManagement',
        'Microsoft.Graph.Users', 'Microsoft.Graph.Groups', 'Microsoft.Graph.Applications',
        'Microsoft.Graph.Identity.Governance', 'Microsoft.Graph.Identity.SignIns'
    )
    
    $allRequiredModules = $requiredModules + $graphModules
    
    # Check missing modules
    $missingModules = $allRequiredModules | Where-Object { 
        -not (Get-Module -ListAvailable -Name $_ -ErrorAction SilentlyContinue) 
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Warning "Missing modules: $($missingModules -join ', ')"
        
        # Try to install if possible
        if (Get-Command Install-Module -ErrorAction SilentlyContinue) {
            try {
                $missingModules | ForEach-Object {
                    Write-Output "Installing module: $_"
                    Install-Module -Name $_ -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                    
                    # Verify installation
                    $installedModule = Get-Module -ListAvailable -Name $_ -ErrorAction SilentlyContinue
                    if ($installedModule) {
                        Write-Output "  ✓ Module $_ installed successfully (version: $($installedModule.Version))"
                    } else {
                        Write-Warning "  ✗ Module $_ installation failed verification"
                    }
                }
                Write-Output "Module installation completed"
            } catch {
                Write-Error "Failed to install modules: $($_.Exception.Message)"
                Write-Warning "Install manually: Install-Module -Name <ModuleName> -Scope CurrentUser -Force"
                Write-Warning "Affected module: $_"
            }
        } 
        else {
            Write-Warning "Install-Module not available. Install modules manually in regular PowerShell"
            Write-Warning "Required commands:"
            $missingModules | ForEach-Object {
                Write-Warning "  Install-Module -Name $_ -Scope CurrentUser -Force"
            }
        }    
    } else {
        Write-Output "All required modules are already installed"
    }
    
    # More aggressive Graph module cleanup to prevent assembly conflicts
    try {
        # Remove all Microsoft.Graph modules to start fresh
        Get-Module Microsoft.Graph* | Remove-Module -Force -ErrorAction SilentlyContinue
        
        # Also trigger garbage collection to clean up assemblies (best effort)
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    } catch {
        # Ignore cleanup errors
    }
}

function Initialize-Connect {
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

    # Azure connection - check if already connected and module loaded
    try {
        # Check if Az.Accounts is already loaded
        $azAccountsModule = Get-Module -Name Az.Accounts -ErrorAction SilentlyContinue
        if (-not $azAccountsModule) {
            Write-Output "Importing Az.Accounts module..."
            Import-Module Az.Accounts -Force -ErrorAction Stop
        } else {
            Write-Output "Az.Accounts already loaded (version: $($azAccountsModule.Version))"
        }
        
        $azContext = Get-AzContext -ErrorAction SilentlyContinue
        if ($null -eq $azContext -or $azContext.Tenant.Id -ne $global:TenantId) {
            Write-Output "Connecting to Azure..."
            # Disable automatic tenant discovery to prevent cross-tenant operations
            $Env:AZURE_TENANT_ID = $global:TenantId
            Connect-AzAccount -Tenant $global:TenantId | Out-Null
        } else {
            Write-Output "Azure: Already connected to tenant $($azContext.Tenant.Id)"
        }
        
        # Set additional protections against cross-tenant operations
        $Env:AZURE_TENANT_ID = $global:TenantId
        
        Write-Output "Azure: Connected"
    }
    catch {
        Write-Error "Azure connection failed: $($_.Exception.Message)"
        return
    }    # Microsoft Graph connection with intelligent conflict handling
    $global:GraphConnected = $false
    
    try {
        # First check if we can already use Graph commands (module might be loaded)
        try {
            $context = Get-MgContext -ErrorAction SilentlyContinue
            if ($context -and $context.TenantId -eq $global:TenantId) {
                $global:GraphConnected = $true
                Write-Output "Graph: Already connected"
                return
            }
        } 
        catch {
            # Get-MgContext failed, need to load module
        }
        
        # Try to use existing loaded module first
        $authModule = Get-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
        if (-not $authModule) {
            # Module not loaded, try to import
            Write-Output "Importing Microsoft.Graph.Authentication module..."
            try {
                Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
                Write-Output "Microsoft.Graph.Authentication imported successfully"
            } 
            catch {                # Assembly conflict - try alternative approach
                Write-Output "Assembly conflict detected - attempting workaround..."
                
                # Try to connect anyway - sometimes the cmdlets work even with assembly warnings
                try {
                    $scopes = @(
                        "Directory.Read.All", "Policy.Read.All", "Reports.Read.All", 
                        "UserAuthenticationMethod.Read.All", "RoleAssignmentSchedule.Read.Directory",
                        "RoleEligibilitySchedule.Read.Directory", "RoleManagement.Read.Directory"
                    )
                    
                    Connect-MgGraph -TenantId $global:TenantId -Scopes $scopes -NoWelcome -ErrorAction Stop | Out-Null
                    $global:GraphConnected = $true
                    Write-Output "Graph: Connected (workaround successful)"
                    return
                } 
                catch {
                    Write-Output "Graph: Connection failed (assembly conflict)"
                    return
                }
            }
        }
        
        # Module is loaded, try to connect
        $scopes = @(
            "Directory.Read.All", "Policy.Read.All", "Reports.Read.All", 
            "UserAuthenticationMethod.Read.All", "RoleAssignmentSchedule.Read.Directory",
            "RoleEligibilitySchedule.Read.Directory", "RoleManagement.Read.Directory"
        )
        
        Connect-MgGraph -TenantId $global:TenantId -Scopes $scopes -NoWelcome | Out-Null
        $global:GraphConnected = $true
        Write-Output "Graph: Connected"    }
    catch {
        Write-Output "Graph: Connection failed - $($_.Exception.Message)"
    }
}

function Import-RequiredModules {
    # Import Az modules - comprehensive list based on actual function usage
    $azSubModules = @(
        'Az.Accounts', 'Az.Resources', 'Az.Monitor', 'Az.Billing', 'Az.Network', 'Az.Storage', 
        'Az.Sql', 'Az.KeyVault', 'Az.Websites', 'Az.ResourceGraph', 'Az.Automation',
        'Az.Consumption', 'Az.CostManagement', 'Az.RecoveryServices', 'Az.OperationalInsights',
        'Az.ManagedServices', 'Az.Compute', 'Az.DataProtection', 'Az.Profile'
    )
    
    # Check which Az modules are already loaded to avoid unnecessary imports
    $azModulesToImport = @()
    $azAlreadyLoaded = @()
    
    foreach ($module in $azSubModules) {
        $loadedModule = Get-Module -Name $module -ErrorAction SilentlyContinue
        if ($loadedModule) {
            $azAlreadyLoaded += "$module (v$($loadedModule.Version))"
        } else {
            $azModulesToImport += $module
        }
    }
    
    if ($azAlreadyLoaded.Count -gt 0) {
        Write-Output "  Az modules already loaded: $($azAlreadyLoaded.Count)/$($azSubModules.Count)"
    }
    
    if ($azModulesToImport.Count -gt 0) {
        Write-Output "  Importing $($azModulesToImport.Count) Az modules..."
        $successCount = 0
        $failureCount = 0
        
        # Import one by one to provide granular feedback
        foreach ($module in $azModulesToImport) {
            try {
                Import-Module $module -Force -ErrorAction Stop
                Write-Output "    ✓ $module imported successfully"
                $successCount++
            }
            catch {
                Write-Warning "    ✗ Failed to import $module : $($_.Exception.Message)"
                $failureCount++
                
                # For critical modules, show more detailed guidance
                if ($module -in @('Az.Accounts', 'Az.Resources', 'Az.ResourceGraph')) {
                    Write-Warning "      → $module is critical for assessment functionality"
                }
            }
        }
        
        Write-Output "  Module import summary: $successCount successful, $failureCount failed"
        
        if ($failureCount -gt 0) {
            Write-Warning "  Some modules failed to import. Assessment functionality may be limited."
            Write-Warning "  Consider restarting PowerShell and running: Update-Module -Force"
        }
    } else {
        Write-Output "  All required Az modules already loaded - skipping import"
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
                $graphAlreadyLoaded += "$module (v$($loadedModule.Version))"
            } else {
                $graphModulesToImport += $module
            }
        }
        
        if ($graphAlreadyLoaded.Count -gt 0) {
            Write-Output "  Graph modules already loaded: $($graphAlreadyLoaded.Count)/$($graphModules.Count)"
        }

        if ($graphModulesToImport.Count -gt 0) {
            try {
                Write-Output "  Importing $($graphModulesToImport.Count) Graph modules..."
                $graphModulesToImport | ForEach-Object {
                    Import-Module $_ -Force -ErrorAction Stop
                }
                Write-Output "  Graph modules imported successfully"
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
    $global:AzData = [PSCustomObject]@{
        Tenant = Get-AzTenant -TenantId $global:TenantId
        ManagementGroups = @()
        Subscriptions = Get-AzSubscription -TenantId $global:TenantId
        Resources = @()
        Policies = @()
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
        }
        catch {
            Write-Warning "  Failed: $($_.Exception.Message)"
        }
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
    Get-AzModules
    
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