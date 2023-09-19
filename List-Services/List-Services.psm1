<#
    .Description
    List the Symbotic services on a specified VM

    .PARAMETER vmName, vm
    The VM to list the Symbotic services for

    .Example
    List-Services -vm "vm_name"
#>

function List-Services {
    param([Parameter(Mandatory)] [Alias("vm")] $vmName)
    Get-Service -ComputerName $vmName -Name "symbotic*" | Select -property Name, StartType, Status | ft -auto
}


Export-ModuleMember -Function List-Services