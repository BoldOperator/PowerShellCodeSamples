param([string]$OutFile,[string]$Connection)

function getMappings($userObject){
	$mappedObjects = Get-QCMappedObjects -QCObject $userObject
    
    $mappings = @()
    
	ForEach ($mapping in $mappedObjects){
        $properties = @{
            "ConnectionName" = $mapping.ConnectionName
            "Object" = $mapping.ObjectEntry.Path
        }
        
        $tempObject = New-Object PSObject -Property $properties
        $mappings += $tempObject
	}
    
    return $mappings
}

function getObjects(){    
    Out-File -FilePath $OutFile -InputObject "Mapped Objects"
    Out-File -FilePath $OutFile -InputObject "------------------------------------" -Append
    Out-File -FilePath $OutFile -InputObject "" -Append
	$tempConnectionObjects = Get-QCObject -Connection $Connection User
	
	ForEach ($user in $tempConnectionObjects){
        $objectMappings = getMappings $user
        
        $properties = @{
            "Object" = $user.ObjectEntry.Path
            "Mappings" = $objectMappings
        }
        
        [string]$tempString = ""
        
        $tempObject = New-Object PSObject -Property $properties
        Out-File -FilePath $OutFile -InputObject "------------" -Append
        Out-File -FilePath $OutFile -InputObject "------------" -Append
        $tempString = $tempObject.Object
        Out-File -FilePath $OutFile -InputObject "Object: $tempString" -Append
        Out-File -FilePath $OutFile -InputObject "------------" -Append
        Out-File -FilePath $OutFile -InputObject "--Mappings--" -Append
        Out-File -FilePath $OutFile -InputObject "------------" -Append
        
        ForEach ($mapping in $tempObject.Mappings){
            $tempString = $mapping.ConnectionName
            Out-File -FilePath $OutFile -InputObject "Mapped Connection: $tempString" -Append
            $tempString = $mapping.Object
            Out-File -FilePath $OutFile -InputObject "Mapped Object: $tempString" -Append
        }
        Out-File -FilePath $OutFile -InputObject "" -Append
        Out-File -FilePath $OutFile -InputObject "" -Append
        Out-File -FilePath $OutFile -InputObject "" -Append
	}
}

getObjects