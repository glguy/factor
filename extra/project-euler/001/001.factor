! Copyright (c) 2007 Aaron Schaefer.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel math math.ranges sequences ;
IN: project-euler.001

! http://projecteuler.net/index.php?section=problems&id=1

! DESCRIPTION
! -----------

! If we list all the natural numbers below 10 that are multiples of 3 or 5, we
! get 3, 5, 6 and 9. The sum of these multiples is 23.

! Find the sum of all the multiples of 3 or 5 below 1000.


! SOLUTION
! --------

! Inclusion-exclusion principle

<PRIVATE

: sum-divisible-by ( target n -- m )
    [ /i dup 1+ * ] keep * 2 /i ;

PRIVATE>

: euler001 ( -- answer )
    999 3 sum-divisible-by
    999 5 sum-divisible-by +
    999 15 sum-divisible-by - ;

! [ euler001 ] 100 ave-time
! 0 ms run / 0 ms GC ave time - 100 trials


! ALTERNATE SOLUTIONS
! -------------------

: euler001a ( -- answer )
    0 999 3 <range> sum 0 999 5 <range> sum + 0 999 15 <range> sum - ;

! [ euler001a ] 100 ave-time
! 0 ms run / 0 ms GC ave time - 100 trials


: euler001b ( -- answer )
    1000 [ dup 5 mod swap 3 mod [ zero? ] either? ] filter sum ;

! [ euler001b ] 100 ave-time
! 0 ms run / 0 ms GC ave time - 100 trials

MAIN: euler001
