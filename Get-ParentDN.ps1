function Get-ParentDN($DN, $CN){
    $result = ($DN -replace "CN=$CN,","")
    return $result
}
Get-ParentDN $full $sub