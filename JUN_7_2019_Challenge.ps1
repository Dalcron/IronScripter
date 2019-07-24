############################ CHALLENGE ###########################################
#  Your goal is to find the values in $List that do not match anything in $Target. 
#  Your code will be successful if you get foo and bar for results.
##################################################################################
$target = "Spooler", "Spork Client", "WinRM", "Spork Agent Service", "BITS","WSearch"
$list = "winrm", "foo", "spooler", "spor*", "bar"
#cycle through each value in $list and if the value matches a value in $target, remove them from $list
$list | %{
            if($target -match $_) #found a match
            {
                $list = $list -ne $_ #removed a match
            }
         }
$list #return results

#### Follow-up:
# I learned you can write the code more concisely with ?{-not ($target -match $_)}
# Thus, lines 8-14 become $list | ?{-not ($target -match $_)}
