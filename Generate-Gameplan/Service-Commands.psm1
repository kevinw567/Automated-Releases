#Requires -Modules configs

<# 
    .Description
    Write a Flip-Services command using the info from the old Startup Tool XML

    .PARAMETER info
    The Yaml node that represents the changing component represented as an ordered dictionary

    .PARAMETER oldVersion
    The old version of the Startup Tool (the name of the current folder containing the current startup tool XML file).

    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.
#>
function Write-StartupToolServiceCommand {
    param(
        [System.Collections.Specialized.OrderedDictionary] $info, 
        [System.Xml.XmlElement] $oldVersion,
        [String] $outputFile,
        [switch] $legacy
    )

    $command = if (-not $legacy) { "Flip-Services" } else { ".\Flip-Services.ps1" }
    [System.Xml.XmlElement] $oldVersion = $oldVersion
    $newServiceName = $info.configs.service_name.trim() -f $info.version
    # remove SM agent version from version line for SM services
    $version = if ($info.name -match "System Manager*") { $oldVersion.Version.split("And")[0] } else { $oldVersion.Version }
    $oldServiceName = $info.configs.service_name.trim() -f $version.trim()
    # if the there are multiple VMs running the same software (ex. PBPs) get VM from XML
    $vm = if ($info.configs.vm -eq "multiple") { $oldVersion.Hostname.split(".")[0] } else { $info.configs.vm }
    "# switch $($info.name) services" >> $outputFile
    "$command -vm '$vm' -enable '$newServiceName' -disable '$oldServiceName'`n" >> $outputFile
}


<# 
    .Description
    Write a Flip-Services command for Non-Startup Tool components.

    .PARAMETER info
    The Yaml node that represents the changing component represented as an ordered dictionary

    .PARAMETER currentServices
    A list of the Symbotic services that are in manual startup mode on all VMs

    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.
#>
function Write-ServiceCommand {
    param(
        [System.Collections.Specialized.OrderedDictionary] $info, 
        [String] $outputFile,
        [Object] $currentServices,
        [switch] $legacy
    )

    $command = if ($legacy) { ".\flipServices.ps1" } else { "Flip-Services" }
    $vm = $info.configs.vm
    $newServiceName = $info.configs.service_name -f $info.version
    $currentService = Get-CurrentService -match $info.name -currentServices $currentServices
    "# switch $($info.name) services" >> $outputFile
    "$command -vm '$vm' -enable '$newServiceName' -disable '$currentService'`n" >> $outputFile
    # Integration Manager must be started
    if ($info.name -match "Integration Manager") {
        "StartStop-Service -vmName '$vm' -stop '$currentService' -start '$newServiceName'" >> $outputFile
    }
}

<# 
    .Description
    Search for and return a service from the list of manual Symbotic services

    .PARAMETER currentServices
    A list of the Symbotic services that are in manual startup mode on all VMs

    .PARAMETER match
    The search term to match to
#>
function Get-CurrentService {
    param([Object] $currentServices, [string] $match)
    # loop through manual services and look for a matching service
    foreach ($service in $currentServices) {
        # if a match is found, return it
        if ($service.Name -match $match) { return $service.Name }
    }

    return -1
}

<#
    .Description
    Write commands to switch and start Cell Gateway services on all Cell Gateway VMs

    .PARAMETER info
    The Yaml node that represents the changing component represented as an ordered dictionary
    
    .PARAMETER currentServices
    A list of the Symbotic services that are in manual startup mode on all VMs

    .PARAMETER site
    The site abbreviation, used to find the correct config module in /configs folder

    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.
#>
function Switch-CellGatewayServices {
    param(
        [System.Collections.Specialized.OrderedDictionary] $info, 
        [Object] $currentServices,
        [string] $site,
        [string] $outputFile,
        [switch] $legacy
    )

    $serviceCommand = if ($legacy) { ".\flipServices.ps1" } else { "Flip-Services" }
    $startCommand = if ($legacy) { ".\startStopService.ps1" } else { "StartStop-Service" }
    $newServiceName = $info.configs.service_name -f $info.version
    # call Get-CurrentService to get current Cell Gateway service
    $currentCellGW = Get-CurrentService -match "Cell Gateways*" -currentServices $currentServices
    # load variables from site specific config file to get CGW VM names
    $(Get-Content $modulespath/configs/$site.psm1) | Out-String | Invoke-Expression
    "# Switch and start gateway services" >> $outputFile
    foreach ($cgw in $CGWs) {
        "# $cgw" >> $outputFile
        "$serviceCommand -vm '$cgw' -enable '$newServiceName' -disable '$currentCellGW'" >> $outputFile
        "$startCommand -vm '$cgw' -stop '$currentCellGW' -start '$newServiceName'`n" >> $outputFile
    }
}

Export-ModuleMember -Function Write-StartupToolServiceCommand
Export-ModuleMember -Function Write-ServiceCommand
Export-ModuleMember -Function Get-CurrentService
Export-ModuleMember -Function Switch-CellGatewayServices