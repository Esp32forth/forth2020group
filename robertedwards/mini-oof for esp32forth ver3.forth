\ Mini-OOF by Bernd Paysan https://bernd-paysan.de/mini-oof.html
\ Adapted for ESP32Forth32 7.0.5.4 and onwards by Bob Edwards July 2022 ver 3
\ Mini-OOF offers no protection against programming errors, nor 'information hiding'
\ This version of Mini-OOF is multitasker compatible

ONLY FORTH DEFINITIONS

DEFINED? *MINI-OOF* [IF] forget *MINI-OOF* [THEN] 
: *MINI-OOF* ;

\ 'Do nothing' placeholder - overwritten later with a deferred word
: NOOP ;

\ remove n chrs from the front of the counted byte block
: /STRING ( addr1 cnt1 n -- addr2 cnt2 ) 
  DUP >R -							\ reduce cnt1
  SWAP R> +							\ increase start address
  SWAP								\ cleanup
 ;

\ subtract a 'cell' - 4 bytes - from n1
: cell-		( n1 -- n1-4 )
	4 -
; 

 
\ The object oriented extensions

\ define a method in a new class - this is what an object can do
: METHOD 
	CREATE ( m v -- m' v )
		OVER ,						\ compile m
		SWAP CELL+ SWAP				\ m' = m + cell			
	DOES> ( ... O -- ... )
		@ OVER @ +					\ calculate the required method address from the object ref.
		@ EXECUTE					\ read the xt of the method and execute it
;

\ define  data within a new class, needed to store an objects' state during operation	
: VAR ( m v size -- ) 
  CREATE 
	OVER ,							\ compile v
	+								( m v+size )
  DOES> ( o -- addr )
	@ +								\ add the vla offset to the object ref to get the val address
;

\ start the definition of a new class, derived from an existing class or the root OBJECT
: CLASS ( class -- class methods vars )
  DUP 
  2@ SWAP  							\ read methods and instvars and copy to the stack 
;

\ end the definition of a new class
: END-CLASS  ( CLASS METHODtotalspace VARtotalspace "name" -- )
	CREATE							\ create the class entry in the dict. with the name that follows
	HERE >R							\ remember the current compilation address - contains VARtotalspace
	, DUP , 						\ compile VARtotalspace, then METHODtotalspace ( CLASS METHODtotalspace -- )
	2 CELLS ?DO						\ if new methods have been defined in the class definition
		['] NOOP ,					\ compile a temporary NOOP for each method defined
	1 CELLS +LOOP					( CLASS -- )
	CELL+ DUP CELL+ R>				( CLASS+4 CLASS+8 VARtotalspace -- )
	ROT								( CLASS+8 VARtotalspace CLASS+4 -- )
	@								( CLASS+8 VARtotalspace METHODtotalspace -- )
	2 CELLS							( CLASS+8 VARtotalspace METHODtotalspace 8 -- )
	/STRING
	CMOVE	 						\ copy across the XTs from the parent class
;

\ used to define what each method actually does
: DEFINES ( xt class -- )
  '									\ find the XT of the method name in the input stream 
  >BODY @ + !						\ address [pfa]+class is set to XT, overwriting the NOOP   
;									\ in the class definition

: NEW ( class -- o )
  HERE								\ find the next unused code location
  OVER @ ALLOT						\ read the total var space reqd. and allot that space
  SWAP								( here class )
  OVER !							\ store class at [here], leaving here on the stack as o
;

\ HNEW is used to create an object, storing it's data on the heap. This is useful for creating objects
\ at run-time. Such objects can remain nameless and can be destroyed by calling FREE	( obj -- )
\ Use HNEW when you don't know how many objects will be needed at compile time
: HNEW ( class -- object )
  DUP @ ALLOCATE THROW				\ read the total var space reqd. and allot that space on the heap
  SWAP								( object class )
  OVER !							\ store class in the 1st location in  obj table & leave obj on stack
;


\ And sometimes derived classes want to access the method of the parent object with early binding
\ There are two ways to achieve this with this OOF: first, you could use named words,
\ or second, you could look up the vtable of the parent object
\ NB use this early binding word only within a definition, because it compiles the method's address in-line
: :: ( class "name" -- )
  ' >BODY @ + @ ,
;
\ Example use:  : TEST1 TIMER1 [ TIMER :: TPRINT ] CR ;   Early binding - the method address is calculated during compilation
\ As opposed to : TEST2 TIMER1 TPRINT CR ;                Late binding - the method address is calculated at runtime


\ this is the root object that all new classes are ultimately derived from
CREATE OBJECT 1 cells , 2 cells ,

\ If all classes are derived from a base class with a method INIT, then this is useful to
\ make INIT automatically run when an object is created

OBJECT CLASS
	method INIT
END-CLASS INITOBJECT

: NEW: ( ... o "name" -- )
	NEW DUP CONSTANT INIT
;

\ Further sub-Classes are created from INITOBJECT, each having INIT overrridden to suit that classes
\ initialisation of VARs etc.

\ e.g. here's a class that requires one VAR initialising from a value on the stack

\ INITOBJECT CLASS
\	cell VAR myvar
\ END-CLASS BABA
\ :noname myvar ! ; BABA DEFINES INIT
\ An object would be created as here, and myvar = 80 automatically
\ 80 BABA NEW: MYBABA


\ In Mini-OOF, when a method executes, the 'current object' reference is placed top of data stack
\ Mini-OOF expects the method to consume the 'current object' before finishing
\ This 'current object' gets in the way when using the data stack within the method
\ and it's quite useful to store it temporarily on the R stack
\ Copies of the 'current object' can be made using R@ to call methods with
\ Don't forget to drop it from the R stack before exiting the method.

ONLY
