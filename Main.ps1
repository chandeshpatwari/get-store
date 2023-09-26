. "$PSScriptRoot\Functions.ps1"

# Create folders
$downloadPath = Join-Path -Path $PSScriptRoot -ChildPath 'Downloads'
$downloadPath = Join-Path -Path $PWD -ChildPath 'Downloads'

New-Item -Path "$downloadPath\Dependencies" -ItemType Directory -Force | Out-Null
New-Item -Path "$downloadPath\XMLPath" -ItemType Directory -Force | Out-Null
New-Item -Path "$downloadPath\license" -ItemType Directory -Force | Out-Null

# Copy license
#Copy-Item -Path $PSScriptRoot\license -Destination "$downloadPath\license" -Force | Out-Null

# Get 7za
if (!(Test-Path "$downloadPath\7za.exe")) { if ((Read-Host '7za.exe Required. Download?(y.n)').ToLower() -eq 'y') { Write-Host 'Downloading 7za.exe'; Get7za } else { break } }

function ShowMenu {
    Write-Host '1. Install Microsoft.StorePurchaseApp,Microsoft.WindowsStore [Internal]'
    Write-Host '2. Install Microsoft.StorePurchaseApp,Microsoft.WindowsStore [External]'
    Write-Host '3. Install Microsoft.DesktopAppInstaller'
    Write-Host '4. Install Microsoft.XboxIdentityProvider'
    Write-Host '5. Exit'
}

do {
    Clear-Host
    . "$PSScriptRoot\install.ps1"
    ShowMenu
    $ChooseMenu = Read-Host 'Enter your choice'

    switch ($ChooseMenu) {
        '1' { StoreInternal }
        '2' { InstallStorePurchase; InstallStore }
        '3' { InstallWinget }
        '4' { InstallXboxID }
        '5' { exit }
        Default { Write-Host 'Invalid choice. Please select a valid option.' }
    }
    Pause
    Clear-Host
} while ($MainChoice -ne '5')