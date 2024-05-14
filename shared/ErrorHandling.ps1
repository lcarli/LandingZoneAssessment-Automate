<#
.SYNOPSIS
    Shared error handling functions.

.DESCRIPTION
    This script contains functions for error handling shared across multiple scripts.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

function Write-Errors {
    param (
        [string]$QuestionID,
        [string]$QuestionText,
        [string]$FunctionName,
        [string]$ErrorMessage
    )

    $errorLogPath = "$PSScriptRoot/../reports/ErrorLog.csv"
    $errorEntry = [PSCustomObject]@{
        QuestionID    = $QuestionID
        QuestionText  = $QuestionText
        FunctionName  = $FunctionName
        ErrorMessage  = $ErrorMessage
    }

    if (-not (Test-Path -Path $errorLogPath)) {
        $errorEntry | Export-Csv -Path $errorLogPath -NoTypeInformation -Append
    } else {
        $errorEntry | Export-Csv -Path $errorLogPath -NoTypeInformation -Append
    }
}

