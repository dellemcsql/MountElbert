param(
[Parameter(Mandatory=$True, HelpMessage="SQL Server Database Name")]
[ValidateNotNull()]
$oraService,
[Parameter(Mandatory=$True, HelpMessage="SQL Server Database Name")]
[ValidateNotNull()]
$oraSchema,
[Parameter(Mandatory=$True, HelpMessage="SQL Server Username")]
[ValidateNotNull()]
$oraUser,
[Parameter(Mandatory=$True, HelpMessage="SQL Server Password")]
[ValidateNotNull()]
$oraPass
)
$table_Suffix = "" #"2"

############################################################################################################
$regionStruct=@"
`(R_REGIONKEY, R_NAME, R_COMMENT`)
"@
$nationStruct =@'
(N_NATIONKEY, N_NAME, N_REGIONKEY, N_COMMENT)
'@
$customerStruct =@'
(C_CUSTKEY, C_NAME, C_ADDRESS, C_NATIONKEY, C_PHONE, C_ACCTBAL, C_MKTSEGMENT, C_COMMENT)
'@
$supplierStruct =@'
(S_SUPPKEY, S_NAME, S_ADDRESS, S_NATIONKEY, S_PHONE, S_ACCTBAL, S_COMMENT)
'@
##############################################################################################################

$kit = Split-Path $((Get-Variable MyInvocation).Value).MyCommand.Path

$dirs = Import-Csv -Path .\config.csv -Delimiter "|" | ? pushTo -EQ "oracle" | select table_name
foreach ($d in $dirs) {
    $tblNmae = $d.table_name
    $destTable = $tblNmae+$table_Suffix

$oraLoc = Join-Path $kit "ora"
$csvLoc = Join-Path $kit "final"

$batFile = $oraLoc + "\" + $tblNmae + ".bat"
$cfName = $tblNmae +".ctl" #"region.ctl"
$ctrlFile = $oraLoc + "\" + $cfName
$logFile = $oraLoc + "\" + $tblNmae + ".log"
$csvFiles = $csvLoc + "\" + $tblNmae + "\*.csv"
New-Item $ctrlFile | Out-Null
Add-Content $ctrlFile 'load data'
Add-Content $ctrlFile "infile '$csvFiles'"
Add-Content $ctrlFile "into table $oraSchema.$destTable"
Add-Content $ctrlFile "fields terminated by '|'"
if ($tblNmae -like "region") {
    Add-Content $ctrlFile "$regionStruct"
} elseif ($tblNmae -like "nation") {
    Add-Content $ctrlFile "$nationStruct"
} elseif ($tblNmae -like "customer") {
    Add-Content $ctrlFile "$customerStruct"
} elseif ($tblNmae -like "supplier") {
    Add-Content $ctrlFile "$supplierStruct"
} 

New-Item $batFile | Out-Null
Add-Content $batFile '@echo off' 
Add-Content $batFile "sqlldr $oraUser)/$oraPass@$oraService control='$ctrlFile' log='$logFile'"
}

$batFiles = Get-ChildItem -Path $oraLoc -Filter *.bat
foreach ($b in $batFiles) {
   $batPath = $b.FullName
   Start-Process "cmd.exe"  "/c $batPath"
}
Start-Sleep -Seconds 10
$delLoc = $oraLoc + "\*.bat"
Remove-Item -Path $delLoc -Force -Confirm:$false | Out-Null
$delLoc = $oraLoc + "\*.ctl"
Remove-Item -Path $delLoc -Force -Confirm:$false | Out-Null
