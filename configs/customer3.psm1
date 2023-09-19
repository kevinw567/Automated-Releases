$var1 = @(
    "FQDN",
    "FQDN",
    "FQDN",
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
    "FQDN04",
    "FQDN05",
    "FQDN09",
    "FQDN"
)

$var3 = @("FQDN02")

Export-ModuleMember -Variable $var1
Export-ModuleMember -Variable $var2
Export-ModuleMember -Variable $var3