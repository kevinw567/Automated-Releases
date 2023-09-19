#requires -Module configs

# C:\Program Files\WindowsPowerShell\Modules for production
$modulesPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"

Import-Module "$modulesPath\StageComponents\Copy-SiteConfigs.psm1"
Import-Module "$modulesPath\StageComponents\Add-DestinationFolder.psm1"
Import-Module "$modulesPath\StageComponents\Add-ReleasesFolder.psm1"
Import-Module "$modulesPath\configs\helpers.psm1"


function StageComponents {
    param([string] $stagingFolder = "$env:USERPROFILE\Desktop\staging-folder", [switch] $deleteExisting, [switch] $testing)
    Push-Location
    $comps = Get-Content "$stagingFolder\components.csv"
    $siteconfigsInfo = $($comps -match "SiteConfig Package").split(",")
    foreach ($comp in $comps) {
        $comp = $comp.split(",")
        # skip the header, release manifest & site configs rows
        if (-not($comp[0] -in "Component", "SiteConfig Package", "Release Manifest")) { 
            $vm = Get-VM -component $comp[0]
            Write-Host "Starting staging for '$comp'" -ForegroundColor Blue -BackgroundColor Black
            if ($vm.GetType().FullName -eq "System.String") {
                Add-DestinationFolder -vm $vm -component $comp[0] -version $comp[1]
                Add-ReleasesFolder -vm $vm -component $comp[0] -version $comp[1] -stagingFolder $stagingFolder 
                Copy-SiteConfigs -vm $vm -siteconfigs "$stagingFolder\SiteConfig Package" -version $siteconfigsInfo[1]  
            }

            elseif ($vm.GetType().FullName -eq "System.Int32") {
                for ($i = 1; $i -le 8; $i++) {
                    $machine = "pbp0$i"
                    Add-DestinationFolder -vm $machine -component $comp[0] -version $comp[1]
                    Add-ReleasesFolder -vm $machine -component $comp[0] -version $comp[1] -stagingFolder $stagingFolder
                    Copy-SiteConfigs -vm $machine -siteconfigs "$stagingFolder\SiteConfig Package" -version $siteconfigsInfo[1]
                }

                continue
            }

            elseif ($vm.GetType().FullName -eq "System.Object[]") {
                $variableName = $vm[1]
                $site = Convert-DomainToSite
                Get-Content $modulesPath\configs\$site.psm1 | Out-String | Invoke-Expression
                switch ($vm[1]) {
                    "CC" { $machines = $CCs }
                    "LIUI" { $machines = $LIUIs }
                    "CGW" { $machines = $CGWs }
                }

                foreach ($machine in $machines) {
                    Add-DestinationFolder -vm $machine -component $comp[0] -version $comp[1]
                    Add-ReleasesFolder -vm $machine -component $comp[0] -version $comp[1] -stagingFolder $stagingFolder 
                    Copy-SiteConfigs -vm $machine -siteconfigs "staging\Folder\SiteConfig Pacakge" -version $siteconfigsInfo[1]
                }
                
            }

            elseif ($vm -eq $false) { Write-Host "Unable to find VMs for $comp" -ForegroundColor Red -BackgroundColor Black; return }

        }
    }

    Pop-Location
}


Export-ModuleMember -Function StageComponents