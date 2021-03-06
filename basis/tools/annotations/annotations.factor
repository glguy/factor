! Copyright (C) 2005, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel words parser io summary quotations
sequences prettyprint continuations effects definitions
compiler.units namespaces assocs tools.walker generic
inspector fry ;
IN: tools.annotations

GENERIC: reset ( word -- )

M: generic reset
    [ call-next-method ]
    [ subwords [ reset ] each ] bi ;

M: word reset
    dup "unannotated-def" word-prop [
        [
            dup dup "unannotated-def" word-prop define
        ] with-compilation-unit
        f "unannotated-def" set-word-prop
    ] [ drop ] if ;

: annotate ( word quot -- )
    over "unannotated-def" word-prop [
        "Cannot annotate a word twice" throw
    ] when
    [
        over dup def>> "unannotated-def" set-word-prop
        >r dup def>> r> call define
    ] with-compilation-unit ; inline

: word-inputs ( word -- seq )
    stack-effect [
        >r datastack r> in>> length tail*
    ] [
        datastack
    ] if* ;

: entering ( str -- )
    "/-- Entering: " write dup .
    word-inputs stack.
    "\\--" print flush ;

: leaving ( str -- )
    "/-- Leaving: " write dup .
    stack-effect [
        >r datastack r> out>> length tail* stack.
    ] [
        .s
    ] if* "\\--" print flush ;

: (watch) ( word def -- def ) over '[ _ entering @ _ leaving ] ;

: watch ( word -- )
    dup [ (watch) ] annotate ;

: (watch-vars) ( quot word vars -- newquot )
    rot
   '[
        "--- Entering: "       write _ .
        "--- Variable values:" print _ [ dup get ] H{ } map>assoc describe
        @
    ] ;

: watch-vars ( word vars -- )
    dupd [ (watch-vars) ] 2curry annotate ;

GENERIC# annotate-methods 1 ( word quot -- )

M: generic annotate-methods
    >r "methods" word-prop values r> [ annotate ] curry each ;

M: word annotate-methods
    annotate ;

: breakpoint ( word -- )
    [ add-breakpoint ] annotate-methods ;

: breakpoint-if ( word quot -- )
    [ [ [ break ] when ] rot 3append ] curry annotate-methods ;
