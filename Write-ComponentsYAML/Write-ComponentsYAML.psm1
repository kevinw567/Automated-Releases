#requires -Modules configs


function Write-ComponentsYAML {
    param([Parameter(Mandatory)] $csv, $outputLocation = "$pwd\components.yaml", [switch] $overWrite)
    if (Test-Path $outputLocation) { 
        if ($overWrite) { Remove-Item $outputLocation }
        else { Write-Host "'$outputLocation' already exists" -ForegroundColor Yellow -BackgroundColor Black; return }
    }

    Copy-Item -Path "$modulesPath\configs\components.yaml" -Destination $outputLocation
    Start-Sleep -Seconds 1
    $changes = Get-Content $csv
    $yaml = ConvertFrom-Yaml -Path $outputLocation
    foreach ($line in $changes) {
        $componentName = $line.split(",")[0]
        $version = $line.split(",")[1]
        if ($componentName -eq "SiteConfig Package") {
            $yaml.newSiteConfigsVersion = "$version"       
        }

        foreach ($component in $yaml.components) {    
            if ($componentName -match "Inbound Agent") {
                if ($component.name -eq "System Manager Inbound") {
                    $component.Agent.changed = 1
                    $component.Agent.version = "$version"
                }
            }

            elseif ($component -match "Outbound Agent") {
                if ($component.name -eq "System Manager Outbound") {
                    $component.Agent.changed = 1
                    $component.Agent.version = "$version"
                }
            }

            if ($component.name -eq $componentName) {
                $component.changed = 1
                if (!$($components.version -match "!!str")) {
                    $component.version = "$version"
                }

                else { $component.version = $component.version + " $version" }
            }
        }

    }

    try {
        Set-Content -Value $(ConvertTo-Yaml $yaml) -Path $outputLocation -ErrorAction STOP
    }

    catch { Write-Host "An unexpected error occurred while writing components.yaml" -ForegroundColor Red -BackgroundColor Black }
    Write-Host "'$outputLocation' written" -ForegroundColor Green -BackgroundColor Black
}


Export-ModuleMember -Function Write-ComponentsYAML