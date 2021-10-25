#!/usr/bin/env pwsh
# Download and extract the latest WSA package

$Script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Import-Module .\wsa.psm1

$wsaProductId = '9p3395vx91nr';
$package = Get-AppxPackage -ProductId $wsaProductId -Ring 'Slow' | Where-Object { $_.Name -ilike '*.msixbundle' } | Sort-Object -Descending Size | Select-Object -First 1
$architecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture

if (!((Test-Path $package.Name) -and (Get-FileHash -Algorithm SHA1 -Path $package.Name -ErrorAction SilentlyContinue).Hash -ieq $package.SHA1)) {
    Write-Output "Downloading" ($package.Name)
    Invoke-WebRequest -Uri $package.Url -OutFile $package.Name
}

$BundlePath = Resolve-Path $package.Name
$bundleExtract = Join-Path -Path (Get-Location) 'BundleExtract'
$msixExtract = Join-Path -Path (Get-Location) ('MsixExtract' + $architecture)

# Extract the bundle file
Expand-Archive -Path $BundlePath -DestinationPath $bundleExtract
Write-Output ($PSStyle.Foreground.Green + "Extracted bundle to $bundleExtract`n" + $PSStyle.Reset)

# Find the msix we need
[xml] $bundleManifest = Get-Content (Join-Path $bundleExtract AppxMetadata AppxBundleManifest.xml)
$package = $bundleManifest.Bundle.Packages.Package | Where-Object { $_.Type -eq 'application' -and $_.Architecture -ieq $architecture }
Expand-Archive -Path (Join-Path $bundleExtract $package.FileName) -DestinationPath $msixExtract
Write-Output ($PSStyle.Foreground.Green + "Extracted package to $msixExtract`n" + $PSStyle.Reset)
