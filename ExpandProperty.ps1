get-wmiobject -class win32_bios -computername (Get-ADComputer =filter * | Select -expandproperty name)
#-ExpandProperty is used to convert from an object into a collection of string objects. In this sample,
#it is used to convert from an ADComputer object typed to a String[] object type, which is the data type
#required by the -computername parameter