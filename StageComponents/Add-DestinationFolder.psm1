function Add-DestinationFolder {
    param([Parameter(Mandatory)] $vm, [Parameter(Mandatory)] $component, [Parameter(Mandatory)] $version, [switch] $deleteExisting, [switch] $testing)
    # decide which drive to install to
    $drive = if (Test-Path "\\$vm\e$") { "e$" } else { "c$" }
	cd \\$vm\$drive
    # create a Program Files folder if there isn't one already
	if (-not $(Test-Path ".\Program Files")) {
	    try { mkdir "$drive\Program Files" -ErrorAction STOP }
	    catch { Write-Host "[$vm] Could not create 'Program Files' folder on $drive drive" -ForegroundColor Red -BackgroundColor Black }
    }

    # create Symbotic folder if there isn't one already
    if (-not $(Test-Path ".\Program Files\Symbotic")) { 
        try {
            cd "$drive\Program Files"
            mkdir ".\Symbotic"
        }

        catch [Microsoft.PowerShell.Commands.NewItemCommand] {
            if ($error[0].Exception -match "already exists") {
                Write-Host "[$vm] Could not create 'Symbotic' folder in '$drive\Program Files'"
            }
        }
    }

    try {
        cd "$drive\Program Files\Symbotic"
        # create the component destination folder if there isn't one already
        if (!(Test-Path "./$component $version")) { mkdir "$component $version" >> $null -ErrorAction Stop }
        # if there is already a destination folder, print a warning
        else {
            Write-Host "[$vm] '$drive\Program Files\Symbotic\$component $version' aleady exists" `
                -ForegroundColor Yellow -BackgroundColor Black
            
            return
        }

        # confirm that the new destiantion folder exists
        if (Test-Path "$drive\Program Files\Symbotic\$component $version") {
            Write-Host "[$vm] '$drive\Program Files\Symbotic\$component $version' created" `
                -ForegroundColor Green -BackgroundColor Black
        }

        else {
            Write-Host "[$vm] '$drive\Program Files\Symbotic\$component $version' could not be created" `
                -ForegroundColor Green -BackgroundColor Black
        }
    }

    catch {
        if ($_ -match "Access to the path * is denied") {
            Write-Host "Could not create '$drive\Program Files\Symbotic\$component $verion' because you" `
                "do not have the correct permissions" -ForegroundColor Red -BackgroundColor Black
        }

        else { Write-Host ($_ -like "Access to the path '*' is denied") }
    }
}


Export-ModuleMember -Function Add-DestinationFolder