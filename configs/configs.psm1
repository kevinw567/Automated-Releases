# static variables
# 'C:/Program Files/WindowsPowerShell/Modules' for production
$modulespath = "$env:userprofile\Documents\WindowsPowerShell\Modules"

# folder containing Startup Tool XML files
# '\\cc01\C:\ProgramData\Symbotic\StartupTool' for production
$pathToStartupToolFolder = "C:\Users\Administrator\Documents\WindowsPowerShell\Modules\Update-StartupToolXML"

# service names (consistent across sites)
$serviceNames = @{
    CSS  = "Symbotic Case Storage Service";
    CPI  = "Symbotic Case Parameter Input";
    GW   = "Symbotic Cell Gateway Service";
    ODS  = "Symbotic Data Services";
    PBP  = "Symbotic Pallet Build Planner";
    PSEQ = "Symbotic Pallet Sequencer";
    SMI  = "Symbotic System Manager Inbound";
    SMO  = "Symbotic System Manager Outbound";
    IM   = "Symbotic Integration Manager Core"
}

Export-ModuleMember -Variable serviceNames
Export-ModuleMember -Variable modulespath
Export-ModuleMember -Variable pathToStartupToolFolder