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

function Get-AzModules {
    Write-Output "Checking Azure modules..."
    
    # Install the complete Az module instead of individual modules for better compatibility
    $requiredModules = @(
        'Az',
        'Az.Accounts',
        'Microsoft.Graph'
    )

    foreach ($module in $requiredModules) {
        Write-Output "Processing module '$module'..."
        
        # Check if the module is installed
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Output "Module '$module' not found. Installing..."
            try {
                Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Write-Output "Module '$module' installed successfully."
            }
            catch {
                Write-Output "Error installing module '$module': $($_.Exception.Message)"
                continue
            }
        }
        else {
            Write-Output "Module '$module' is already installed."
        }

        # Only import essential modules - others will be auto-loaded when needed
        if ($module -eq "Az") {
            # Import only core Az modules to speed up initialization
            $coreModules = @('Az.Accounts', 'Az.Profile')
            foreach ($coreModule in $coreModules) {
                if (Get-Module -ListAvailable -Name $coreModule) {
                    try {
                        Import-Module $coreModule -Force -ErrorAction SilentlyContinue
                        Write-Output "Core module '$coreModule' imported."
                    }
                    catch {
                        Write-Output "Warning: Could not import '$coreModule': $($_.Exception.Message)"
                    }
                }
            }
        }
        # Skip importing Microsoft.Graph - it will be loaded when Connect-MgGraph is called
    }
    
    Write-Output "Module installation completed. Other Az modules will be auto-loaded as needed."
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
    }


    # Check if the user is already connected to Microsoft Graph
    try {
        $graphContext = Get-MgContext
        if (-not $graphContext) {
            Write-Output "You are not connected to Microsoft Graph. Please sign in."
            Connect-MgGraph -TenantId $TenantId -NoWelcome -Scopes "Directory.Read.All Reports.Read.All Policy.Read.All UserAuthenticationMethod.Read.All"
        }
        else {
            Write-Output "You are already connected to Microsoft Graph."
        }
    }
    catch {
        Write-Output "You are not connected to Microsoft Graph. Please sign in."
        Connect-MgGraph -TenantId $TenantId -NoWelcome -Scopes "Directory.Read.All Reports.Read.All Policy.Read.All UserAuthenticationMethod.Read.All"
    }
}

function Get-AzData {
    Write-Output "Getting data from Azure..."

    # Initialize global object
    $global:AzData = [PSCustomObject]@{
        Tenant             = Get-AzTenant -TenantId $TenantId
        ManagementGroups   = @()
        Subscriptions      = Get-AzSubscription -TenantId $TenantId
        Resources          = @()
        Policies           = @()
        Users              = @()
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
                } catch {
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

