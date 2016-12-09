#Populating an array with eight known values
$collection = "red", "orange", "yellow", "green", "blue", "indigo", "violet", "rainbow"

#Making seven empty arrays
$array0 = @()
$array1 = @()
$array2 = @()
$array3 = @()
$array4 = @()
$array5 = @()
$array6 = @()


#Iterating the populated array
for($i = 0; $i -lt $collection.Count; $i++) 
{
	#The modulus operator (%) will return N known results for $int%N
	switch ($i%7)
	{
		#These are the seven known results from performing the modulus operation in the switch.
		0{$array0 += $collection[$i]}
		1{$array1 += $collection[$i]}
		2{$array2 += $collection[$i]}
		3{$array3 += $collection[$i]}
		4{$array4 += $collection[$i]}
		5{$array5 += $collection[$i]}
		6{$array6 += $collection[$i]}
	}

#Outputting results.
#We expect that the eighth item in the populated collection will be populated to the first of the empty arrays
Write-Host "array0"
Write-Host $array0
write-host " "
Write-Host "array1"
Write-Host $array1
write-host " "
Write-Host "array2"
Write-Host $array2
write-host " "
Write-Host "array3"
Write-Host $array3
write-host " "
Write-Host "array4"
Write-Host $array4
write-host " "
Write-Host "array5"
Write-Host $array5
write-host " "
Write-Host "array6"
Write-Host $array6