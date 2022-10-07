\ MINI-OOF demo - Bob Edwards July 2021

\ include "mini-oof for esp32forth.fth"

object class
	cell var teeth#
	cell var height
	method speak
	method greet
	method walk
	method add.
end-class pet

:noname ." pet speaks" drop	; pet defines speak
:noname ." pet greets" drop	; pet defines greet
:noname ." pet walks" drop	; pet defines walk
:noname  drop + ." n1 + n2 = " . ; pet defines add.	( n1 n2 -- )

pet class
	method  happy	\ cats can do more than pets
end-class cat

:noname ." cat purrs" drop ; cat defines happy

\ cats override pets for these two methods
:noname ." cat says meow" drop ; cat defines speak	
:noname ." cat raises tail" drop ; cat defines greet

pet class
end-class dog

\ dogs override pets for these two methods
:noname ." dog says wuff" drop ; dog defines speak	
:noname ." dog wags tail" drop ; dog defines greet

\ create a cat and dog object to work with
cat new constant tibby
dog new constant fido

20 tibby teeth# !
30 fido teeth# !

50 tibby height !
75 fido height !

tibby greet
fido speak

tibby teeth# @ . cr
fido height @ . cr

tibby walk	\ notice tibby is a pet so she can walk OK
34 56 fido add.	\ the parent methods are inherited
