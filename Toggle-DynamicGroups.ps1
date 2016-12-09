Param(
[Switch]$Enable,
[Switch]$Disable
)

If ($Enable){
    Add-PSSnapin Quest.ActiveRoles.ADManagement
    Set-QADObject "CN=Built-in Policy - Dynamic Groups,CN=Builtin,CN=Administration,CN=Policies,CN=Configuration" -ObjectAttributes @{edsaPolicyDisabled='FALSE'} -Proxy
}

If ($Disable){
    Add-PSSnapin Quest.ActiveRoles.ADManagement
    Set-QADObject "CN=Built-in Policy - Dynamic Groups,CN=Builtin,CN=Administration,CN=Policies,CN=Configuration" -ObjectAttributes @{edsaPolicyDisabled='TRUE'} -Proxy
}