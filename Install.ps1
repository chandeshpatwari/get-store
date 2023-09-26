function StoreInternal {
    if ((Get-AppxPackage | Where-Object { $_.Name -match 'Microsoft.WindowsStore' })) { Write-Host 'Store Available!' } else { Start-Process -FilePath 'WSReset.exe' -ArgumentList '-i' }
}

function InstallStore {

    $Package = @{
        CategoryID        = '642932525926453C94942D4021F1C78D'
        PackageFamilyName = 'Microsoft.WindowsStore_8wekyb3d8bbwe'
        IDType            = 'CategoryID'
        Ring              = 'Retail'
    }

    $PackageName = $Package.PackageFamilyName.Split('_')[0]
    $mainPackgeType = 'msixbundle'

    # Get and organize store packages
    $allPackages = Get-StorePackages -Identifier $Package.CategoryID -IdentifierType $Package.IDType -Ring $Package.Ring | Sort-Object Keys -Unique
    if ($null -eq $allPackages) { Write-Host 'Could not Fetch Packages'; break }

    # Sort & Download Main Package
    $mainPackge = $allPackages | Where-Object { $_.Keys -match $mainPackgeType }
    if ($null -eq $mainPackge) { Write-Host 'Could not Fetch Main Package'; break }
    try { DownloadFile -downloadedFilesdir "$downloadPath" -FilesTable $mainPackge } catch { Write-Host $_; return }

    # Extract XML For Dependencies
    $DependenciesArray = XtractXMLGetDependency -FileName $mainPackge.Keys -APPName $PackageName
    $DependenciesHash = foreach ($dep in $DependenciesArray) { $allPackages | Where-Object { $_.Keys -match $dep } }
    if ($null -eq $DependenciesHash) { Write-Host 'Could not check for Dependencies'; break }
    try { DownloadFile -downloadedFilesdir "$downloadPath\Dependencies" -FilesTable $DependenciesHash } catch { Write-Host $_; return }

    # Install Store Purchase
    InstallProvisioned -APPName $PackageName -Dependencies $DependenciesHash.Keys -license $Package.PackageFamilyName
}

function InstallStorePurchase {

    $Package = @{
        CategoryID        = '214308D74262449DA78D9A2306144B11'
        PackageFamilyName = 'Microsoft.StorePurchaseApp_8wekyb3d8bbwe'
        IDType            = 'CategoryID'
        Ring              = 'Retail'
    }

    $PackageName = $Package.PackageFamilyName.Split('_')[0]
    $mainPackgeType = 'appxbundle'

    # Get and organize store packages
    $allPackages = Get-StorePackages -Identifier $Package.CategoryID -IdentifierType $Package.IDType -Ring $Package.Ring | Sort-Object Keys -Unique
    if ($null -eq $allPackages) { Write-Host 'Could not Fetch Packages'; break }

    # Sort & Download Main Package
    $mainPackge = $allPackages | Where-Object { $_.Keys -match $mainPackgeType }
    if ($null -eq $mainPackge) { Write-Host 'Could not Fetch Main Package'; break }
    try { DownloadFile -downloadedFilesdir "$downloadPath" -FilesTable $mainPackge } catch { Write-Host $_; return }

    # Extract XML For Dependencies
    $DependenciesArray = XtractXMLGetDependency -FileName $mainPackge.Keys -APPName $PackageName
    $DependenciesHash = foreach ($dep in $DependenciesArray) { $allPackages | Where-Object { $_.Keys -match $dep } }
    if ($null -eq $DependenciesHash) { Write-Host 'Could not check for Dependencies'; break }
    try { DownloadFile -downloadedFilesdir "$downloadPath\Dependencies" -FilesTable $DependenciesHash } catch { Write-Host $_; return }

    # Install Store Purchase
    InstallProvisioned -APPName $PackageName -Dependencies $DependenciesHash.Keys -license $Package.PackageFamilyName
}

function InstallXboxID {

    $Package = @{
        CategoryID        = '9db724c9-966d-4aeb-9d3b-d6b2c77f3de3'
        PackageFamilyName = 'microsoft.xboxidentityprovider_8wekyb3d8bbwe'
        IDType            = 'CategoryID'
        Ring              = 'Retail'
    }

    $PackageName = $Package.PackageFamilyName.Split('_')[0]
    $mainPackgeType = '(?=.*_(\d{2}\.\d{2}\.\d{4}))(?=.*appxbundle)'

    # Get and organize store packages
    $allPackages = Get-StorePackages -Identifier $Package.CategoryID -IdentifierType $Package.IDType -Ring $Package.Ring | Sort-Object Keys -Unique
    if ($null -eq $allPackages) { Write-Host 'Could not Fetch Packages'; break }

    # Sort & Download Main Package
    $mainPackge = $allPackages | Where-Object { $_.Keys -match $mainPackgeType }
    if ($null -eq $mainPackge) { Write-Host 'Could not Fetch Main Package'; break }
    try { DownloadFile -downloadedFilesdir "$downloadPath" -FilesTable $mainPackge } catch { Write-Host $_; return }

    # Extract XML For Dependencies
    $DependenciesArray = XtractXMLGetDependency -FileName $mainPackge.Keys -APPName $PackageName
    $DependenciesHash = foreach ($dep in $DependenciesArray) { $allPackages | Where-Object { $_.Keys -match $dep } }
    if ($null -eq $DependenciesHash) { Write-Host 'Could not check for Dependencies'; break }
    try { DownloadFile -downloadedFilesdir "$downloadPath\Dependencies" -FilesTable $DependenciesHash } catch { Write-Host $_; return }

    # Install Store Purchase
    InstallProvisioned -APPName $PackageName -Dependencies $DependenciesHash.Keys -license $Package.PackageFamilyName
}

function InstallWinget {

    $Package = @{
        CategoryID        = 'f855810c-9f77-45ff-a0f5-cd0feaa945c6'
        PackageFamilyName = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
        IDType            = 'CategoryID'
        Ring              = 'Retail'
    }

    $PackageName = $Package.PackageFamilyName #.Split('_')[0]
    $mainPackgeType = 'msixbundle'

    # Get and organize store packages
    $allPackages = Get-StorePackages -Identifier $Package.CategoryID -IdentifierType $Package.IDType -Ring $Package.Ring | Sort-Object Keys -Unique
    if ($null -eq $allPackages) { Write-Host 'Could not Fetch Packages'; break }

    # Sort & Download Main Package
    $mainPackge = $allPackages | Where-Object { $_.Keys -match $mainPackgeType }
    if ($null -eq $mainPackge) { Write-Host 'Could not Fetch Main Package'; break }
    try { DownloadFile -downloadedFilesdir "$downloadPath" -FilesTable $mainPackge } catch { Write-Host $_; return }

    # Extract XML For Dependencies
    $DependenciesArray = XtractXMLGetDependency -FileName $mainPackge.Keys -APPName $PackageName
    $DependenciesHash = foreach ($dep in $DependenciesArray) { $allPackages | Where-Object { $_.Keys -match $dep } }
    if ($null -eq $DependenciesHash) { Write-Host 'Could not check for Dependencies'; break }
    try { DownloadFile -downloadedFilesdir "$downloadPath\Dependencies" -FilesTable $DependenciesHash } catch { Write-Host $_; return }

    # License
    $WingetGit = $(Invoke-RestMethod 'https://api.github.com/repos/microsoft/winget-cli/releases/latest').assets | Where-Object { $_.name -match 'xml' }
    $License = @{ $WingetGit.name = $WingetGit.browser_download_url }
    $LicenseFile = ($WingetGit.name).trimEnd('.xml')
    if ($null -eq $License) { Write-Host 'Could not fetch license'; break }
    try { DownloadFile -downloadedFilesdir "$downloadPath\license" -FilesTable $License } catch { Write-Host $_; return }

    # Install Store Purchase
    InstallProvisioned -APPName $PackageName -Dependencies $DependenciesHash.Keys -license $LicenseFile
}