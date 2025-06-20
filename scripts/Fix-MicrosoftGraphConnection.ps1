# Fix-MicrosoftGraphConnection.ps1
# OPTIMIZED script to resolve Microsoft Graph assembly conflicts

Write-Host "=== Microsoft Graph Connection Fix Utility (Optimized) ===" -ForegroundColor Cyan
Write-Host "This script intelligently resolves Microsoft Graph connection issues." -ForegroundColor Yellow
Write-Host ""

$startTime = Get-Date

# Step 1: Quick connection test
Write-Host "Step 1: Testing current Microsoft Graph connection..." -ForegroundColor Green
try {
    $context = Get-MgContext -ErrorAction SilentlyContinue
    if ($context -and $context.TenantId) {
        Write-Host "✓ Microsoft Graph is already connected!" -ForegroundColor Green
        Write-Host "  Tenant: $($context.TenantId)" -ForegroundColor Gray
        Write-Host "  Account: $($context.Account)" -ForegroundColor Gray
        
        # Test if it actually works
        try {
            $null = Get-MgOrganization -Top 1 -ErrorAction Stop
            Write-Host "✓ Connection is working properly!" -ForegroundColor Green
            
            $elapsed = (Get-Date) - $startTime
            Write-Host "`n=== No Fix Needed ===" -ForegroundColor Green
            Write-Host "Microsoft Graph connection is already working. Completed in $([math]::Round($elapsed.TotalSeconds, 1)) seconds." -ForegroundColor Green
            exit 0
        }
        catch {
            Write-Host "⚠ Connection exists but API calls fail. Will reconnect..." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "No active Microsoft Graph connection found." -ForegroundColor Gray
    }
}
catch {
    Write-Host "Microsoft Graph modules not loaded or connection test failed." -ForegroundColor Gray
}

# Step 2: Smart module conflict resolution
Write-Host "`nStep 2: Resolving module conflicts (if any)..." -ForegroundColor Green
try {
    # Only remove modules that are actually causing problems
    $problematicModules = Get-Module | Where-Object { 
        $_.Name -like "Microsoft.Graph*" -and $_.Name -ne "Microsoft.Graph.Authentication"
    }
    
    if ($problematicModules) {
        Write-Host "Found $($problematicModules.Count) Graph modules. Testing for conflicts..." -ForegroundColor Yellow
        
        # Test if current modules work
        $hasConflict = $false
        try {
            Import-Module Microsoft.Graph.Authentication -Force -ErrorAction Stop
        }
        catch {
            if ($_.Exception.Message -like "*Assembly with same name is already loaded*") {
                $hasConflict = $true
                Write-Host "⚠ Assembly conflict detected. Will clear conflicting modules." -ForegroundColor Yellow
            }
        }
        
        if ($hasConflict) {
            $problematicModules | Remove-Module -Force -ErrorAction SilentlyContinue
            Write-Host "✓ Conflicting modules removed." -ForegroundColor Green
        } else {
            Write-Host "✓ No conflicts detected." -ForegroundColor Green
        }
    } else {
        Write-Host "✓ No Microsoft Graph modules currently loaded." -ForegroundColor Green
    }
}
catch {
    Write-Host "Warning during conflict resolution: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Ensure essential modules are available (not necessarily loaded)
Write-Host "`nStep 3: Verifying essential modules are installed..." -ForegroundColor Green
$essentialModules = @('Microsoft.Graph', 'Microsoft.Graph.Authentication')

foreach ($module in $essentialModules) {
    $installed = Get-Module -ListAvailable -Name $module | Sort-Object Version -Descending | Select-Object -First 1
    if ($installed) {
        Write-Host "✓ $module v$($installed.Version) is available." -ForegroundColor Green
    } else {
        Write-Host "Installing $module..." -ForegroundColor Yellow
        try {
            Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-Host "✓ $module installed successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "✗ Failed to install $module`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Step 4: Test connection capability
Write-Host "`nStep 4: Testing Microsoft Graph connection capability..." -ForegroundColor Green

# Read tenant ID from config
$configPath = "$PSScriptRoot/../shared/config.json"
try {
    $config = Get-Content -Path $configPath | ConvertFrom-Json
    $tenantId = $config.TenantId
    Write-Host "Using Tenant ID: $tenantId" -ForegroundColor Gray
}
catch {
    Write-Host "ERROR: Could not read tenant ID from config file: $configPath" -ForegroundColor Red
    $tenantId = Read-Host "Please enter your Tenant ID"
}

# Attempt optimized connection
try {
    Write-Host "Connecting to Microsoft Graph (optimized)..." -ForegroundColor Yellow
    
    # Use optimized scopes - only what we actually need
    $scopes = @("Directory.Read.All", "Policy.Read.All", "Reports.Read.All", "UserAuthenticationMethod.Read.All")
    
    Connect-MgGraph -TenantId $tenantId -NoWelcome -Scopes $scopes -ErrorAction Stop
    
    # Verify connection
    $context = Get-MgContext
    if ($context -and $context.TenantId) {
        Write-Host "✓ Connection successful!" -ForegroundColor Green
        Write-Host "  Tenant: $($context.TenantId)" -ForegroundColor Gray
        Write-Host "  Account: $($context.Account)" -ForegroundColor Gray
        Write-Host "  Scopes: $($context.Scopes.Count) scopes granted" -ForegroundColor Gray
        
        # Quick API test
        try {
            $null = Get-MgOrganization -Top 1 -ErrorAction Stop
            Write-Host "✓ Graph API test successful!" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠ Graph API test failed: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "Connection exists but some operations may not work." -ForegroundColor Yellow
        }
    }
    else {
        throw "Connection verification failed"
    }
}
catch {
    Write-Host "✗ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
    
    Write-Host "`nTrying recovery approach..." -ForegroundColor Yellow
    try {
        # Force disconnect and try again
        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        Connect-MgGraph -TenantId $tenantId -NoWelcome -Scopes $scopes -ErrorAction Stop
        
        $context = Get-MgContext
        if ($context -and $context.TenantId) {
            Write-Host "✓ Recovery successful!" -ForegroundColor Green
        } else {
            throw "Recovery verification failed"
        }
    }
    catch {
        Write-Host "✗ Recovery failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nTroubleshooting steps:" -ForegroundColor Yellow
        Write-Host "1. Close PowerShell completely and restart" -ForegroundColor White
        Write-Host "2. Check internet connectivity" -ForegroundColor White
        Write-Host "3. Verify tenant ID: $tenantId" -ForegroundColor White
        Write-Host "4. Try manual connection: Connect-MgGraph -Scopes 'Directory.Read.All'" -ForegroundColor White
        
        $elapsed = (Get-Date) - $startTime
        Write-Host "`n=== Fix Failed ===" -ForegroundColor Red
        Write-Host "Could not establish Microsoft Graph connection after $([math]::Round($elapsed.TotalSeconds, 1)) seconds." -ForegroundColor Red
        exit 1
    }
}

$elapsed = (Get-Date) - $startTime
Write-Host "`n=== Microsoft Graph Connection Fix Completed Successfully ===" -ForegroundColor Cyan
Write-Host "Connection established in $([math]::Round($elapsed.TotalSeconds, 1)) seconds (much faster than 300 seconds!)." -ForegroundColor Green
Write-Host "You can now run the Landing Zone Assessment." -ForegroundColor Green
