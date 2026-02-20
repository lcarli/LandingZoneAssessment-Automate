<#
.SYNOPSIS
    Removes old versions of Az modules, keeping only the latest of each.
    Must be run in a CLEAN PowerShell session (pwsh -NoProfile).
#>

Write-Host "==========================================="
Write-Host "  Az Module Version Cleanup"
Write-Host "==========================================="
Write-Host ""

$allAzModules = Get-Module -ListAvailable -Name Az.* | Group-Object Name | Where-Object { $_.Count -gt 1 }
$totalToRemove = 0

foreach ($group in $allAzModules) {
    $versions = $group.Group | Sort-Object Version -Descending
    $keep = $versions[0]
    $remove = $versions | Select-Object -Skip 1
    $totalToRemove += $remove.Count
}

Write-Host "Found $($allAzModules.Count) modules with multiple versions ($totalToRemove old versions to remove)"
Write-Host ""

$removed = 0
$failed = 0

foreach ($group in $allAzModules) {
    $versions = $group.Group | Sort-Object Version -Descending
    $keep = $versions[0]
    $remove = $versions | Select-Object -Skip 1
    
    Write-Host "  $($group.Name): keeping v$($keep.Version), removing $($remove.Count) old version(s)"
    
    foreach ($old in $remove) {
        try {
            # Try Uninstall-Module first
            Uninstall-Module -Name $group.Name -RequiredVersion $old.Version -Force -ErrorAction Stop 2>$null
            Write-Host "    Uninstalled v$($old.Version)"
            $removed++
        }
        catch {
            # Fallback: remove the module folder directly
            if (Test-Path $old.ModuleBase) {
                try {
                    Remove-Item -Path $old.ModuleBase -Recurse -Force -ErrorAction Stop
                    Write-Host "    Removed folder v$($old.Version)"
                    $removed++
                }
                catch {
                    Write-Host "    FAILED to remove v$($old.Version): $($_.Exception.Message)" -ForegroundColor Red
                    $failed++
                }
            }
            else {
                Write-Host "    v$($old.Version) folder not found (already removed?)"
                $removed++
            }
        }
    }
}

Write-Host ""
Write-Host "==========================================="
Write-Host "  Results: $removed removed, $failed failed"
Write-Host "==========================================="

if ($failed -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS! All old versions removed." -ForegroundColor Green
    Write-Host "Close ALL PowerShell terminals and open a new one before running Main.ps1" -ForegroundColor Yellow
}
else {
    Write-Host ""
    Write-Host "Some removals failed. Try running as Administrator:" -ForegroundColor Yellow
    Write-Host "  pwsh -NoProfile -File Debug\CleanupAzModules.ps1" -ForegroundColor Yellow
}
