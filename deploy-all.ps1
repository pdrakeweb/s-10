<#
.SYNOPSIS
    Update, pull, build, and OTA-push the current ESPHome config to every
    target device.

.DESCRIPTION
    Runs the full deploy workflow in three steps:
      1. Update to the latest bins  - `pip install --upgrade esphome`
      2. Pull the latest source     - `git pull`
      3. Build and push             - `esphome update-all <targets>`
         (compiles and OTA-uploads a binary for each target file)
    Run this after editing s10.yaml (or any target file), or any time you
    want to make sure every device is running the latest config.

.PARAMETER Targets
    Device config files to deploy. Defaults to every *-s10.yaml file in this
    directory (site-a-s10.yaml, site-b-s10.yaml, ...). The shared s10.yaml base
    file is intentionally excluded — it's not a standalone device config.

.PARAMETER SkipUpgrade
    Skip step 1: upgrading the esphome CLI itself.

.PARAMETER SkipPull
    Skip step 2: pulling the latest source with `git pull`.

.EXAMPLE
    .\deploy-all.ps1

.EXAMPLE
    .\deploy-all.ps1 -Targets site-a-s10.yaml

.EXAMPLE
    .\deploy-all.ps1 -SkipUpgrade -SkipPull
#>
[CmdletBinding()]
param(
    [string[]]$Targets = (Get-ChildItem -Path $PSScriptRoot -Filter "*-s10.yaml" | Select-Object -ExpandProperty Name),
    [switch]$SkipUpgrade,
    [switch]$SkipPull
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not $Targets -or $Targets.Count -eq 0) {
    Write-Error "No *-s10.yaml target files found in $PSScriptRoot"
    exit 1
}

# 1. Update to the latest bins
if (-not $SkipUpgrade) {
    Write-Host "==> [1/3] Upgrading esphome CLI..." -ForegroundColor Cyan
    pip install --upgrade esphome
    if ($LASTEXITCODE -ne 0) {
        Write-Error "pip install --upgrade esphome failed"
        exit $LASTEXITCODE
    }
}

# 2. Pull the latest source
if (-not $SkipPull) {
    Write-Host "==> [2/3] Pulling latest source..." -ForegroundColor Cyan
    $null = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "No upstream tracking branch configured -- skipping git pull. Run 'git remote add origin <url>' and 'git branch --set-upstream-to=origin/master' to enable it."
    }
    else {
        git pull
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git pull failed"
            exit $LASTEXITCODE
        }
    }
}

# 3. Build and push
Write-Host "==> [3/3] Deploying targets: $($Targets -join ', ')" -ForegroundColor Cyan
esphome update-all @Targets
exit $LASTEXITCODE
