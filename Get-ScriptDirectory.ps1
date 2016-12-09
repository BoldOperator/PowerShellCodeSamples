function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

Write-Host (Get-ScriptDirectory)

Join-Path -Path (Get-ScriptDirectory) -ChildPath "install.bat"