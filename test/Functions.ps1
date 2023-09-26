
# Fetch Links and stuff form 'https://store.rg-adguard.net'
function Get-StorePackages {
    param (
        [string]$Identifier
    )

    $apiUrl = 'https://store.rg-adguard.net/api/GetFiles'

    $body = @{
        type = 'CategoryID'
        url  = $Identifier
        ring = 'Retail'
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
function XtractXML {
    param (
        [string]$FileName,
        [string]$APPName
    )

    $FilePath = "$downloadPath\$FileName"

    if (Test-Path "$downloadPath\XMLPath\$APPName.xml") { return }

    Start-Process -FilePath "$downloadPath\7za.exe" -ArgumentList "e $FilePath *x64* -o$downloadPath\ -y" -NoNewWindow -Wait
    $Appx2 = (Get-ChildItem "$downloadPath\*_x64*").FullName

    Start-Process -FilePath "$downloadPath\7za.exe" -ArgumentList "x $Appx2 *AppxManifest.xml* -o$downloadPath\ -y" -NoNewWindow -Wait
    Remove-Item $Appx2 -Force
    Move-Item "$downloadPath\AppxManifest.xml" "$downloadPath\XMLPath\$APPName.xml" -Force   
}

# Function to load XML file and get dependency full names
function GetDependencyFullNames($xmlPath) {
    $xml = [xml](Get-Content $xmlPath)
    $dependencyNames = $xml.Package.Dependencies.PackageDependency.Name | ForEach-Object {
        (Get-ChildItem "$downloadPath\Dependencies\$_*").FullName
    }
    return $dependencyNames
}

# Install Provisioned
function InstallProvisioned {
    param (
        [string]$APPName,
        [array]$Dependencies,
        [string]$Seclicense
    )

    $AppxBundlePath = (Get-ChildItem $downloadPath | Where-Object { $_.Name -match "$APPName.*bundle" }).FullName
    $AppxBundlePath; Pause
    $LicencePath = (Get-ChildItem "$downloadPath\license" | Where-Object { $_.Name -match "$APPName.*xml|$Seclicense" }).FullName
    Add-AppxProvisionedPackage -Online -PackagePath $AppxBundlePath -DependencyPackagePath $Dependencies -LicensePath $LicencePath  
}