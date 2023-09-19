#requires -Modules configs
$path = "path\to\file"

function Switch-StartupToolXML {
    param(
        [Parameter(Mandatory)]
        [Alias("vm")]
        [String[]]
        $vmName,

        [Parameter(Mandatory)]
        [Alias("old")]
        [string]
        $oldVersion,

        [Parameter(Mandatory)]
        [Alias("new")]
        [string]
        $newVersion
    )

    Push-Location
    (Get-Content $path\StackDefinerFilelist.symbotic).replace($oldVersion, $newVersion) | Set-Content $path\FileName1
    (Get-Content $path\StartupToolTopology.symbotic).replace($oldVersion, $newVersion) | Set-Content $path\FileName2
    Pop-Location
}

Export-ModuleMember -Function Switch-StartupToolXML