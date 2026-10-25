param(
    [Parameter(Mandatory = $false)]
    [string]$ContainerName = "aras2025_ap",
    
    [Parameter(Mandatory = $true)]
    [string]$LicenseString
)

$ErrorActionPreference = 'Stop'

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Aras Innovator License Update Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if container is running
Write-Host "[1/4] Checking if container '$ContainerName' is running..." -ForegroundColor Cyan
try {
    $container = docker ps --filter "name=$ContainerName" --format "{{.Names}}"
    if (-not $container) {
        throw "Container '$ContainerName' is not running. Please start the container first."
    }
    Write-Host "[OK] Container is running" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}

$configFiles = @(
    "C:\Innovator\innovatorserverconfig.xml",
    "C:\Innovator\vault\InnovatorServerConfig.xml"
)

Write-Host ""
Write-Host "[2/4] Locating configuration files..." -ForegroundColor Cyan
foreach ($configPath in $configFiles) {
    Write-Host "      Config file: $configPath"
}

Write-Host ""
Write-Host "[3/4] Creating backups and updating licenses in container..." -ForegroundColor Cyan

# Escape the license string for use in regex
$escapedLicense = $LicenseString -replace '\\', '\\'
$escapedLicense = $escapedLicense -replace '"', '\"'
$escapedLicense = $escapedLicense -replace "'", "''"

# Command to run inside container using regex replacement
$command = @"
`$configFiles = @(
    'C:\Innovator\innovatorserverconfig.xml',
    'C:\Innovator\vault\InnovatorServerConfig.xml'
)
`$newLicense = '$escapedLicense'

foreach (`$configPath in `$configFiles) {
    if (Test-Path `$configPath) {
        `$backupPath = `$configPath + '.backup'
        
        # Read the config file
        `$content = Get-Content `$configPath -Raw
        
        # Create backup
        Copy-Item `$configPath `$backupPath -Force
        
        # Replace License element using regex
        `$pattern = '<License[^>]*/>'
        if (`$content -match `$pattern) {
            `$updatedContent = `$content -replace `$pattern, `$newLicense
            `$updatedContent | Set-Content `$configPath -Encoding UTF8
            Write-Host "[OK] License updated in: `$configPath" -ForegroundColor Green
            Write-Host "     Backup saved at: `$backupPath" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] License element not found in: `$configPath" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] Config file not found: `$configPath" -ForegroundColor Cyan
    }
}
"@

try {
    $output = docker exec $ContainerName powershell -Command $command 2>&1
    Write-Host $output
    if ($LASTEXITCODE -ne 0) {
        throw "License update failed"
    }
} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}

# Step 4: Recycle the app pools
Write-Host ""
Write-Host "[4/4] Recycling Aras Innovator AppPools..." -ForegroundColor Cyan

$appPools = @(
    "Aras Innovator AppPool ASP.NET Core",
    "Aras Innovator AppPool"
)

foreach ($appPool in $appPools) {
    try {
        docker exec $ContainerName powershell -Command "C:\Windows\System32\inetsrv\appcmd.exe recycle apppool '$appPool'" 2>&1 | Out-Null
        Write-Host "[OK] AppPool '$appPool' recycled" -ForegroundColor Green
    } catch {
        Write-Host "[INFO] AppPool '$appPool' not found or already recycled" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "License update completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Wait 5-10 seconds for the AppPool to restart"
Write-Host "  2. Access http://localhost/innovator/client in your browser"
Write-Host "  3. The new license should now be active"
Write-Host ""
Write-Host "To restore a previous license, run:" -ForegroundColor Yellow
Write-Host "  docker exec aras2025_ap powershell -Command `"Copy-Item 'C:\Innovator\innovatorserverconfig.xml.backup' 'C:\Innovator\innovatorserverconfig.xml' -Force`"" -ForegroundColor Yellow
Write-Host ""
