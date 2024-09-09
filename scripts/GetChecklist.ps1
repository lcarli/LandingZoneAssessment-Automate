
function Get-ALZChecklist {
    $url = "https://raw.githubusercontent.com/Azure/review-checklists/main/checklists/alz_checklist.en.json"
    $jsonFilePath = "$PSScriptRoot/alz_checklist.en.json"

    Invoke-WebRequest -Uri $url -OutFile $jsonFilePath
    Write-Host "Downloaded checklist JSON file successfully."

    $jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
        
    return $jsonContent
}


function Create-DesignAreas {
    param (
        [Parameter(Mandatory=$true)]
        [array]$checklistItems
    )

    $designAreas = @()

    foreach ($item in $checklistItems) {
        $designArea = [pscustomobject]@{
            Category    = $item.category
            SubCategory = $item.subcategory
            Text        = $item.text
            WAF         = $item.waf
            Service     = $item.service
            GUID        = $item.guid
            ID          = $item.id
            Severity    = $item.severity
            Link        = $item.link
            Training    = $item.training
        }
        $designAreas += $designArea
    }

    return $designAreas | Group-Object -Property Category
}


function List-Categories {
    param (
        [Parameter(Mandatory=$true)]
        [array]$groupedDesignAreas
    )

    Write-Host "Available Categories:"
    $categories = $groupedDesignAreas.Values
    for ($i = 0; $i -lt $categories.Count; $i++) {
        Write-Host "$($i+1). $($categories[$i])"
    }

    $selection = Read-Host "Select a category by entering the number"
    $selectedCategory = $categories[$selection - 1]

    Write-Host "Selected Category: $selectedCategory"

    $groupedDesignAreas = $groupedDesignAreas | Where-Object { $_.Name -eq $selectedCategory }
    
    return $groupedDesignAreas
}


function Show-Questions {
    param (
        [Parameter(Mandatory=$true)]
        [array]$selectedDesignArea
    )

    foreach ($item in $selectedDesignArea) {
        $item.Group | ForEach-Object {
            Write-Host "ID: $($_.ID) - Question: $($_.Text)"
        }
    }
}


$checklist = Get-ALZChecklist
$groupedDesignAreas = Create-DesignAreas -checklistItems $checklist.items

$categoryGroup = List-Categories -groupedDesignAreas $groupedDesignAreas
Show-Questions -selectedDesignArea $categoryGroup
