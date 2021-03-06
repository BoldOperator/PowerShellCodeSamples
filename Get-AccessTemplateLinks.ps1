# The following script is provided as is and is NOT supported but Dell Software.
# Use this script at your own discretion.
#
# This script must be run on a computer that has the ActiveRoles Server Management Shell installed.
# Empty values would indicate objects such as "Self" or "Authenticated Users" where they do not have an AD object associated with their SID.

# Editable Options #
$global:outputFile = "c:\atLinks.csv" # Path to CSV output file.
$global:templateName = "" # If left empty, all access templates will be checked.
$global:searchRoot = "" # If left empty, all users and groups will be checked. Syntax: "test.domain.com/OU/subOU"
# MODIFY BELOW AT YOUR OWN RISK #

if ( (Get-PSSnapin -Name Quest.ActiveRoles.ADManagement -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin Quest.ActiveRoles.ADManagement
}

Connect-QADService -Proxy | Out-Null # Connect to ActiveRoles Administration Service

Set-QADPSSnapinSettings -DefaultSizeLimit 0 | Out-Null # Allow unlimited objects to be returned.

function getAccounts(){
    Write-Host "Performing scan, please wait..."
    if ($global:searchRoot -eq ""){
        $global:tempUsers = Get-QADUser -IncludedProperties DN,objectSid
        $global:tempGroups = Get-QADGroup -IncludedProperties DN,objectSid
    }
    else{
        $global:tempUsers = Get-QADUser -SearchRoot $global:searchRoot -IncludedProperties DN,objectSid
        $global:tempGroups = Get-QADGroup -SearchRoot $global:searchRoot -IncludedProperties DN,objectSid
    }
}


function getSecDN($sid){
    $tempUser = $global:tempUsers | Where-Object{$_.objectSid -eq $sid}
    $tempGroup = $global:tempGroups | Where-Object{$_.objectSid -eq $sid}
    
    $tempReturn = ""
    
    if ($tempUser.objectSid.Length -gt 0){
        $tempReturn = $tempUser.DN
    }
    
    if ($tempGroup.objectSid.Length -gt 0){
        $tempReturn = $tempGroup.DN
    }
    
    return $tempReturn
}

function getLinks(){
    getAccounts

    $atLinks = @()
    
    if ($global:templateName -eq ""){
        $links = Get-QARSAccessTemplateLink -IncludedProperties edsvaAccessTemplateDN,edsvaSecObjectDN,edsaTrusteeSID | Sort-Object edsvaAccessTemplateDN
    }
    else{
        $links = Get-QARSAccessTemplateLink -Name $global:templateName -IncludedProperties edsvaAccessTemplateDN,edsvaSecObjectDN,edsaTrusteeSID | Sort-Object edsvaAccessTemplateDN
    }
    
    $links | ForEach-Object {
        [string]$property1 = ""
        [string]$property2 = ""
        [string]$property3 = ""
        
        if ($_.edsvaAccessTemplateDN){
            $property1 = $_.edsvaAccessTemplateDN.ToString()
        }
        else{
            $property1 = ""
        }
        
        if ($_.edsvaSecObjectDN){
            $property2 = $_.edsvaSecObjectDN.ToString()
        }
        else{
            $property2 = ""
        }
        
        
        if (getSecDN($_.edsaTrusteeSID)){
            $property3 = (getSecDN($_.edsaTrusteeSID)).ToString()
        }
        else{
            $property3 = ""
        }
        
        $atLinks += New-Object PSObject -Property @{AccessTemplateDN=$property1;AppliedOn=$property2;AppliedTo=$property3}
    }
    
    $atLinks | Select-Object AccessTemplateDN,AppliedOn,AppliedTo | Export-Csv -Path $global:outputFile -NoTypeInformation
    Write-Host "Completed! Please check output file:   $global:outputfile"
}

getLinks