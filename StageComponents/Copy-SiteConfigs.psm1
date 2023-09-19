
function Copy-SiteConfigs {
    param([Parameter(Mandatory)] $vm, [Parameter(Mandatory)] $siteconfigs, $version, [switch] $deleteExisting, [switch] $testing)
    # determine which drive to install to
    $drive = if (Test-Path "\\$vm\e$") { "e$" } else { "c$" }
	cd \\$vm\$drive
    # if the site configs folder already exists, print a warning
    if (Test-Path "SiteConfigs $version") {
        if ($(ls "SiteConfigs $version").count -ne 0) {
            Write-Host "[$vm] '$drive\SiteConfigs $version' already "`
                "exists and is not empty`n" -ForegroundColor Yellow -BackgroundColor Black

            return
        }

        else {
            # rm -r "$drive\SiteConfigs $version"
            Write-Host "[$vm] '$drive\Siteconfig $version' already exists but is empty"`
                -ForegroundColor Yellow -BackgroundColor Black
				
			return
        }
    }

    else {
        try {
            # create the new site configs folder 
            mkdir ".\SiteConfigs $version" -ErrorAction Stop >> $null
            # unzip the site configs .zip folder to the new site configs folder
            Expand-Archive -Path "$siteconfigs\*" -DestinationPath ".\SiteConfigs $version" -ErrorAction Stop
            # confirm that files were extracted to the new folder & it is not empty 
            if ($(ls "$drive\SiteConfigs $version").count -ne 0) { 
                Write-Host "[$vm] SiteConfig package was copied to "`
                    "'$drive\SiteConfigs $version`n'" -ForegroundColor Green -BackgroundColor Black
            }
        }

        catch {
            Write-Host "[$vm] Unable to copy site config files`n"`
                -ForegroundColor Red -BackgroundColor Black
            if ($testing) { Write-Host "[ERROR MESSAGE]: $_" -ForegroundColor Red -BackgroundColor Black }
        }
    }
}

Export-ModuleMember -Function Copy-SiteConfigs