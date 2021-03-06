! Copyright (C) 2007, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel kernel.private alien.accessors sequences
sequences.private math math.private byte-arrays accessors
alien.c-types parser prettyprint.backend ;
IN: float-arrays

TUPLE: float-array
{ length array-capacity read-only }
{ underlying byte-array read-only } ;

: <float-array> ( n -- float-array )
    dup "double" <c-array> float-array boa ; inline

M: float-array clone
    [ length>> ] [ underlying>> clone ] bi float-array boa ;

M: float-array length length>> ;

M: float-array nth-unsafe
    underlying>> double-nth ;

M: float-array set-nth-unsafe
    [ >float ] 2dip underlying>> set-double-nth ;

: >float-array ( seq -- float-array )
    T{ float-array } clone-like ; inline

M: float-array like
    drop dup float-array? [ >float-array ] unless ;

M: float-array new-sequence
    drop <float-array> ;

M: float-array equal?
    over float-array? [ sequence= ] [ 2drop f ] if ;

M: float-array resize
    [ drop ] [
        [ "double" heap-size * ] [ underlying>> ] bi*
        resize-byte-array
    ] 2bi
    float-array boa ;

M: float-array byte-length length "double" heap-size * ;

INSTANCE: float-array sequence

: 1float-array ( x -- array )
    1 <float-array> [ set-first ] keep ; inline

: 2float-array ( x y -- array )
    T{ float-array } 2sequence ; inline

: 3float-array ( x y z -- array )
    T{ float-array } 3sequence ; inline

: 4float-array ( w x y z -- array )
    T{ float-array } 4sequence ; inline

: F{ \ } [ >float-array ] parse-literal ; parsing

M: float-array pprint-delims drop \ F{ \ } ;
M: float-array >pprint-sequence ;
M: float-array pprint* pprint-object ;

! Rice
USING: hints math.vectors arrays ;

HINTS: vneg { float-array } { array } ;
HINTS: v*n { float-array float } { array object } ;
HINTS: n*v { float float-array } { array object } ;
HINTS: v/n { float-array float } { array object } ;
HINTS: n/v { float float-array } { object array } ;
HINTS: v+ { float-array float-array } { array array } ;
HINTS: v- { float-array float-array } { array array } ;
HINTS: v* { float-array float-array } { array array } ;
HINTS: v/ { float-array float-array } { array array } ;
HINTS: vmax { float-array float-array } { array array } ;
HINTS: vmin { float-array float-array } { array array } ;
HINTS: v. { float-array float-array } { array array } ;
HINTS: norm-sq { float-array } { array } ;
HINTS: norm { float-array } { array } ;
HINTS: normalize { float-array } { array } ;

! More rice. Experimental, currently causes a slowdown in raytracer
! for some odd reason.

USING: words classes.algebra compiler.tree.propagation.info ;

{ v+ v- v* v/ vmax vmin } [
    [
        [ class>> float-array class<= ] both?
        float-array object ? <class-info>
    ] "outputs" set-word-prop
] each

{ n*v n/v } [
    [
        nip class>> float-array class<= float-array object ? <class-info>
    ] "outputs" set-word-prop
] each

{ v*n v/n } [
    [
        drop class>> float-array class<= float-array object ? <class-info>
    ] "outputs" set-word-prop
] each

{ vneg normalize } [
    [
        class>> float-array class<= float-array object ? <class-info>
    ] "outputs" set-word-prop
] each

\ norm-sq [
    class>> float-array class<= float object ? <class-info>
] "outputs" set-word-prop

\ v. [
    [ class>> float-array class<= ] both?
    float object ? <class-info>
] "outputs" set-word-prop
