\ display n1 right justified in a field of n2 chars 
: .r        ( n1 n2 -- )
swap dup >r abs
<#          
0 >r        
begin                   \ count how many numbers to print
    #
    r> 1+ >r
    dup 0=
until
r> r>
dup 0< if
         swap 1+ swap    \ add one for any negtaive sign
       then
sign
swap >r
- dup 0 > if
    0 do 
        bl hold          \ if there's roon, fill left with spaces
    loop
then
r> #> type   
;

\ test words

12345 12 .r
-12345 12 .r
12345 2 .r
