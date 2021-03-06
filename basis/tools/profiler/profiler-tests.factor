IN: tools.profiler.tests
USING: accessors tools.profiler tools.test kernel memory math
threads alien tools.profiler.private sequences compiler.units ;

[ t ] [
    \ length counter>>
    10 [ { } length drop ] times
    \ length counter>> =
] unit-test

[ ] [ [ 10 [ gc ] times ] profile ] unit-test

[ ] [ [ 1000 sleep ] profile ] unit-test 

[ ] [ profile. ] unit-test

[ ] [ vocabs-profile. ] unit-test

[ ] [ "kernel.private" vocab-profile. ] unit-test

[ ] [ \ + usage-profile. ] unit-test

: callback-test ( -- callback ) "void" { } "cdecl" [ ] alien-callback ;

: indirect-test ( callback -- ) "void" { } "cdecl" alien-indirect ;

: foobar ;

[
    [ ] [ callback-test indirect-test ] unit-test
    foobar
] profile

[ 1 ] [ \ foobar counter>> ] unit-test

: fooblah { } [ ] each ;

: foobaz fooblah fooblah ;

[ foobaz ] profile

[ 1 ] [ \ foobaz counter>> ] unit-test

[ 2 ] [ \ fooblah counter>> ] unit-test

: recompile-while-profiling-test ( -- ) ;

[ ] [
    [
        333 [ recompile-while-profiling-test ] times
        { recompile-while-profiling-test } compile
        333 [ recompile-while-profiling-test ] times
    ] profile
] unit-test

[ 666 ] [ \ recompile-while-profiling-test counter>> ] unit-test
