param(
[string]$connection1,
[string]$connection2,
[string]$connection1ObjectType,
[string]$connection2ObjectType
)

function checkParams(){
    if ((-not $connection1) -or (-not $connection2)){
        throw "Please provide a value for both connection1 AND connection2."
    }
    if ((-not $connection1ObjectType) -or (-not $connection2ObjectType)){
        throw "Pleacse provide a value for both connection1ObjectType AND conenction2ObjectType."
    }
}

function getMappedObject($userObject){
	$mappedObject = Get-QCMappedObjects -QCObject $userObject | where-object{$_.ConnectionName -eq $connection2 -and $_.ObjectType -eq $connection2ObjectType}
	return $mappedObject
}

function main(){
    Write-Host "Unmapping objects..."
    $count = 0
    $conn = Get-QCObject -Connection $connection1 $connection1ObjectType

    $conn | ForEach-Object{
        $mapped = getMappedObject $_
        if ($mapped){
            $count += 1
            Start-QCObjectUnmap -QCObject1 $_ -QCObject2 $mapped | Out-Null
        }
    }

    Write-Host "Unmapping complete."
    Write-Host "$count objects unmapped."
}

checkParams
main