function Test-Port
{
    Param(
        [parameter(ParameterSetName='ComputerName', Position=0)]
        [string]
        $ComputerName,

        [parameter(ParameterSetName='IP', Position=0)]
        [System.Net.IPAddress]
        $IPAddress,

        [parameter(Mandatory=$true , Position=1)]
        [int]
        $Port
        )

    $RemoteServer = If ([string]::IsNullOrEmpty($ComputerName)) {$IPAddress} Else {$ComputerName};

    $test = New-Object System.Net.Sockets.TcpClient;
    Try
    {
        Write-Host "Connecting to "$RemoteServer":"$Port" (TCP)..";
        $test.Connect($RemoteServer, $Port);
        Write-Host "Connection successful";
    }
    Catch
    {
        Write-Host "Connection failed";
    }
    Finally
    {
        $test.Dispose();
    }
}