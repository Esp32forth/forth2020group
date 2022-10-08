\ Portable, Stack Based String Library for ESP32forth
\ Original - Mark Wills February 2014 - http://turboforth.net/resources/string_library.html
\ Based on a string stack concept developed by Brian Fox circa 1988
\ Adapted for ESP32forth by Bob Edwards Oct 2022

\ N.B. Needs X("U<", ULESS, tos = (ucell_t) *sp < (ucell_t) tos ? -1 : 0; --sp) \
\ adding to the ESP32forth source code to support the WITHIN definition below

\ General Note:
\ Words surrounded by parenthesis are for low-level internal use by the string
\ library, and should not need to be called by higher-level application code

DEFINED? *STRINGS* [IF] forget *STRINGS* [THEN] 
: *STRINGS* ;

\ string format:
\ String constants (held in STRING types):
\ max_len actual_len <string_data> <?>
\ | | | |
\ cell cell chars padding (if required)
\ Transient strings (held on the string stack):
\ actual_len <string_data> <?>
\ | | |
\ cell chars padding (if required)

\ Throw Code|Nature of Error
\ ----------+-----------------------------------------
\ 9900 | String stack underflow
\ 9901 | String too large to assign
\ 9902 | String stack is empty
\ 9903 | Need at least 2 strings on string stack
\ 9904 | String too large for string constant
\ 9905 | Illegal LEN value
\ 9906 | Need at least 3 strings on string stack
\ 9907 | String is not a legal number
\ 9908 | Illegal start value

base @ \ save systems' current number base
decimal

forth definitions
only forth also internals

-1 constant true
0 constant false

: within ( test low high -- flag ) OVER - >R - R> U< ;

internals definitions
only forth also internals

\ Set up string stack. The stack grows towards lower memory addresses.
256 constant ($sSize) \ store stack size
\ Adjust to your own needs. Choose a value that is a multiple of your 
\ systems' cell size.

here ($sSize) allot \ reserve space for string stack 
constant ($sEnd) \ bottom of string stack
variable ($sp) \ pointer to top of string stack
($sEnd) ($sSize) + ($sp) ! \ initialise it
variable ($depth) \ count of items on the string stack
variable ($temp0) \ reserved for internal use
variable ($temp1) \ reserved for internal use
variable ($temp2) \ reserved for internal use
variable ($temp3) \ reserved for internal use

: ($depth+) ( -- ) 
 \ Increments the string stack item count
 1 ($depth) +! ;
 
: ($sp@) ( -- addr ) \ "string stack pointer fetch"
 \ Returns address of current top of string stack
 ($sp) @ ;
 
: (sizeOf$) ( $addr - $size)
 \ Given an address of a transient string, compute the stack size in bytes
 \ required to hold it, rounded up to the nearest cell size, and including
 \ the length cell.
 @ aligned cell+ ;
 
: (set$SP) ( $size -- )
 \ Given the stack size of a transient string set the string stack pointer
 \ to the new address required to accomodate it.
 negate dup ($sp@) + ($sEnd) < if 9900 throw then 
 ($sp) +! ;
 
: (addrOf$) ( index -- addr )
 \ Given an index into the string stack, return the start address of the 
 \ string. addr points to the length cell. Topmost string is index 0,
 \ next string is index 1 and so on.
 ($sp@) swap dup if 0 do dup (sizeOf$) + loop else drop then ;
 
: (lenOf$) ( $addr -- len )
 \ Given the address of a transient string on the string stack (the address
 \ of the length cell), return the length of the string.
 \ Note: Immediate, compiling word for performance reasons.
 \ Modern compilers will inline this.
 state @ if postpone @ else @ then ; immediate

forth definitions
only forth also internals

\ duplicate nth item on the data stack, 0 pick = dup, 1 pick = over
: pick ( .... n - nth item )
    sp@ swap 1+ cells - @ ;
 
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
 
: depth$ ( -- $sDepth)
 \ Returns the depth of the string stack.
 ($depth) @ ;
 
: $const ( max_len tib:"name" -- ) ( runtime: -- $Caddr) \ "string constant"
 \ Creates a string constant. When "name" is referenced the address of the
 \ max_len field is pushed to the stack.
 \ e.g. 100 string msg
 \ The above creates a string called msg with capacity for 100 characters.
 create dup ( max_len) , ( actual_len) 0 , allot align ;
 
: clen$ ( $Caddr -- len ) \ "string constant length"
 \ Given the address of a string constant, returns its length.
 cell+ @ ;
 
: maxLen$ ( $Caddr -- max_len ) \ "maximum length of string"
 \ Given the address of a string constant, returns its maximum length.
 \ Dependencies: (lenOf$)
 (lenOf$) ;
 
: .$const ( $Caddr -- ) \ "display string constant"
 \ Displays the string constant. e.g. fred .$const
 \ Dependencies: (lenOf$)
 cell+ dup (lenOf$) swap cell+ swap type ;
 
: :=" ( $Caddr tib:"string" -- ) \ "assign string constant"
 \ Assigns the string "string" to the string constant.
 \ e.g. msg :=" hello mother!"
 \ Dependencies: PARSE (core ext, 6.2.2008)
 dup @ [char] " parse swap >r
 2dup < if 9901 throw then
 nip 2dup swap cell+ !
 >r [ 2 cells ] literal + r> r> -rot cmove ;

internals definitions
only forth also internals
 
: ($") ( addr len -- ) ( ss: -- str )
 \ Run-time action for $" (see below).
 \ Dependencies: aligned ($set$SP) ($sp) ($depth+)
 dup aligned cell+ (set$SP)
 dup ($sp@) ! ($sp@) cell+ swap cmove ($depth+) ;

forth definitions
only forth also internals
 
: $" ( tib:"string" -- ) ( ss: -- str) \ "string to string stack"
 \ Pushes a string directly to the string stack.
 \ e.g. $" hello world" .$
 \ Dependencies: ($") PARSE (core ext, 6.2.2008)
 \ Note: State smart word. Runtime behaviour is in ($")
 state @ if
 postpone s" postpone ($")
 else
 [char] " parse ($")
 then ; immediate 
 
: >$ ( $Caddr -- ) ( ss: -- str) \ "to string stack"
 \ Moves a string constant to the string stack
 \ e.g. msg >$
 \ Dependencies: (lenOf$) ($")
 cell+ dup (lenOf$) swap cell+ swap ($") ;
 
: pick$ ( n -- ) ( ss: -- strN) \ "pick string"
 \ Given an index into the string stack, copy the indexed string to the top
 \ of the string stack.
 \ 0 $pick is equivalent to $DUP
 \ 1 $pick is equivalent to $OVER etc.
\ Dependencies: (lenOf$) depth$ ($addrOf$) ($")
 depth$ 0= if 9902 throw then 
 (addrOf$) dup (lenOf$) swap cell+ swap ($") ;
 
: dup$ ( -- ) ( ss: s1 -- s1 s1) \ "duplicate string"
 \ Duplicates a string on the string stack.
 \ Dependencies: depth$ pick$
 depth$ 0= if 9902 throw then 
 0 pick$ ;
 
: drop$ ( -- ) ( ss: str -- ) \ "drop string"
 \ Drops the top string from the string stack.
 \ Dependencies: depth$ (sizeOf$) (set$SP)
 depth$ 0= if 9900 throw then
 ($sp@) (sizeOf$) negate (set$SP) -1 ($depth) +! ;
 
: swap$ ( -- ) ( ss: s1 s2 -- s2 s1) \ "swap string"
 \ Swaps the top two string items on the string stack.
 \ Dependencies: depth$ (sizeOf$) (addrOf$) HERE (core 6.1.1650)
 depth$ 2 < if 9903 throw then 
 ($sp@) dup (sizeOf$) here swap cmove
 1 (addrOf$) dup (sizeOf$) ($sp@) swap cmove
 here dup (sizeOf$) ($sp@) dup (sizeOf$) + swap cmove ;
 
: nip$ ( -- ) ( ss: s1 s2 -- s2) \ "nip string"
 \ Remove the string under the top string.
 \ Dependencies: swap$ drop$ depth$
 depth$ 2 < if 9903 throw then 
 swap$ drop$ ;
 
: over$ ( -- ) ( ss: s1 s2 -- s1 s2 s1) \ "over string"
 \ Move a copy of s1 to top of string stack.
 \ Dependencies: pick$ depth$
 depth$ 2 < if 9903 throw then
 1 pick$ ;

: rot$ ( -- ) ( ss: s3 s2 s1 -- s2 s1 s3) \ "rotate strings"
 \ Rotates the top three string to the left.
 \ The third string moves to the top of the string stack.
($sp@)                                                                  \ save this addr for stack pointer
 2 pick$ 
 ($sp@) 1 (addrOf$)                                                     \ source & destination
 ($sp@) (sizeOf$)   1 (addrOf$) (sizeOf$)   2 (addrOf$) (sizeOf$) + +   \ number of bytes
 cmove>
 ($sp) !                                                                \ save stack pointer
 -1 ($depth) +!                                                         \ and fix depth
 ;
 
: -rot$ ( -- ) ( ss: s3 s2 s1 -- s1 s3 s2) \ "rotate strings"
 \ Rotates the top three string to the right.
 \ The top string moves to the third position.
 ($sp@)                                                                  \ save this addr for stack pointer
 2 pick$ 2 pick$
 ($sp@) 2 (addrOf$)
 ($sp@) (sizeOf$)   1 (addrOf$) (sizeOf$)   2 (addrOf$) (sizeOf$) + +   \ number of bytes
 cmove>
  ($sp) !                                                                \ save stack pointer
 -2 ($depth) +!                                                         \ and fix depth
 ;
 
: len$ ( -- len ) ( ss: -- ) \ "length of string"
 \ Returns the length of the topmost string.
 \ Dependencies: none
 depth$ 1 < if 9902 throw then 
 ($sp@) @ ;
 
: >$const ( $Caddr -- ) ( ss: str -- ) \ "to string constant"
 \ Move top of string stack to the string constant.
 \ e.g. $" blue" fred >$const fred .$const 
 \ displays "blue" 
 \ Dependencies: depth$ (sizeOf$) drop$
 >r depth$ 1 < if 9902 throw then
 len$ r@ @ > if 9904 throw then
 ($sp@) dup (sizeOf$) r> cell+ swap cmove drop$ ;
 
: +$ ( -- ) ( ss: s1 s2 -- s2+s1) \ concatenate strings
 \ Replaces the top most two strings on the string stack with their
 \ concatenated equivalent.
 \ eg: $" red" $" blue" +$ .$
 \ displays "redblue"
 \ Dependencies: depth$ (addrOf$) (lenOf$) len$ drop$ HERE (core 6.1.1650)
 depth$ 2 < if 9903 throw then 
 1 (addrof$) cell+ here 1 (addrof$) (lenof$) cmove
 ($sp@) cell+ 1 (addrof$) (lenof$) here + len$ cmove
 here len$ 1 (addrof$) (lenof$) + drop$ drop$ ($") ;
 
: mid$ ( start len -- ) ( ss: str1 -- str1 str2) \ "mid-string"
 \ The characters from start to start+len are pushed to the string stack
 \ as a new string. The original string is retained.
 \ Dependencies: len$ ($")
 depth$ 1 < if 9902 throw then 
 dup len$ > over 1 < or if 9905 throw then
 over dup len$ > swap 0< or if 9908 throw then 
 swap ($sp@) cell+ + swap ($") ;
 
: left$ ( len -- ) ( ss: str1 -- str1 str2) \ "left of string"
 \ The leftmost len characters are pushed to the string stack as a new 
 \ string. The original string is retained.
 \ Dependencies: mid$
 depth$ 1 < if 9902 throw then 
 dup len$ > over 1 < or if 9905 throw then 
 0 ($sp@) cell+ + swap ($") ;
 
 
: right$ ( len -- ) ( ss: str1 -- str1 str2) \ "right of string"
 \ The rightmost len characters, pushed to the string stack as a new string.
 \ the original string is retained.
 \ Dependencies: (lenOf$) mid$ 
 depth$ 1 < if 9902 throw then 
 dup len$ > over 1 < or if 9905 throw then 
 ($sp@) (lenOf$) over - ($sp@) cell+ + swap ($") ;
 
: findc$ ( char -- pos|-1 ) ( ss: -- ) \ "find character in string"
 \ Returns the first occurance of the character char in the top string.
 \ The string is retained. Returns -1 if the char is not found.
 \ Dependencies: PICK (ANS core ext) depth$
 depth$ 1 < if 9902 throw then 
 ($sp@) cell+ ($sp@) (lenOf$) 0 do
 dup c@ 2 pick = if i -1 leave then 1+ loop
 -1 = if nip nip else drop -1 then ;
 
: find$ ( offset -- pos|-1 ) ( ss: s1 s2 -- s1) \ "find string"
 \ Searches string s1, beginning at offset, for the substring s2.
 \ If the string is found, returns the position of the string relative
 \ to the offset, otherwise returns -1.
 \ Dependencies: depth$ len$ (addrOf$) (lenOf$) drop$
 depth$ 2 < if 9903 throw then 
 len$ ($temp1) ! 1 (addrOf$) (lenOf$) ($temp0) !
 dup ($temp0) @ > if drop -1 exit then 
 1 (addrOf$) cell+ + ($temp2) ! ($sp@) cell+ ($temp3) !
 ($temp1) @ ($temp0) @ > if drop -1 exit then 
 0 ($temp0) @ 0 do
 ($temp3) @ over + c@ 
 ($temp2) @ i + c@ = if
 1+ dup ($temp1) @ = if 
 drop i ($temp1) @ - 1+ -2 leave then 
 else drop 0 then
 loop 
 dup -2 = if drop else drop -1 then drop$ ;
 
: .$ ( -- ) ( ss: str -- ) \ "display string"
 \ Pop and display the topmost string from string stack.
 \ Dependencies: depth$ (lenOf$) drop$
 depth$ 0= if 9902 throw then 
 ($sp@) cell+ ($sp@) (lenOf$) type drop$ ;
 
: rev$ ( -- ) ( ss: s1 -- s2 ) \ "reverse string"
 \ Reverse topmost string on string stack.
 \ Dependencies: depth$ (lenOf$) HERE (core 6.1.1650)
 depth$ 0= if 9902 throw then 
 ($sp@) dup cell+ >r (lenOf$) r> swap here swap cmove 
 ($sp@) (lenOf$) here 1- +
 ($sp@) cell+ dup ($sp@) (lenOf$) + swap do
 dup c@ i c! 1- loop drop ;
 
: ltrim$ ( -- ) ( ss: s1 -- s2 ) \ "left trim string"
 \ Removes leading spaces from s1, resulting in s2.
 \ Dependencies: depth$ (lenOf$) (sizeOf$) drop$ HERE (core 6.1.1650)
 depth$ 0= if 9902 throw then 
 ($sp@) dup (lenOf$) >r here over (sizeOf$) cmove
 0 r> here cell+ dup >r + r> do
 i c@ bl = if 1+ else leave then loop 
 dup 0 > if 
 >r ($sp@) (lenOf$) drop$
 here cell+ r@ + swap r> - ($")
 else drop then ;
 
: rtrim$ ( -- ) ( ss: s1 -- s2 ) \ "right trim string"
 \ Removes trailing spaces from s1, resulting in s2.
 \ Dependencies: depth$ rev$ ltrim$
 depth$ 0= if 9902 throw then
rev$ ltrim$ rev$ ;

: trim$ ( -- ) ( ss: s1 -- s2 ) \ "trim string"
 \ Remove both leading and trailing spaces from s1, resulting in s2.
 \ Dependencies: rtrim$ ltrim$
 rtrim$ ltrim$ ;
 
: replace$ ( -- pos ) ( found: ss: s1 s2 s3 -- s4 not found: s1 s2 -- s1 s2)
 \ In string s2 find s3 and replace with s1, resulting in s4. 
 \ If a replacement is made, the starting position of the replacement is 
 \ returned, otherwise -1 is returned.
 \ Dependencies: depth$ find$ (addrOf$) (lenOf$) drop$ ($")
 \ nip$ HERE (core 6.1.1650)
 depth$ 3 < if 9906 throw then
 len$ >r
 0 find$ dup ($temp0) ! -1 > if
 ($sp@) cell+ here ($temp0) @ cmove 
 1 (addrOf$) cell+ here ($temp0) @ + 
 1 (addrOf$) (lenof$) cmove
 ($sp@) cell+ ($temp0) @ + r@ + 
 here ($temp0) @ + 1 (addrOf$) (lenof$) +
 len$ r> - ($temp0) @ - dup >r cmove
 r> ($temp0) @ + 1 (addrOf$) (lenof$) +
 drop$ drop$ here swap ($")
 else r> drop ($temp0) @ then ;

: ucase$ ( -- ) ( ss: str -- STR) \ "convert to upper case"
 \ On the topmost string, converts all lower case characters to upper case.
 \ Dependencies: WITHIN (core ext) (lenOf$) depth$
 depth$ 1 < if 9902 throw then
 ($sp@) dup (lenOf$) + cell+ ($sp@) cell+ do
 i c@ dup [ char a ] literal [ char { ] literal within if 
 32 - i c! else drop then loop ;
 
: lcase$ ( -- ) ( ss: STR -- str) \ "convert to lower case"
 \ On the topmost string, converts all upper case characters to lower case.
 \ Dependencies: WITHIN (core ext) (lenOf$) depth$
 depth$ 1 < if 9902 throw then 
 ($sp@) dup (lenOf$) + cell+ ($sp@) cell+ do
 i c@ dup [ char A ] literal [ char [ ] literal within if 
 32 + i c! else drop then loop ;
 
: ==$? ( -- flag ) ( ss: -- ) \ "is equal to string"
 \ Performs a case-sensitive comparison of the topmost two strings on the 
 \ string stack, returning true if their length and contents are identical,
 \ otherwise returning false.
 \ Dependencies: depth$ (addrOf$) (lenOf$)
 depth$ 2 < if 9903 throw then              \ If the string stack has less than two items, throw an error 
 len$ 1 (addrOf$) (lenOf$) =                \ compare the two top string lengths: Are they equal?
 if                                         \ yes, equal length strings
    1 (addrOf$) cell+                       \ point to 1st char of 2nd string on stack
    ($sp@) cell+ len$ + ($sp@) cell+        \ last char of tostringstack, first char of the same 
    do
        dup c@ i c@ <>
        if
            drop false leave
        then
    1+ loop
    dup
    if
        drop true
    then 
 else                                       \ no, unequal length strings
    false                                   \ so return false
 then ;
 
: $.s ( -- ) ( ss: -- )
 \ Non-destructively displays the string stack.
 \ Dependencies: depth$ len$ .$ .R (core ext, 6.2.0210)
 cr depth$ 0 > if
 ($sp@) depth$
 ." Index|Length|String" cr
 ." -----+------+------" cr 
 0 begin
 depth$ 0 > while
 dup 5 .r ." |" len$ 6 .r ." |" .$ 1+ cr
 repeat drop
 ($depth) ! ($sp) ! cr
 else
 ." String stack is empty." cr
 then
 ." Allocated stack space:" ($sEnd) ($sSize) + ($sp@) - 4 .r ." bytes" cr
 ." Total stack space:" ($sSize) 4 .r ." bytes" cr
 ." Stack space remaining:" ($sp@) ($sEnd) - 4 .r ." bytes" cr ;
 
: $>n ( -- n ) ( ss: str -- )
 \ Interprets the topmost string as a number, returning its value
 \ on the data stack as a signed integer
 \ Dependencies: (lenOf$) drop$
 ( ud1) ($sp@) dup (lenOf$) swap cell+ swap ( c-addr1 u1)
 ['] evaluate catch 0<> if 9907 throw then
 drop$ ; 
 
: n>$ ( n -- ) ( ss: -- str )
 \ Pushes the signed number on the data stack to the string stack.
 \ Dependencies: ($")
 dup abs
 <# #s swap sign #> ($") ;

only forth
 
base ! \ restore systems' current number base
