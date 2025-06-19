# CompareChecklist.ps1
# Script to compare the updated alz_checklist.en.json with existing implementations

param(
    [string]$ChecklistPath = "c:\repos\LandingZoneAssessment-Automate\shared\alz_checklist.en.json",
    [string]$FunctionsPath = "c:\repos\LandingZoneAssessment-Automate\functions"
)

Write-Host "Starting comparison of updated checklist with existing implementations..." -ForegroundColor Green

# Read the updated checklist
$checklist = Get-Content $ChecklistPath | ConvertFrom-Json

# Extract all question IDs and details from the updated checklist
$updatedQuestions = @{}
foreach ($item in $checklist.items) {
    $updatedQuestions[$item.id] = @{
        Id = $item.id
        Category = $item.category
        Subcategory = $item.subcategory
        Text = $item.text
        Severity = $item.severity
        Guid = $item.guid
    }
}

Write-Host "Found $($updatedQuestions.Count) questions in updated checklist" -ForegroundColor Yellow

# Extract all implemented question IDs from function files
$implementedQuestions = @{}
$functionFiles = Get-ChildItem -Path $FunctionsPath -Filter "*.ps1"

foreach ($file in $functionFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Find all Test-Question function declarations
    $testFunctionMatches = [regex]::Matches($content, 'function Test-Question([A-Z0-9]+)\s*{')
    foreach ($match in $testFunctionMatches) {
        $questionId = $match.Groups[1].Value
        # Convert from function name format (e.g., "B0301") to checklist format (e.g., "B03.01")
        if ($questionId -match '^([A-Z])(\d{2})(\d{2})$') {
            $formattedId = "$($matches[1])$($matches[2]).$($matches[3])"
            $implementedQuestions[$formattedId] = @{
                Id = $formattedId
                File = $file.Name
                FunctionName = "Test-Question$questionId"
            }
        }
    }
    
    # Also find questions called in the assessment functions
    $calledQuestionMatches = [regex]::Matches($content, '\$\(\.id -eq "([A-Z]\d{2}\.\d{2})"\)\)')
    foreach ($match in $calledQuestionMatches) {
        $questionId = $match.Groups[1].Value
        if (-not $implementedQuestions.ContainsKey($questionId)) {
            $implementedQuestions[$questionId] = @{
                Id = $questionId
                File = $file.Name
                FunctionName = "Called in assessment"
            }
        }
    }
}

Write-Host "Found $($implementedQuestions.Count) implemented questions in function files" -ForegroundColor Yellow

# Create comparison lists
$newQuestions = @()
$removedQuestions = @()

# Find new questions (in updated checklist but not implemented)
foreach ($questionId in $updatedQuestions.Keys) {
    if (-not $implementedQuestions.ContainsKey($questionId)) {
        $newQuestions += $updatedQuestions[$questionId]
    }
}

# Find removed questions (implemented but not in updated checklist)
foreach ($questionId in $implementedQuestions.Keys) {
    if (-not $updatedQuestions.ContainsKey($questionId)) {
        $removedQuestions += $implementedQuestions[$questionId]
    }
}

# Generate category-based summary report
Write-Host "`n=== COMPARISON SUMMARY ===" -ForegroundColor Cyan
Write-Host "Updated Checklist Questions: $($updatedQuestions.Count)" -ForegroundColor White
Write-Host "Currently Implemented: $($implementedQuestions.Count)" -ForegroundColor White
Write-Host "New Questions to Implement: $($newQuestions.Count)" -ForegroundColor Green
Write-Host "Questions Removed: $($removedQuestions.Count)" -ForegroundColor Red

# Generate detailed statistics by category
Write-Host "`n=== STATISTICS BY CATEGORY ===" -ForegroundColor Cyan

# Get all categories from updated checklist
$categories = $updatedQuestions.Values | Group-Object Category | Sort-Object Name

# Create summary statistics by category
$categorySummary = @{}
foreach ($category in $categories) {
    $categoryName = $category.Name
    $totalQuestions = $category.Count
    
    # Count implemented questions in this category
    $implementedInCategory = 0
    foreach ($question in $category.Group) {
        if ($implementedQuestions.ContainsKey($question.Id)) {
            $implementedInCategory++
        }
    }
      # Count new questions in this category (questions that exist in checklist but are not implemented)
    $newInCategory = $totalQuestions - $implementedInCategory
    
    # Count changed questions would require comparison logic - for now, set to 0
    # This would need the previous version to compare against
    $changedInCategory = 0
    
    $categorySummary[$categoryName] = @{
        Total = $totalQuestions
        Implemented = $implementedInCategory
        New = $newInCategory
        Changed = $changedInCategory
    }
      # Display category statistics
    Write-Host "`n${categoryName}:" -ForegroundColor Yellow
    Write-Host "  Total questions: $totalQuestions" -ForegroundColor White
    Write-Host "  Implemented: $implementedInCategory" -ForegroundColor Green
    Write-Host "  New questions: $newInCategory" -ForegroundColor Cyan
    Write-Host "  Changed questions: $changedInCategory" -ForegroundColor Magenta
    
    if ($totalQuestions -gt 0) {
        $implementedPercent = [math]::Round(($implementedInCategory / $totalQuestions) * 100, 1)
        Write-Host "  Implementation progress: $implementedPercent%" -ForegroundColor Gray
    }
}

# Save detailed results to JSON files
$results = @{
    Summary = @{
        UpdatedChecklistCount = $updatedQuestions.Count
        ImplementedCount = $implementedQuestions.Count
        NewQuestionsCount = $newQuestions.Count
        RemovedQuestionsCount = $removedQuestions.Count
        CategorySummary = $categorySummary
    }
    NewQuestions = $newQuestions | Sort-Object Id
    RemovedQuestions = $removedQuestions | Sort-Object Id
    UpdatedQuestions = $updatedQuestions.Values | Sort-Object Id
}

$outputPath = "c:\repos\LandingZoneAssessment-Automate\comparison_results.json"
$results | ConvertTo-Json -Depth 10 | Out-File $outputPath -Encoding UTF8

Write-Host "`nDetailed results saved to: $outputPath" -ForegroundColor Cyan
Write-Host "`nComparison completed successfully!" -ForegroundColor Green
