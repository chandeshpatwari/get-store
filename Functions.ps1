
# Fetch Links and stuff form 'https://store.rg-adguard.net'
function Get-StorePackages {
    param (
        [string]$Identifier,
        [string]$IdentifierType,
        [string]$Ring
    )

    $apiUrl = 'https://store.rg-adguard.net/api/GetFiles'

    $body = @{
        type = $IdentifierType
        url  = $Identifier
        ring = $Ring
        lang = 'en-US'
    }

    $rawResult = Invoke-RestMethod -Method Post -Uri $apiUrl -ContentType 'application/x-www-form-urlencoded' -Body $body

    $urlPattern = '<a href="(?<url>[^"]*)"[^>]*>(?<text>.*?)<\/a>'
    $filterUrls = [regex]::Matches($rawResult, $urlPattern) | ForEach-Object { @{$_.Groups['text'].Value = $_.Groups['url'].Value } }

    $finalPackages = $filterUrls | Where-Object { $_.Keys -notlike '*.BlockMap*' -and $_.Keys -match 'x64|x86|appxbundle|msixbundle' }

    return $finalPackages
}


# Download Files
function DownloadFile {
    param (
        [string]$downloadedFilesDir,
        [array]$filesTable
    )

    $requiredFiles = $filesTable.Keys

    do {
        $downloadedFiles = (Get-ChildItem "$downloadedFilesDir").Name
        $filesToDownload = $requiredFiles | Where-Object { $_ -notin $downloadedFiles }

        if ($filesToDownload) {
            Write-Host 'Required Files:'; $filesToDownload
            if ((Read-Host 'Download the Files? (y/n)').ToLower() -eq 'y') {
                $filesTable | ForEach-Object {
                    $url = $_.Values; $fileName = $_.Keys; $filePath = Join-Path -Path $downloadedFilesDir -ChildPath $fileName
                    if (!(Test-Path $filePath)) {
                        try {
                            Start-BitsTransfer -Source $url -Destination $filePath -Description "$fileName" -ErrorAction Stop
                        } catch {
                            Write-Host "Error downloading $fileName : $_"
                            Pause
                            Write-Host 'Retrying' 
                        }
                    }
                }
            } else {
                throw 'User chose not to download files'  # Throw an exception to stop the script
            }
        } else { Write-Host 'No File Missing. Skipping download.' }
    } until (!($filesToDownload))
}


# Download 7za
function Get7za {
    $response = Invoke-WebRequest -UseBasicParsing -Uri 'https://7-zip.org/'
    $versionLink = ($response.Links | Where-Object { $_.outerHTML -match '7z(\d+)' })[0]
    $versionNumber = [regex]::Match($versionLink.href, '\/(.*?)\-').Groups[1].Value
    $7za = 'https://7-zip.org/a/' + $versionNumber + '-extra.7z'
    $7zr = 'https://www.7-zip.org/a/7zr.exe'
    if (!(Test-Path "$DataPath\7za.7z")) { Start-BitsTransfer -Source $7za -Destination "$DataPath\7za.7z" }
    if (!(Test-Path "$DataPath\7zr.exe")) { Start-BitsTransfer -Source $7zr -Destination "$DataPath\7zr.exe" }
    Start-Process -FilePath "$DataPath\7zr.exe" -ArgumentList "x `"$DataPath\7za.7z`" -o$DataPath\7za" -NoNewWindow -Wait    
    Copy-Item "$DataPath\7za\x64\7za.exe" "$DataPath" -Force
    New-Item -Path "$DataPath\Bin" -ItemType Directory -Force
    Remove-Item -Path "$DataPath\7za\" -Recurse -Force
    '7zr.exe', '7za.7z' | ForEach-Object { Move-Item "$DataPath\$_" "$DataPath\Bin\" -Force -ErrorAction SilentlyContinue } 
}

# Extract AppManifest With 7za
function XtractXMLGetDependency {
    param (
        [string]$FileName,
        [string]$PackageName
    )

    $FilePath = "$downloadPath\$FileName"
    $XmlPath = "$downloadPath\XMLPath\$PackageName.xml"

    Start-Process -FilePath "$downloadPath\7za.exe" -ArgumentList "e $FilePath *x64* -o$downloadPath\ -y" -NoNewWindow -Wait
    $Appx64 = (Get-ChildItem "$downloadPath\*_x64*").FullName

    Start-Process -FilePath "$downloadPath\7za.exe" -ArgumentList "x $Appx64 *AppxManifest.xml* -o$downloadPath\ -y" -NoNewWindow -Wait
    Remove-Item $Appx64 -Force; Move-Item "$downloadPath\AppxManifest.xml" "$downloadPath\XMLPath\$APPName.xml" -Force
    Start-Sleep 2
    $xml = [xml](Get-Content $XmlPath)
    $DependenciesArray = $xml.Package.Dependencies.PackageDependency.Name
    return $DependenciesArray
}


# Install Provisioned
function InstallProvisioned {
    param (
        [string]$APPName,
        [array]$Dependencies,
        [string]$license
    )

    $AppxBundlePath = (Get-ChildItem $downloadPath | Where-Object { $_.Name -match "$APPName.*bundle" }).FullName
    $Dependencies = $Dependencies | ForEach-Object { (Get-ChildItem "$downloadPath\Dependencies\$_*").FullName }
    $LicencePath = (Get-ChildItem "$downloadPath\license" | Where-Object { $_.Name -match "$APPName.*xml|$license.xml" }).FullName
    Add-AppxProvisionedPackage -Online -PackagePath $AppxBundlePath -DependencyPackagePath $Dependencies -LicensePath $LicencePath  
}