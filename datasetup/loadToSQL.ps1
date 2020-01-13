param(
[Parameter(Mandatory=$True, HelpMessage="SQL Server Instance ")]
[ValidateNotNull()]
$sqlserver,
[Parameter(Mandatory=$True, HelpMessage="SQL Server Database Name")]
[ValidateNotNull()]
$database,
[Parameter(Mandatory=$True, HelpMessage="SQL Server Username")]
[ValidateNotNull()]
$user,
[Parameter(Mandatory=$True, HelpMessage="SQL Server Password")]
[ValidateNotNull()]
$pass
)

Function loatToSQL {

Param(
    [parameter(Mandatory=$true)]
    [String]
    $sqlserver,
    [parameter(Mandatory=$true)]
    [String]
    $database,
    [parameter(Mandatory=$true)]
    [String]
    $table,
    [parameter(Mandatory=$true)]
    [String]
    $user,
    [parameter(Mandatory=$true)]
    [String]
    $pass,
    [parameter(Mandatory=$true)]
    [String]
    $csvPath
)

$csvdelimiter = "|" #"`t"
$firstRowColumnNames = $false
$elapsed = [System.Diagnostics.Stopwatch]::StartNew() 
$csvs = Get-ChildItem -Path $csvPath -Filter *.csv
foreach ($csv in $csvs) {

    $csvfile = $csv.FullName

################### No need to modify anything below ###################
Write-Host "Script started..."

[void][Reflection.Assembly]::LoadWithPartialName("System.Data")
[void][Reflection.Assembly]::LoadWithPartialName("System.Data.SqlClient")
# 50k worked fastest and kept memory usage to a minimum
$batchsize = 50000
# Build the sqlbulkcopy connection, and set the timeout to infinite
#$connectionstring = "Data Source=$sqlserver;Integrated Security=true;Initial Catalog=$database;"
$connectionstring = "Data Source=$sqlserver;Initial Catalog=$database;User ID=$user;Password=$pass;"
$bulkcopy = New-Object Data.SqlClient.SqlBulkCopy($connectionstring, [System.Data.SqlClient.SqlBulkCopyOptions]::TableLock)
$bulkcopy.DestinationTableName = $table
$bulkcopy.bulkcopyTimeout = 0
$bulkcopy.batchsize = $batchsize
# Create the datatable, and autogenerate the columns.
$datatable = New-Object System.Data.DataTable
# Open the text file from disk
$reader = New-Object System.IO.StreamReader($csvfile)
$columns = (Get-Content $csvfile -First 1).Split($csvdelimiter)
if ($firstRowColumnNames -eq $true) { $null = $reader.readLine() }
foreach ($column in $columns) { 
$null = $datatable.Columns.Add()
}
# Read in the data, line by line
while (($line = $reader.ReadLine()) -ne $null)  {
$null = $datatable.Rows.Add($line.Split($csvdelimiter))
$i++; if (($i % $batchsize) -eq 0) { 
$bulkcopy.WriteToServer($datatable) 
#Write-Host "$i rows have been inserted in $($elapsed.Elapsed.ToString())."
$datatable.Clear() 
} 
} 
# Add in all the remaining rows since the last clear
if($datatable.Rows.Count -gt 0) {
$bulkcopy.WriteToServer($datatable)
$datatable.Clear()
}
# Clean Up
$reader.Close(); $reader.Dispose()
$bulkcopy.Close(); $bulkcopy.Dispose()
$datatable.Dispose()
Write-Host "Script complete. $i rows have been inserted into $table table."
# Sometimes the Garbage Collector takes too long to clear the huge datatable.
[System.GC]::Collect()
}
Write-Host "Total Elapsed Time: $($elapsed.Elapsed.ToString())"
}

$kit = Split-Path $((Get-Variable MyInvocation).Value).MyCommand.Path
$configFile = Join-Path $kit "config.csv" 
#$configFile
$dirs = Import-Csv -Path $configFile -Delimiter "|" | ? pushTo -EQ "sql" | select table_name
foreach ($d in $dirs) {
    $table = $d.table_name
    $csvPath = "final\"+$table
    loatToSQL -sqlserver $sqlserver -database $database -table $table -user $user -pass $pass -csvPath $csvPath 
}
