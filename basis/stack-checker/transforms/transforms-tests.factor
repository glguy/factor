IN: stack-checker.transforms.tests
USING: sequences stack-checker.transforms tools.test math kernel
quotations stack-checker accessors combinators words arrays
classes classes.tuple ;

: compose-n-quot ( word -- quot' ) <repetition> >quotation ;
: compose-n ( quot -- ) compose-n-quot call ;
\ compose-n [ compose-n-quot ] 2 define-transform
: compose-n-test ( a b c -- x ) 2 \ + compose-n ;

[ 6 ] [ 1 2 3 compose-n-test ] unit-test

TUPLE: color r g b ;

C: <color> color

: cleave-test ( color -- r g b )
    { [ r>> ] [ g>> ] [ b>> ] } cleave ;

{ 1 3 } [ cleave-test ] must-infer-as

[ 1 2 3 ] [ 1 2 3 <color> cleave-test ] unit-test

[ 1 2 3 ] [ 1 2 3 <color> \ cleave-test def>> call ] unit-test

: 2cleave-test ( a b -- c d e ) { [ 2array ] [ + ] [ - ] } 2cleave ;

[ { 1 2 } 3 -1 ] [ 1 2 2cleave-test ] unit-test

[ { 1 2 } 3 -1 ] [ 1 2 \ 2cleave-test def>> call ] unit-test

: spread-test ( a b c -- d e f ) { [ sq ] [ neg ] [ recip ] } spread ;

[ 16 -3 1/6 ] [ 4 3 6 spread-test ] unit-test

[ 16 -3 1/6 ] [ 4 3 6 \ spread-test def>> call ] unit-test

[ fixnum instance? ] must-infer

: bad-new-test ( -- obj ) V{ } new ;

[ bad-new-test ] must-infer

[ bad-new-test ] must-fail
