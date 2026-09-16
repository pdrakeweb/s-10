<#
.SYNOPSIS
    Compile and OTA-push the current ESPHome config to every target device.

.DESCRIPTION
    Wraps `esphome update-all`, which compiles and OTA-uploads a binary for
    each YAML file it's given. Run this after editing s10.yaml (or any
    target file) to push the change out to every device in one go.

.PARAMETER Targets
    Device config files to deploy. Defaults to every *-s10.yaml file in this
    directory (site-a-s10.yaml, site-b-s10.yaml, ...). The shared s10.yaml base
    file is intentionally excluded — it's not a standalone device config.

.PARAMETER SkipUpgrade
    Skip upgrading the esphome CLI itself before deploying.

.EXAMPLE
    .\deploy-all.ps1

.EXAMPLE
    .\deploy-all.ps1 -Targets site-a-s10.yaml

.EXAMPLE
    .\deploy-all.ps1 -SkipUpgrade
#>
[CmdletBinding()]
param(
    [string[]]$Targets = (Get-ChildItem -Path $PSScriptRoot -Filter "*-s10.yaml" | Select-Object -ExpandProperty Name),
    [switch]$SkipUpgrade
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not $Targets -or $Targets.Count -eq 0) {
    Write-Error "No *-s10.yaml target files found in $PSScriptRoot"
    exit 1
}

if (-not $SkipUpgrade) {
    Write-Host "==> Upgrading esphome CLI..." -ForegroundColor Cyan
    pip install --upgrade esphome
    if ($LASTEXITCODE -ne 0) {
        Write-Error "pip install --upgrade esphome failed"
        exit $LASTEXITCODE
    }
}

Write-Host "==> Deploying targets: $($Targets -join ', ')" -ForegroundColor Cyan
esphome update-all @Targets
exit $LASTEXITCODE
