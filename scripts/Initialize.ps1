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

function Initialize-Connect {
    <#
    .SYNOPSIS
        Conectar ao Azure.

    .DESCRIPTION
        Esta função conecta ao Azure usando o método padrão de autenticação.

    .EXAMPLE
        Connect-AzAccount

    .NOTES
        A função requer que o módulo Az esteja instalado e configurado.
    #>
    Write-Host "Conectando ao Azure..."
    $configPath = "$PSScriptRoot/../shared/config.json"
    $config = Get-Content -Path $configPath | ConvertFrom-Json
    $TenantId = $config.TenantId
    Set-Variable -Name "TenantId" -Value $TenantId -Scope Global

    Connect-AzAccount -Tenant $TenantId
}

