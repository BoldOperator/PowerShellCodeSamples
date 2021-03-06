#Begin Script
 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Migrate-GroupsManagedBy.ps1
#
# This script will get all groups managed by the sourceIdentity user and change the managed by account to the newIdentity user.
# This is useful when a user is changing roles or is being replaced.
# For the 'sourceIdentity' and 'newIdentity' parameters, provide the username of the user.
#
# Syntax:
# Migrate-GroupsManagedBy.ps1 -sourceIdentity test.user1 -newIdentity test.user2
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
 
Param([string]$sourceIdentity = "",[string]$newIdentity = "")
 
function checkParameters
{
    if ($sourceIdentity -eq "")
    {
        throw "The source identity must be specified with the -sourceIdentity switch."
        exit
    }
 
    if ($newIdentity -eq "")
    {
        throw "The new identity must be specified with the -newIdentity switch."
        exit
    }
}
 
function migrateManagedBy
{
    Get-QADGroup -ManagedBy $sourceIdentity | ForEach-Object {Set-QADGroup -Identity $_.Name -ManagedBy $newIdentity}
}
 
checkParameters
migrateManagedBy
 
 
#End Script