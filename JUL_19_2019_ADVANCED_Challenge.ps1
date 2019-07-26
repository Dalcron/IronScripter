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
### Helper Functions
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
function writeOutput()
{
    <#
        .SYNOPSIS
            Writes message with color to screen or returns error message.
        .DESCRIPTION
            Timestamp is appended to the beginning of every message. If error switch is not 
            supplied, the message is written to the screen using write-host with the 
            foreground color parameter set to Yellow unless a different color is specified.  
            
            If the error switch is specified, the timestamp is followed by '- [ERROR]' and 
            the string is returned instead of using write-host.
        .PARAMETER message
            String value to be formatted.
        .PARAMETER color
            Default value is yellow.  Error given if invalid color is provided.
        .PARAMETER error
            Switch to add '[ERROR]' and return string instead of using write-host.
    #>
    [CmdletBinding(DefaultParameterSetName="color")]
    param(
        [parameter(Mandatory=$true,Position=0)]
        [string]$message, 
        [parameter(ParameterSetName="color")]
        [parameter(Mandatory=$false,Position=1)]
        [System.ConsoleColor]$color = [System.ConsoleColor]::Yellow,
        [parameter(ParameterSetName="error")]
        [parameter(Mandatory=$false)]
        [switch]$error)
    if($error)
    {
        return "$(get-date -format "[HH:mm:ss] - ")[ERROR] $message"
    }
    Write-Host "$(get-date -format "[HH:mm:ss] - ")$message" -ForegroundColor $color
}
function getFileInfo
{
    param([string[]]$fileLocationArray)
    foreach ($fileLocation in $fileLocationArray)
    {
        if(Test-Path $_ -PathType Container) #test every path
        {
            #search location recursively for files (if mode starts with 'd' it's a directory).
            $files = gci $_ -recurse | ?{$_.Mode -notlike "d*"}
            if($files.count -le 0) #respond if no files found
            {
                writeOutput "No files found in $_." Red
                continue
            }
            else
            {
                #return files when present
                return $files 
            }
        }
        else #respond to invalid paths with an error message, but don't stop the processing of other paths
        {
            writeOutput "File location is not valid.  Value provided: $_" Red
        }
    }
}
### Main Function
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
    #>
    param(
        [parameter(ValueFromPipeline=$true,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$fileLocationArray,
        [parameter(Position=0)]
        [string]$target = $env:COMPUTERNAME,
        [switch]$AsJob,
        [string]$jobName = "fileInvestigation_$(get-date -format "MM_dd_yyyy_HH_mm_ss_fff")"
    )
    Begin
    {
        if($target -ne $env:COMPUTERNAME)
        {
            $cred = Get-Credential -Message "Provide credentials for connecting to $target"
        }
        # CONNECTION CHECK
        if(Test-Connection $target -count 1)
        {
            writeOutput "$target is reachable"
        }
        else
        {
            Throw (writeOutput "Unable to connect to $target")
        }
    }
    Process
    {
        if($AsJob)
        {
            if($target -eq $env:COMPUTERNAME)
            {
                writeOutput "Starting job: $jobName"
                Invoke-Command -ComputerName $target -ScriptBlock {getFileInfo $fileLocationArray} -ArgumentList (,$fileLocationArray) -AsJob -JobName $jobName
                writeOutput "Waiting for job: $jobName..."
            }
            else
            {
                writeOutput "Starting job on $target with job name: $jobName"
                Invoke-Command -ComputerName $target -ScriptBlock {getFileInfo $fileLocationArray} -ArgumentList (,$fileLocationArray) -AsJob -Credential $cred -JobName $jobName
                writeOutput "Waiting for job: $jobName on $target..."
            }
            Get-Job -Name $jobName | Wait-Job
            writeOutput "$jobName job completed."
            $results = Receive-Job -Name $jobName
        }
        else
        {
            if($target -eq $env:COMPUTERNAME)
            {
                writeOutput "Gathering file information..."
                $results = Invoke-Command -ComputerName $target -ScriptBlock {getFileInfo $fileLocationArray} -ArgumentList (,$fileLocationArray) 
            }
            else
            {
                writeOutput "Gathering file information on $target..."
                $results = Invoke-Command -ComputerName $target -ScriptBlock {getFileInfo $fileLocationArray} -ArgumentList (,$fileLocationArray) -Credential $cred
            }
        }
    }
    End
    {
        #process results and write result to pipeline
        $results | measure-object -Property Length -Sum -Average | select @{label="Path";Expression={$fileLocation}},`
                                                                        @{label="ComputerName";Expression={$env:COMPUTERNAME}},` #not sure if this will return remotely without testing
                                                                        @{label="WhenRun";Expression={$(get-date).ToString()}},`
                                                                        @{label="NumberOfFiles";Expression={$_.count}},`
                                                                        @{label="SizeOfFiles";Expression={roundandconvert $_.sum}},`
                                                                        @{label="AverageFileSize";Expression={roundandconvert $_.average}}
    }
    return $results
