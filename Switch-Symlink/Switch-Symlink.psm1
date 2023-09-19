<# 
    Function delete - Determines whether or not there is a symlink with the 
    provided name to delete and if there is, deletes it

    This function looks in the $location path for a symbolic link named 
    $symlinkName. if it is there it will be deleted and if it is not 
#>
function delete {
    # check if the target symlink exists, if not return
    $s = New-PSSession -ComputerName $vmName
    Invoke-Command -Session $s -ScriptBlock {
        param($location, $symlinkName, $vmName)
        Set-Location $location 
        if (!(Test-Path "./$symlinkName")) {
            pwd
            Write-Host ("[$vmName] There is no symlink with name '$symlinkName' " + 
                "in '$location'") -ForegroundColor Yellow
            return
        }
        
        # check if a symlink already exists
        elseif ((Get-Item ./$symlinkName -ErrorAction STOP).Attributes.ToString() `
                -match "ReparsePoint") {
            # if it the symlink exists, delete it
            try {
                (Get-Item "./$symlinkName" -ErrorAction STOP).Delete() > $null
            }

            # catch runtime exception, there was no symlink to delete
            catch [System.Management.Automation.ItemNotFoundException] {
                Write-Host ("[$vmName] There is no symlink with name " + `
                        "'$symlinkName' found in '$location'") `
                    -ForegroundColor Yellow
            }

            # if an error occurred print the error message
            catch {
                Write-Host $_
                return
            }
            
            Write-Host ("[$vmName] '$symlinkName' symlink was deleted  " +
                "successfully from '$location'") -ForegroundColor Green
        }

        else {
            Write-Host ("There is no symlink with name '$symlinkName' in " +
                "'$location'")
        }
    } -ArgumentList $location, $symlinkName, $vmName
    Remove-PSSession $s
}

<#
    Function create - Create a new symlink
    
    Creates a symlink with $symlinkName as the name and points it at $target.
#>
function create {
    # create the new symlink
    try {
        # run a new PS session to create the new symlink
        $s = New-PSSession -ComputerName $vmName
        Invoke-Command -Session $s -ScriptBlock { 
            param($linkName, $linkTarget, $linkLocation)
            cd "$linkLocation";
            New-Item -ItemType SymbolicLink -Path "./$linkName" -Target "$linkTarget" -ErrorAction STOP > $null
        } -ArgumentList $symlinkName, $target, $location
    }
	
    # catch IOException error, usually a symlink with that name already exists
    catch [System.IO.IOException] {
        Write-Host ("[$vmName] An error occurred, there may already be a " +
            "'$symlinkName' symlink in '$location'") -ForegroundColor Red
        return
    }

    # catch any other errors
    catch {
        Write-Error $_
        return
    }
	
    $sym = (Get-Item $location\$symlinkName).Target
    Write-Host "[$vmName] '$symlinkName' symlink, with target '$sym', was created in '$location'" `
        -ForegroundColor Green
    Remove-PSSession $s
}

<#  
    Function switchSymlink - Driver function

    Determine whether to create, delete or do both based on the parameters
    passed to this script
#>
function Switch-Symlink {
    param(
        [Parameter(Mandatory, HelpMessage = "The VM to create the new symlink on")]
        # [Parameter(ParameterSetName = "deleteonly")]
        # [Parameter(ParameterSetName = "createonly")]
        [Alias("vm")]
        $vmName,

        [Parameter(Mandatory, HelpMessage = "Where the new symlink should be" + 
            " created and old one should be removed from")
        ]
        # [Parameter(ParameterSetName = "deleteonly")]
        # [Parameter(ParameterSetName = "createonly")]
        $location,

        [Parameter(Mandatory, HelpMessage = "Name of the symlink to delete/create" +
            "(ex. 'SiteConfigs'")
        ]
        # [Parameter(ParameterSetName = "deleteonly")]
        # [Parameter(ParameterSetName = "createonly")]
        $symlinkName,

        [Parameter(HelpMessage = "The location the symlink should " + 
            "point to", ParameterSetName = "both")
        ]
        [Parameter(ParameterSetName = "createonly")]
        $target,

        [Parameter(HelpMessage = "Use -deleteOnly to only delete a symlink", `
                ParameterSetName = "deleteonly")
        ]
        [switch] $deleteOnly,

        [Parameter(HelpMessage = "Use -createOnly to only create a symlink", `
                ParameterSetName = "createonly")
        ]
        [switch] $createOnly
    )
    # save the location the script was called from
    Push-Location
    # only create a symlink
    if ($PsCmdlet.ParameterSetName -eq "createonly") {
        create
        Pop-Location
    }
	
    # only delete a symlink
    elseif ($PsCmdlet.ParameterSetName -eq "deleteonly") {
        delete
        Pop-Location
    }
    
    # do both
    else {
        delete
        create
		
    }

    Exit-PSSession
    # return to the location this script was called from
    Pop-Location
}

Export-ModuleMember -Function Switch-Symlink