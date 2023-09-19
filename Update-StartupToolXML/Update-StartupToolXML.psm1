#requires -Module configs
<#

#>

# will be C:\PrograData\Symbotic\startuptool for production

$components = @(
    "Baker", 
    "Bot Saver", 
    "Case Parameter Input", 
    "Case Storage Service", 
    "ControlCenter", 
    "Data Services",
    "MessagingProxy", 
    "Pallet Build Planner",
    "Pallet Sequencer", 
    "System Manager Inbound", 
    "System Manager Outbound",
    "Toaster"
)

function Update-StartupToolXML {
    param(
        [Parameter(Mandatory)]
        [String[]]
        $vmName,

        [Parameter(Mandatory)]
        [String]
        $oldVersion,

        [Parameter(Mandatory)]
        [String]
        $newVersion,

        [string]
        $readFile = "$pwd\components.yaml"
    )

    # save location the command was called from
    pushd
    try {
        Set-location $pathToStartupToolFolder\$oldVersion
        # create new version directory
        mkdir ../$newVersion > $null -ErrorAction STOP
        # copy old version XML to new version directory
        Copy-Item $pathToStartupToolFolder\$oldVersion\$oldVersion.xml $pathToStartupToolFolder\$newVersion\$newVersion.xml
        Set-Location ../$newVersion
        # read in XML file
        $xml = [xml]::new()
        $xml.PreserveWhitespace = $true
        $xml.psbase.PreserveWhitespace = $true
        [xml]$xml.Load("$pathToStartupToolFolder\$newVersion\$newVersion.xml")
        # select node to change
        $nodes = $xml.SelectNodes("//Component")
        $yml = ConvertFrom-Yaml -Path $readFile
        for ($i = 0; $i -le $yml.components.Length; $i++) {
            # change name and version
            foreach ($node in $nodes) {
                # if component matches, make changes 
                if ($node.Name -match $yml.components[$i].name) {
                    $new = $yml.components[$i]
                    if ($new.changed -in "True", 1, "t") {
                        # save old component version, will be changed if it is a service
                        $oldCompVersion = $node.Version
                        # if the component is a service replace the old version in the name
                        if ($node.ItemType -eq "Service") {
                            # save the old component version number
                            $oldCompVersion = $node.Name.split(" ")[$node.Name.split(" ").Length - 1]
                            $node.Name = $node.Name.replace($oldCompVersion, $new.version)
                        }

                        # if the component is an app, replace the old version number in the location path
                        if ($node.ItemType -eq "Application") {
                            $node.Location = $node.Location.replace($oldCompVersion, $new.version)
                        }

                        # changed version
                        $node.Version = $node.Version.replace($oldCompVersion, $new.version)
                    }
                    
                    # if the component is a System Manager, check if SM Agent was changed
                    if ($node.Name -match "System Manager") {
                        #Write-Output "Agent[changed]: " #$($new.Agent.changed | Out-String)
                        if ($new.Agent.changed -eq $True) {
                            # save old agent version
                            $oldAgent = $node.Version.split(" ")[$node.Version.split(" ").Length - 1]
                            # replace old agent verison with new agent version
                            $node.Version = $node.Version.replace($oldAgent, $new.Agent.version)
                        }
                    }
                }
            }
        }

        # configure writer to preserve new lines & whitespaces
        $writerSettings = New-Object System.Xml.XmlWriterSettings
        $writerSettings.Indent = $true
        $writerSettings.NewLineChars = "`r`n"
        $writerSettings.NewLineOnAttributes = $true
        $writer = [System.Xml.XmlWriter]::Create("$pathToStartupToolFolder\$newVersion\$newVersion.xml", $writerSettings)
        # save changes to new file
        $xml.Save($writer)
        $writer.Dispose()
        
    }

    # catch directory already exists error
    catch [System.IO.IOException] {
        Write-Host "[WARN] '$pathToStartupToolFolder\$newVersion' already exists. No changes were made." -ForegroundColor Yellow
        popd
    }

    catch {
        # catch can't read input file error
        if ($_.CategoryInfo.Category -eq "Microsoft.PowerShell.Commands.WriteErrorException") {
            Write-Host "[ERROR] Could not open file '$readFile' because it does not exist"
            popd
            return
        }

        # # catch unknown errors
        # Write-Host "[ERROR] An unknown error occurred, could not update Startuptool XML" -ForegroundColor Red
        # Write-Host "    $_" -ForegroundColor Red
        # # delete the new directory
        # # rm -r $pathToStartupToolFolder\$newVersion
        popd
    }

    # return to location command was called from
    popd
}

Export-ModuleMember -Function Update-StartupToolXML