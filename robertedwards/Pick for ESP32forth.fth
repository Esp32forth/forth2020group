\ duplicate nth item on the data stack, 0 pick = dup, 1 pick = over
: pick ( .... n - nth item )
    sp@ swap 1+ cells - @
;
