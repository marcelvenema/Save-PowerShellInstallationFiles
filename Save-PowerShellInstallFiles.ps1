<#
.SYNOPSIS
    Save-PowerShellInstallFiles
.DESCRIPTION
    Save the latest version of all Powershell install files to disk.
.INPUTS
    - Destination   # Destination folder
    - Force         # Overwrite destination if exists
.OUTPUTS
    <none>
.NOTES
    Copyright (c) Marcel Venema, 
    Licensed under MIT license.
#>
[CmdletBinding()]
param(
    [string] $Destination = $PSScriptRoot,
    [switch] $Force
)

# Parse Destination parameter
If (-Not (Test-Path $Destination)) {
    Write-Verbose "Destination $Destination does not exists. Using current folder..."
    $Destination = $PSScriptRoot
}

# Get metadata file
$Metadata = Invoke-RestMethod https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json
$Release = $Metadata.ReleaseTag -replace '^v'
Write-Output "Powershell version $Release found on github..."

If (-Not ($Force)) { # Stop if version folder present
    If (Test-Path "$Destination\$Release") {
        Write-Error "Destination '$Destination' already contains folder '$Release'. Cannot continue..."
        Break
    }
}

# Save metadata to destination folder
$Metadata | ConvertTo-Json | Out-File "$Destination\metadata.json" -Force

# Download installation files
$Releases = Invoke-RestMethod "https://api.github.com/repos/PowerShell/PowerShell/releases"
$Assets = $Releases | Where-Object "tag_name" -eq "v$Release" | Select-Object -ExpandProperty assets
ForEach($Asset in $Assets) {
    Write-Output "About to download package '$($Asset.Name)'..."
    $PackagePath = Join-Path -Path "$Destination\$Release" -ChildPath $Asset.Name
    Try {
        Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $PackagePath
    }
    Finally {}
}
