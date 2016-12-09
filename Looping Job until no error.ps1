$blob = {
    param($param1, $param2)
    $result = $false;

    function test($param1,$param2){
        try {
            $param1 + " AND THEN " +  $param2 | Out-File -FilePath C:\test.txt
            return $true

        } catch {
            Start-Sleep -Seconds 120
            return $false
        }
    }    

    while (-not $result){
        $result = test $param1 $param2
    }
}

Start-Job -ScriptBlock $blob -ArgumentList "Test1","Test2"