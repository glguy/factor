USING: math kernel kernel.private slots.private ;
IN: benchmark.typecheck3

TUPLE: hello n ;

: hello-n* ( obj -- val ) dup tag 2 eq? [ 2 slot ] [ 3 throw ] if ;

: foo ( obj -- obj n ) 0 100000000 [ over hello-n* + ] times ;

: typecheck-main ( -- ) 0 hello boa foo 2drop ;

MAIN: typecheck-main
