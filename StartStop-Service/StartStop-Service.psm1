
# choose the service to start/stop from an on screen list
function startStopServiceList {
    Write-Host "Listing Symbotic services on $vmName"
    Get-Service -Name "symbotic*" -ComputerName $vmName | Select -Property name, displayname, status | ft -auto
    # prompt user for service to start
    $serviceToStart = Read-Host -Prompt "Select a service above to start (copy & paste the 'name' or leave blank to skip)"
    # call changeService with action = "start"
    if (!($serviceToStart -eq '' -and $serviceToStart -ne $null)) { changeService -vm $vmName -service $serviceToStart }
    # prompt user for service to stop
    $serviceToStop = Read-Host -Prompt "Select a service above to stop (copy & paste the 'name' or leave blank to skip)"
    # call changeService with action = "stop"
    if (!(($serviceToStop -eq '') -and ($serviceToStop -ne $null))) { changeService -vm $vmName -service $serviceToStop }
}

function startStopServiceCmd {
    # if there is a service to start, call changeService with action = "start"
    if (!($start -eq '' -and $start -ne $null)) { changeService -action "start" -vm $vmName -service $start }
    # if there is a service to stop, call changeService with action = "stop"
    if (!(($stop -eq '') -and !($stop -eq $null))) { changeService -action "stop" -vm $vmName -service $stop }
}

# function that starts or stops the service
function changeService {
    param ([Parameter(Mandatory)] $action, [Parameter(Mandatory)] $vm, [Parameter(Mandatory)] [AllowEmptyString()] $service)
    if ($service -eq $null -or $service -eq "") { return }
    $currentStatus = (Get-Service -ComputerName $vm -name $service).status
    # if the service is already starting, do nothing
    if ($currentStatus -eq "Running" -and $action -eq "start") {
        Write-Host "[$vmName] ------------------------------------------------------------------------" -ForegroundColor Green -BackgroundColor Black
        Write-Host "[$vmName] $service is already running`n" -ForegroundColor Yellow -BackgroundColor Black
        return
    }
	
    # if the service is already stopped, do nothing
    elseif ($currentStatus -eq "Stopped" -and $action -eq "stop") {
        Write-Host "[$vmName] ------------------------------------------------------------------------" -ForegroundColor Green -BackgroundColor Black
        Write-Host "[$vmName] $service is already stopped`n" -ForegroundColor Yellow -BackgroundColor Black
        return
    }
	
    # start the service if action is start
    if ($action -eq "start") { 
        try { Get-Service -ComputerName $vm -Name $service | Start-Service -ErrorAction STOP }
        # catch any errors and print to terminal
        catch { 
            Write-Host $_ -ForegroundColor Red -BackgroundColor Black
            return
        }

        Write-Host "[$vmName] ------------------------------------------------------------------------" -ForegroundColor Green -BackgroundColor Black
        Get-Service -Name $service -ComputerName $vmName | Select -property name, displayname, status | ft -auto
        Write-Host "[$vmName] '$service' was started successfully`n" -ForegroundColor Green -BackgroundColor Black
    }

    # stop the service if action is stop
    if ($action -eq "stop") {
        try { Get-Service -ComputerName $vmName -Name $service -ErrorAction STOP | Stop-Service -ErrorAction STOP }
        catch {
            Write-Host $_ -ForegroundColor Red -BackgroundColor Black
            return
        }

        Write-Host "[$vmName] ------------------------------------------------------------------------" -ForegroundColor Green -BackgroundColor Black
        Get-Service -Name $service -ComputerName $vmName | Select -property name, displayname, status | ft -auto
        Write-Host "[$vmName] '$service' was stopped successfully`n" -ForegroundColor Green -BackgroundColor Black
    }    
}
function StartStop-Service {
    param (
        [Parameter(ParameterSetName = "commandline")] $start = "",
        [Parameter(ParameterSetName = "commandline")] $stop = "",
        [Parameter(Mandatory)] $vmName
    )
    # entry point
    if ($PsCmdlet.ParameterSetName -eq "commandline") { startStopServiceCmd }
    else { startStopServiceList }
}

Export-ModuleMember -Function StartStop-Service