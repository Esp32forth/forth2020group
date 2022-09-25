\ Adding simple stacks to ESP32forth - adapted from code found at
\ https://rosettacode.org/wiki/Stack#Forth by Bob Edwards Aug 2022
\ No bounds checking
	
cell negate value -cell

: stack ( size -- )
  create					\ make a new dictionary entry using the name of the stack	
  here cell+ ,				\ initialise the stack pointer as an empty stack 
  cells allot				\ allocate the storage space for the stack
; 
 
: push ( n st -- )
	swap over				( st n st -- )
	@						\ read the stack pointer ( st n -- )
	!						\ store n on the top of stack ( st  -- )
	cell swap +!			\ and increment the stack pointer
;

: pop ( st -- n ) 
	-cell over +!			\ decrement the stack pointer ( st -- )
	@						\ read the stack pointer
	@						\ read the value top of stack
;

: tos@	( -- tos_copy )
	@ cell - @				\ read a copy of the top of stack
;

: empty? ( st -- ? )
	dup @ - cell+ 0=
;

\ Test words
 
10 stack st
 
1 st push
2 st push
3 st push

st tos@ .					\ 3

st empty? .  				\ 0 (false)
st pop . st pop . st pop .  \ 3 2 1
st empty? .  				\ -1 (true)

