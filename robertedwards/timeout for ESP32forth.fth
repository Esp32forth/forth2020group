\ ESP32forth Timeout function - Bob Edwards Aug 2022
\ When you want a function to repeat for a limited period of time only

\ returns true if period has expired; starttime, period or both in ms
: timeout?	( starttime period -- starttime false , if not yet timed out | true , if timed out )
	over + MS-TICKS <=
;

\ run a loop for a limited period
: test
MS-TICKS						\ read the current time
begin
	." try something "			\ these words will run until a key is pressed or the timeout occurs
	2000 timeout? key? or
until
." timed out!"
drop							\ drop the original start time
;
