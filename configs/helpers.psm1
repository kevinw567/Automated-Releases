<#
    .Description
    Given a component name, return the corresponding installer name

    .PARAMETER component
    The name of the software component
#>
function Get-ExeName {
    param([Parameter(Mandatory)] [string] $component)
    switch -regex ($component) {
        "Control Center*" { return $exeNames["Control Center"]; }
        "Bot Saver*" { return $exeNames["Bot Saver"] }
        "Start Up Tool*" { return $exeNames["Start Up Tool"] }
        "Case Parameter Input*" { return $exeNames["Case Parameter Input"] }
        "Label Inquiry Application*" { return $exeNames["Label Inquiry Application"] }
        "Depalletization User Interfaces*" { return $exeNames["Depalletization User Interfaces"] }
        "Maintenance Stand UI*" { return $exeNames["Maintenance Stand UI"] }
        "Messaging Proxy*" { return $exeNames["Messaging Proxy"] }
        Default { return -1 }
    }
}


<#
    .Description
    Using the domain of the current machine, determine which customer is being worked on.
    
    .PARAMETER domain
    The domain name of the current machine.
#>
function Convert-DomainToSite {
    $domain = $(whoami).split("\")[0]
    switch ($domain) {
        "domain1" { return "customer1" }
        "domain2" { return "customer2" }
    }
}

<#
    .Description
    Given the name of a software component, return the machine that component should be installed on

    .PARAMETER component
    The name of the software component
#>
function Get-VM {
    param([Parameter(Mandatory)] $component)
    switch -regex ($component) {
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        "componentname" { return "machinename" }
        # return false for non-matches
        default { return $False }
    }
}

# from stagecomponents.ps1
function Test-PBPs {
    for ($i = 8; $i -ge 1; $i--) {
        return 8 # remove for production
        # test for the highest number pbp machine and return that number
        if ($i -eq 8 <#Test-Path "pbp0$i\c$"#>) {
            return $i
        }
    }

    return -1
}


Export-ModuleMember -Function Get-ExeName
Export-ModuleMember -Function Convert-DomainToSite
Export-ModuleMember -Function Get-VM
Export-ModuleMember -Function Test-PBPs
