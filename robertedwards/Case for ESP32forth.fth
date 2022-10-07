\ case structure for esp32forth

DEFINED? *CASE* [IF] forget *CASE* [THEN] 
: *CASE* ;

: ?dup dup if dup then ; 
internals 
: case 0 ; immediate 
: of ['] over , ['] = , ['] 0branch , here 0 , ['] drop , ; immediate 
: endof ['] branch , here 0 , swap here swap ! ; immediate 
: endcase ['] drop , begin ?dup while here swap ! repeat ; immediate 
 
 \ end of case structure
 