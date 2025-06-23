<#
.SYNOPSIS
    Script de inicialização e configuração.

.DESCRIPTION
    Este script contém funções de inicialização, como autenticação ao Azure.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Removed InstallAndImportModule function - functionality integrated into Get-AzModules

function Get-AzModules {    # Disable module auto-loading to prevent conflicts
    $global:PSModuleAutoLoadingPreference = 'None'
    
    $requiredModules = @(
        'Az.Accounts', 'Az.Resources', 'Az.Monitor',
        'Microsoft.Graph.Authentication', 'Microsoft.Graph.Identity.DirectoryManagement',
        'Microsoft.Graph.Users', 'Microsoft.Graph.Groups', 'Microsoft.Graph.Applications',
        'Microsoft.Graph.Identity.Governance', 'Microsoft.Graph.Identity.SignIns'
    )
    
    # Check missing modules
    $missingModules = $requiredModules | Where-Object { 
        -not (Get-Module -ListAvailable -Name $_ -ErrorAction SilentlyContinue) 
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Warning "Missing modules: $($missingModules -join ', ')"
        
        # Try to install if possible
        if (Get-Command Install-Module -ErrorAction SilentlyContinue) {
            try {
                $missingModules | ForEach-Object {
                    Install-Module -Name $_ -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                }
                Write-Output "Modules installed successfully"
            } catch {
                Write-Error "Failed to install modules: $($_.Exception.Message)"
                Write-Warning "Install manually: Install-Module -Name <ModuleName> -Scope CurrentUser -Force"
            }
        } else {
            Write-Warning "Install-Module not available. Install modules manually in regular PowerShell"
        }    }
    
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
    }
    catch {
        Write-Error "Failed to read config file: $($_.Exception.Message)"
        return
    }

    # Azure connection
    try {
        Import-Module Az.Accounts -Force -ErrorAction Stop
        
        $azContext = Get-AzContext -ErrorAction SilentlyContinue
        if ($null -eq $azContext -or $azContext.Tenant.Id -ne $global:TenantId) {
            Connect-AzAccount -Tenant $global:TenantId | Out-Null
        }
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
        } catch {
            # Get-MgContext failed, need to load module
        }
        
        # Try to use existing loaded module first
        $authModule = Get-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
        if (-not $authModule) {
            # Module not loaded, try to import
            try {
                Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            } catch {                # Assembly conflict - try alternative approach
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
                } catch {
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

function Get-AzData {
    # Import required modules (Az.Monitor added for diagnostic settings)
    Import-Module Az.Resources, Az.Monitor -Force -ErrorAction SilentlyContinue

    $global:AzData = [PSCustomObject]@{
        Tenant = Get-AzTenant -TenantId $global:TenantId
        ManagementGroups = @()
        Subscriptions = Get-AzSubscription -TenantId $global:TenantId
        Resources = @()
        Policies = @()
    }

    # Get Management Groups
    try {
        $mgs = Get-AzManagementGroup -ErrorAction SilentlyContinue
        foreach ($mg in $mgs) {
            $detailed = Get-AzManagementGroup -GroupName $mg.Name -ErrorAction SilentlyContinue
            if ($detailed) { $global:AzData.ManagementGroups += $detailed }
        }
    }
    catch {
        Write-Warning "Management Groups: $($_.Exception.Message)"
    }

    # Get Policy Assignments
    try {
        $global:AzData.Policies = Get-AzPolicyAssignment -ErrorAction SilentlyContinue
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



function Initialize-Environment {
    Write-Output "=== Azure Landing Zone Assessment Initialization ==="
    $startTime = Get-Date
    
    # Check for potential conflicts early with clear guidance
    $hasConflicts = Test-ModuleConflicts
    
    Write-Output "Step 1/6: Checking modules..."
    Get-AzModules
    
    Write-Output "Step 2/6: Loading checklist..."
    Set-GlobalChecklist
    
    Write-Output "Step 3/6: Connecting to Azure and Graph..."
    Initialize-Connect
    
    Write-Output "Step 4/6: Collecting Azure data..."
    Get-AzData
    
    Write-Output "Step 5/6: Collecting Graph data..."
    Get-GraphData
    
    Write-Output "Step 6/6: Preparing reports..."
    New-ReportFolder
    
    $duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
    Write-Output "=== Initialization completed in $duration seconds ==="
    
    # Final status summary
    if ($global:GraphConnected) {
        Write-Output "  Status: Full assessment with Azure + Graph data"
    } else {
        Write-Output "  Status: Limited assessment (Azure data only)"
        if ($hasConflicts) {
            Write-Output "   → For complete assessment: restart PowerShell and try again"
        }
    }
}

# Function to check for potential assembly conflicts
function Test-ModuleConflicts {
    $loadedGraphModules = Get-Module Microsoft.Graph* -ErrorAction SilentlyContinue
    if ($loadedGraphModules) {
        Write-Output "⚠️  Microsoft Graph modules already loaded: $($loadedGraphModules.Name -join ', ')"
        Write-Output "⚠️  This may cause assembly conflicts. For full Graph support:"
        Write-Output "   1. Close this PowerShell session completely"
        Write-Output "   2. Open fresh PowerShell session" 
        Write-Output "   3. Run the assessment again"
        Write-Output ""
        return $true
    }
    return $false
}

# Function to collect and cache all Microsoft Graph data
function Get-GraphData {
    if (-not $global:GraphConnected) {
        Write-Output "Graph: Not connected, skipping data collection"
        $global:GraphData = @{}
        return
    }

    Write-Output "  Importing Graph modules..."
    # Import all Graph modules at once - only if not already loaded
    $graphModules = @(
        'Microsoft.Graph.Identity.DirectoryManagement', 'Microsoft.Graph.Users',
        'Microsoft.Graph.Groups', 'Microsoft.Graph.Applications',
        'Microsoft.Graph.Identity.Governance', 'Microsoft.Graph.Identity.SignIns'
    )

    try {
        $graphModules | ForEach-Object {
            if (-not (Get-Module $_ -ErrorAction SilentlyContinue)) {
                Import-Module $_ -Force -ErrorAction Stop
            }
        }
        Write-Output "  Graph modules imported successfully"
    }
    catch {
        Write-Warning "Failed to import Graph modules: $($_.Exception.Message)"
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