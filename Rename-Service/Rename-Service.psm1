

# function that does the renaming
function renameServiceFromList {
    param ([Parameter(Mandatory)] $vmName)
    Get-Service -ComputerName $vmName -name "symbotic*" | Select -property name, displayname | ft -auto
    # prompt user for service to rename
    $serviceToRename = Read-Host -Prompt "Select a service above to rename (copy and paste the 'name', not 'display name')"
    $inputName = Read-Host -Prompt "New display name for '$serviceToRename'"
    Set-Service -name $serviceToRename -ComputerName $vmName -DisplayName $inputName -ErrorAction STOP
    Write-Output "[$vmName] $serviceToRename's display name has been renamed to $inputName --------------------"
}

function renameServiceCommandLine {
    param ([Parameter(Mandatory)] $vmName, [Parameter(Mandatory)] $serviceName, [Parameter(Mandatory)] $newName)
    if ($(Get-Service -name $serviceName | Select -Property DisplayName) -eq $newDisplayName) {
        Write-Host "[$vmName] $serviceName's display name is already set to $newDisplayName --------------------"
    }
	
    Set-Service -name $serviceName -ComputerName $vmName -DisplayName $newName -ErrorAction STOP
    Write-Output "[$vmName] $serviceName's display name was renamed to $newName --------------------"
}

# loop through numVMs and call rename service for each vm
function renameMultipleServices {
    param ([Parameter(ParameterSetName = "multiple", Mandatory)] $prefix, [Parameter(ParameterSetName = "multiple", Mandatory)] $numOfVMs, [Parameter(Mandatory)] $oldService, [Parameter(Mandatory)] $newService)
    for ($i = 1; $i -le $numVMs; $i++) {
        # create vmName string
        $vm = $vmPrefix + "0" + $i
        # call renameService on $vm
        renameService -vmName $vm -oldName $oldServiceName -newName $newServiceName
    }
}

function Rename-Service {
    param (
        [Parameter(Mandatory)] $vmName,
        <# [Parameter(ParameterSetName="multiple")] $vmPrefix,
	    [Parameter(ParameterSetName="multiple")] $numVMs, #>
        [Parameter(ParameterSetName = "cmd")] $serviceName,
        [Parameter(ParameterSetName = "cmd")] $newDisplayName
    )
    # if only a vm name is given rename on 1 VM
    if ($PsCmdlet.ParameterSetName -eq "cmd") { 
        Write-Host "cmd" 
        renameServiceCommandLine -vmName $vmName -serviceName $serviceName -newName $newDisplayName
    }

    # renaming multiple services on multiple VMs
    elseif ($PsCmdlet.ParameterSetName -eq "multiple") {
        Write-Host "multiple"
        renameMultipleServices -vmName $vmName -prefix $vmPrefix -numOfVMs $numVMs -oldService $oldServiceName -newService $newServiceName
    }
    # renaming 1 VM from command line call 
    else { renameServiceFromList -vmName $vmName }
}

Export-ModuleMember -Function Rename-Service