<#
.SYNOPSIS
    Update, pull, build, and OTA-push the current ESPHome config to every
    target device.

.DESCRIPTION
    Runs the full deploy workflow in three steps:
      1. Update to the latest bins  - `pip install --upgrade esphome`
      2. Pull the latest source     - `git pull` (plus the repo sites/ links
                                      into, if sites/ is a link)
      3. Build and push             - `esphome update-all <targets>`
         (compiles and OTA-uploads a binary for each target file)
    Run this after editing s10.yaml (or any target file), or any time you
    want to make sure every device is running the latest config.

.PARAMETER Targets
    Device config files to deploy. Defaults to every *-s10.yaml file in
    sites/. Bare file names are looked up in sites/, so `-Targets foo-s10.yaml`
    means sites/foo-s10.yaml.

.PARAMETER SkipUpgrade
    Skip step 1: upgrading the esphome CLI itself.

.PARAMETER SkipPull
    Skip step 2: pulling the latest source with `git pull`.

.EXAMPLE
    .\deploy-all.ps1

.EXAMPLE
    .\deploy-all.ps1 -Targets example-s10.yaml

.EXAMPLE
    .\deploy-all.ps1 -SkipUpgrade -SkipPull
#>
[CmdletBinding()]
param(
    [string[]]$Targets,
    [switch]$SkipUpgrade,
    [switch]$SkipPull
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$SitesDir = Join-Path $PSScriptRoot 'sites'
if (-not (Test-Path $SitesDir)) {
    Write-Error "No sites/ folder. Create it with your device targets (start from examples/example-s10.yaml), or link it in from wherever you keep them."
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

    # If sites/ is a junction/symlink into another git repo, pull that too.
    $sitesItem = Get-Item $SitesDir -Force
    if ($sitesItem.LinkType) {
        $sitesTarget = $sitesItem.Target | Select-Object -First 1
        $sitesRepo = git -C $sitesTarget rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $sitesRepo) {
            $null = git -C $sitesRepo rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
        }
        if ($LASTEXITCODE -ne 0 -or -not $sitesRepo) {
            Write-Warning "sites/ links to $sitesTarget, which isn't a git repo with an upstream -- not pulling it."
        }
        else {
            Write-Host "    Pulling sites/ repo ($sitesRepo)..." -ForegroundColor Cyan
            git -C $sitesRepo pull --ff-only
            if ($LASTEXITCODE -ne 0) {
                Write-Error "git pull of the sites/ repo failed"
                exit $LASTEXITCODE
            }
        }
    }
}

# Resolve targets after the pull so newly pulled site files are picked up
if (-not $Targets) {
    $Targets = Get-ChildItem -Path $SitesDir -Filter "*-s10.yaml" | ForEach-Object { "sites/$($_.Name)" }
}
else {
    $Targets = $Targets | ForEach-Object {
        if (-not (Test-Path $_) -and (Test-Path (Join-Path $SitesDir $_))) { "sites/$_" } else { $_ }
    }
}
if (-not $Targets -or $Targets.Count -eq 0) {
    Write-Error "No *-s10.yaml target files found in $SitesDir"
    exit 1
}

# 3. Build and push
Write-Host "==> [3/3] Deploying targets: $($Targets -join ', ')" -ForegroundColor Cyan
esphome update-all @Targets
exit $LASTEXITCODE
