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