$fullpath = "C:\Documents and Settings\ndollimount\My Documents\Shared"

$existingUsers = @(Import-Csv (Join-Path $fullpath "existingusers.csv"))
$rimCorrected = @(Import-Csv (Join-Path $fullpath "rimcorrected.csv"))


$existingUsersLowerCase = @()
$rimCorrectedLowerCase = @()

foreach ($item in $existingUsers) {
    [string]$tempString = $item.Email
    $tempString = $tempString.ToLower()
    $existingUsersLowerCase += $tempString
    }
    
foreach ($item in $rimCorrected) {
    [string]$tempString = $item.Email
    $tempString = $tempString.ToLower()
    $rimCorrectedLowerCase += $tempString
    }

$newlist = @()

foreach ($item in $rimCorrectedLowerCase) {
    [string]$tempItem = $item
    $action = $true
    foreach ($item in $existingUsersLowerCase) {
        if ($item -eq $tempItem) {
            $action = $false
        }
    }
    
    if ($action -eq $true) {
        if ($tempItem -ne "#n/a") {
            $newlist += $tempItem
        }
    }
}

$newlist > (Join-Path $fullpath "newusers.csv")