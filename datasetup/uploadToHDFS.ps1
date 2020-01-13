param(
[Parameter(Mandatory=$True, HelpMessage="SQL BDC Cluster Namespace")]
[ValidateNotNull()]
$CLUSTER_NAMESPACE,
[Parameter(Mandatory=$True, HelpMessage="SQL Server Master instance IP")]
[ValidateNotNull()]
$SQL_MASTER_IP,
[Parameter(Mandatory=$True, HelpMessage="SQL Server user password")]
[ValidateNotNull()]
$KNOX_PASSWORD,
[Parameter(Mandatory=$True, HelpMessage="Source CSV files Location")]
[ValidateNotNull()]
$SOURCE_LOCATION,
[Parameter(Mandatory=$True, HelpMessage="Destination CSV files Location at HDFS")]
[ValidateNotNull()]
$DESTINATION_LOCATION
)

#write-host $SQL_PASSWORD
$ns = $CLUSTER_NAMESPACE
$ip = $SQL_MASTER_IP
$pwd = $KNOX_PASSWORD
$srcLoc = $SOURCE_LOCATION
$dest = $DESTINATION_LOCATION

$kit = Split-Path $((Get-Variable MyInvocation).Value).MyCommand.Path
$batLoc = Join-Path $kit "bats"
$dirs = Import-Csv -Path .\config.csv -Delimiter "|" | ? pushTo -EQ "hdfs" | select table_name
$i =1
foreach ($d in $dirs) {
    $curDir = $d.table_name
    #$curDir
    $csvLoc = join-path $kit $srcLoc
    $csvPath = Join-Path $csvLoc $curDir
    $csvs = Get-ChildItem -Path $csvPath -Filter *.csv
    foreach ($f in $csvs) {
        $filePath = $f.FullName
        $fName = $f.Name
        #$curDir
        $batFile = $batLoc + "\bat_"+$i+".bat"
        $url1 = "`"https://%KNOX_ENDPOINT%/gateway/default/webhdfs/v1/" + $dest+"/csv/"+$curDir+"`?op=MKDIRS`""
        $url2 = "`"https://%KNOX_ENDPOINT%/gateway/default/webhdfs/v1/" + $dest+"/csv/"+$curDir+"/"+$fName+"`?op=create&overwrite=true`" -H `"Content-Type: application/octet-stream`" -T `""+$filePath+"`""
        New-Item $batFile | Out-Null
        Add-Content $batFile '@echo off'
        Add-Content $batFile 'setlocal enableextensions'
        Add-Content $batFile " "
        Add-Content $batFile "set CLUSTER_NAMESPACE=$ns"
        Add-Content $batFile "set SQL_MASTER_IP=$ip"
        Add-Content $batFile "set SQL_MASTER_SA_PASSWORD=$pwd"
        Add-Content $batFile "if NOT DEFINED KNOX_PORT set KNOX_PORT=30443"
        Add-Content $batFile " "
        Add-Content $batFile "set KNOX_IP=%SQL_MASTER_IP%"
        Add-Content $batFile "set KNOX_PASSWORD=%SQL_MASTER_SA_PASSWORD%"
        Add-Content $batFile "set KNOX_ENDPOINT=%KNOX_IP%:%KNOX_PORT%"
        Add-Content $batFile " "
        Add-Content $batFile "echo Uploading csv data to HDFS..."
        Add-Content $batFile "echo Uploading csv data to HDFS..."
        Add-Content $batFile "%DEBUG% curl -L -k -u root:%KNOX_PASSWORD% -X PUT $url1"
        Add-Content $batFile "%DEBUG% curl -L -k -u root:%KNOX_PASSWORD% -X PUT $url2"

        $i++
    }
}

$batFiles = Get-ChildItem -Path $batLoc -Filter *.bat
foreach ($b in $batFiles) {
   $batPath = $b.FullName
   Start-Process "cmd.exe"  "/c $batPath"
}
Start-Sleep -Seconds 10
$delLoc = $batLoc + "\*.bat"
Remove-Item -Path $delLoc -Force -Confirm:$false

Function San-CSV { 
param(
    [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$false)]
    [System.Int32]
    $pt,

    [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$false)]
    [System.String]
    $path
)

$files = Get-ChildItem -Path $path -Filter "*.bat" -File

# Split the files up into processing groups. For Each group and excel process will be started. 
$numberOfGroups = $pt 
$maxGroupMemberSize = [math]::Ceiling($files.Count / $numberOfGroups)
Write-Host " No of Files per batch is $maxGroupMemberSize" -ForegroundColor Yellow
# Create as many file groups
$fileGroups = 0..($numberOfGroups - 1) | Foreach-object{
    $groupIndexStart = $maxGroupMemberSize * $_
    # Use the unary comma operator to be sure an array is returned and not unrolled
    ,$files[$groupIndexStart..($groupIndexStart + $maxGroupMemberSize - 1)]
}

# Create a job for each file group.
for($jobCount = 0; $jobCount -lt $fileGroups.Count; $jobCount++){

    Start-Job -Name "DataCleanup$jobCount" -ScriptBlock {
        param($files)
        ForEach ($f in $files){    
            $header = @()
            $fullName = $f.FullName
            $baseName = [io.path]::GetFileNameWithoutExtension($fullName)
            $fName = $f.Name
            $prnt = Split-Path $fullName -Parent -Resolve

            $out = $baseName+".csv"
            $fcsv = "final_"+$baseName+".csv"
            
            $inFile = Join-Path $prnt $fName
            $outFile = Join-Path $prnt $out
            $finalOut = Join-Path $prnt $fcsv
            #$inFile
            #$outFile
            #$finalOut
            $line = Get-Content -Path $fullName -TotalCount 1 
            $Occurrences = $line.Split("|").GetUpperBound(0);
            for ($i = 1; $i -le $Occurrences; $i++) {
                $headContent = 'H'+$i.ToString()
                $header += $headContent
            }    
            Import-Csv $inFile -delimiter "|" -Header $header | export-csv $outFile -Delimiter "|" -NoTypeInformation -UseQuotes Never 
            Get-Content $outFile | select -Skip 1 | Set-Content $finalOut
            
            Remove-Item $inFile
            Remove-Item $outFile
            #Write-host "Processed file $inFile"
        }

    } -ArgumentList (,($fileGroups[$jobCount])) | Out-Null
}

# Wait for the jobs to be completed and remove them from inventory since they won't have output we need
Get-Job -Name "DataCleanup*" | Wait-Job | Receive-Job
        
}
