$var1 = @(
    "FQDN",
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
    "FQDN03",
    "FQDN04",
    "FQDN05",
    "FQDN",
    "FQDN09"
)

$var3 = @("FQDN03")

$var4 = @{
    "Component Name1" = @{ "default value" = "nondefault value" }
}

Export-ModuleMember -Variable $var1
Export-ModuleMember -Variable $var2
Export-ModuleMember -Variable $var3
Export-ModuleMember -Variable $var4