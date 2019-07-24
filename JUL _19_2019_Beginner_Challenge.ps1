### CHALLENGE ##############################################
# Using your solution from the previous beginner challenge, 
# turn this into a simple PowerShell function that will 
# allow the user to specify the path. Your function should 
# write the same result to the pipeline.
############################################################
function begGetFI($fileLocation)
{
    return gci $fileLocation -recurse | ?{$_.Mode -notlike "d*"} | measure-object -Property Length -Sum -Average | select $env:COMPUTERNAME,$(get-date).ToString(),count,sum,average
}
begGetFI "C:\Temp"
