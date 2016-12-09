##  $Guid is the value retrieved from the edsaARServiceGUID attribute on one of the Administration Service objects that you want to be the service to run on.

Param(
    [string]$GroupFamilyName,
    [string]$ARGuid,
    [string]$SQLInstance,
    [string]$SQLDatabase,
    [switch]$FixPreviouslyControlledGroups)

function executeSQL($sqlText, $database = "master", $server = ".",$timeout=30)
{
    $connection = New-Object System.Data.SqlClient.SQLConnection("Data Source=$server;Integrated Security=SSPI;Initial Catalog=$database;Connect Timeout=$timeout;");
    $cmd = New-Object System.Data.SqlClient.SqlCommand($sqlText, $connection);

    $connection.Open();
    $cmd.ExecuteReader()

}


$GF = Get-QADObject -Identity $GroupFamilyName -IncludedProperties edsvaGFControlledGroups -Proxy
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

Set-QADObject -Identity $GroupFamilyName -ObjectAttributes @{'accountNameHistory' = $GFAccountNameHistory.OuterXml}

### Update previously controlled groups

if ($FixPreviouslyControlledGroups){
    [XML]$ControlledGroupAccountNameHistory = "<GroupFamily xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema""><IsControlledGroup>True</IsControlledGroup><IsCreatedByGroupFamily>True</IsCreatedByGroupFamily><ControlledBy>$guid</ControlledBy><LastUpdateTime></LastUpdateTime><LastPopulatedMembersCount></LastPopulatedMembersCount></GroupFamily>"

    $GF.edsvaGFControlledGroups | ForEach-Object{
        Set-QADObject -Identity $_ -ObjectAttributes @{'accountNameHistory'=$ControlledGroupAccountNameHistory.OuterXml} -Proxy
    }
}