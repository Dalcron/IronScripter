#In progress
# To Do:
#   -Update help block in advGetFI
#   -Add parrallel processing in ADVANCED_v2.0
#   -Write tests
#      -single path locally
#      -single path remotely
#      -multiple paths locally
#      -multiple paths remotely
#      -single path as job with no name locally
#      -single path as job with name locally
#      -single path as job with no name remotely
#      -single path as job with name remotely
#      -multiple paths as job with no name locally
#      -multiple paths as job with name locally
#      -multiple paths as job with no name remotely
#      -multiple paths as job with name remotely
#      -remote with bad credentials
#      -remote with no credentials provided
#      -bad directory
#      -empty directory
#      -unreachable host

function roundandconvert([double]$i)
{
    <#
        .SYNOPSIS
            Helper function that converts bytes to KB, MB, GB, or TB
        .DESCRIPTION
            Takes in a value in bytes (expected from what get-childitem returns) and rounds 
            and checks to see if it should be converted to KB, MB, GB, or TB. 
        .PARAMETER i
            Input original byte value.
        .EXAMPLE
            PS> roundandconvert 1024
            1 KB
        .EXAMPLE
            PS> roundandconvert 100000000
            95.37 MB
    #>
    switch($i)
    {
        {$i -lt 1024 * 1024}               {return "$([Math]::Round($i/1KB,2)) KB";continue}
        {$i -lt 1024 * 1024 * 1024}        {return "$([Math]::Round($i/1MB,2)) MB";continue}
        {$i -lt 1024 * 1024 * 1024 * 1024} {return "$([Math]::Round($i/1GB,2)) GB";continue}
        default                            {return "$([Math]::Round($i/1TB,2)) TB";continue}
    }
}
function advGetFI()
{
    <#
        .SYNOPSIS
            Recursive investigation of file path for file information.
        .DESCRIPTION
            Takes all files found in a directory path (recursively) and displays the computer's name, timestamp, number of files, and average file size. 
            
            Allows remote execution and multiple file locations. Can be ran as a job if desired. Default job names will be fileInformation_MM_dd_yyyy_HH_mm_ss_fff to prevent duplicate job name errors.
        .PARAMETER fileLocation
            Directory where file information will be gathered from.
        .PARAMETER 
        .EXAMPLE
            PS> intGetFI "C:\Temp"

            Path          : C:\Temp
            Computer Name : LG6GYP72
            WhenRun       : 7/23/2019 12:20:48 PM
            Count         : 16
            Sum           : 593620
            Average       : 37101.25
        .EXAMPLE
            PS> "C:Temp" | intGetFI

            Path          : C:\Temp
            Computer Name : LG6GYP72
            WhenRun       : 7/23/2019 12:20:48 PM
            Count         : 16
            Sum           : 593620
            Average       : 37101.25
    #>

    param(
        [parameter(ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$fileLocationArray,
        [parameter(Position=0)]
        [string]$remoteHost = "",
        [switch]$AsJob,
        [string]$jobName = "fileInvestigation_$(get-date -format "MM_dd_yyyy_HH_mm_ss_fff")"
    )
    # CONNECTION CHECK
    $target = $env:COMPUTERNAME
    if([string]::IsNullOrEmpty($remoteHost))
    {
        $target = $remoteHost
        $cred = Get-Credential -Message "Provide credentials for connecting to $target"
    }
    if(Test-Connection $target)
    {
        Write-Host "$(get-date -format "[HH:mm:ss] - ")$target is reachable" -ForegroundColor Yellow       
    }
    else
    {
        Throw "$(get-date -format "[HH:mm:ss] - ")[ERROR] Unable to connect to $target"
    }
    #Script block
    $cmd = {
            param($fileLocationArray)
            foreach($fileLocation in $fileLocationArray)
            {
                if(Test-Path $_ -PathType Container)
                {
                    if((gci $_ -recurse | ?{$_.Mode -notlike "d*"}).count -le 0)
                    {
                        Write-Host "No files found in $_." -ForegroundColor Red
                        continue
                    }
                gci $fileLocation -recurse | ?{$_.Mode -notlike "d*"} | measure-object -Property Length -Sum -Average | select @{label="Path";Expression={$fileLocation}},`
                                                                                                                                    @{label="ComputerName";Expression={$env:COMPUTERNAME}},`
                                                                                                                                    @{label="WhenRun";Expression={$(get-date).ToString()}},`
                                                                                                                                    @{label="NumberOfFiles";Expression={$_.count}},`
                                                                                                                                    @{label="SizeOfFiles";Expression={roundandconvert $_.sum}},`
                                                                                                                                    @{label="AverageFileSize";Expression={roundandconvert $_.average}}
                }
                else
                {
                    Write-Host "File location is not valid.  Value provided: $_" -ForegroundColor Red
                    continue
                }
            }}
    # JOB
    if($AsJob)
    {
        if($target -eq $env:COMPUTERNAME)
        {
            Write-Host "$(get-date -format "[HH:mm:ss] - ")Starting job: $jobName" -ForegroundColor Yellow
            Invoke-Command -ComputerName $target -ScriptBlock $sc -ArgumentList (,$fileLocationArray) -AsJob -JobName $jobName
            Write-Host "$(get-date -format "[HH:mm:ss] - ")Waiting for job: $jobName..." -ForegroundColor Yellow
        }
        else
        {
            Write-Host "$(get-date -format "[HH:mm:ss] - ")Starting job on $target with job name: $jobName" -ForegroundColor Yellow
            Invoke-Command -ComputerName $target -ScriptBlock $sc -ArgumentList (,$fileLocationArray) -AsJob -Credential $cred -JobName $jobName
            Write-Host "$(get-date -format "[HH:mm:ss] - ")Waiting for job: $jobName on $target..." -ForegroundColor Yellow
        }
        Get-Job -Name $jobName | Wait-Job
        Write-Host "$(get-date -format "[HH:mm:ss] - ")$jobName job completed." -ForegroundColor Yellow
        Receive-Job -Name $jobName
    }
    else
    {
        if($target -eq $env:COMPUTERNAME)
        {
            Write-Host "$(get-date -format "[HH:mm:ss] - ")Gathering file information..." -ForegroundColor Yellow
            Invoke-Command -ComputerName $target -ScriptBlock $sc -ArgumentList (,$fileLocationArray) 
        }
        else
        {
            Write-Host "$(get-date -format "[HH:mm:ss] - ")Gathering file information on $target..." -ForegroundColor Yellow
            Invoke-Command -ComputerName $target -ScriptBlock $sc -ArgumentList (,$fileLocationArray) -Credential $cred
        }
    }
    return 
}
