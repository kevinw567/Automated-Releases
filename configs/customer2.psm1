$var1 = @(
    "FQDN",
    "FQDN",
    "FQDN",
    "FQDN",
    "FQDN",
    "FQDN"
)

$var2 = @(
    "FQDN01",
    "FQDN02",
    "FQDN03",
    "FQDN04",
    "FQDN05"
)

$var3 = @("FQDN01")

Export-ModuleMember -Variable $var1
Export-ModuleMember -Variable $var2
Export-ModuleMember -Variable $var3