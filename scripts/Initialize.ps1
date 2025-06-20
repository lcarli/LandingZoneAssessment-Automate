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

function Clear-GraphModuleConflicts {
    <#
    .SYNOPSIS
        Clears Microsoft Graph module conflicts only when necessary
    .DESCRIPTION
        Selectively removes only problematic Microsoft Graph modules to prevent assembly loading issues
    #>
    
    Write-Output "Checking for Microsoft Graph module conflicts..."
    
    try {
        # Only look for modules that are known to cause assembly conflicts
        $problematicModules = @(
            'Microsoft.Graph.Authentication'
        )
        
        $modulesToRemove = @()
        foreach ($moduleName in $problematicModules) {
            $loadedModule = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
            if ($loadedModule) {
                # Check if this module is causing issues by testing a simple Graph call
                try {
                    $null = Get-MgContext -ErrorAction Stop
                    # If this works, the module is fine, don't remove it
                    Write-Output "Module '$moduleName' is loaded and working correctly."
                }
                catch {
                    # This module might be causing issues
                    $modulesToRemove += $loadedModule
                    Write-Output "Module '$moduleName' appears to be causing conflicts."
                }
            }
        }
        
        if ($modulesToRemove.Count -gt 0) {
            Write-Output "Removing $($modulesToRemove.Count) problematic modules..."
            $modulesToRemove | Remove-Module -Force -ErrorAction SilentlyContinue
            Write-Output "Problematic modules removed."
            
            # Brief pause to allow cleanup
            Start-Sleep -Milliseconds 500
        } else {
            Write-Output "No conflicting modules found."
        }
    }
    catch {
        Write-Output "Warning during conflict check: $($_.Exception.Message)"
    }
}

function Test-MgGraphConnection {
    <#
    .SYNOPSIS
        Tests if Microsoft Graph connection is working and can execute commands
    .DESCRIPTION
        Validates that Microsoft Graph is connected and can execute basic commands
    .RETURNS
        Boolean indicating if the connection is working
    #>
    
    try {
        # Test basic Graph connection
        $context = Get-MgContext -ErrorAction Stop
        if (-not $context -or -not $context.TenantId) {
            return $false
        }
        
        # Test if we can actually execute a simple Graph command
        $testResult = Get-MgOrganization -Top 1 -ErrorAction Stop
        if ($testResult) {
            return $true
        }
        
        return $false
    }
    catch {
        Write-Output "Microsoft Graph connection test failed: $($_.Exception.Message)"
        return $false
    }
}

function Test-MgGraphConnectionQuick {
    <#
    .SYNOPSIS
        Quick test if Microsoft Graph connection exists (without API calls)
    .DESCRIPTION
        Fast check that only verifies if Get-MgContext returns a valid context
    .RETURNS
        Boolean indicating if there's an active Graph context
    #>
    
    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        return ($context -and $context.TenantId)
    }
    catch {
        return $false
    }
}

function Get-AzModules {
    Write-Output "Checking Azure modules (optimized)..."
    $startTime = Get-Date
    
    # Required modules with their minimum versions
    $requiredModules = @{
        'Az.Accounts' = @{ MinVersion = '2.0.0'; Critical = $true }
        'Microsoft.Graph.Authentication' = @{ MinVersion = '2.0.0'; Critical = $true }
    }

    foreach ($moduleName in $requiredModules.Keys) {
        $moduleInfo = $requiredModules[$moduleName]
        $minVersion = $moduleInfo.MinVersion
        $isCritical = $moduleInfo.Critical
        
        Write-Output "Checking module '$moduleName'..."
        
        # Check if module is already loaded with adequate version
        $loadedModule = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
        if ($loadedModule -and $loadedModule.Version -ge [version]$minVersion) {
            Write-Output "✓ Module '$moduleName' v$($loadedModule.Version) already loaded and compatible."
            continue
        }
        
        # Check if module is available (installed)
        $availableModule = Get-Module -ListAvailable -Name $moduleName | Sort-Object Version -Descending | Select-Object -First 1
        if (-not $availableModule) {
            Write-Output "Installing module '$moduleName'..."
            try {
                Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Write-Output "✓ Module '$moduleName' installed successfully."
                $availableModule = Get-Module -ListAvailable -Name $moduleName | Sort-Object Version -Descending | Select-Object -First 1
            }
            catch {
                Write-Output "✗ Error installing module '$moduleName': $($_.Exception.Message)"
                if ($isCritical) {
                    throw "Critical module installation failed: $moduleName"
                }
                continue
            }
        }
        
        # Import only if not loaded or version is inadequate
        if (-not $loadedModule -or $loadedModule.Version -lt $availableModule.Version) {
            try {
                # For critical modules, import carefully
                if ($moduleName -eq 'Microsoft.Graph.Authentication') {
                    # Only import if we don't have a working Microsoft Graph connection
                    if (-not (Test-MgGraphConnectionQuick)) {
                        Import-Module $moduleName -Force -ErrorAction Stop
                        Write-Output "✓ Module '$moduleName' v$($availableModule.Version) imported."
                    } else {
                        Write-Output "✓ Microsoft Graph already connected, skipping authentication module import."
                    }
                } else {
                    Import-Module $moduleName -Force -ErrorAction Stop
                    Write-Output "✓ Module '$moduleName' v$($availableModule.Version) imported."
                }
            }
            catch {
                Write-Output "⚠ Warning: Could not import '$moduleName': $($_.Exception.Message)"
                if ($isCritical) {
                    Write-Output "Module will be auto-loaded when needed."
                }
            }
        }
    }
    
    $elapsed = (Get-Date) - $startTime
    Write-Output "Module check completed in $([math]::Round($elapsed.TotalSeconds, 1)) seconds."
    Write-Output "Note: Other Az and Microsoft.Graph modules will be auto-loaded as needed."
}

function Initialize-Connect {
    Write-Output "Connecting to Azure..."
    $configPath = "$PSScriptRoot/../shared/config.json"
    
    try {
        $config = Get-Content -Path $configPath | ConvertFrom-Json
        $TenantId = $config.TenantId
        Set-Variable -Name "TenantId" -Value $TenantId -Scope Global
    }
    catch {
        Write-Output "Error reading configuration file: $_.Exception.Message"
        return
    }

    try {
        $azContext = Get-AzContext
        if ($null -eq $azContext) {
            Write-Output "No existing Azure connection found. Connecting..."
            Connect-AzAccount -Tenant $TenantId   
        }
        else {
            if ($azContext.Tenant.Id -eq $TenantId) {
                Write-Output "Already connected to Azure."
                Get-AzContext
            }
            else {
                Write-Output "No existing Azure connection found. Connecting..."
                Connect-AzAccount -Tenant $TenantId
            }  
        }
    }
    catch {
        Write-Output "Error checking Azure connection: $_.Exception.Message"
        Write-Output "Connecting to Azure..."
        try {
            Connect-AzAccount -Tenant $TenantId
        }
        catch {
            Write-Output "Error connecting to Azure: $_.Exception.Message"
        }
    }    # Check if the user is already connected to Microsoft Graph
    Write-Output "Checking Microsoft Graph connection..."
    $startTime = Get-Date
    
    # Quick check - if already connected and working, skip everything
    if (Test-MgGraphConnectionQuick) {
        try {
            $context = Get-MgContext
            Write-Output "✓ Already connected to Microsoft Graph."
            Write-Output "  Tenant: $($context.TenantId)"
            Write-Output "  Account: $($context.Account)"
            
            # Quick validation - try one simple call
            $null = Get-MgContext -ErrorAction Stop
            $elapsed = (Get-Date) - $startTime
            Write-Output "Microsoft Graph connection verified in $([math]::Round($elapsed.TotalSeconds, 1)) seconds."
            return
        }
        catch {
            Write-Output "Existing connection seems invalid, will reconnect..."
        }
    }
    
    # If we get here, we need to establish a new connection
    Write-Output "Establishing Microsoft Graph connection..."
    
    try {
        # Only clear modules if we're having issues
        # Don't clear modules proactively to avoid the 300-second reload
        
        # Attempt connection with optimized scopes
        $scopes = @("Directory.Read.All", "Policy.Read.All", "Reports.Read.All", "UserAuthenticationMethod.Read.All")
        Connect-MgGraph -TenantId $TenantId -NoWelcome -Scopes $scopes -ErrorAction Stop
        
        # Verify connection
        $context = Get-MgContext
        if ($context -and $context.TenantId) {
            Write-Output "✓ Microsoft Graph connection established successfully."
            Write-Output "  Tenant: $($context.TenantId)"
            Write-Output "  Scopes: $($context.Scopes -join ', ')"
        } else {
            throw "Connection verification failed - no valid context found"
        }
        
        $elapsed = (Get-Date) - $startTime
        Write-Output "Microsoft Graph connection completed in $([math]::Round($elapsed.TotalSeconds, 1)) seconds."
    }
    catch {
        Write-Output "Microsoft Graph connection failed: $($_.Exception.Message)"
        
        # Only now try the more drastic measures
        Write-Output "Attempting recovery with module refresh..."
        try {
            Clear-GraphModuleConflicts
            
            # Try once more with clean modules
            Connect-MgGraph -TenantId $TenantId -NoWelcome -Scopes $scopes -ErrorAction Stop
            
            $context = Get-MgContext
            if ($context -and $context.TenantId) {
                Write-Output "✓ Microsoft Graph connection recovered successfully."
            } else {
                throw "Recovery failed"
            }
        }
        catch {
            Write-Output "CRITICAL: Microsoft Graph connection could not be established."
            Write-Output "Error: $($_.Exception.Message)"
            Write-Output ""
            Write-Output "Possible solutions:"
            Write-Output "1. Restart PowerShell completely and try again"
            Write-Output "2. Run: Disconnect-MgGraph; Connect-MgGraph -Scopes 'Directory.Read.All'"
            Write-Output "3. Check if admin consent is required"
            Write-Output ""
            Write-Output "Some Identity and Access Management assessments will not work."
        }
    }
}

function Get-AzData {
    Write-Output "Getting data from Azure..."

    # Initialize global object
    $global:AzData = [PSCustomObject]@{
        Tenant           = Get-AzTenant -TenantId $TenantId
        ManagementGroups = @()
        Subscriptions    = Get-AzSubscription -TenantId $TenantId
        Resources        = @()
        Policies         = @()
        Users            = @()
    }

    # Get Management Groups with error handling to prevent blocking
    try {
        Write-Output "Retrieving Management Groups..."
        $managementGroups = Get-AzManagementGroup -ErrorAction SilentlyContinue
        if ($managementGroups) {
            foreach ($mg in $managementGroups) {
                try {
                    $detailedMG = Get-AzManagementGroup -GroupName $mg.Name -ErrorAction SilentlyContinue
                    if ($detailedMG) {
                        $global:AzData.ManagementGroups += $detailedMG
                    }
                }
                catch {
                    Write-Warning "Unable to retrieve details for Management Group: $($mg.Name). Skipping..."
                }
            }
        }
        else {
            Write-Output "No Management Groups found or insufficient permissions."
        }
    }
    catch {
        Write-Warning "Error retrieving Management Groups: $($_.Exception.Message). Continuing without MG data..."
    }

    # Get Policy Assignments with timeout protection
    try {
        Write-Output "Retrieving Policy Assignments..."
        
        # Get policies from Management Groups
        foreach ($mg in $global:AzData.ManagementGroups) {
            try {
                $policyAssignments = Get-AzPolicyAssignment -Scope $mg.Id -ErrorAction SilentlyContinue
                if ($policyAssignments) {
                    $global:AzData.Policies += $policyAssignments
                }
            }
            catch {
                Write-Warning "Could not retrieve policies for MG: $($mg.Name)"
            }
        }

        # Get general policy assignments
        $policyAssignments = Get-AzPolicyAssignment -ErrorAction SilentlyContinue
        if ($policyAssignments) {
            $global:AzData.Policies += $policyAssignments
        }
    }
    catch {
        Write-Warning "Error retrieving Policy Assignments: $($_.Exception.Message)"
    }

    # Get Resources from subscriptions with better error handling
    $subscriptionCount = $global:AzData.Subscriptions.Count
    $currentSub = 0
    
    foreach ($subscription in $global:AzData.Subscriptions) {
        $currentSub++
        Write-Output "Getting data for subscription [$currentSub/$subscriptionCount]: $($subscription.Name)"
        
        try {
            Set-AzContext -Subscription $subscription.Id -Tenant $TenantId -ErrorAction Stop
            
            # Get resources with timeout protection
            $resources = Get-AzResource -ErrorAction SilentlyContinue
            if ($resources) {
                $global:AzData.Resources += $resources
                Write-Output "  - Retrieved $($resources.Count) resources"
            }
            else {
                Write-Output "  - No resources found in this subscription"
            }
        }
        catch {
            Write-Warning "  - Error accessing subscription $($subscription.Name): $($_.Exception.Message)"
            continue
        }
    }
    
    Write-Output "Data collection completed. Found $($global:AzData.Resources.Count) total resources across $($global:AzData.Subscriptions.Count) subscriptions."
}

function Set-GlobalChecklist {
    Write-Output "Setting global checklist..."
    $configPath = "$PSScriptRoot/../shared/config.json"
    $config = Get-Content -Path $configPath | ConvertFrom-Json
    $checklistPath = "$PSScriptRoot/../shared/$($config.AlzChecklist)"
    $checklists = Get-Content -Path $checklistPath | ConvertFrom-Json
    $global:Checklist = $checklists
    $global:ChecklistPath = $checklistPath
}

function New-ReportFolder {
    Write-Output "Ensuring 'reports' folder exists and clearing previous log files..."

    # Define the reports directory path
    $reportsDirectory = "$PSScriptRoot/../reports"
    $errorLogPath = Join-Path -Path $reportsDirectory -ChildPath "ErrorLog.json"
    $reportPath = Join-Path -Path $reportsDirectory -ChildPath "report.json"

    # Check if the reports directory exists; if not, create it
    if (!(Test-Path -Path $reportsDirectory)) {
        New-Item -ItemType Directory -Path $reportsDirectory -Force
        Write-Output "Created 'reports' folder."
    }

    # Remove ErrorLog.json if it exists
    if (Test-Path -Path $errorLogPath) {
        Remove-Item -Path $errorLogPath -Force
        Write-Output "Deleted 'ErrorLog.json'."
    }

    # Remove report.json if it exists
    if (Test-Path -Path $reportPath) {
        Remove-Item -Path $reportPath -Force
        Write-Output "Deleted 'report.json'."
    }
}



function Initialize-Environment {
    Write-Output "=== Starting Azure Landing Zone Assessment Initialization ==="
    $initStartTime = Get-Date
    
    Write-Output "Step 1/5: Installing and checking Azure modules..."
    $moduleStartTime = Get-Date
    Get-AzModules
    $moduleEndTime = Get-Date
    Write-Output "Modules completed in $([math]::Round(($moduleEndTime - $moduleStartTime).TotalSeconds, 2)) seconds"
    
    Write-Output "Step 2/5: Setting up global checklist..."
    Set-GlobalChecklist
    
    Write-Output "Step 3/5: Connecting to Azure and Microsoft Graph..."
    $connectStartTime = Get-Date
    Initialize-Connect
    $connectEndTime = Get-Date
    Write-Output "Connection completed in $([math]::Round(($connectEndTime - $connectStartTime).TotalSeconds, 2)) seconds"
    
    Write-Output "Step 4/5: Collecting Azure data..."
    $dataStartTime = Get-Date
    Get-AzData
    $dataEndTime = Get-Date
    Write-Output "Data collection completed in $([math]::Round(($dataEndTime - $dataStartTime).TotalSeconds, 2)) seconds"
    
    Write-Output "Step 5/5: Preparing report folder..."
    New-ReportFolder
    
    $initEndTime = Get-Date
    $totalTime = [math]::Round(($initEndTime - $initStartTime).TotalSeconds, 2)
    Write-Output "=== Initialization completed successfully in $totalTime seconds ==="
}

