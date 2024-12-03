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

function InstallAndImportModule {
    param(
        [string]$ModuleName
    )

    Write-Host "Processing module '$ModuleName'..."

    # Check if the module is installed
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "Module '$ModuleName' not found. Installing..."
        try {
            Install-Module -Name $ModuleName -Scope CurrentUser -Force -ErrorAction Stop
            Write-Host "Module '$ModuleName' installed successfully."
        }
        catch {
            Write-Host "Error installing module '$ModuleName': $($_.Exception.Message)"
            return
        }
    }
    else {
        Write-Host "Module '$ModuleName' is already installed."
    }

    # Check if the module is already imported
    if ($ModuleName -eq "Microsoft.Graph") {
        Write-Host "Skipping module 'Microsoft.Graph'. This module is not allowed to be imported."
    }
    else {
        # Check if the module is already imported
        if (-not (Get-Module -Name $ModuleName)) {
            Write-Host "Importing module '$ModuleName'..."
            try {
                Import-Module $ModuleName -Force -ErrorAction Stop
                Write-Host "Module '$ModuleName' imported successfully."
            }
            catch {
                Write-Host "Error importing module '$ModuleName': $($_.Exception.Message)"
            }
        }
        else {
            Write-Host "Module '$ModuleName' is already imported."
        }
    }

}

function Get-AzModules {
    Write-Host "Getting Azure modules..."
    $requiredModules = @(
        'Az.Accounts',
        'Az.Resources',
        'Az.Compute',
        'Az.Network',
        'Az.Monitor',
        'Az.PolicyInsights',
        'Az.Portal',
        'Az.ResourceGraph',
        'Az.ManagedServices'
        'Az.CostManagement',
        'Microsoft.Graph'
    )

    foreach ($module in $requiredModules) {
        Measure-ExecutionTime -ScriptBlock {
            InstallAndImportModule -ModuleName $module
        } -FunctionName "InstallAndImportModule $module"
        
    }
}

function Initialize-Connect {
    Write-Host "Connecting to Azure..."
    $configPath = "$PSScriptRoot/../shared/config.json"
    
    try {
        $config = Get-Content -Path $configPath | ConvertFrom-Json
        $TenantId = $config.TenantId
        Set-Variable -Name "TenantId" -Value $TenantId -Scope Global
    }
    catch {
        Write-Host "Error reading configuration file: $_.Exception.Message"
        return
    }

    try {
        $azContext = Get-AzContext
        if ($null -eq $azContext) {
            Write-Host "No existing Azure connection found. Connecting..."
            Connect-AzAccount -Tenant $TenantId   
        }
        else {
            if ($azContext.Tenant.Id -eq $TenantId) {
                Write-Host "Already connected to Azure."
                Get-AzContext
            }
            else {
                Write-Host "No existing Azure connection found. Connecting..."
                Connect-AzAccount -Tenant $TenantId
            }  
        }
    }
    catch {
        Write-Host "Error checking Azure connection: $_.Exception.Message"
        Write-Host "Connecting to Azure..."
        try {
            Connect-AzAccount -Tenant $TenantId
        }
        catch {
            Write-Host "Error connecting to Azure: $_.Exception.Message"
        }
    }


    # Check if the user is already connected to Microsoft Graph
    try {
        $graphContext = Get-MgContext
        if (-not $graphContext) {
            Write-Host "You are not connected to Microsoft Graph. Please sign in."
            Connect-MgGraph -TenantId $TenantId -NoWelcome
        }
        else {
            Write-Host "You are already connected to Microsoft Graph."
        }
    }
    catch {
        Write-Host "You are not connected to Microsoft Graph. Please sign in."
        Connect-MgGraph -TenantId $TenantId -NoWelcome
    }
}

function Get-AzData {
    Write-Host "Getting data from Azure..."

    # Initialize global object
    $global:AzData = [PSCustomObject]@{
        Tenant             = Get-AzTenant -TenantId $TenantId
        ManagementGroups   = @()
        Subscriptions      = Get-AzSubscription -TenantId $TenantId
        Resources          = @()
        Policies           = @()
        Users              = @()
    }

    $managementGroups = Get-AzManagementGroup
    foreach ($mg in $managementGroups) {
        try {
            $detailedMG = Get-AzManagementGroup -GroupName $mg.Name
            $global:AzData.ManagementGroups += $detailedMG
        } catch {
            Write-Warning "Unable to retrieve details for Management Group: $($mg.Name). Error: $($_.Exception.Message)"
        }
    }

    foreach ($mg in $global:AzData.ManagementGroups) {
        $policyAssignments = Get-AzPolicyAssignment -Scope $mg.Id
        $global:AzData.Policies += $policyAssignments
    }

    $policyAssignments = Get-AzPolicyAssignment
    $global:AzData.Policies += $policyAssignments

    foreach ($subscription in $global:AzData.Subscriptions) {
        Write-Host "Getting data for subscription: $($subscription.Name)"
        Set-AzContext -Subscription $subscription.Id -Tenant $TenantId

        $resources = Get-AzResource
        $global:AzData.Resources += $resources
    }
}

function Set-GlobalChecklist {
    Write-Host "Setting global checklist..."
    $configPath = "$PSScriptRoot/../shared/config.json"
    $config = Get-Content -Path $configPath | ConvertFrom-Json
    $checklistPath = "$PSScriptRoot/../shared/$($config.AlzChecklist)"
    $checklists = Get-Content -Path $checklistPath | ConvertFrom-Json
    $global:Checklist = $checklists
    $global:ChecklistPath = $checklistPath
}

function New-ReportFolder {
    Write-Host "Ensuring 'reports' folder exists and clearing previous log files..."

    # Define the reports directory path
    $reportsDirectory = "$PSScriptRoot/../reports"
    $errorLogPath = Join-Path -Path $reportsDirectory -ChildPath "ErrorLog.json"
    $reportPath = Join-Path -Path $reportsDirectory -ChildPath "report.json"

    # Check if the reports directory exists; if not, create it
    if (!(Test-Path -Path $reportsDirectory)) {
        New-Item -ItemType Directory -Path $reportsDirectory -Force
        Write-Host "Created 'reports' folder."
    }

    # Remove ErrorLog.json if it exists
    if (Test-Path -Path $errorLogPath) {
        Remove-Item -Path $errorLogPath -Force
        Write-Host "Deleted 'ErrorLog.json'."
    }

    # Remove report.json if it exists
    if (Test-Path -Path $reportPath) {
        Remove-Item -Path $reportPath -Force
        Write-Host "Deleted 'report.json'."
    }
}



function Initialize-Environment {
    Get-AzModules
    Set-GlobalChecklist
    Initialize-Connect
    Get-AzData
    New-ReportFolder
}

