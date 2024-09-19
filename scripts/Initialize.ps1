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

function Install-And-ImportModule {
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
        } catch {
            Write-Host "Error installing module '$ModuleName': $($_.Exception.Message)"
            return
        }
    } else {
        Write-Host "Module '$ModuleName' is already installed."
    }

    # Check if the module is already imported
    if (-not (Get-Module -Name $ModuleName)) {
        Write-Host "Importing module '$ModuleName'..."
        try {
            Import-Module $ModuleName -Force -ErrorAction Stop
            Write-Host "Module '$ModuleName' imported successfully."
        } catch {
            Write-Host "Error importing module '$ModuleName': $($_.Exception.Message)"
        }
    } else {
        Write-Host "Module '$ModuleName' is already imported."
    }
}

function Get-AzModules {
    $requiredModules = @(
        'Az.Accounts',
        'Az.Resources',
        'Az.Compute',
        'Az.Network',
        'Az.Monitor',
        'Az.PolicyInsights',
        'Az.Portal',
        'Az.ResourceGraph',
        'Az.ManagedServices',
        'Az.CostManagement',
        'Microsoft.Graph'
    )

    foreach ($module in $requiredModules) {
        Install-And-ImportModule -ModuleName $module
    }
}

function Initialize-Connect {
    Write-Host "Connecting to Azure..."
    $configPath = "$PSScriptRoot/../shared/config.json"
    
    try {
        $config = Get-Content -Path $configPath | ConvertFrom-Json
        $TenantId = $config.TenantId
        Set-Variable -Name "TenantId" -Value $TenantId -Scope Global
    } catch {
        Write-Host "Error reading configuration file: $_.Exception.Message"
        return
    }

    try {
        $azContext = Get-AzContext
        if ($null -eq $azContext) {
            Write-Host "No existing Azure connection found. Connecting..."
            Connect-AzAccount -Tenant $TenantId
        } else {
            Write-Host "Already connected to Azure."
            Get-AzContext
        }
    } catch {
        Write-Host "Error checking Azure connection: $_.Exception.Message"
        Write-Host "Connecting to Azure..."
        try {
            Connect-AzAccount -Tenant $TenantId
        } catch {
            Write-Host "Error connecting to Azure: $_.Exception.Message"
        }
    }


    # Check if the user is already connected to Microsoft Graph
    try {
        $graphContext = Get-MgContext
        if (-not $graphContext) {
            Write-Host "You are not connected to Microsoft Graph. Please sign in."
            Connect-MgGraph
        } else {
            Write-Host "You are already connected to Microsoft Graph."
        }
    }
    catch {
        Write-Host "You are not connected to Microsoft Graph. Please sign in."
        Connect-MgGraph
    }
}

function Get-AzData {
    Write-Host "Getting data from Azure..."

    $global:AzData = [PSCustomObject]@{
        Tenant        = Get-AzTenant -TenantId $TenantId
        Subscriptions = Get-AzSubscription -TenantId $TenantId
        Resources     = @()
        Policies      = @()
        Users         = @()
    }

    #$global:AzData.Users = Get-MgUser -All

    foreach ($subscription in $global:AzData.Subscriptions) {
        Write-Host "Getting data for subscription: $($subscription.Name)"
        Select-AzSubscription -SubscriptionId $subscription.Id

        $resources = Get-AzResource
        $global:AzData.Resources += $resources

        $policyAssignments = Get-AzPolicyAssignment
        $global:AzData.Policies += $policyAssignments

    }
}

function Set-GlobalChecklist {
    $configPath = "$PSScriptRoot/../shared/config.json"
    $config = Get-Content -Path $configPath | ConvertFrom-Json
    $checklistPath = "$PSScriptRoot/../shared/$($config.AlzChecklist)"
    $checklists = Get-Content -Path $checklistPath | ConvertFrom-Json
    $global:Checklist = $checklists
}


function Initialize-Environment {
    Get-AzModules
    Set-GlobalChecklist
    Initialize-Connect
    Get-AzData
}

