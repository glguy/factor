! Copyright (C) 2004, 2007 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: math kernel math.constants math.private
math.libm combinators math.order ;
IN: math.functions

<PRIVATE

: (rect>) ( x y -- z )
    dup 0 = [ drop ] [ <complex> ] if ; inline

PRIVATE>

: rect> ( x y -- z )
    over real? over real? and [
        (rect>)
    ] [
        "Complex number must have real components" throw
    ] if ; inline

GENERIC: sqrt ( x -- y ) foldable

M: real sqrt
    >float dup 0.0 < [ neg fsqrt 0.0 swap rect> ] [ fsqrt ] if ;

: each-bit ( n quot: ( ? -- ) -- )
    over 0 = pick -1 = or [
        2drop
    ] [
        2dup >r >r >r odd? r> call r> 2/ r> each-bit
    ] if ; inline recursive

: ^n ( z w -- z^w )
    1 swap [
        [ dupd * ] when >r sq r>
    ] each-bit nip ; inline

: integer^ ( x y -- z )
    dup 0 > [ ^n ] [ neg ^n recip ] if ; inline

: >rect ( z -- x y )
    [ real-part ] [ imaginary-part ] bi ; inline

: >float-rect ( z -- x y )
    >rect [ >float ] bi@ ; inline

: >polar ( z -- abs arg )
    >float-rect [ [ sq ] bi@ + fsqrt ] [ swap fatan2 ] 2bi ;
    inline

: cis ( arg -- z ) dup fcos swap fsin rect> ; inline

: polar> ( abs arg -- z ) cis * ; inline

: ^mag ( w abs arg -- magnitude )
    >r >r >float-rect swap r> swap fpow r> rot * fexp /f ;
    inline

: ^theta ( w abs arg -- theta )
    >r >r >float-rect r> flog * swap r> * + ; inline

: ^complex ( x y -- z )
    swap >polar [ ^mag ] [ ^theta ] 3bi polar> ; inline

: real^? ( x y -- ? )
    2dup [ real? ] both? [ drop 0 >= ] [ 2drop f ] if ; inline

: 0^ ( x -- z )
    dup zero? [ drop 0./0. ] [ 0 < 1./0. 0 ? ] if ; inline

: ^ ( x y -- z )
    {
        { [ over zero? ] [ nip 0^ ] }
        { [ dup integer? ] [ integer^ ] }
        { [ 2dup real^? ] [ fpow ] }
        [ ^complex ]
    } cond ;

: (^mod) ( n x y -- z )
    1 swap [
        [ dupd * pick mod ] when >r sq over mod r>
    ] each-bit 2nip ; inline

: (gcd) ( b a x y -- a d )
    over zero? [
        2nip
    ] [
        swap [ /mod >r over * swapd - r> ] keep (gcd)
    ] if ;

: gcd ( x y -- a d )
    0 -rot 1 -rot (gcd) dup 0 < [ neg ] when ; foldable

: lcm ( a b -- c )
    [ * ] 2keep gcd nip /i ; foldable

: mod-inv ( x n -- y )
    tuck gcd 1 = [
        dup 0 < [ + ] [ nip ] if
    ] [
        "Non-trivial divisor found" throw
    ] if ; foldable

: ^mod ( x y n -- z )
    over 0 < [
        [ >r neg r> ^mod ] keep mod-inv
    ] [
        -rot (^mod)
    ] if ; foldable

GENERIC: absq ( x -- y ) foldable

M: real absq sq ;

: ~abs ( x y epsilon -- ? )
    >r - abs r> < ;

: ~rel ( x y epsilon -- ? )
    >r [ - abs ] 2keep [ abs ] bi@ + r> * < ;

: ~ ( x y epsilon -- ? )
    {
        { [ pick fp-nan? pick fp-nan? or ] [ 3drop f ] }
        { [ dup zero? ] [ drop number= ] }
        { [ dup 0 < ] [ ~rel ] }
        [ ~abs ]
    } cond ;

: conjugate ( z -- z* ) >rect neg rect> ; inline

: arg ( z -- arg ) >float-rect swap fatan2 ; inline

: [-1,1]? ( x -- ? )
    dup complex? [ drop f ] [ abs 1 <= ] if ; inline

: >=1? ( x -- ? )
    dup complex? [ drop f ] [ 1 >= ] if ; inline

GENERIC: exp ( x -- y )

M: real exp fexp ;

M: complex exp >rect swap fexp swap polar> ;

GENERIC: log ( x -- y )

M: real log dup 0.0 >= [ flog ] [ 0.0 rect> log ] if ;

M: complex log >polar swap flog swap rect> ;

: cos ( x -- y )
    dup complex? [
        >float-rect 2dup
        fcosh swap fcos * -rot
        fsinh swap fsin neg * rect>
    ] [ fcos ] if ; foldable

: sec ( x -- y ) cos recip ; inline

: cosh ( x -- y )
    dup complex? [
        >float-rect 2dup
        fcos swap fcosh * -rot
        fsin swap fsinh * rect>
    ] [ fcosh ] if ; foldable

: sech ( x -- y ) cosh recip ; inline

: sin ( x -- y )
    dup complex? [
        >float-rect 2dup
        fcosh swap fsin * -rot
        fsinh swap fcos * rect>
    ] [ fsin ] if ; foldable

: cosec ( x -- y ) sin recip ; inline

: sinh ( x -- y )
    dup complex? [
        >float-rect 2dup
        fcos swap fsinh * -rot
        fsin swap fcosh * rect>
    ] [ fsinh ] if ; foldable

: cosech ( x -- y ) sinh recip ; inline

: tan ( x -- y )
    dup complex? [ dup sin swap cos / ] [ ftan ] if ; inline

: tanh ( x -- y )
    dup complex? [ dup sinh swap cosh / ] [ ftanh ] if ; inline

: cot ( x -- y ) tan recip ; inline

: coth ( x -- y ) tanh recip ; inline

: acosh ( x -- y )
    dup sq 1- sqrt + log ; inline

: asech ( x -- y ) recip acosh ; inline

: asinh ( x -- y )
    dup sq 1+ sqrt + log ; inline

: acosech ( x -- y ) recip asinh ; inline

: atanh ( x -- y )
    dup 1+ swap 1- neg / log 2 / ; inline

: acoth ( x -- y ) recip atanh ; inline

: i* ( x -- y ) >rect neg swap rect> ;

: -i* ( x -- y ) >rect swap neg rect> ;

: asin ( x -- y )
    dup [-1,1]? [ fasin ] [ i* asinh -i* ] if ; inline

: acos ( x -- y )
    dup [-1,1]? [ facos ] [ asin pi 2 / swap - ] if ;
    inline

: atan ( x -- y )
    dup complex? [ i* atanh i* ] [ fatan ] if ; inline

: asec ( x -- y ) recip acos ; inline

: acosec ( x -- y ) recip asin ; inline

: acot ( x -- y ) recip atan ; inline

: truncate ( x -- y ) dup 1 mod - ; inline

: round ( x -- y ) dup sgn 2 / + truncate ; inline

: floor ( x -- y )
    dup 1 mod dup zero?
    [ drop ] [ dup 0 < [ - 1- ] [ - ] if ] if ; foldable

: ceiling ( x -- y ) neg floor neg ; foldable
