function Add-ReleasesFolder {
    param([Parameter(Mandatory)] $vm, [Parameter(Mandatory)] $component, [Parameter(Mandatory)] $version, [Parameter(Mandatory)] $stagingFolder)
    # determine which drive to install to
    $drive = if (Test-Path "\\$vm\e$") { "e$" } else { "c$" }
	cd \\$vm\$drive
    if (-not (Test-Path ".\Releases")) {
        mkdir "$drive\Releases"
    }

    cd "Releases"
    $newFolderName = "$component $version"
    if (Test-Path ".\$newFolderName") {
        Write-Host "[$vm] '$drive\Releases\$newFolderName' already exists" `
            -ForegroundColor Red -BackgroundColor Black 
        
        return
    }

    mkdir ".\$newFolderName" >> $null
    Copy-Item "$stagingFolder\$component\*.exe" ".\$newFolderName"
    Write-Host "[$vm] Installer copied to '$drive\Releases\$newFolderName'"`
        -ForegroundColor Green -BackgroundColor Black
}

Export-ModuleMember -Function Add-ReleasesFolder