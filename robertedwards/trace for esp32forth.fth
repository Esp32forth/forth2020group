TRACE - originally by Mark Wills - see https://www.bernd-paysan.de/screenful.html
\ Adapted for ESP32forth by Bob Edwards Sept 2022
\ A small piece of code, but very effective at showing word flow  & entry and exit data stack conditions
<<<<<<< HEAD
\ It's very simple so easily understood and added to 
=======
\ It's very simple, so easily understood and added to 
>>>>>>> 350a8f7e998f83aea858cc8e82fe8969974baf0c

DEFINED? *TRACE* [IF] forget *TRACE* [THEN] 
: *TRACE* ;


-1 constant true
0 constant false
0 VALUE indents
0 VALUE tracing
RP@ 2 cells + value USERRP0

: .rstack
    ." [ r-stack "
    USERRP0 RP@ <> IF
        RP@ USERRP0 DO
            I @ .
        cell +LOOP
    ELSE
        ." No new entries"
    THEN
    ." ]"
;

\ duplicate nth item on the data stack, 0 pick = dup, 1 pick = over
: pick ( .... n - nth item )
    sp@ swap 1+ cells - @
;

CREATE BLIST 15 CELLS ALLOT  

: BLIST[] indents CELLS BLIST + ;

: TRACE TRUE TO tracing  0 TO indents ;

: UNTRACE FALSE TO tracing ;

: >indents ( -- ) 0 indents MAX 12 MIN SPACES ;

<<<<<<< HEAD
: .stack ( -- ) ." [ d-stack " DEPTH ?DUP IF 1 SWAP DO I 1- PICK . -1
=======
: .stack ( -- ) ." [ " DEPTH ?DUP IF 1 SWAP DO I 1- PICK . -1
>>>>>>> 350a8f7e998f83aea858cc8e82fe8969974baf0c
  +LOOP ." ]" ELSE ." empty ]" THEN  ;

: .name ( CFA -- ) >NAME TYPE ;

: (:) 
    R@ 2 CELLS - BLIST[] !
    tracing
    IF
        >indents BLIST[] @ .name
        58 EMIT .stack CR
    THEN
    1 +TO indents
;

: (;)
    tracing
    IF
        >indents ." Exit:" .stack CR
    THEN
    -1 +TO indents
;

 : : : POSTPONE (:) ;       \ this has to be my favourite definition!!    
 
 : ; POSTPONE (;) POSTPONE ; ; IMMEDIATE

 : BREAK CR ." **BREAK**" CR .stack CR  0 indents 2 - DO ." in " I
 CELLS BLIST + @ .name SPACE -1 +LOOP  0 TO indents  CR QUIT ;

 
\ Example:

\ With TRACE loaded:- 

\ Use TRACE to switch on
\ use UNTRACE to switch off
\ Use BREAK in a definition to force a break-point and dump the stack to the screen
\ e.g. : TEST IF BREAK ELSE .... THEN ;
 
\ Here's an example

: HARRY 4 ;
: DICK 5 >R 6 >r 7 >r 3 HARRY RDROP RDROP RDROP ;
: TOM 2 DICK BREAK ;
: TEST 1 TOM ;

TRACE
TEST
2DROP 2DROP
