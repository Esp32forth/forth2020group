\ Periodic Timers using Mini-OOF ver 2 by Bob Edwards April 2022
\ this code allows multiple words to execute periodically, all with different time periods, 
\ on one cog.
\ Run MAIN for a demo, which terminates on any key being pressed 

\ NB On entering each method, the address of the current object is top of the data stack
\ This must be removed by the method before exiting
\ You can see that it is often convenient to transfer that to the R stack to get
\ to any input parameters. You must clean up the R stack before exiting the method, though

DEFINED? *TIMERS* [IF] forget *TIMERS* [THEN] 
: *TIMERS* ;

\ TIMER class definition
OBJECT CLASS
	4 VAR STARTTIME
	4 VAR PERIOD
	4 VAR TCODE
	METHOD TSET
	METHOD TRUN
	METHOD TPRINT
END-CLASS TIMER

:noname >R 
	R@ PERIOD !									\ save the reqd period in ms
	R@ TCODE !									\ save the cfa of the word that will run periodically
	MS-TICKS R> STARTTIME !						\ save the current time since reset
; TIMER DEFINES TSET	( codetorun period -- ) 	\ initialises the TIMER

:noname >R
	MS-TICKS DUP									\ read the present time
	R@ STARTTIME @								\ read when this TIMER last ran
	-												\ calculate how long ago that is 
	R@ PERIOD @ >=								\ is it time to run the TCODE?
	IF
		R@ STARTTIME !							\ save the present time
		R> TCODE @ EXECUTE						\ run cfa stored in TCODE
	ELSE
		DROP R> DROP							\ else forget the present time
	THEN
; TIMER DEFINES TRUN	( -- )					\ run TCODE every PERIOD ms

:noname >R
	CR
	." STARTTIME = " R@ STARTTIME @ . CR
	." PERIOD = " R@ PERIOD @ . CR
	." TCODE = " R> TCODE @ . CR
; TIMER DEFINES TPRINT	( -- )						\ print timer variables for debug
\ end of TIMER class definition

\ Example application
TIMER NEW CONSTANT TIMER1
TIMER NEW CONSTANT TIMER2
TIMER NEW CONSTANT TIMER3
TIMER NEW CONSTANT TIMER4
TIMER NEW CONSTANT TIMER5

: HELLO1 ." Hi from HELLO1" CR ;
: HELLO2 ." HELLO2 here !" CR ;
: HELLO3 ." Watcha there from HELLO3" CR ;
: HELLO4 ." Good day, Mate from HELLO4" CR ;
: HELLO5 ." How's it going? from HELLO5" CR ;

\ Print all timer variables
: .VARS	( -- )
	CR CR ." Timer1" CR
	TIMER1 TPRINT
	CR ." Timer2" CR
	TIMER2 TPRINT
	CR ." Timer3" CR
	TIMER3 TPRINT
	CR ." Timer4" CR
	TIMER4 TPRINT
	CR ." Timer5" CR
	TIMER5 TPRINT
;

: MAIN	( -- )										\ demo runs until a key is pressed
	CR
	['] HELLO1 2000 TIMER1 TSET
	['] HELLO2 450 TIMER2 TSET
	['] HELLO3 3500 TIMER3 TSET
	['] HELLO4 35000 TIMER4 TSET
	['] HELLO5 2500 TIMER5 TSET						\ all timer periods and actions defined
	0
	BEGIN
		1+
		TIMER1 TRUN
		TIMER2 TRUN
		TIMER3 TRUN
		TIMER4 TRUN
		TIMER5 TRUN									\ all timers repeatedly run
	KEY? UNTIL
	CR ." The five timers TRUNs were each run " . ." times" CR
	.VARS											\ show each timer's data
;

 
