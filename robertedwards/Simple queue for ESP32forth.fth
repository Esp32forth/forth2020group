\ Queues for ESP32forth ver1 - Bob Edwards Sept 2022
\ Useful for passing messages between tasks in a multitask application
\ sharing a resource between tasks etc.
\ As many queues as you wish can be made using the QUEUE word - see below
\ This is also an example of 'hand made' object oriented programming

forth definitions
hex

\ print a byte as two hex digits
: byte.	( byte -- )
	base @ >R hex
	<# # #s 24 hold #> type space
	R> base !
;

\ better hex dump
: hexdump	( a n -- )
	hex
    cr 0 SWAP 1-		( a 0 n )
	FOR					( a bytecount )
        DUP 10 mod 0=
		IF
            cr
			2dup + .
        THEN
        2dup + C@ byte. 1+	
    NEXT
    2drop cr
	r> base !
;

decimal

\ primitive for abort"
: (abort")  ( f addr len -- )
    rot if
        type
        quit
    else
        drop drop
    then
  ;

\ stop execution of word and send error message if fl<>0
: abort"  ( comp: -- <str> | exec: fl -- )
    [  ' s" , ] 
    postpone (abort")
  ; immediate

INTERNALS DEFINITIONS

: QSIZE@		( queue -- queuesize )
	4 cells + @
;

: QUSED@		( queue -- used )
	3 cells + @
;

: QUSED!		( n queue -- )
	3 cells + !
;

: QTAIL@		( queue -- n )
   2 cells + @
;

: QTAIL!		( n queue -- )
	2 cells + !
;

: QHEAD@		 ( queue -- n )
	cell + @
;

: QHEAD!		( n queue -- )
	cell + !
;

\ move a buffer address ptr to the next position with wrap around
: QNEXT			( ptr1 queue -- ptr2 )
	>R								\ store queue on the R stack
	cell+							\ ( ptr+4 ) ptr=ptr+4
	DUP R@ @ =						\ ( ptr+4 flag )compare ptr with END
	IF								( ptr+4 )
		DROP
		R> 5 cells +				\ wrap around to start of the data area
	ELSE
		R> DROP
	THEN
;

FORTH DEFINITIONS
FORTH ALSO INTERNALS

\ create a new queue
: QUEUE								( n "name" -- )
	create							\ make a new dictionary entry using the name of the stack
	dup >R
	cells here dup >R + 5 cells + ,	\ constant END, the end address of the queue at queue+0
	R> 5 cells + DUP ,				\ variable HEAD at queue+4
	,								\ variable TAIL	at queue+8
	0 ,								\ variable USED	at queue+12
	R> DUP ,						\ constant SIZE	at queue+16
	cells ALLOT 					\ and the data starts at queue+20	
;									

\ is the queue empty?
: QEMPTY?		( queue -- flag )
	QUSED@ 0=
;

\ is the queue full?
: QFULL?		( queue -- flag )
	DUP QUSED@
	SWAP QSIZE@ =
;

\ insert n into the queue
: QPUT			( n queue -- )
	DUP QFULL? ABORT" queue full" >R
	R@ QTAIL@ !						\ store n in the queue
	R@ QTAIL@ R@ QNEXT R@ QTAIL! 	\ increment TAIL with wrap around
	1 R@ QUSED@ + R> QUSED!			\ and increment USED 
;

\ remove n from the queue
: QGET			( queue -- n )
	DUP QEMPTY? ABORT" buffer empty" >R
	R@ QHEAD@ @						\ read n from the queue
	R@ QHEAD@ R@ QNEXT R@ QHEAD!	\ increment HEAD with wrap around
	-1 R@ QUSED@ + R> QUSED!		\ and decrement USED
;

\ display queue control variables for debug
: Q.	( queue -- )
cr ." END  = $" dup @ hex .
cr ." HEAD = $" dup QHEAD@ .
cr ." TAIL = $" dup QTAIL@ .
cr ." USED = " dup QUSED@ decimal .
cr ." SIZE = " QSIZE@ .
cr
;

ONLY

\ Example code

4 queue myq

\ check that a word that follows ism't overwritten by queue data
: test 10 0 do i . loop ;

myq qempty? .
myq qfull? .
\ so myq is empty

1 myq qput
2 myq qput
3 myq qput
4 myq qput

myq qempty? .
myq qfull? .
\ so myq is now full


\ So qempty? and qfull? are essential as semaphores regulating program flow in a task
\  - putting or getting too much data causes program stop and an error message

myq qget .
myq qget .
myq qget .
myq qget .

myq qempty? .
myq qfull? .

\ The queue's internal control registers can also be displayed"
myq q.

10 myq qput
11 myq qput

myq q.
\ myq is part full

myq qget .
myq qget .

myq q.
\ myq is empty again

test
\ and the test word hasn't been overwritten by the data in myq - as a programming check
