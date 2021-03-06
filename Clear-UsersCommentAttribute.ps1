function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$workingDirectory = Get-ScriptDirectory

$inputFilePath = Join-Path $workingDirectory "users.csv"
Import-Csv($inputFilePath) | ForEach-Object {
    Set-QADUser -Identity $_.username -ObjectAttributes @{'comment'=$null}
    #Get-QADUser -identity $_.username -includeAllProperties | Format-List comment
}