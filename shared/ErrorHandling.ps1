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

function Write-ErrorLog {
    param (
        [string]$QuestionID,
        [string]$QuestionText,
        [string]$FunctionName,
        [string]$ErrorMessage
    )

    # Define paths for the CSV and JSON files
    # $errorLogCsvPath = "$PSScriptRoot/../reports/ErrorLog.csv"
    $errorLogJsonPath = "$PSScriptRoot/../reports/ErrorLog.json"

    # Retrieve the category from the global checklist
    $category = ($global:Checklist.items | Where-Object { $_.text -eq $QuestionText }).category

    # Create a new error log entry
    $errorEntry = [PSCustomObject]@{
        Category      = $category
        QuestionID    = $QuestionID
        QuestionText  = $QuestionText
        FunctionName  = $FunctionName
        ErrorMessage  = $ErrorMessage
    }

    # # Handle CSV log
    # if (-not (Test-Path -Path $errorLogCsvPath)) {
    #     # Create the CSV file with headers if it doesn't exist
    #     $errorEntry | Export-Csv -Path $errorLogCsvPath -NoTypeInformation
    # } else {
    #     # Append to the existing CSV file
    #     $errorEntry | Export-Csv -Path $errorLogCsvPath -NoTypeInformation -Append
    # }

    # Handle JSON log
    $errorLogObject = @{
        errorsArray = @()
    }

    if (Test-Path -Path $errorLogJsonPath) {
        # Load existing JSON entries if the file exists
        $existingJsonContent = Get-Content -Path $errorLogJsonPath -Raw
        if ($existingJsonContent.Trim() -ne "") {
            $errorLogObject = $existingJsonContent | ConvertFrom-Json
        }
    }

    # Ensure errorsArray exists and is an array
    if (-not $errorLogObject.errorsArray) {
        $errorLogObject.errorsArray = @()
    }

    # Add the new entry to errorsArray
    $errorLogObject.errorsArray += $errorEntry

    # Save back to the JSON file
    $errorLogObject | ConvertTo-Json -Depth 10 | Set-Content -Path $errorLogJsonPath -Encoding UTF8
}
