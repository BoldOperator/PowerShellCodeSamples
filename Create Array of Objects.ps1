function Test-Object {
    $array = @()
    
    $object1 = New-Object PSObject -Property @{
        "First Name" = "Nick"
        "Last Name" = "Dollimount"
        "Date Of Birth" = "04/22/1985"
    }
    
    $object2 = New-Object PSObject -Property @{
        "First Name" = "Michael"
        "Last Name" = "Horne"
        "Date Of Birth" = "03/06/1984"
    }
    
    $array += $object1
    $array += $object2
    
    return $array
}

Test-Object