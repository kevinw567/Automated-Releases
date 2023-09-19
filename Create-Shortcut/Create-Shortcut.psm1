

# components and their executable names
$exeNames = @{
    "ComponentName" = "ExecutableName"
    "ComponentName1" = "ExecutableName1";
    "ComponentName2" = "ExecutableName2";
    "ComponentName3" = "ExecutableName3"; 
    "ComponentName4" = "ExecutableName4";
    "ComponentName5" = "ExecutableName5";
    "ComponentName6" = "ExecutableName6"
    "ComponentName7" = "ExecutableName7"
}

<#
    .Description
    Delete shortcuts, for a given software component, from the service user desktop

    .Parameter component
    The name of the software component  
#>
function delete_shortcuts {
    param([string] $component)
    $session = New-PSSession $vmName
    Invoke-Command -Session $session -ScriptBlock {
        param([string] $shortcutDestination, $vmName, $component)
        # modify component name to create a regex expression
        $shortcutRegex = $component -replace "[0-9\.]", ""
        $shortcutRegex = $($shortcutRegex -replace " ", "*")
        # if there are any matching shortcuts in the desktination folder delete them
        if (Test-Path "$shortcutDestination\$shortcutRegex") {
            # get all matching shortcuts
            $shortcuts = Get-ChildItem -Path $shortcutDestination -Filter "$shortcutRegex"
            if ($shortcuts.Length -eq 2279) { foreach ($s in $shortcuts) { Write-Host $shortcut } }
            # delete all the matching shortcuts on the desktop
            foreach ($shortcut in $shortcuts) { Remove-Item "$shortcutDestination\$shortcut" }
        }
		
        if (Test-Path "$shorcutDestination\$shortcutRegex") {
            Write-Host "[$vmName] Unable to delete $component shorcuts from '$shortcutDestination'" -ForegroundColor Yellow -Background Black
        }
		
        else { Write-Host "[$vmName] $($shortcutRegex.replace("*"," ")) shortcuts were deleted from '$shortcutDestination'" -ForegroundColor Green -Background Black }
    } -Args $shortcutDestination, $vmName, $component
}

<# 
    .Description
    Create a desktop shortcut for the selected component on the service user desktop

    .Parameter component
    The name of the software component

    .Parameter exeName
    The executable file to create the shortcut for
#>
function create_shortcut {
    param([string] $component, [string] $exeName)
    $session = New-PSSession $vmName
    Invoke-Command -Session $session -ScriptBlock {
        param([string] $pathToNewExe, [string] $shortcutDestination, [string] $component, [string] $exeName, [string] $vmName)
        # use the apps folder name as the shortcut name
        $shortcutName = $pathToNewExe.split("\")[$pathToNewExe.split("\").Length - 1]
        # create the shortcut (ex. ccuser/Desktop)
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut("$shortcutDestination\$shortcutName.lnk")
        # add shortcut info
        $exePath = "$pathToNewExe\$exeName"
        $exe = Get-Item($exePath)
        $shortcut.TargetPath = $exe.FullName
        $shortcut.WorkingDirectory = $pathToNewExe
        $shortcut.IconLocation = "$($pathToNewExe)\$exeName,o"
        $shortcut.Save()
        # set shortcut to run as administrator
        $bytes = [System.IO.File]::ReadAllBytes("$shortcutDestination.lnk")
        # set executable to run as administrator
        $bytes[0x15] = $bytes[0x15] -bor 0x20 # set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes("$shortcutDestination.lnk", $bytes)
        if (Test-Path "$shortcutDestination.lnk") { Write-Host "[$vmName] $shortcutDestination shortcut was created" -ForegroundColor Green -BackgroundColor Black }
        else { Write-Host "[$vmName] $shortcutDestination shortcut could not be created" -ForegroundColor Red -BackgroundColor Black }
    } -Args $pathToNewExe, $shortcutDestination, $component, $exeName, $vmName
}

<# 
    .Description
    Disable the old services' executable file by appending .bak to it

    .Parameter component
    The name of the software component

    .Parameter exeName
    The name of this software component's executable
#>
function disable_old_exe {
    param([string] $component, [string] $exeName)
    $session = New-PSSession $vmName
    Invoke-Command -Session $session -ScriptBlock {
        param([string] $bak, [string] $component, [string] $exeName, [string] $vmName)
        if (Test-Path "$bak\$exeName") {
            Rename-Item -Path "$bak\$exeName" -NewName "$exeName.bak"
            Write-Host "[$vmName] '$bak$exeName' was renamed to '$exeName.bak'" -ForegroundColor Green -Background Black
        }

        else { Write-Host "[$vmName] $bak\$exeName was not found and could not be disabled" -ForegroundColor Red -Background Black }
    } -Args $bak, $component, $exeName, $vmName
}

<#
    .Description
    Given a software component name, return the name of that component's executable file

    .Parameter component
    The name of the software component
#>
function get_exe_name {
    param([Parameter(Mandatory)] [string] $component)
    switch -regex ($component) {
        "ComponentName*" { return $exeNames["ComponentName"]; }
        "ComponentName1*" { return $exeNames["ComponentName1"] }
        "ComponentName2*" { return $exeNames["ComponentName2"] }
        "ComponentName3*" { return $exeNames["ComponentName3"] }
        "ComponentName4*" { return $exeNames["ComponentName4"] }
        "ComponentName5*" { return $exeNames["ComponentName5"] }
        "ComponentName6*" { return $exeNames["ComponentName6"] }
        "ComponentName7*" { return $exeNames["ComponentName7"] }
        Default { return -1 }
    }
}

function Create-Shortcut {
    param(
        [Parameter(Mandatory)]
        [Alias("vm")]
        [string]
        $vmName,
        
        [Parameter(Mandatory, HelpMessage = "Absolute path to new software folder ")]
        [string]
        [Alias("new")]
        $pathToNewExe,

        [Parameter(Mandatory, HelpMessage = "Absolute path to shortcut destination (including shortcut name")]
        [Alias("destination")]
        [string]
        $shortcutDestination,

        [Parameter(HelpMessage = "Absolute path of executable to .bak")]
        [Alias("old")]
        [string]
        $bak,

        [Parameter(HelpMessage = "Use this switch only if you want to disable the old exe")]
        [switch]
        [Alias("bakOnly")]
        $disableOnly
    )
    
    $split = $pathToNewExe.split("\")
    $component = $split[$split.Length - 1]
    $exe = get_exe_name $component
    if ($exe -eq -1) {
        Write-Host "[Error] $component is not recognized as a valid component" -ForegroundColor Red -BackgroundColor Black
        return
    }
	
    if ($disableOnly) { disable_old_exe -exeName $exe -component $component }
    else {
        delete_shortcuts -exeName $exe -component $component
        create_shortcut -exeName $exe -component $component
        if ($bak -ne "") { disable_old_exe -exeName $exe -component $component }
    }
}

Export-ModuleMember -Function Create-Shortcut