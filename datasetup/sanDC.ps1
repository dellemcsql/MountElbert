param(
    [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$false)]
    [System.Int32]
    $parellelThread = 25
)
<#
$parellelThread = 64
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

Function San-CSV { 
param(
    [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$false)]
    [System.Int32]
    $pt,

    [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$false)]
    [System.String]
    $path
)

$files = Get-ChildItem -Path $path -Filter "*.tbl" -File

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

Function San-Segg {
param(
[Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$false)]
    [System.String]
    $path
)

$files = Get-ChildItem  -Path $path -Filter *.csv
foreach ($f in $files){
    $fullname = $f.FullName
    $bname = $f.basename
    $fname = $f.Name
    $fPath = Split-Path -Path $fullname  
    $tabname = $bname.Split("_")[2]
    $tabPath = Join-Path $fPath $tabname
    if ( !(Test-Path $tabPath -PathType Container)){
        New-Item -ItemType Directory -Force -Path $tabPath | Out-Null
    }
    $newPath = Join-Path $tabPath $fname
    Move-Item -Path $fullname $newPath
}
}

# Root directory containing your files.
$kit = Split-Path $((Get-Variable MyInvocation).Value).MyCommand.Path
$path = Join-Path $kit "final"

$itr = 0
Do {

    San-CSV -pt $parellelThread -path $path
    Write-Host "Done..."
    # Collect the files
    $files = Get-ChildItem -Path $path -Filter "*.tbl" -File
    $itr = $Files.length 
    if ($Files.length -eq 0) {
      write-host "No files remains to process further..." -ForegroundColor Yellow
      Start-Sleep -Seconds 5
      $files = Get-ChildItem -Path $path -Filter "*.tbl" -File
      $itr = $Files.length
    }
} While ( $itr -ne 0)

Write-Host "Data conversion completed..." -ForegroundColor Green
Start-Sleep -Seconds 2
Write-Host "Starting File segrigation process..." -ForegroundColor Yellow
San-Segg -path $path
Start-Sleep -Seconds 2
Write-Host "Starting File segrigation process completed..." -ForegroundColor Green







