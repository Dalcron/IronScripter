### Challenge ###################################################################################
# To solve or decrypt, you need to find a pair of numbers, X and Y.  Starting in the upper left, 
# you would start counting X number of characters, starting at 1. Once you have the first letter,
# then count Y number of characters for the 2nd letter. Then X number of characters for the 3rd 
# letter and so on. 
#
# The end result will be a word or phrase with no spaces. 
#################################################################################################
<#  Example for testing - look for 1,5 in the output to see the code: get-help
$crypto = @"
g - 2 5 R e t o p c 7 -
h v 1 Q n e l b e d E p
"@  
#>
#Challenge string block
$crypto = @"
P k T r 2 s z 2 * c F -
r a z 7 G u D 4 w 6 U #
g c t K 3 E @ B t 1 a Y
Q P i c % 7 0 5 Z v A e
W 6 j e P R f p m I ) H
y ^ L o o w C n b J d O
S i 9 M b e r # ) i e U
* f 2 Z 6 M S h 7 V u D
5 a ( h s v 8 e l 1 o W
Z O 7 l p K y J l D z $
- j I @ t T 2 3 R a i k
q = F & w B 6 c % H l y
"@.replace(" ","").split("`n").trimend("`r") -join "" #take out white space and join for a single string

# There's a lot of output to find the answer, I started in batches with the assumption that the values could be 0-144.
#  $x or $y can be 0 in this code, but not both or the do loop will never exit.

for($x = 1; $x -lt 5; $x++) #  Start with $x = 1 to subtract 1 to account for the string index starting at 0.
{
    for($y = 0; $y -lt 13; $y++) # there are 12 characters per line so I wanted to keep it under 13 to start
    {
        $o = "" #init the output
        $i = $x - 1
        do
        {
            $o += $crypto[$i]
            $i += $y
            $o += $crypto[$i]
            $i += $x
        }while($i -lt $crypto.Length) # end when you reach the end of the string.  Length will be 1 more than the index of the last character in the array.
        write-host "( $x , $y )`t$o" -f Yellow #write the answers to the screen in a color that is readable
    }
}
#You have to review the screen output to decipher what the answer is -> 1,12
