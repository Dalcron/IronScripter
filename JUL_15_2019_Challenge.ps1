### CHALLENGE ######################################################
# Get all files in a given folder including subfolders and display
# a result that shows the total number of files, the total size of 
# all files, the average file size, the computer name, and the date 
# when you ran the command.
####################################################################

#Version 1
gci $fileLocation -recurse | ?{$_.Mode -notlike "d*"} | measure-object -Property Length -Sum -Average | select $env:COMPUTERNAME,$(get-date).ToString(),count,sum,average

#Version 2
gci "C:\Temp" -recurse | ?{$_.Mode -notlike "d*"} | measure-object -Property Length -Sum -Average | %{"Computer Name: $env:COMPUTERNAME`r`nWhen run: $(get-date)`r`nNumber of Files: $($_.count)`r`nTotal Size of Files: $($_.sum) KB`r`nAverage File Size: $($_.average) KB"}

### THOUGHTS #######################################################
# Version 1 tries to get it into the pipeline and is a little goofy 
# without using more advanced code for formatting the output.
#
# Version 2 is cleaner but not as easily consumed by the pipeline.
####################################################################
