\ Batch file for ESP32forth ver 1 by Bob Edwards Oct 2022
\ Typing INCLUDE /spiffs/mybatchfilename is a bit of a mouthful if
\ you just want to run a few lines of forth from disk
\ The dictionary will be searched  for the word first, if not found then ...
\ The spiffs drive will be searched for a file of the same name. If found it will load, else an error displayed
\ the file can contain a list of commands to interpret or a words to compile, run & forget etc
\ The feature can be turned on with ON BATCH and normal 'word not found'
\ behaviour restored with OFF BATCH

\ N.B. Requires loading this string library first - https://esp32.arduino-forth.com/listing/page/text/strings

forth definitions
only forth also internals

DEFINED? *BATCH* [IF] forget *BATCH* [THEN] 
: *BATCH* ;


20 string filename                              \ 20 chr filename stringvar
: root s" /spiffs/" ;                           \ the spiff root directory

: ON -1 ;
: OFF 0 ;

\ add string a n to end of a stringvar - truncates string if too long
: $+                ( a n stringvar -- )
    swap dup >r swap
    maxlen$
    over -
    >r + r>
    >r swap r> min
    dup >r
    cmove                                       \ stringvar=stringvar + string
    r> r>
    cell - +!                                   \ update the string length
;

\ If flag=true, word a , n not found - try executing a batch file in the root folder of disk
: (BATCH)           ( a n flag -- )
    IF
        S" /spiffs/" filename $!                 \ filename = root directory
        filename $+                              \ append unknown word to filename 
        filename included
    THEN
;

variable save'notfound

\ Turn on / off batch file execution if word not found in dictionary
: BATCH                 ( ON | OFF -- )
    IF
        'notfound @
        save'notfound !
        ['] (BATCH) 'notfound !
    ELSE
        save'notfound @
        'notfound !
    THEN
;

\ Turn on / off all display to the terminal
\ Useful for hiding parts of a batch file operation
: DISPLAY               ( ON | OFF -- )
    echo !
;

ON BATCH                                        \ turn on the Batch file feature

\ test file to put into the spiffs root directory

\ off display
\ : test
\ ." Hi ESP32forth User - this is a count to 1000" cr
\ 1000 0 do
\    i . space
\ loop
\ cr ." We're all done now!" cr
\ ;
\ on display test
\ off display
\ forget test
\ on display


\ The above program loads from source, runs and displays, then the program is forgotten again
\ Uncomment the above code and save to a file on the spiffs store and try it out
\ The program displays very neatly, thanks to the ON DISPLAY and OFF DISPLAY commands
