###############################################################################
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, #
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED       #
# WARRANTIES OF MERCHANTBILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE        #
#                                                                             #
# IF YOU WANT THIS FUNCTIONALITY TO BE CONDITIONALLY SUPPORTED,               #
# PLEASE CONTACT DELL PROFESSIONAL SERVICES OR YOUR ACCOUNT MANAGER.          #
###############################################################################
# Version 1.1 #
###############

Param(
    [Parameter(Mandatory=$false)][switch]$Timed,
    [Parameter(Mandatory=$false)][switch]$Ship,
    [Parameter(Mandatory=$false)][int]$Seconds,
    [Parameter(Mandatory=$false)][string]$Destination,
    [Parameter(Mandatory=$false)][int]$MaxMegabytes,
    [Parameter(Mandatory=$false)][switch]$Help
)

[Boolean]$syntaxShown = $false
[System.Collections.ArrayList]$ARSInfo = @()

if (Test-Path -Path 'HKLM:\SOFTWARE\Dell\Active Roles\7.0'){
    $regPath = 'HKLM:\SOFTWARE\Dell\Active Roles'
    $ARSInfo.Add('7.0') *> $null
}elseif (Test-Path -Path 'HKLM:\SOFTWARE\Aelita\Enterprise Directory Manager'){
    $regPath = 'HKLM:\SOFTWARE\Aelita\Enterprise Directory Manager'
    $ARSInfo.Add('6.x') *> $null
}else{
    Write-Host 'No Active Roles Server version found!'
    Write-Host 'Please run this script on the Active Roles Server Administration Service host.'
    exit
}

Add-Type -Assembly System.IO.Compression.FileSystem ## Load FileSystem assembly for use with zipping.

function isNumeric($inputToCheck) {
    return $inputToCheck -is [byte]  -or $inputToCheck -is [int16]  -or $inputToCheck -is [int32]  -or $inputToCheck -is [int64] -or $inputToCheck -is [sbyte] -or $inputToCheck -is [uint16] -or $inputToCheck -is [uint32] -or $inputToCheck -is [uint64] -or $inputToCheck -is [float] -or $inputToCheck -is [double] -or $inputToCheck -is [decimal]
}

function checkParams(){
    Clear-Host
    showHeader
    if (-not $Ship -and -not $Timed -and -not $Help){
        showSyntax
    }

    if ($Help){
        showSyntax
    }

    if ($Timed -and $Ship){
        Throw('Both the -Timed and -Ship switches cannot be used at the same time. For more information, please use the -Help switch.')
    }

    if ($Timed){
        while (-not $Seconds -or -not (isNumeric($Seconds)) -or $Seconds -lt 1)
        {
            $Seconds = Read-Host 'Enter logging time (Seconds [Number])'
            try{
                $Seconds = [convert]::ToInt32($Seconds,10)
            }
            catch{}
        }

        getARSInfo
        timedLogging
    }

    if ($Ship){
        while (-not $Destination){
            $Destination = Read-Host 'Enter a valid path'
        }
        while (-not (Test-Path -Path $Destination)){
            $Destination = Read-Host 'Enter a valid path'
        }

        while ($MaxMegabytes -lt 1 -or -not (isNumeric($MaxMegabytes))){
            $MaxMegabytes = Read-Host 'Enter max log size (MB) [Leave blank for default 500MB]'
            try{                
                $MaxMegabytes = [convert]::ToInt32($MaxMegabytes,10)
            }
            catch{}
            if ($MaxMegabytes -eq ''){
                $MaxMegabytes = 500
            }
        }

        getARSInfo
        shipLog
    }
}

function showHeader(){
    Write-Host '======================================='
    switch ($ARSInfo[0]){
        '6.x' {
            Write-Host '        Active Roles 6.x found!'
        }

        '7.0' {
            Write-Host '        Active Roles 7.0 found!'
        }
    }
    Write-Host '======================================='
    Write-Host '*     Press CTRL+C to exit script.    *'
    Write-Host '======================================='
    Write-Host ''
}

function getARSInfo(){
    switch ($ARSInfo[0]){
        '6.x' {
            $ARSInfo.Add((Get-ItemProperty $regPath -Name 'Debug').Debug) *> $null
            $ARSInfo.Add((Get-ItemProperty $regPath -Name 'InstallPath').InstallPath) *> $null
        }

        '7.0' {
            $ARSInfo.Add((Get-ItemProperty (Join-Path -Path $regPath -ChildPath 'Configuration/Service') -Name 'Debug').Debug) *> $null
            $ARSInfo.Add((Get-ItemProperty (Join-Path -Path $regPath -ChildPath '7.0/Service') -Name 'InstallPath').InstallPath) *> $null
        }
    }
    
}

function isLoggingEnabled(){
    switch ($ARSInfo[0]){
        '6.x' {
            if ((Get-ItemProperty $regPath -Name 'Debug').Debug -eq 1){
                return $true
            }else{
                return $false
            }
        }

        '7.0' {
            if ((Get-ItemProperty (Join-Path -Path $regPath -ChildPath 'Configuration/Service') -Name 'Debug').Debug -eq 1){
                return $true
            }else{
                return $false
            }
        }
    }
}

function showSyntax(){
    $Global:syntaxShown = $true
    Write-Host ''
    Write-Host 'SYNTAX'
    Write-Host '    ARS-Logging.ps1 [-Ship] [-Destination] <String[]> [-MaxMegabytes] <Int[]> [-Timed] [-Seconds] <Int[]> [-Help]'
    Write-Host ''
    Write-Host 'EXAMPLES'
    Write-Host ''
    Write-Host '    ARS-Logging.ps1 -Ship -Destination ''D:\ARSLogsBackup'' -MaxMegabytes 500'
    Write-Host ''
    Write-Host '    ARS-Logging.ps1 -Timed -Seconds 600'
    Write-Host ''
    Write-Host 'NOTE'
    Write-Host 'If the -Ship switch is used and the -MaxMegabytes parameter is not defined, a value of 500 is used by default.'
    Write-Host ''
    Exit
}

function timedLogging(){
    if ($ARSInfo[1] -eq 1){ ## Checking if debug logging is already enabled.
        Clear-Host
        showHeader
        Write-Host 'Debug logging is currently enabled.'
        Write-Host 'Disabling debug logging...'
        disableLogging
        Write-Host 'DEBUG LOGGING DISALBED'
        Write-Host ''
        Start-Sleep -Seconds 5
    }

    $log = Join-Path -Path $ARSInfo[2] -ChildPath 'ds.log'
    $logBackup = $log + '.bak'

    While((Test-Path $logBackup)){ ## Looping through existing ds.log backup files to avoid overwriting existing .bak file.
        $logBackup = $logBackup + '.bak'
    }

    Clear-Host

    showHeader

    if (Test-Path -Path $log){
        Write-Host 'Renaming current ds.log to:'
        Write-Host $logBackup
        Write-Host ''
        Rename-Item $log $logBackup ## Renaming ds.log appropriately to start with a clean log file.
    }

    Write-Host 'Enabling debug logging...'
    enableLogging
    Write-Host 'DEBUG LOGGING ENABLED'
    Write-Host 'Enabled for' $Seconds 'seconds...'
    Start-Sleep -Seconds $Seconds
    Write-Host 'Disabling debug logging...'
    disableLogging
    Write-Host 'DEBUG LOGGING DISABLED'
    Write-Host ''

    Write-Host 'Logging completed after' $Seconds 'seconds'
    Write-Host ''
    Write-Host 'Log: ' $log
}

function shipLog(){
    $i = 1
    While ($i -gt 0) {
        if (-not (isLoggingEnabled)){ ## Checking if debug logging is enabled.
            Clear-Host
            showHeader
            Write-Host 'Debug logging is currently disabled.'
            $enableLogging = Read-Host 'Do you want to enable logging now? [Y/y] (press any other key to exit script)'
            if ($enableLogging -eq "Y" -or $enableLogging -eq "y"){
                Clear-Host
                showHeader
                Write-Host 'Enabling logging...'
                enableLogging
                Write-Host 'LOGGING ENABLED'
                Start-Sleep -Seconds 2
            }else{
                Exit
            }
        }

        $log = Join-Path -Path $ARSInfo[2] -ChildPath 'ds.log'  ## Full log path and filename.
        While (-not (Test-Path $log)){  ## Testing if ds.log file exists.
            Clear-Host
            showHeader
            Write-Host 'ds.log file does not exist...'
            Write-Host 'Please enable debug logging.'
            Write-Host 'Sleeping for 10 seconds...'
            Start-Sleep -Seconds 10
        }

        $logSize = (Get-Item $log).Length ## Getting ds.log file size.

        if (($logSize/1000000) -gt $MaxMegabytes){
            $time = Get-Date -Format 'MM-dd-yyyy-HH_mm_ss'
            $tempName = 'ds_' + $env:computername + '_' + $time
            $newLog = $tempName + '.log'
            $tempDirectory = Join-Path -Path $ARSInfo[2] -ChildPath ($tempName)
            $tempZip = $tempName + '.zip'

            Clear-Host
            showHeader
            Write-Host 'ds.log file has reached the maximum size limit of' $MaxMegabytes 'MB and will be shipped.'
            Write-Host 'Disabling debug logging to release ds.log file...'

            disableLogging
            Start-Sleep -Seconds 5 ## Allowing 5 seconds for the service to release the log file before continuing.

            Write-Host 'DEBUG LOGGING DISABLED'
            Write-Host ''       
        
            Rename-Item $log $newLog
            enableLogging

            Write-Host 'Renamed ds.log to' $newLog '...'
            Write-Host ''
            Write-Host 'DEBUG LOGGING ENABLED'
            Write-Host ''
            Write-Host 'Zipping' $newLog 'to' $Destination '...'

            New-Item -Path $tempDirectory -ItemType directory *> $null ## Creating temp directory since using 'CreateFromDirectory' zip class.
            Move-Item -Path (Join-Path -Path $ARSInfo[2] -ChildPath $newLog) -Destination $tempDirectory ## Move log file to temp directory.
            zipDirectory $tempDirectory (Join-Path -Path $Destination -ChildPath $tempZip) ## Zipping log file.
            Remove-Item -Path $tempDirectory -Recurse -Force ## Clean up temp files.     

            Write-Host 'COMPLETED'
        
            Write-Host ''
            Write-Host 'Will continue checking in 30 seconds...'
            Start-Sleep -Seconds 30
        }else{
            Clear-Host
            showHeader
            Write-Host 'ds.log file is currently under the max size specified of' $MaxMegabytes 'MB.'
            Write-Host 'Monitoring...'        
        }
        Start-Sleep -Seconds 2
    }
}

function enableLogging(){
    switch ($ARSInfo[0]){
        '6.x' {
            Set-ItemProperty -Path $regPath -Name 'Debug' -Value 1
        }

        '7.0' {
            Set-ItemProperty -Path (Join-Path -Path $regPath -ChildPath 'Configuration/Service') -Name 'Debug' -Value 1
        }
    }
}

function disableLogging(){
    switch ($ARSInfo[0]){
        '6.x' {
            Set-ItemProperty -Path $regPath -Name 'Debug' -Value 0
        }

        '7.0' {
            Set-ItemProperty -Path (Join-Path -Path $regPath -ChildPath 'Configuration/Service') -Name 'Debug' -Value 0
        }
    }
}

function zipDirectory( $directory, $zip )
{
   $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
   [System.IO.Compression.ZipFile]::CreateFromDirectory($directory, $zip, $compressionLevel, $false)
}


try{checkParams}
finally{
    if ((isLoggingEnabled) -and $Global:syntaxShown -eq $false){
        Clear-Host
        showHeader
        Write-Host 'Logging is still enabled!'
        Write-Host 'Disabling logging...'
        disableLogging
        Write-Host 'LOGGING DISABLED'
    }
    Write-Host 'EXITING'
    Start-Sleep -Seconds 3
}