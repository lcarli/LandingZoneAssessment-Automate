<#
.SYNOPSIS
    Master function to create all other functions in real time.

.DESCRIPTION
    This script contains functions to create files to each design area.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>


function Generate-ScriptForCategory {
    param (
        [string]$categoryName,
        [string]$outputFolder
    )

    $sanitizedCategoryName = $categoryName -replace '\s+', '' -replace '[^a-zA-Z0-9]', ''
    $scriptFileName = "$outputFolder\$sanitizedCategoryName.ps1"

    $scriptContent = @"
# $sanitizedCategoryName.ps1

<#
.SYNOPSIS
    Functions related to $sanitizedCategoryName assessment.

.DESCRIPTION
    This script contains functions to evaluate the $sanitizedCategoryName area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

# Import shared modules
Import-Module "`$PSScriptRoot/../shared/Enums.ps1"
Import-Module "`$PSScriptRoot/../shared/ErrorHandling.ps1"

function Invoke-${sanitizedCategoryName}Assessment {
    Write-Host "Evaluating the ${sanitizedCategoryName} design area..."

    `$results = @()

    return `$results
}
"@

    # Write the script content to the file
    Set-Content -Path $scriptFileName -Value $scriptContent
    Write-Host "Created script: $scriptFileName"
}

function Generate-ScriptsFromJson {
    param (
        [string]$jsonFilePath,
        [string]$outputFolder
    )

    # Read and parse the JSON file
    $jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
    Write-Host "Parsed JSON content successfully."

    # Create the output folder if it doesn't exist
    if (-not (Test-Path -Path $outputFolder)) {
        New-Item -Path $outputFolder -ItemType Directory
    }

    # Iterate through each checklist item and generate scripts by category
    foreach ($item in $jsonContent) {
        foreach ($category in $item.categories) {
            $categoryName = $category.name
            Generate-ScriptForCategory -categoryName $categoryName -outputFolder $outputFolder
        }
    }
}