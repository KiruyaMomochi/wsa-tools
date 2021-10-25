Set-StrictMode -Version Latest

class MsSourceMetadata {
    [string] $name
    [string] $product
    [string] $release
    [string] $dependency
    [Int64] $size
    [uri] $url
}

function Get-WsaKernel {
    [CmdletBinding()]
    [OutputType([MsSourceMetadata[]])]
    $json = Invoke-RestMethod 'https://3rdpartysource.microsoft.com/downloads'
    $wsaKernel = $json | Where-Object Name -ILike '*WSA-Linux-Kernel.zip'
    return $wsaKernel
}

function Invoke-WsaXmlPatch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [xml]
        $AppxManifest,
        [Parameter()]
        [string]
        $Identity = $null,
        [Parameter()]
        [string]
        $Publisher = 'CN=Kiruya Momochi, O=Kiruya Momochi, L=Gourmet Edifice, S=Landsol, C=Astraea'
    )

    process {
        # Change identity and publisher
        if ($Identity) {
            $AppxManifest.Package.Identity.Name = $Identity
        }
        if ($Publisher) {
            $AppxManifest.Package.Identity.Publisher = $Publisher
        }

        # Remove capabilities
        $capabilities = $AppxManifest.Package.Capabilities
        $capabilities.Capability.Where({ $_.Name -eq 'customInstallActions' }) | Foreach-Object { $capabilities.RemoveChild($_) }
        $capabilities.CustomCapability | Foreach-Object { $capabilities.RemoveChild($_) }

        # Remove Windows AppxManifest extension
        $extensions = $msixManifest.Package.Extensions
        $extensions.Extension.Where({ $_.Category -like 'windows.customInstall' }) | Foreach-Object { $extensions.RemoveChild($_) }

        return $AppxManifest
    }
}
function Invoke-WsaPackagePatch {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Package = ".",
        [Parameter()]
        [switch]
        $PatchXml = $false
    )

    $Package = Resolve-Path $Package

    Push-Location $Package    
    # Disable signature verification
    Remove-Item -LiteralPath '[Content_Types].xml', 'AppxBlockMap.xml', 'AppxSignature.p7x' -Force -ErrorAction SilentlyContinue 
    Remove-Item -Path 'AppxMetadata' -Recurse -Force -ErrorAction SilentlyContinue
    
    if ($PatchXml) {
        $msixManifestPath = Join-Path -Path $Package 'AppxManifest.xml' -Resolve
        [xml] $msixManifest = Get-Content $msixManifestPath -Raw
        $msixManifest = Invoke-WsaXmlPatch $msixManifest
        $msixManifest.Save($msixManifestPath)
    }

    Pop-Location
}
function Set-WsaMagisk {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Magisk = "."
    )

    $abi = adb shell getprop ro.product.cpu.abi
    if ( $LASTEXITCODE -ne 0 ) {
        Write-Output $abi
        throw "adb shell getprop failed!"
    }
    
    $abi = $abi.Trim()
    $outdir = Join-Path $Magisk native out -Resolve
    $busybox = Join-Path $outdir $abi 'busybox' -Resolve
    $app = Join-Path $Magisk out 'app-debug.apk'
    $script = Join-Path $Magisk scripts emulator.sh
    adb push $busybox $app $script '/data/local/tmp'

    if ( $LASTEXITCODE -ne 0 ) {
        throw "adb push failed!"
    }

    adb shell sh '/data/local/tmp/emulator.sh'
    if ( $LASTEXITCODE -ne 0 ) {
        throw "emulator.sh failed!"
    }
}

class AppxMetadata {
    [uri] $Url
    [string] $Name
    [datetime] $Expire
    [string] $SHA1
    [int64] $Size
}

function Get-AppxPackage {
    <#
    .DESCRIPTION
    Get-AppxPackage Fetch ms store package data from rg-adguard.

    .EXAMPLE
    Get-AppxPackage -ProductId 9p3395vx91nr -Ring 'Slow' 
    #>
    [CmdletBinding()]
    [OutputType([AppxMetadata[]])]
    param (
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "PackageFamilyName")]
        [string]$PackageFamilyName,
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "url")]
        [string]$Url,
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "ProductId")]
        [string]$ProductId,
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "CategoryID")]
        [string]$CategoryID,
        [Parameter(Mandatory = $false,
            Position = 2,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("RP", "Fast", "Slow", "Retail")]
        [string]$Ring = "RP"            
    )
       
    process {
        $url = switch ($PSCmdlet.ParameterSetName) {
            "PackageFamilyName" {
                $PackageFamilyName
            }
            "url" {
                $Url
            }
            "ProductId" {
                $ProductId
            }
            "CategoryID" {
                $CategoryID
            }
            Default {
                throw "Unsupported parameter set!"
            }
        }

        $realRing = switch ($Ring) {
            "RP" {
                "RP"
            }
            "Fast" {
                "WIF"
            }
            "Slow" {
                "WIS"
            }
            "Retail" {
                "Retail"
            }
            Default {
                throw "Unsupported ring!"
            }
        }

        $response = Invoke-WebRequest -Method 'POST' -Uri 'https://store.rg-adguard.net/api/GetFiles' -Body @{
            type = $PSCmdlet.ParameterSetName;
            url  = $url;
            ring = $realRing;
        } -ContentType 'application/x-www-form-urlencoded'

        $template = '<td><a href="(?<Url>.+?)" rel="noreferrer">(?<Name>.+?)</a></td><td align="center">(?<Expire>.+?)</td><td align="center">(?<SHA1>\w+?)</td><td align="center">(?<Size>.+?)</td></tr>'

        foreach ($match in ([regex]::Matches($response.Content, $template))) {
            $Size = $match.Groups["Size"].Value;
            if ($Size.EndsWith(' B')) {
                $Size = $Size.Substring(0, $Size.Length - 2)
            }
            $Size = [int64]($Size.Replace(' ', ''));

            [AppxMetadata] @{
                Url    = $match.Groups["Url"].Value;
                Name   = $match.Groups["Name"].Value;
                Expire = [datetime]::Parse($match.Groups["Expire"].Value);
                SHA1   = $match.Groups["SHA1"].Value;
                Size   = $Size
            }
        }    
    }
}
function Install-WsaMagisk {
    if (-not (Test-Path .\Magisk)) {
        git clone https://github.com/topjohnwu/Magisk --depth=1 --single-branch --recurse-submodules
    }

    Push-Location Magisk
    
    # jdk version should be less than 16: https://youtrack.jetbrains.com/issue/KT-45545
    # $env:ANDROID_SDK_ROOT = Join-Path $env:LOCALAPPDATA Android Sdk
    pip install colorama
    python ./build.py ndk     
    python ./build.py stub
    python ./build.py emulator

    Pop-Location
}

function Test-Admin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")  
}

function Add-WsaPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path,
        [switch]
        $Register = $false
    )

    if (Test-Admin) {
        Add-AppxPackage -Path $Path -Register:$Register
    }
    else {
        Write-Output ($PSStyle.Foreground.Red + "Now we will install the package, please grant admin permission." + $PSStyle.Reset)
        Start-Process powershell.exe `
            -ArgumentList (
            '-NoProfile',
            '-NoLogo',
            '-Command',
            "Add-AppxPackage -Path `"$msixManifestPath`" -Register"
        ) `
            -Verb runAs `
            -Wait
    }
}
