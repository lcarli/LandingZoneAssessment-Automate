<#
.SYNOPSIS
    Orchestrator to create base files to analyze everythjing.

.DESCRIPTION
    This script contains functions to create files and all questions.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>


#Import
. "$PSScriptRoot/FunctionsCreator.ps1"

function Get-ALZChecklist {
    $url = "https://raw.githubusercontent.com/Azure/review-checklists/main/checklists/alz_checklist.en.json"
    $jsonFilePath = "$PSScriptRoot/alz_checklist.en.json"

    Invoke-WebRequest -Uri $url -OutFile $jsonFilePath
    Write-Host "Downloaded checklist JSON file successfully."

    $jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
        
    return $jsonContent
}

# Example usage
$jsonContent = Get-ALZChecklist
$jsonFilePath = ".\scripts\alz_checklist.en.json"
Set-Content -Path $jsonFilePath -Value ($jsonContent | ConvertTo-Json -Depth 32)
$outputFolder = ".\functions"

#Generate-ScriptsFromJson -jsonFilePath $jsonFilePath -outputFolder $outputFolder
# Remove-Item -Path $jsonFilePath -Force
# Write-Host "Deleted JSON file: $jsonFilePath"




