Param(
    [string]$GroupFamilyDN,
    [switch]$FixPreviouslyControlledGroups)

function executeSQL($sqlText, $database = "master", $server = ".",$timeout=30)
{
    $connection = New-Object System.Data.SqlClient.SQLConnection("Data Source=$server;Integrated Security=SSPI;Initial Catalog=$database;Connect Timeout=$timeout;");
    $cmd = New-Object System.Data.SqlClient.SqlCommand($sqlText, $connection);

    $connection.Open();
    $cmd.ExecuteReader()

}

$ARGuid = ""
$SQLInstance = ""
$SQLDatabase = ""

$arServices = Get-QADObject -SearchRoot 'Configuration/Server Configuration/Administration Services' -Type edsARService -IncludeAllProperties -Proxy

switch ($arServices.getType().Name){
    "ArsDirectoryObject" {
        $guid_object = [System.Guid] $arServices.edsaARServiceGUID
        $guid_temp1 = (($guid_object.ToByteArray() | %{ '\' + $_.ToString('x2') }) -join '').Replace("\","")
        $ARGuid = ($guid_temp1.Substring(0,8) + "-" + $guid_temp1.Substring(8,4) + "-" + $guid_temp1.Substring(12,4) + "-" + $guid_temp1.Substring(16,4) + "-" + $guid_temp1.Substring(20))
        $SQLInstance = $arServices.edsaSQLAlias
        $SQLDatabase = $arServices.edsaDatabaseName
        break
    }

    "Object[]" {
        $arConnectivity = $true
        $arServices | %{
            try{
                Connect-QADService -Service $_.edsaEdmServiceComputerName -Proxy
            } catch {
                $arConnectivity = $false
            }

            if ($arConnectivity){
                $guid_object = [System.Guid] $_.edsaARServiceGUID
                $guid_temp1 = (($guid_object.ToByteArray() | %{ '\' + $_.ToString('x2') }) -join '').Replace("\","")
                $ARGuid = ($guid_temp1.Substring(0,8) + "-" + $guid_temp1.Substring(8,4) + "-" + $guid_temp1.Substring(12,4) + "-" + $guid_temp1.Substring(16,4) + "-" + $guid_temp1.Substring(20))
                $SQLInstance = $_.edsaSQLAlias
                $SQLDatabase = $_.edsaDatabaseName
                break
            }

            $arConnectivity = $true
        }
    }
}

$GF = Get-QADObject -Identity $GroupFamilyDN -IncludedProperties edsvaGFControlledGroups -Proxy
[XML]$GFAccountNameHistory = $GF.accountNameHistory

$guid = $GF.Guid

$sqlCommand =  "
    DECLARE @GUID VARCHAR(MAX)
    DECLARE @ARGUID VARCHAR(MAX)
SET @GUID = '$guid'
SET @ARGUID = '$ARGuid'
INSERT [dbo].[ScheduledTasks] ([ParentObjectGUID], [name], [distinguishedName], [description], [objectClass], [edsaDataSource], [edsaIsPredefined], [edsaSystemObject], [showInAdvancedViewOnly], [edsaShowInRawViewOnly], [systemFlags], [edsaParameters], [edsaXMLSchedule], [edsaDisableSchedule], [edsaModule], [edsaTaskState], [edsaTaskType], [edsaLastActionMessage], [edsaLastRunTime], [edsaServerToExecute], [edsaForceTermination], [edsaForceExecution], [edsaExtensionType], [edsaExtensionNetClassID], [whenCreated], [whenChanged], [sign], [displayName]) VALUES (N'dfb0c60b-3cde-42cb-935b-aafc6d675bfb', N'GroupFamily-' + @GUID, N'CN=GroupFamily-' + @GUID + ',CN=Group Family,CN=Scheduled Tasks,CN=Server Configuration,CN=Configuration', N'Auto-generated task to run Group Family. Do not modify or delete this task; otherwise, Group Family may stop functioning. This is part of Group Family configuration, and should only be administered by managing Group Family properties.', N'edsScheduledTask', NULL, 0, 1, NULL, 1, NULL, NULL, N'<?xml version=""1.0""?>
<Schedule><Daily><Every>1</Every><Start><Time>15:00:00.000</Time><Date>2016-12-08</Date></Start></Daily></Schedule>
', 0, @GUID, 4, 0, NULL, CAST(0x0000A6D401457F58 AS DateTime), @ARGUID, NULL, 0, NULL, NULL, CAST(0x0000A6D4013E0C9A AS DateTime), CAST(0x0000A6D401458741 AS DateTime), 0, NULL)"

executeSQL $sqlCommand $SQLDatabase $SQLInstance

[string]$taskGuid = ((Get-QADObject -Identity "GroupFamily-$guid" -Proxy).Guid).toString()

$GFAccountNameHistory.GroupFamily.GuidTask = $taskGuid
$GFAccountNameHistory.GroupFamily.ServerToExecute = $ARGuid

Set-QADObject -Identity $GroupFamilyDN -ObjectAttributes @{'accountNameHistory' = $GFAccountNameHistory.OuterXml}

### Update previously controlled groups

if ($FixPreviouslyControlledGroups){
    [XML]$ControlledGroupAccountNameHistory = "<GroupFamily xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema""><IsControlledGroup>True</IsControlledGroup><IsCreatedByGroupFamily>True</IsCreatedByGroupFamily><ControlledBy>$guid</ControlledBy><LastUpdateTime></LastUpdateTime><LastPopulatedMembersCount></LastPopulatedMembersCount></GroupFamily>"

    $GF.edsvaGFControlledGroups | %{
        Set-QADObject -Identity $_ -ObjectAttributes @{'accountNameHistory'=$ControlledGroupAccountNameHistory.OuterXml} -Proxy
    }
}