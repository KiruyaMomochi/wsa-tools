# Build kernel and replace it using wsl

$Script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Import-Module .\wsa.psm1

$architecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
$msixExtract = Join-Path -Path (Get-Location) ('MsixExtract' + $architecture) -Resolve
$kernelPath = Join-Path -Path $msixExtract 'Tools' 'kernel' -Resolve
$kernelPathWsl = wsl.exe wslpath -a -u $kernelPath

$kernel = Get-WsaKernel | Select-Object -First 1 | ForEach-Object url
wsl.exe sh -c 'mkdir -p /tmp/buildsu && cp ./build-kernel-su.sh /tmp/buildsu'
wsl.exe sh -c "cd /tmp/buildsu && ./build-kernel-su.sh $kernel $kernelPathWsl"
