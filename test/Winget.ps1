function InstallWinget {
    # Define identifiers
    $identifiers = @('f855810c-9f77-45ff-a0f5-cd0feaa945c6')
    $AppName = 'Microsoft.DesktopAppInstaller'

    # Get and organize store packages
    $allPackages = $identifiers | ForEach-Object { Get-StorePackages -Identifier $_ } | Sort-Object Keys -Unique
    if ($null -eq $allPackages) { Write-Host 'Connection Error 1'; break }

    # Download Main Packages
    $mainPackge = $allPackages | Where-Object { $_.Keys -match '(?=.*_(\d{2}\.\d{2}\.\d{4}))(?=.*appxbundle)' }
    DownloadFile -downloadedFilesdir "$downloadPath" -FilesTable $mainPackge

    # Extract XML For Dependencies
    $fileArray = $mainPackge.Keys | Sort-Object -Unique
    $fileArray | ForEach-Object { XtractXML -FileName $_ -APPName $($_.split('_')[0]) }
    $DependenciesArray = GetDependencyFullNames -xmlPath "$downloadPath\XMLPath\$AppName.xml"
    $Dependencies = $allPackages | Where-Object { $($DependenciesArray | Split-Path -Leaf ) -contains $_.Keys }
    if ($null -eq $Dependencies) { Write-Host 'Connection Error 2'; break }

    # License
    $WingetGit = Invoke-RestMethod 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
    $License = $WingetGit.assets | Where-Object { $_.name -match 'xml' }
    $License = @{ $License.name = $License.browser_download_url }
    if ($null -eq $License) { Write-Host 'Connection Error'; break }
    DownloadFile -downloadedFilesdir "$downloadPath\license" -FilesTable $License

    # Download Dependencies
    try {
        DownloadFile -downloadedFilesdir "$downloadPath\Dependencies" -FilesTable $dependencies
        Write-Host 'Proceed with the rest of the script.'
    } catch {
        Write-Host $_
        Write-Host 'Script execution halted.'
        return
    }

    # Install Winget
    $LicenseString = $License | ForEach-Object { $_.Keys }

    InstallProvisioned $AppName -Dependencies $DependenciesArray -Seclicense $LicenseString
}


# 
# Locate Dependencies,License,AppxBundle
$DependenciesPath = $DependenciesHash.Keys | ForEach-Object { (Get-ChildItem "$downloadPath\Dependencies\$_").FullName }
$LicencePath = (Get-ChildItem "$downloadPath\license" | Where-Object { $_.Name -match $License.Keys }).FullName
$AppxBundlePath = (Get-ChildItem $downloadPath | Where-Object { $_.Name -match $mainPackge.Keys }).FullName
$DependenciesPath; $LicencePath; $AppxBundlePath; Pause


function InstallProvisioned {
    param (
        [string]$APPName,
        [array]$Dependencies,
        [string]$Seclicense
    )


    #


    $AppxBundlePath = (Get-ChildItem $downloadPath | Where-Object { $_.Name -match "$APPName.*bundle" }).FullName

    $LicencePath = (Get-ChildItem "$downloadPath\license" | Where-Object { $_.Name -match "$Seclicense" }).FullName
    Add-AppxProvisionedPackage -Online -PackagePath $AppxBundlePath -DependencyPackagePath $Dependencies -LicensePath $LicencePath  
}