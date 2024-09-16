<#
.SYNOPSIS
    Shared functions for multiple uses.

.DESCRIPTION
    This script contains functions for multiple uses shared across multiple scripts.

.LICENSE
    MIT License

.AUTHOR
    maximeroy@microsoft.com
#>

function Set-WeightValue {
    [CmdletBinding()]
    param (
        [string]$Severity
    )

    $weight = 0
    switch ($Severity) {
        'Low' {
            $weight = 1
            break
        }
        'Medium' {
            $weight = 3
            break
        }
        'High' {
            $weight = 5
            break
        }
        Default {
            break
        }
    }
    
    return $weight
}

function Invoke-AzGraphQueryWithPagination {
    param (
        [string]$Query,
        [int]$PageSize = 1000
    )

    $results = @()
    $skipToken = $null

    do {
        $response = Search-AzGraph -Query "$Query" -First $PageSize -SkipToken $skipToken
        $results += $response.Data
        $skipToken = $response.SkipToken
    } while ($skipToken)

    return $results
}

