param(
    [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$false)]
    [System.Int32]
    $NumberOfWarehouses,

    [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$false)]
    [System.Int32]
    $noOfFilePerTable,

    [Parameter(Mandatory=$True, Position=2, ValueFromPipeline=$false)]
    [System.Int32]
    $parellelThred
)
<#
$NumberOfWarehouses = 1000
$noOfFilePerTable = 6000
$parellelThred = 150
#>

Function Set-PSPriority  { 
<#   
  .SYNOPSIS    
   Set the process priority of the current Powershell session 
  .PARAMETER priority 
   The priority as an integer value from -2 to 3.  -2 is the lowest, 0 is the default (normal) and 3 is the highest (which may require Administrator privilege) 
  .PARAMETER processID 
   The process ID that will be change.  Omit to set the current powershell session. 
  .PARAMETER silent 
   Suppress the message at the end 
  .EXAMPLE   
   Set-PSPriority 2  
#>  
 
param ( 
[ValidateRange(-2,3)]  
[Parameter(Mandatory=$true)] 
[int]$priority, 
[int]$processID = $pid, 
[switch]$silent 
) 
$priorityhash = @{-2="Idle";-1="BelowNormal";0="Normal";1="AboveNormal";2="High";3="RealTime"} 
(Get-Process -Id $processID).priorityclass = $priorityhash[$priority] 
if (!$silent) { 
  "Process ID [$processID] is now set to " + (Get-Process -Id $pid).priorityclass 
} 
}

Function Change-Extn {
$files = Get-ChildItem  .\*.tbl*
foreach ($f in $files){
    $fullname = $f.FullName
    $fPath = Split-Path -Path $fullname
    $fname = $f.Name
    [Int32]$index = ($f.Name).Split(".",3)[2]
    $nindex = "F{0:d6}" -f $index # "{0:d4}$($index)" -f 0
    $tabname = ($f.Name).Split(".",2)[0]
    $extn = ($f.Name).Split(".",3)[1]
    $newname = $nindex+"_"+$tabname+"."+$extn 
    $newfullname = Join-Path $fPath $newname
    $finalMove = Join-Path $fPath "final"
    $finalFileName = Join-Path $finalMove $newname
    rename-item $fullname $newfullname 
    if (Test-Path -Path $finalFileName) {
        Remove-Item $finalFileName
    }
    Move-Item -Path $newfullname $finalFileName
    } 
}

$toolPath = Split-Path $((Get-Variable MyInvocation).Value).MyCommand.Path

$delFiles = Join-Path $toolPath "final"
$delFiles = $delFiles + "\"
Remove-Item -Path $delFiles -Recurse -Force -Exclude *.kit

$k = 0
[int]$noOfRow = 0
Get-Job | Remove-Job
#$StartTime = Get-Date
For ($i = 1; $i -le ($noOfFilePerTable/$parellelThred); $i++) {

    For ($j = 1; $j -le ($parellelThred); $j++) {
        $k = $k+1;
        $jName="DG_"+$i+"_"+$k+"_Job_"+$NumberOfWarehouses+"_"+$noOfFilePerTable
        Start-Job -Name $jName -ScriptBlock { 
            Param ($Path, $Scale, $noOfFilePerTable, $Child)
            CD $Path
            Invoke-Expression ".\dbgen.exe -f -s $Scale -C $noOfFilePerTable -S $Child" 
        } -ArgumentList $toolPath, $NumberOfWarehouses,$noOfFilePerTable, $k
    }

    $process = Get-Process | Where name -In ('dbgen','pwsh','conhost') 
    foreach ($p in $process) {
        Set-PSPriority 3 $p.id -silent 
    }

    $noOfRow = 0
    while(Get-Job -State Running){
        if(($noOfRow % 60) -eq 0){
            Write-Host ""
            Write-Host -NoNewline "Generating Data for batch $i=> "            
        }
        Write-Host -NoNewline ([char]9612) -ForegroundColor Cyan
        Start-Sleep -s 10
        $noOfRow = $noOfRow +1
    }
    Write-Host " "
    Start-Sleep -Seconds 1
    Change-Extn
    Start-Sleep -Seconds 1
}
#$EndTime = Get-Date
#Write-Host " "
#Write-Host "Data generation start time : $StartTime" -ForegroundColor Yellow
#Write-Host "Data generation end time   : $EndTime" -ForegroundColor Yellow
#$diff = ($EndTime-$StartTime).Minutes
#Write-Host "Data generation for `"$NumberOfWarehouses`" warehouses of TPCH dataset took $diff minutes to complete" -ForegroundColor Yellow
