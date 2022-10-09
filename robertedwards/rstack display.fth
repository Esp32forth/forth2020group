\ display the user application entries on the return stack

RP@ 2 cells + value USERRP0             \ RSTACK base address prior to executing user word, and <> RP0

: .rstack
    ." [ r-stack "
    USERRP0 RP@ <> IF
        RP@ USERRP0 DO
            I @ .
        cell +LOOP
    ELSE
        ." No user values"
    THEN
    ." ]"
;

: TEST1 1 >R 2 >R 3 >R .rstack rdrop rdrop rdrop ;

: TEST2 .rstack ;

TEST1 CR
TEST2 CR
