$ManagerDN = $Request.DN
$tempArray = $ManagerDN.Split(",")

$ManagedUnitName = $tempArray[0]
$ManagedUnitName = $ManagedUnitName.Substring(3)

$ManagedUnitFullPath = "EDMS://CN=" + $ManagedUnitName + ",CN=Managed Units,cn=Configuration"

$path = [ADSI]"EDMS://CN=Managed Units,cn=Configuration"
$managedUnit = $path.Create("edsManagedUnit", "CN=" + $ManagedUnitName)
$managedUnit.SetInfo()

Start-Sleep -Seconds 2

$ManagedUnit = [ADSI]$ManagedUnitFullPath


$RuleCollection = $ManagedUnit.MembershipRuleCollection

$MembershipRule = New-Object -ComObject "EDSIManagedUnitCondition"
$MembershipRule.Base = "EDMS://DC=ndtest,DC=domain,DC=local"
$MembershipRule.Filter = "(&(objectClass=user)(Manager=" + $ManagerDN + "))"
$MembershipRule.Type = 1

$RuleCollection.Add($MembershipRule)
$ManagedUnit.SetInfo()

