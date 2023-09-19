# get all Symbotic services in Manual
function Get-ManualServices {
    Get-Service -Computername localhost <#(Get-Content -path .\Hostnames.config)#> Sym* | Select-Object MachineName, Name, Starttype | Where-Object { $_.Starttype -EQ "Manual" } | Sort-Object MachineName
}

Export-ModuleMember -Function Get-ManualServices