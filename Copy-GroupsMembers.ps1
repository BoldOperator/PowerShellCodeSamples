Param([string]$sourceIdentity = "",[string]$destinationIdentity = "")

function checkParameters
{
    if ($sourceIdentity -eq "")
    {
        throw "The source identity must be specified with the -sourceIdentity switch."
        exit
    }

    if ($destinationIdentity -eq "")
    {
        throw "The destination identity must be specified with the -destinationIdentity switch."
        exit
    }
}

function copyGroups
{
    get-qadmemberof -Identity $sourceIdentity | ForEach-Object {add-qadmemberof -identity $destinationIdentity -Group $_.Name}
}

checkParameters

copyGroups