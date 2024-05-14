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
        'Az.Portal'
    )

    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "Installing module $module..."
            Install-Module -Name $module -Scope CurrentUser -Force
        } else {
            Write-Host "Module $module is already installed."
        }

        Write-Host "Importing module $module..."
        try {
            Import-Module $module -Force
        }
        catch {
            Write-Host "Error importing module ${module}: $_.Exception.Message"
        }
    }
}


function Initialize-Connect {
    Write-Host "Conectando ao Azure..."
    $configPath = "$PSScriptRoot/../shared/config.json"
    $config = Get-Content -Path $configPath | ConvertFrom-Json
    $TenantId = $config.TenantId
    Set-Variable -Name "TenantId" -Value $TenantId -Scope Global


    try {
        $azContext = Get-AzContext
        if ($null -eq $azContext) {
            Write-Host "No existing Azure connection found. Connecting..."
            Connect-AzAccount -Tenant $TenantId
        } else {
            Write-Host "Already connected to Azure."
        }
    } catch {
        Write-Host "Error checking Azure connection: $_"
        Write-Host "Connecting to Azure..."
        Connect-AzAccount -Tenant $TenantId
    }
}


function Initialize-Environment {
    Get-AzModules
    Initialize-Connect
}

