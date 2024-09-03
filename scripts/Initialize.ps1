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

function Get-AzModules {
    $requiredModules = @(
        'Az.Accounts',
        'Az.Resources',
        'Az.Compute',
        'Az.Network',
        'Az.Monitor',
        'Az.PolicyInsights',
        'Az.Portal',
        'Az.ResourceGraph'
    )

    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "Installing module $module..."
            try {
                Install-Module -Name $module -Scope CurrentUser -Force
                Write-Host "Module $module installed successfully."
            } catch {
                Write-Host "Error installing module $($module): $($_.Exception.Message)"
                continue
            }
        } else {
            Write-Host "Module $module is already installed."
        }

        Write-Host "Importing module $module..."
        try {
            Import-Module $module -Force
            Write-Host "Module $module imported successfully."
        } catch {
            Write-Host "Error importing module $($module): $($_.Exception.Message)"
        }
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
        $Credential = Get-Credential
        Connect-AzAccount -Tenant $TenantId -Credential $Credential
        Write-Host "Connected to Azure successfully."
    } catch {
        Write-Host "Error connecting to Azure: $_.Exception.Message"
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
}


function Initialize-Environment {
    Get-AzModules
    Initialize-Connect
}

