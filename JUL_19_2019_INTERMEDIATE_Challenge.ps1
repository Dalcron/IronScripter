### CHALLENGE ##########################################################
#
## Beginner description
# Using your solution from the previous beginner challenge, turn this 
# into a simple PowerShell function that will allow the user to specify 
# the path. Your function should write the same result to the pipeline.
#
## Intermediate description
# Create a similar function as the beginner level but accept piping in 
# a directory name. Your function only needs to process a single path. 
# You should also include parameter validation and error handling. The 
# output must include the path. Include comment-based help.
#
########################################################################

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
function intGetFI()
{
    <#
        .SYNOPSIS
            Recursive investigation of file path for file information.
        .DESCRIPTION
            Takes all files found in a directory path (recursively) and displays the computer's name, timestamp, number of files, and average file size.
        .PARAMETER fileLocation
            Directory where file information will be gathered from.
        .EXAMPLE
            intGetFI "C:\Temp"

            Path          : C:\Temp
            Computer Name : COMP1
            WhenRun       : 7/23/2019 12:20:48 PM
            Count         : 16
            Sum           : 593620
            Average       : 37101.25

            This example show how to use this function with positional input.
        .EXAMPLE
            "C:Temp" | intGetFI

            Path          : C:\Temp
            Computer Name : COMP1
            WhenRun       : 7/23/2019 12:20:48 PM
            Count         : 16
            Sum           : 593620
            Average       : 37101.25
            
            This example shows how to use this function with pipeline input
    #>

    param(
        [parameter(ValueFromPipeline=$true)] #accept input from the pipeline
        [ValidateNotNullOrEmpty()] #validate input isn't null or empty
        [ValidateScript({ #validation script to check that the value is a directory and has files.
                            if(Test-Path $_ -PathType Container)
                            {
                                if((gci $_ -recurse | ?{$_.Mode -notlike "d*"}).count -le 0)
                                {
                                    Throw [System.Management.Automation.ValidationMetadataException] "No files found in $_."
                                }
                            $true
                            }
                            else
                            {
                                Throw [System.Management.Automation.ValidationMetadataException] "File location is not valid.  Value provided: $_"
                            }
                        })]
        [string]$fileLocation
    )
    # A bit more advanced from the beginner version.  
    # Label/Expression format used to keep data clean in the pipeline. 
    # roundandconvert helper function used to make output more readable.
    return gci $fileLocation -recurse | ?{$_.Mode -notlike "d*"} | measure-object -Property Length -Sum -Average | select @{label="Path";Expression={$fileLocation}},`
                                                                                                                          @{label="ComputerName";Expression={$env:COMPUTERNAME}},`
                                                                                                                          @{label="WhenRun";Expression={$(get-date).ToString()}},`
                                                                                                                          @{label="NumberOfFiles";Expression={$_.count}},`
                                                                                                                          @{label="SizeOfFiles";Expression={roundandconvert $_.sum}},`
                                                                                                                          @{label="AverageFileSize";Expression={roundandconvert $_.average}}
}
### TESTS #####################################################
#
# Uncomment a line below to explore the script's functionality
#
#@ Test help functions
# 
# get-help roundandconvert 
# get-help roundandconvert -examples
#
# get-help intGetFI
# get-help intGetFI -examples
#
## Function Tests
# 
# roundandconvert 900 #less than 1 KB
# roundandconvert 1024 # 1 KB
# roundandconvert 100000 # more than 1 KB but less than 1 MB
# roundandconvert 100000000 # more than 1MB but less than 1GB
# roundandconvert 10000000000 # more than 1GB but less than 1 TB
# roundandconvert 1000000000000000 # more than 1 TB
#
# intGetFI "C:\test" #bad directory
# intGetFI "C:\Temp" #typical
# intGetFI "C:\Empty" #location with 0 files
# "C:\Temp" | intGetFI #from pipeline
###############################################################
