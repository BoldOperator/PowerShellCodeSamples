Param(
    [string]$GroupFamilyDN,
    [switch]$UseSqlAuthentication,
    [string]$SQLusername = "",
    [string]$SQLpassword = "",
    [switch]$FixPreviouslyControlledGroups)

function writeTitle(){
    Clear-Host
    status "###########################"
    status "# Group Family Import Fix #"
    status "###########################"
    status "`n"
}

function executeSQL($sqlText, $database = "master", $server = ".",$timeout=30,$username,$password)
{
    status "- Creating new Scheduled Task..."

    if ($UseSqlAuthentication){
        if ($SQLusername -eq "" -or $SQLpassword -eq ""){
            throw [System.Exception] "-UseSqlAuthentication switch was used. Please supply a value for both -SQLusername and -SQLpassword."
        }
        $connection = New-Object System.Data.SqlClient.SQLConnection("Data Source=$server;Initial Catalog=$database;User Id=$username; Password=$password;Connect Timeout=$timeout;");
    } else {
        $connection = New-Object System.Data.SqlClient.SQLConnection("Data Source=$server;Integrated Security=SSPI;Initial Catalog=$database;Connect Timeout=$timeout;");
    }

    
    $cmd = New-Object System.Data.SqlClient.SqlCommand($sqlText, $connection);

    $connection.Open();
    $cmd.ExecuteReader()

    status "- Scheduled task creation complete."
}

function stopError($errorText){
    Throw [System.Exception] $errorText
}

function status($statusText){
    Write-Host $statusText
}

function getExecutionServer(){
    $script:ARGuid = ""
    $script:SQLInstance = ""
    $script:SQLDatabase = ""

    $arServices = Get-QADObject -SearchRoot "Configuration/Server Configuration/Administration Services" -Type edsARService -IncludeAllProperties -Proxy

    switch ($arServices.getType().Name){
        "ArsDirectoryObject" {
            status ("- Using " + $arServices.edsaEdmServiceComputerName + " as Execution Server.")
            $guid_object = [System.Guid] $arServices.edsaARServiceGUID
            $guid_temp1 = (($guid_object.ToByteArray() | %{ '\' + $_.ToString('x2') }) -join '').Replace("\","")
            $script:ARGuid = ($guid_temp1.Substring(0,8) + "-" + $guid_temp1.Substring(8,4) + "-" + $guid_temp1.Substring(12,4) + "-" + $guid_temp1.Substring(16,4) + "-" + $guid_temp1.Substring(20))
            $script:SQLInstance = $arServices.edsaSQLAlias
            $script:SQLDatabase = $arServices.edsaDatabaseName
            break
        }

        "Object[]" {
            $arConnectivity = $true
            $arServices | %{
                try{
                    Connect-QADService -Service $_.edsaEdmServiceComputerName -Proxy | Out-Null
                } catch {
                    $arConnectivity = $false
                }

                if ($arConnectivity){
                    status ("- Using " + $_.edsaEdmServiceComputerName + " as Execution Server.")
                    $guid_object = [System.Guid] $_.edsaARServiceGUID
                    $guid_temp1 = (($guid_object.ToByteArray() | %{ '\' + $_.ToString('x2') }) -join '').Replace("\","")
                    $script:ARGuid = ($guid_temp1.Substring(0,8) + "-" + $guid_temp1.Substring(8,4) + "-" + $guid_temp1.Substring(12,4) + "-" + $guid_temp1.Substring(16,4) + "-" + $guid_temp1.Substring(20))
                    $script:SQLInstance = $_.edsaSQLAlias
                    $script:SQLDatabase = $_.edsaDatabaseName
                    break
                }

                $arConnectivity = $true
            }
        }
    }
}

function checkExistingObjects(){
    try {
        $script:GF = Get-QADObject -Identity $script:GroupFamilyDN -IncludeAllProperties -Proxy
    } catch {
        stopError "Specified Group Family does not exist.  Cannot continue."
    }

    [XML]$script:GFAccountNameHistory = $script:GF.accountNameHistory

    $script:guid = ($script:GF.Guid).toString()

    status "- Checking for existing Scheduled Task for this Group Family..."

    $script:ScheduledTaskDN = "CN=GroupFamily-$script:guid,CN=Group Family,CN=Scheduled Tasks,CN=Server Configuration,CN=Configuration"

    $ScheduledTaskExists = $true

    try {
        Get-QADObject -Identity $script:ScheduledTaskDN -Proxy | Out-Null
    } catch {
        $ScheduledTaskExists = $false
    }

    if ($ScheduledTaskExists){
        stopError "Scheduled Task for this Group Family already exists! Unable to continue."
    }

    status "- No existing Scheduled Task found; continuing."
}

function constructSQLQuery(){
    $script:sqlCommand =  "
        DECLARE @GUID VARCHAR(MAX)
        DECLARE @ARGUID VARCHAR(MAX)
    SET @GUID = '$script:guid'
    SET @ARGUID = '$script:ARGuid'
    INSERT [dbo].[ScheduledTasks] ([ParentObjectGUID], [name], [distinguishedName], [description], [objectClass], [edsaDataSource], [edsaIsPredefined], [edsaSystemObject], [showInAdvancedViewOnly], [edsaShowInRawViewOnly], [systemFlags], [edsaParameters], [edsaXMLSchedule], [edsaDisableSchedule], [edsaModule], [edsaTaskState], [edsaTaskType], [edsaLastActionMessage], [edsaLastRunTime], [edsaServerToExecute], [edsaForceTermination], [edsaForceExecution], [edsaExtensionType], [edsaExtensionNetClassID], [whenCreated], [whenChanged], [sign], [displayName]) VALUES (N'dfb0c60b-3cde-42cb-935b-aafc6d675bfb', N'GroupFamily-' + @GUID, N'CN=GroupFamily-' + @GUID + ',CN=Group Family,CN=Scheduled Tasks,CN=Server Configuration,CN=Configuration', N'Auto-generated task to run Group Family. Do not modify or delete this task; otherwise, Group Family may stop functioning. This is part of Group Family configuration, and should only be administered by managing Group Family properties.', N'edsScheduledTask', NULL, 0, 1, NULL, 1, NULL, NULL, N'<?xml version=""1.0""?>
    <Schedule><Daily><Every>1</Every><Start><Time>15:00:00.000</Time><Date>2016-12-08</Date></Start></Daily></Schedule>
    ', 0, @GUID, 4, 0, NULL, CAST(0x0000A6D401457F58 AS DateTime), @ARGUID, NULL, 0, NULL, NULL, CAST(0x0000A6D4013E0C9A AS DateTime), CAST(0x0000A6D401458741 AS DateTime), 0, NULL)"
}

function updateGroupFamily(){
    [string]$taskGuid = ((Get-QADObject -Identity $ScheduledTaskDN -Proxy).Guid).toString()

    $script:GFAccountNameHistory.GroupFamily.GuidTask = $taskGuid
    $script:GFAccountNameHistory.GroupFamily.ServerToExecute = $script:ARGuid

    status "- Updating Group Family to associate to new Scheduled Task..."

    Set-QADObject -Identity $script:GroupFamilyDN -ObjectAttributes @{'accountNameHistory' = $script:GFAccountNameHistory.OuterXml} | Out-Null

    status "- Updating Group Family complete."
}

function updatePreviouslyControlledGroups(){
    if ($script:FixPreviouslyControlledGroups){
        status "- '-FixPreviouslyControlledGroups' switch used; updating previously controlled groups..."
        [XML]$ControlledGroupAccountNameHistory = "<GroupFamily xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema""><IsControlledGroup>True</IsControlledGroup><IsCreatedByGroupFamily>True</IsCreatedByGroupFamily><ControlledBy>$script:guid</ControlledBy><LastUpdateTime></LastUpdateTime><LastPopulatedMembersCount></LastPopulatedMembersCount></GroupFamily>"

        $script:GF.edsvaGFControlledGroups | %{
            Set-QADObject -Identity $_ -ObjectAttributes @{'accountNameHistory'=$ControlledGroupAccountNameHistory.OuterXml} -Proxy | Out-Null
        }

        status "- Controlled groups update complete."
    }
}

writeTitle
getExecutionServer
checkExistingObjects
constructSQLQuery
executeSQL $sqlCommand $SQLDatabase $SQLInstance 30 $SQLusername $SQLpassword
updateGroupFamily
updatePreviouslyControlledGroups