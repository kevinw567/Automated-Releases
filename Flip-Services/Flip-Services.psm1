<#
	.Description
	This module is used to enable and the windows service for each software component
#>

# user chooses the services to disable and set to manual from an on screen list
function switchServiceFromList {
	Write-Host "Listing services on $vmName"
	Get-Service -name "symbotic*" -ComputerName $vmName | Select-Object -Property Name, status, starttype | Format-Table -auto
	# get service to disable from user
	$serviceToDisable = Read-Host -Prompt "Select a service above to disable (copy and paste the name here)"
	Clear-Host
	# call changeService to disable service
	changeService -serviceName $serviceToDisable.Trim() -VM $vmName -action "Disabled"
	Write-Host "Current state of Symbotic services on $vmName"
	Get-Service -name "symbotic*" -ComputerName $vmName | Select-Object -Property Name, status, starttype | Format-Table -auto
	# get service to set to manual from user
	$serviceToEnable = Read-Host -Prompt "Select a service above to enable (copy and paste the name here)"
	Clear-Host
	# call change service to set service to manual
	changeService -serviceName $serviceToEnable.Trim() -VM $vmName -action "Manual"
	Write-Host "Current state of Symbotic services on $vmName"
	Get-Service -name "symbotic*" -ComputerName $vmName | Select-Object -Property Name, status, starttype | Format-Table -auto
}

# services to disable/set to manual are taken as command line args
function switchServiceCommandline {
	# set old service to disabled
	if ($disable) { changeService -VM $vmName -serviceName $disable -action "Disabled" }
	# set new service to manual
	if ($enable) { changeService -VM $vmName -serviceName $enable -action "Manual" }	
}

# the function that makes the service changes
function changeService {
	param([Parameter(Mandatory)] $serviceName, [Parameter(Mandatory)] $VM , [Parameter(Mandatory)] $action)
	# set new service to manual
	try {
		# check if the service is already in the new state, if it is do nothing
		$s = Get-Service -ComputerName $VM -Name $serviceName -ErrorAction STOP
		if ($s.StartType -eq $action) {
			Write-Host "[$vmName] '$serviceName' is already set to $action" -ForegroundColor Yellow -BackgroundColor Black
			return
		}
		
		Set-Service -name $serviceName -ComputerName $VM -Startuptype $action -ErrorAction STOP
		if ($action -eq "Disabled") {
			Write-Host "[$vmName] Status of Old Service: '$disable'"
			Get-Service -name $disable -ComputerName $vmName | Select-Object -Property Name, Status, Starttype | Format-Table -auto
		}

		else {
			Write-Host "[$vmName] Status of New Service '$enable'"
			Get-Service -name $enable -ComputerName $vmName | Select-Object -Property Name, Status, Starttype | Format-Table -auto
		}
	}

	# catch invalid operation exception, most likely a spelling error in service name
	catch [ System.InvalidOperationException ]  {
		Write-Host "[$vmName] '$serviceName' was not found. Check the spelling of the service name." -ForegroundColor Red -BackgroundColor Black
		return
	}

	# catch error for no service with given name
	catch [ Microsoft.PowerShell.Commands.ServiceCommandException ] {
		Write-Host "[$vmName] '$serviceName' was not found. Check the spelling of the service name." -ForegroundColor Red -BackgroundColor Black
		return
	}
	
	# catch all other exceptions
	catch {
		Write-Host "An error occurred while setting '$serviceName' to manual" -ForegroundColor Red -BackgroundColor Black
		Write-Output $_
		Write-Host
		return
	}

	# verify whether the change was made
	$service = Get-Service -name $serviceName -ComputerName $vmName
	if ($service.StartType -eq $action) { Write-Host "[$vmName] '$serviceName' was changed to '$action'" -ForegroundColor Green -BackgroundColor Black }
	else { Write-Host "[$vmName] '$serviceName' could not be switched to '$action'" -ForegroundColor Red -BackgroundColor Black }
}


# entry point
function Flip-Services {
	param ([Parameter(ParameterSetName = "commandline")] $enable, [Parameter(ParameterSetName = "commandline")] $disable, [Parameter(Mandatory)] $vmName)
	if ($PsCmdlet.ParameterSetName -eq "commandline") { switchServiceCommandline }
	else { switchServiceFromList }
}

Export-ModuleMember -Function Flip-Services
