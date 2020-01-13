param (
    $executeOption
)
$executeOption = $executeOption.ToLower()
$pass = Read-Host "Enter KNOX Password" -AsSecureString
$pwd = [System.Net.NetworkCredential]::new("", $pass).Password
$elapsed = [System.Diagnostics.Stopwatch]::StartNew() 
$configs = Import-Csv -Path .\finalConfig.csv -Delimiter "|" #| ? pushTo -EQ "hdfs" | select table_name
foreach ($c in $configs) {
    $dw = $c.noOfDW
    $fpt = $c.filePerTable
    $gt = $c.genThred
    $cb = $c.convBatch
    $sns = $c.sqlNS
    $sip = $c.sqlIP
    $dest = $c.hdfsDir
    $sqlInstance = $sip+",31433"
    $sqlUserName ="admin"

    if ($executeOption.ToLower() -eq "dg") {
        Write-Host "Starting TPC-H Data generation process" -ForegroundColor Cyan 
        .\sanDG.ps1 -NumberOfWarehouses $dw -noOfFilePerTable $fpt -parellelThred $gt 
        Write-Host "TPC-H Data generation process completed" -ForegroundColor Green
    } elseif ($executeOption -eq "dconly") {
        Write-Host "Starting TPC-H Data Conversion process" -ForegroundColor Cyan 
        .\sanDC.ps1 -parellelThred $cb 
        Write-Host "TPC-H Data Conversion process completed" -ForegroundColor Green
    }elseif ($executeOption -eq "dc") {
        Write-Host "Starting TPC-H Data generation process" -ForegroundColor Cyan 
        .\sanDG.ps1 -NumberOfWarehouses $dw -noOfFilePerTable $fpt -parellelThred $gt 
        Write-Host "TPC-H Data generation process completed" -ForegroundColor Green 
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data Conversion process" -ForegroundColor Cyan 
        .\sanDC.ps1 -parellelThred $cb 
        Write-Host "TPC-H Data Conversion process completed" -ForegroundColor Green
    } elseif ($executeOption -eq "alldl") {
        Write-Host "Starting TPC-H Data load process to HDFS" -ForegroundColor Cyan
        .\uploadToHDFS.ps1 -CLUSTER_NAMESPACE $sns -SQL_MASTER_IP $sip -SQL_PASSWORD $pwd -SOURCE_LOCATION "final" -DESTINATION_LOCATION $dest 
        Write-Host "TPC-H Data load process to HDFS completed" -ForegroundColor Green 
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data load process to SQL Server Instance" -ForegroundColor Cyan
        .\loadToSQL.ps1 -sqlserver $sqlInstance -database $dest -user $sqlUserName -pass $pwd
        Write-Host "TPC-H Data load process to SQL Server completed" -ForegroundColor Green
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data load process to Oracle database" -ForegroundColor Cyan
        .\loatToOracle.ps1
        Write-Host "TPC-H Data load process to Oracle database completed" -ForegroundColor Green
    } elseif ($executeOption -eq "dl2hdfsonly") {
        Write-Host "Starting TPC-H Data load process to HDFS" -ForegroundColor Cyan
        .\uploadToHDFS.ps1 -CLUSTER_NAMESPACE $sns -SQL_MASTER_IP $sip -SQL_PASSWORD $pwd -SOURCE_LOCATION "final" -DESTINATION_LOCATION $dest 
        Write-Host "TPC-H Data load process to HDFS completed" -ForegroundColor Green
    } elseif ($executeOption -eq "dl2sqlonly") {
        Write-Host "Starting TPC-H Data load process to SQL Server Instance" -ForegroundColor Cyan
        .\loadToSQL.ps1 -sqlserver $sqlInstance -database $dest -user $sqlUserName -pass $pwd
        Write-Host "TPC-H Data load process to SQL Server completed" -ForegroundColor Green
    } elseif ($executeOption -eq "dl2oracleonly") {
        Write-Host "Starting TPC-H Data load process to Oracle database" -ForegroundColor Cyan
        .\loatToOracle.ps1
        Write-Host "TPC-H Data load process to Oracle database completed" -ForegroundColor Green
    } elseif ($executeOption -eq "dl2hdfs") {
        Write-Host "Starting TPC-H Data generation process" -ForegroundColor Cyan 
        .\sanDG.ps1 -NumberOfWarehouses $dw -noOfFilePerTable $fpt -parellelThred $gt 
        Write-Host "TPC-H Data generation process completed" -ForegroundColor Green 
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data Conversion process" -ForegroundColor Cyan 
        .\sanDC.ps1 -parellelThred $cb 
        Write-Host "TPC-H Data Conversion process completed" -ForegroundColor Green 
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data load process to HDFS" -ForegroundColor Cyan
        .\uploadToHDFS.ps1 -CLUSTER_NAMESPACE $sns -SQL_MASTER_IP $sip -SQL_PASSWORD $pwd -SOURCE_LOCATION "final" -DESTINATION_LOCATION $dest 
        Write-Host "TPC-H Data load process to HDFS completed" -ForegroundColor Green
    } elseif ($executeOption -eq "dl2sql") {
        Write-Host "Starting TPC-H Data generation process" -ForegroundColor Cyan 
        .\sanDG.ps1 -NumberOfWarehouses $dw -noOfFilePerTable $fpt -parellelThred $gt 
        Write-Host "TPC-H Data generation process completed" -ForegroundColor Green 
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data Conversion process" -ForegroundColor Cyan 
        .\sanDC.ps1 -parellelThred $cb 
        Write-Host "TPC-H Data Conversion process completed" -ForegroundColor Green 
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data load process to HDFS" -ForegroundColor Cyan
        .\uploadToHDFS.ps1 -CLUSTER_NAMESPACE $sns -SQL_MASTER_IP $sip -SQL_PASSWORD $pwd -SOURCE_LOCATION "final" -DESTINATION_LOCATION $dest 
        Write-Host "TPC-H Data load process to HDFS completed" -ForegroundColor Green 
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data load process to SQL Server Instance" -ForegroundColor Cyan
        .\loadToSQL.ps1 -sqlserver $sqlInstance -database $dest -user $sqlUserName -pass $pwd
        Write-Host "TPC-H Data load process to SQL Server completed" -ForegroundColor Green
    } elseif ($executeOption -eq "all" -or $executeOption -eq "dl2oracle") {
        Write-Host "Starting TPC-H Data generation process" -ForegroundColor Cyan 
        .\sanDG.ps1 -NumberOfWarehouses $dw -noOfFilePerTable $fpt -parellelThred $gt 
        Write-Host "TPC-H Data generation process completed" -ForegroundColor Green 
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data Conversion process" -ForegroundColor Cyan 
        .\sanDC.ps1 -parellelThred $cb 
        Write-Host "TPC-H Data Conversion process completed" -ForegroundColor Green 
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data load process to HDFS" -ForegroundColor Cyan
        .\uploadToHDFS.ps1 -CLUSTER_NAMESPACE $sns -SQL_MASTER_IP $sip -SQL_PASSWORD $pwd -SOURCE_LOCATION "final" -DESTINATION_LOCATION $dest 
        Write-Host "TPC-H Data load process to HDFS completed" -ForegroundColor Green 
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data load process to SQL Server Instance" -ForegroundColor Cyan
        .\loadToSQL.ps1 -sqlserver $sqlInstance -database $dest -user $sqlUserName -pass $pwd
        Write-Host "TPC-H Data load process to SQL Server completed" -ForegroundColor Green
        Start-Sleep -Seconds 2
        Write-Host "Starting TPC-H Data load process to Oracle database" -ForegroundColor Cyan
        .\loatToOracle.ps1
        Write-Host "TPC-H Data load process to Oracle database completed" -ForegroundColor Green
    }
}
Write-Host "Total Elapsed Time: $($elapsed.Elapsed.ToString())"