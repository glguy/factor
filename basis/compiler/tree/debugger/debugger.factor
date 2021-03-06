! Copyright (C) 2006, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel assocs match fry accessors namespaces make effects
sequences sequences.private quotations generic macros arrays
prettyprint prettyprint.backend prettyprint.sections math words
combinators io sorting hints qualified
compiler.tree
compiler.tree.recursive
compiler.tree.normalization
compiler.tree.cleanup
compiler.tree.propagation
compiler.tree.propagation.info
compiler.tree.def-use
compiler.tree.builder
compiler.tree.optimizer
compiler.tree.combinators
compiler.tree.checker ;
RENAME: _ match => __
IN: compiler.tree.debugger

! A simple tool for turning tree IR into quotations and
! printing reports, for debugging purposes.

GENERIC: node>quot ( node -- )

MACRO: match-choose ( alist -- )
    [ '[ _ ] ] assoc-map '[ _ match-cond ] ;

MATCH-VARS: ?a ?b ?c ;

: pretty-shuffle ( effect -- word/f )
    [ in>> ] [ out>> ] bi 2array {
        { { { } { } } [ ] }
        { { { ?a } { ?a } } [ ] }
        { { { ?a ?b } { ?a ?b } } [ ] }
        { { { ?a ?b ?c } { ?a ?b ?c } } [ ] }
        { { { ?a } { } } [ drop ] }
        { { { ?a ?b } { } } [ 2drop ] }
        { { { ?a ?b ?c } { } } [ 3drop ] }
        { { { ?a } { ?a ?a } } [ dup ] }
        { { { ?a ?b } { ?a ?b ?a ?b } } [ 2dup ] }
        { { { ?a ?b ?c } { ?a ?b ?c ?a ?b ?c } } [ 3dup ] }
        { { { ?a ?b } { ?a ?b ?a } } [ over ] }
        { { { ?b ?a } { ?a ?b } } [ swap ] }
        { { { ?b ?a ?c } { ?a ?b ?c } } [ swapd ] }
        { { { ?a ?b } { ?a ?a ?b } } [ dupd ] }
        { { { ?a ?b } { ?b ?a ?b } } [ tuck ] }
        { { { ?a ?b ?c } { ?a ?b ?c ?a } } [ pick ] }
        { { { ?a ?b ?c } { ?c ?a ?b } } [ -rot ] }
        { { { ?a ?b ?c } { ?b ?c ?a } } [ rot ] }
        { { { ?a ?b } { ?b } } [ nip ] }
        { { { ?a ?b ?c } { ?c } } [ 2nip ] }
        { __ f }
    } match-choose ;

TUPLE: shuffle-node { effect effect } ;

M: shuffle-node pprint* effect>> effect>string text ;
 
M: #shuffle node>quot
    shuffle-effect dup pretty-shuffle
    [ % ] [ shuffle-node boa , ] ?if ;

M: #push node>quot literal>> , ;

M: #call node>quot word>> , ;

M: #call-recursive node>quot label>> id>> , ;

DEFER: nodes>quot

DEFER: label

M: #recursive node>quot
    [ label>> id>> literalize , ]
    [ child>> nodes>quot , \ label , ]
    bi ;

M: #if node>quot
    children>> [ nodes>quot ] map % \ if , ;

M: #dispatch node>quot
    children>> [ nodes>quot ] map , \ dispatch , ;

M: #>r node>quot
    [ in-d>> length ] [ out-r>> empty? \ drop \ >r ? ] bi
    <repetition> % ;

DEFER: rdrop

M: #r> node>quot
    [ in-r>> length ] [ out-d>> empty? \ rdrop \ r> ? ] bi
    <repetition> % ;

M: #alien-invoke node>quot params>> , \ #alien-invoke , ;

M: #alien-indirect node>quot params>> , \ #alien-indirect , ;

M: #alien-callback node>quot params>> , \ #alien-callback , ;

M: node node>quot drop ;

: nodes>quot ( node -- quot )
    [ [ node>quot ] each ] [ ] make ;

: optimized. ( quot/word -- )
    dup word? [ specialized-def ] when
    build-tree optimize-tree nodes>quot . ;

SYMBOL: words-called
SYMBOL: generics-called
SYMBOL: methods-called
SYMBOL: intrinsics-called
SYMBOL: node-count

: make-report ( word/quot -- assoc )
    [
        dup word? [ build-tree-from-word nip ] [ build-tree ] if
        optimize-tree

        H{ } clone words-called set
        H{ } clone generics-called set
        H{ } clone methods-called set
        H{ } clone intrinsics-called set

        0 swap [
            >r 1+ r>
            dup #call? [
                word>> {
                    { [ dup "intrinsics" word-prop over "if-intrinsics" word-prop or ] [ intrinsics-called ] }
                    { [ dup generic? ] [ generics-called ] }
                    { [ dup method-body? ] [ methods-called ] }
                    [ words-called ]
                } cond 1 -rot get at+
            ] [ drop ] if
        ] each-node
        node-count set
    ] H{ } make-assoc ;

: report. ( report -- )
    [
        "==== Total number of IR nodes:" print
        node-count get .

        {
            { generics-called "==== Generic word calls:" }
            { words-called "==== Ordinary word calls:" }
            { methods-called "==== Non-inlined method calls:" }
            { intrinsics-called "==== Open-coded intrinsic calls:" }
        } [
            nl print get keys natural-sort stack.
        ] assoc-each
    ] bind ;

: optimizer-report. ( word -- )
    make-report report. ;

! More utilities

: final-info ( quot -- seq )
    build-tree
    analyze-recursive
    normalize
    propagate
    compute-def-use
    dup check-nodes
    peek node-input-infos ;

: final-classes ( quot -- seq )
    final-info [ class>> ] map ;

: final-literals ( quot -- seq )
    final-info [ literal>> ] map ;

: cleaned-up-tree ( quot -- nodes )
    [
        check-optimizer? on
        build-tree optimize-tree 
    ] with-scope ;

: inlined? ( quot seq/word -- ? )
    [ cleaned-up-tree ] dip
    dup word? [ 1array ] when
    '[ dup #call? [ word>> _ member? ] [ drop f ] if ]
    contains-node? not ;
