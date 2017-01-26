[string] $Server= "SQL\instance1"
[string] $Database = "ActiveRoles70_Test_History" # Management history database.
[string] $attributeName = "description"
[string] $operationID = "1-18142"
[string] $SQLQuery= $("select data from [" + $Database + "].[dbo].[WfSharedOperations] inner join [" + $Database + "].[dbo].[WfOperationValues] on [" + $Database + "].[dbo].[WfSharedOperations].guid = [" + $Database + "].[dbo].[WfOperationValues].operation where [" + $Database + "].[dbo].[WfOperationValues].value_short = '" + $operationID + "'")

function GenericSqlQuery ($Server, $Database, $SQLQuery) {
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "server='$Server';database='$Database';trusted_connection=true;"
    $Connection.Open()
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $SQLQuery
    $Reader = $Command.ExecuteReader()
    while ($Reader.Read()) {
         $Reader.GetValue($1)
    }
    $Connection.Close()
}

[xml] $xmlResults = GenericSqlQuery $Server $Database $SQLQuery
$oldValues = $xmlResults.Operation.PreviousAttributes.PreviousAttribute
$oldValue = ($oldValues | Where-Object{$_.Name -eq $attributeName}).Values.Value