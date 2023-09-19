#Requires -Modules configs

<#
    .Description
    Write a Create-Shortcut command using the info from the old Startup Tool XML

    .PARAMETER info
    The Yaml node that represents the changing component represented as an ordered dictionary

    .PARAMETER oldVersion
    The old version of the Startup Tool (the name of the current folder containing the current startup tool XML file).

    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.
#>
function Write-StartupToolAppCommand {
    param(
        [System.Collections.Specialized.OrderedDictionary] $info, 
        [System.Xml.XmlElement] $oldVersion,
        [string] $outputFile,
        [switch] $legacy
    )

    $command = if ($legacy) { ".\shortcut.ps1" } else { "Create-Shortcut" }
    $destination = "$($info.configs.appDestination)\$($info.name) $($info.version)"
    $vm = $info.configs.vm 
    $pathToNew = $info.configs.path -f $info.version
    $pathToOld = $oldVersion.Location.trim()
    $options = if ($info.configs.options) { $info.configs.options.trim() } else { "" }
    "# create $($info.name) shortcut" >> $outputFile
    "$command -vm '$vm' -pathToNewExe '$pathToNew' -bak '$pathToOld' -shortcutDestination '$destination' $options `n" >> $outputFile
}


<#
    .Description
    Write a Create-Shortcut command for Non-Startup Tool componenets

    .PARAMETER info
    The Yaml node that represents the changing component represented as an ordered dictionary
    
    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.
#>
function Write-AppCommand {
    param (
        [System.Collections.Specialized.OrderedDictionary] $info, 
        [String] $outputFile,
        [switch] $legacy
    )
    
    $command = if ($legacy) { ".\shortcut.ps1" } else { "Create-Shortcut" }
    $vm = $info.configs.vm
    $destination = $info.configs.appDestination
    $pathToNewExe = $info.configs.path -f $info.version
    # list all installed versions of the current component
    $appFolders = ls "$($info.configs.path -f "*")"     # for production: ls $info.vm//$info.configs.path
    # if the is only 1 installed version, nothing is return
    # if there are 2 or more installed versions, the second most recent is taken as the app to disable
    $bak = if ($appFolders.Length -lt 1) { "" } else { $appFolders[$appFolders.Length - 2] }
    "# create $($info.name) shortcut" >> $outputFile
    "$command -vm '$vm' -shortcutDestination '$destination' -pathToNewExe '$pathToNewExe' -bak '$bak'`n" >> $outputFile
}


<#
    .Description
    Write Create-Shortcut commands for all CC machines

    .PARAMETER info
    The Yaml node that represents the changing component represented as an ordered dictionary

    .PARAMETER oldVersion
    The old version of the Startup Tool (the name of the current folder containing the current startup tool XML file).

    .PARAMETER site
    The site abbreviation, used to find the correct config module in /configs folder

    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.
#>
function Write-CCAppCommands {
    param(
        [System.Collections.Specialized.OrderedDictionary] $info, 
        [System.Xml.XmlElement] $oldVersion,
        [string] $site,
        [string] $outputFile,
        [switch] $legacy
    )

    $command = if ($legacy) { ".\shortcut.ps1" } else { "Create-Shortcut" }
    # get site specific variables
    $(Get-Content $modulespath/configs/$site.psm1) | Out-String | Invoke-Expression
    foreach ($cc in $CCs) {
        "# $cc" >> $outputFile
        "$command -vm '$cc' -shortcutDestination '$($info.configs.appDestination)'" + `
            " -pathToNewExe '$($info.configs.path -f $info.version)' -bak" + `
            " '$($info.configs.path -f $oldVersion.Version)'`n" >> $outputFile
    }
}


<#
    .Description
    Write Create-Shortcut commands for DepalUI apps

    .PARAMETER info
    The Yaml node that represents the changing component represented as an ordered dictionary

    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.
#>
function Write-DepalUICommands {
    param(
        [System.Collections.Specialized.OrderedDictionary] $info, 
        [string] $outputFile,
        [switch] $legacy
    )
    
    $command = if ($legacy) { ".\shortcut.ps1" } else { "Create-Shortcut" }
    # E: for production
    $appFolders = ls "C:\Program Files\Symbotic\Depalletization User Interfaces*"
    $oldVersion = $($appFolders[$appFolders.Length - 2] -replace "[^0-9.]", "")
    $firstOldExe = $info.configs.path -f $oldVersion, $info.configs.first_app.name
    $firstNewExe = $info.configs.path -f $info.version, $info.configs.first_app.name
    $firstDestination = $info.configs.first_app.appDestination
    "# create $($info.configs.first_app.name) DepalUI shortcut" >> $outputFile
    "$command -vm '$($info.configs.vm)' -shortcutDestination '$firstDestination'" + `
        " -pathToNewExe '$firstNewExe' -bak '$firstOldExe'`n" >> $outputFile

    $secondOldExe = $info.configs.path -f $oldVersion, $info.configs.second_app.name
    $secondNewExe = $info.configs.path -f $info.version, $info.configs.second_app.name
    $secondDestination = $info.configs.second_app.appDestination
    "# create $($info.configs.second_app.name) DepalUI shortcut" >> $outputFile
    "$command -vm '$($info.configs.vm)' -shortcutDestination '$secondDestination'" + `
        " -pathToNewExe '$secondNewExe' -bak '$secondOldExe'`n" >> $outputFile
}


<#
    .Description
    Write Create-Shortcut commands for LIUI apps

    .PARAMETER info
    The Yaml node that represents the changing component represented as an ordered dictionary

    .PARAMETER site
    The site abbreviation, used to find the correct config module in /configs folder

    .PARAMETER outputFile
    The .ps1 script to write the commands to, defaults to gameplan.ps1 in the current directory.
#>
function Write-LIUICommands {
    param(
        [System.Collections.Specialized.OrderedDictionary] $info, 
        [string] $site,
        [string] $outputFile,
        [switch] $legacy
    ) 

    $command = if ($legacy) { ".\shortcut.ps1" } else { "Create-Shortcut" }
    $appFolders = ls "C:\Program Files\Symbotic\Label Inquiry*"
    $oldVersion = $($appFolders[$appFolders.Length - 2]) -replace "[^0-9.]", ""
    $oldExe = $info.configs.path -f $oldVersion
    $newExe = $info.configs.path -f $info.version
    $destination = $info.configs.appDestination
    $(Get-Content $modulespath/configs/$site.psm1) | Out-String | Invoke-Expression
    "# create LIUI shortcuts" >> $outputFile
    foreach ($liui in $LIUIs) {
        "$command -vm '$liui' -shortcutDestination '$destination'" + `
            " -pathToNewExe '$newExe' -bak '$oldExe'`n" >> $outputFile
    }
}

Export-ModuleMember -Function Write-StartupToolAppCommand
Export-ModuleMember -Function Write-AppCommand
Export-ModuleMember -Function Write-CCAppCommands
Export-ModuleMember -Function Write-DepalUICommands
Export-ModuleMember -Function Write-LIUICommands