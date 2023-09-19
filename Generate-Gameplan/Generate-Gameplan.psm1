#Requires -Modules configs
# all will be 'C:/Program Files/WindowsPowerShell/Modules' for production
Import-Module "$modulesPath\Generate-Gameplan\Service-Commands.psm1"
Import-Module "$modulesPath\Generate-Gameplan\App-Commands.psm1"

$pathToStartupToolFolder = "path"
<#
    .Description
    Generate a deployment script by reading the input Yaml file

    .PARAMETER oldVersion
    The old version of the Startup Tool (the name of the current folder containing the current startup tool XML file).

    .PARAMETER componentsFile
    The Yaml file to read component changes from, by default looks for a 'components.yaml' in the current directory

    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.

    .PARAMETER overWrite
    Overwrite any .ps1 files with the same name as the desired output file.
#>
function Generate-Gameplan {
    param(
        [string] $oldVersion = "",
        [ValidatePattern(".yaml")] [string] $componentsFile = "$pwd\components.yaml",
        [string] $outputFile = "./gameplan.ps1",
        [switch] $overWrite,
        [switch] $legacy
    )

    Push-Location
    # load component changes
    $yml = ConvertFrom-Yaml -Path $componentsFile
    if ("" -eq $oldVersion) { [string] $oldVersion = $yml.components.oldVersion }
    $options = if ($legacy -eq $true) { " -legacy" } else { "" }
    # load old components from startup tool xml
    $xml = [xml]::new()
    [xml]$xml.Load("$pathToStartupToolFolder\$oldVersion\$oldVersion.xml")
    $nodes = $xml.SelectNodes("//Component")
    # get a list of the services currently set to manual
    $currentServices = Get-ManualServices 
    # if overwrite is passed in, "overwrite" the current file
    if ($overWrite -and $(Test-Path $outputFile)) { Remove-Item $outputFile }
    # if there is already a file with the name $outputFile and overWrite isn't passed throught, exit
    elseif (-not $overWrite -and $(Test-Path $outputFile)) {
        Write-Host "'$outputFile' already exists, to overwrite it add '-overWrite'" -ForegroundColor Yellow -BackgroundColor Black
        exit 1
    }

    $site = Convert-DomainToSite
    # iterate through components file and write commands for changes
    for ($i = 0; $i -le $yml.components.Length - 1; $i++) {
        $component = $yml.components[$i]
        # check if the component is marked as changed in the yaml file
        if (("True", "t", "1").contains([string] $component.changed)) {
            # keep track of whether a command was written to prevent repeats
            $repeat = $false
            # the component isn't a start up tool component 
            if ($component.name -match "Cell Gateways*") {
                Switch-CellGatewayServices -info $component -site $site -currentServices $currentServices -outputFile $outputFile $options
                $repeat = $true
            }

            # write DepalUI shortcut commands
            elseif ($component.name -match "Depalletization User Interface") {
                Write-DepalUICommands -info $component -outputFile $outputFile $options
                $repeat = $true
            }

            # write LIUI shortcut commands
            elseif ($component.name -match "Label Inquiry UI") {
                Write-LIUICommands -info $component -outputFile $outputFile -site $site $options
                $repeat = $true
            }

            # check if component is a startup tool component
            foreach ($comp in $nodes) {
                if ($comp.Name -match "$($component.name)*") {
                    # write CC shortcut commands
                    if ($component.name -match "ControlCenter*") {
                        # write CC shortcut commands
                        Write-CCAppCommands -info $component -oldVersion $comp -outputFile $outputFile -site $site $options
                        $repeat = $true
                    }

                    # write CPI commands
                    elseif ($component.name -eq "Case Parameter Input") {
                        Write-CPICommands -info $component -oldVersion $comp -outputFile $outputFile $options
                        $repeat = $true
                    }

                    # write command based on component type (service vs. app)
                    elseif ($component.configs.type -eq "service") {
                        # write flip services command
                        Write-StartupToolServiceCommand -info $component -oldVersion $comp -outputFile $outputFile $options
                        $repeat = $true
                    }

                    # write app commands using information from Startup Tool XML
                    elseif ($component.configs.type -eq "app") {
                        # write create shortcut command
                        Write-StartupToolAppCommand -info $component -oldVersion $comp -outputFile $outputFile $options
                        $repeat = $true
                    }    
                }
            } 

            # write remaining commands for components that require info from different sources (not in startup tool XML)
            if ($repeat -eq $false) {
                # write service command using current manual services
                if ($component.configs.type -eq "service") {
                    Write-ServiceCommand -info $component -outputFile $outputFile -currentServices $currentServices $options
                    $repeat = $true
                }

                # write app command for non-startup tool component
                else {
                    Write-AppCommand -info $component -outputFile $outputFile $options
                    $repeat = $true
                }
            }
        }

        # if there is not a new version of IM, change the SiteConfigs symlink
        elseif ($component.name -match "Integration Manager") {
            Switch-IMSymlink -component $component -currentServices $currentServices -outputFile $outputFile $options
        }
    }

    Pop-Location
}

<#
    .Description
    Write a Switch-Symlink command to change the IM01 SiteConfigs symlink

    .PARAMETER component
    The Yaml node that represents the changing component represented as an ordered dictionary

    .PARAMETER currentServices
    A list of the Symbotic services that are in manual startup mode on all VMs

    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.
#>
function Switch-IMSymlink {
    param(
        [System.Collections.Specialized.OrderedDictionary] $component,
        [Object] $currentServices,
        [string] $outputFile,
        [switch] $legacy
    )
    
    $command = if ($legacy) { ".\switchSymlink.ps1" } else { "Switch-Symlink" }
    $vm = $component.configs.vm
    # get current Integration Manager version
    $currentIM = $currentServices -match "Integration Manager"
    # remove everything except version number from service name
    $currentIM = $currentIM.Name.replace("Symbotic Integration Manager Core ", "")
    $location = $component.symlink.location -f $currentIM
    $symlinkName = $component.symlink.symlink_name
    $target = $component.symlink.target -f $yml.components.newSiteConfigsVersion
    "# switch IM01 symlink" >> $outputFile
    "$command -vmName '$vm' -location '$location' -symlinkName '$symlinkName' -target '$target'" >> $outputFile
    # restart IM for changes to take effect
    "StartStop-Service -vmName '$vm' -stop 'Symbotic Integration Manager Core $currentIM'" >> $outputFile
    "StartStop-Service -vmName '$vm' -start 'Symbotic Integration Manager Core $currentIM'`n" >> $outputFile
}


<#
    .Description
    Write a Flip-Services command for CPI server and a Create-Shortcut command for CPI client.

    .PARAMETER info
    The Yaml node that represents the changing component represented as an ordered dictionary

    .PARAMETER oldVersion
    The old version of the Startup Tool (the name of the current folder containing the current startup tool XML file).

    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.
#>
function Write-CPICommands {
    param(
        [System.Collections.Specialized.OrderedDictionary] $info, 
        [System.Xml.XmlElement] $oldVersion,
        [string] $outputFile,
        [switch] $legacy
    )

    $site = Convert-DomainToSite
    $serviceCommand = if ($legacy -eq $true) { ".\FlipServices.ps1" } else { "Flip-Services" }
    $appCommand = if ($legacy -eq $true) { ".\shortcut.ps1" } else { "Create-Shortcut" }
    
    # formulate old and new service names
    $oldServiceName = $info.configs.server.service_name -f $oldVersion.Version
    $newServiceName = $info.configs.server.service_name -f $info.version
    $(Get-Content $modulespath\configs\$site.psm1) | Out-String | Invoke-Expression
    if ("Case Parameter Input" -in $override.keys) {
        foreach ($k in $override."Case Parameter Input".keys) {
            Set-Variable -Name $k -Value $override."Case Parameter Input".$k
        }
    }
    
    $clientVM = if ($null -eq $clientVM) { $info.configs.client.vm } else { $clientVM }
    $serverVM = if ($null -eq $serverVM) { $info.configs.server.vm } else { $serverVM }
    "# CPI Server and Client" >> $outputFile
    "$serviceCommand -vm '$serverVM' -enable '$newServiceName' -disable '$oldServiceName'" >> $outputFile
    $appDestination = $info.configs.client.appDestination
    $pathToNewExe = $info.configs.client.path -f $info.version
    $pathToOldExe = $info.configs.client.path -f $oldVersion.Version
    "$appCommand -vm '$clientVM' -pathToNewExe '$pathToNewExe' -shortcutDestination '$appDestination' -bak '$pathToOldExe'`n" >> $outputFile
}

<#
    .Description
    Convert the current machines domain name to the site code.
    
    .PARAMETER domain
    The domain name of the current machine.
#>
function Convert-DomainToSite {
    $domain = $(whoami).split("\")[0]
    switch ($domain) {
        ("Domain") { return "customer" }
    }
}

Export-ModuleMember -Function Generate-Gameplan