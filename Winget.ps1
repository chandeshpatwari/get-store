function InstallWinget {
    # Define identifiers
    $AppName = 'Microsoft.DesktopAppInstaller'

    # Define Links

    ## UI XML
    $UIXMLGit = Invoke-RestMethod 'https://api.github.com/repos/microsoft/microsoft-ui-xaml/releases'
    $UIXMLArray = $UIXMLGit.assets | Where-Object { $_.name -match 'Microsoft\.UI\.Xaml\.2\.7.*(x86|x64)' }
    $DependenciesHash = $UIXMLArray | ForEach-Object { @{ $_.name = $_.browser_download_url } }
    if ($null -eq $DependenciesHash) { Write-Host 'Connection Error 1'; break }

    ## VCLibs UWP
    $DependenciesHash += @{'Microsoft.VCLibs.x64.14.00.Desktop.appx' = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' }
    $DependenciesHash += @{'Microsoft.VCLibs.x86.14.00.Desktop.appx' = 'https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx' }
    if ($null -eq $DependenciesHash) { Write-Host 'Connection Error 2'; break }

    ## Winget
    $WingetGit = Invoke-RestMethod 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
    $WingetArray = $WingetGit.assets | Where-Object { $_.name -match 'msixbundle' }
    $mainPackge = $WingetArray | ForEach-Object { @{ $_.name = $_.browser_download_url } }
    if ($null -eq $mainPackge) { Write-Host 'Connection Error 3'; break }


    # License
    $LicenseArray = $WingetGit.assets | Where-Object { $_.name -match 'xml' }
    $License = $LicenseArray | ForEach-Object { @{ $_.name = $_.browser_download_url } }
    if ($null -eq $License) { Write-Host 'Connection Error 4'; break }



    # Download
    DownloadFile -downloadedFilesdir "$downloadPath" -FilesTable $mainPackge
    DownloadFile -downloadedFilesdir "$downloadPath\license" -FilesTable $License
    DownloadFile -downloadedFilesdir "$downloadPath\Dependencies" -FilesTable $DependenciesHash

    # Locate Dependencies,License,AppxBundle
    $DependenciesPath = $DependenciesHash.Keys | ForEach-Object { (Get-ChildItem "$downloadPath\Dependencies\$_").FullName }
    $LicencePath = (Get-ChildItem "$downloadPath\license" | Where-Object { $_.Name -match $License.Keys }).FullName
    $AppxBundlePath = (Get-ChildItem $downloadPath | Where-Object { $_.Name -match $mainPackge.Keys }).FullName
    $DependenciesPath; $LicencePath; $AppxBundlePath; Pause

    # Install
    Add-AppxProvisionedPackage -Online -PackagePath $AppxBundlePath -DependencyPackagePath $DependenciesPath -LicensePath $LicencePath

}