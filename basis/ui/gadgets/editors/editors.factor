! Copyright (C) 2006, 2008 Slava Pestov
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays documents io kernel math models
namespaces make opengl opengl.gl sequences strings io.styles
math.vectors sorting colors combinators assocs math.order
ui.clipboards ui.commands ui.gadgets ui.gadgets.borders
ui.gadgets.buttons ui.gadgets.labels ui.gadgets.scrollers
ui.gadgets.theme ui.gadgets.wrappers ui.render ui.gestures
math.geometry.rect ;
IN: ui.gadgets.editors

TUPLE: editor < gadget
font color caret-color selection-color
caret mark
focused? ;

: <loc> ( -- loc ) { 0 0 } <model> ;

: init-editor-locs ( editor -- editor )
    <loc> >>caret
    <loc> >>mark ; inline

: editor-theme ( editor -- editor )
    black >>color
    red >>caret-color
    selection-color >>selection-color
    monospace-font >>font ; inline

: new-editor ( class -- editor )
    new-gadget
        <document> >>model
        init-editor-locs
        editor-theme ; inline

: <editor> ( -- editor )
    editor new-editor ;

: activate-editor-model ( editor model -- )
    2dup add-connection
    dup activate-model
    swap model>> add-loc ;

: deactivate-editor-model ( editor model -- )
    2dup remove-connection
    dup deactivate-model
    swap model>> remove-loc ;

M: editor graft*
    dup
    dup caret>> activate-editor-model
    dup mark>> activate-editor-model ;

M: editor ungraft*
    dup
    dup caret>> deactivate-editor-model
    dup mark>> deactivate-editor-model ;

: editor-caret* ( editor -- loc ) caret>> value>> ;

: editor-mark* ( editor -- loc ) mark>> value>> ;

: set-caret ( loc editor -- )
    [ model>> validate-loc ] keep
    caret>> set-model ;

: change-caret ( editor quot -- )
    over >r >r dup editor-caret* swap model>> r> call r>
    set-caret ; inline

: mark>caret ( editor -- )
    dup editor-caret* swap mark>> set-model ;

: change-caret&mark ( editor quot -- )
    over >r change-caret r> mark>caret ; inline

: editor-line ( n editor -- str ) control-value nth ;

: editor-font* ( editor -- font ) font>> open-font ;

: line-height ( editor -- n )
    editor-font* "" string-height ;

: y>line ( y editor -- line# )
    [ line-height / >fixnum ] keep model>> validate-line ;

: point>loc ( point editor -- loc )
    [
        >r first2 r> tuck y>line dup ,
        >r dup editor-font* r>
        rot editor-line x>offset ,
    ] { } make ;

: clicked-loc ( editor -- loc )
    [ hand-rel ] keep point>loc ;

: click-loc ( editor model -- )
    >r clicked-loc r> set-model ;

: focus-editor ( editor -- ) t >>focused? relayout-1 ;

: unfocus-editor ( editor -- ) f >>focused? relayout-1 ;

: (offset>x) ( font col# str -- x )
    swap head-slice string-width ;

: offset>x ( col# line# editor -- x )
    [ editor-line ] keep editor-font* -rot (offset>x) ;

: loc>x ( loc editor -- x ) >r first2 swap r> offset>x ;

: line>y ( lines# editor -- y )
    line-height * ;

: caret-loc ( editor -- loc )
    [ editor-caret* ] keep 2dup loc>x
    rot first rot line>y 2array ;

: caret-dim ( editor -- dim )
    line-height 0 swap 2array ;

: scroll>caret ( editor -- )
    dup graft-state>> second [
        dup caret-loc over caret-dim { 1 0 } v+ <rect>
        over scroll>rect
    ] when drop ;

: draw-caret ( -- )
    editor get focused?>> [
        editor get
        dup caret-color>> set-color
        dup caret-loc origin get v+
        swap caret-dim over v+
        [ { 0.5 -0.5 } v+ ] bi@ gl-line
    ] when ;

: line-translation ( n -- loc )
    editor get line-height * 0.0 swap 2array ;

: translate-lines ( n -- )
    line-translation gl-translate ;

: draw-line ( editor str -- )
    >r font>> r> { 0 0 } draw-string ;

: first-visible-line ( editor -- n )
    clip get rect-loc second origin get second -
    swap y>line ;

: last-visible-line ( editor -- n )
    clip get rect-extent nip second origin get second -
    swap y>line 1+ ;

: with-editor ( editor quot -- )
    [
        swap
        dup first-visible-line \ first-visible-line set
        dup last-visible-line \ last-visible-line set
        dup model>> document set
        editor set
        call
    ] with-scope ; inline

: visible-lines ( editor -- seq )
    \ first-visible-line get
    \ last-visible-line get
    rot control-value <slice> ;

: with-editor-translation ( n quot -- )
    >r line-translation origin get v+ r> with-translation ;
    inline

: draw-lines ( -- )
    \ first-visible-line get [
        editor get dup color>> set-color
        dup visible-lines
        [ draw-line 1 translate-lines ] with each
    ] with-editor-translation ;

: selection-start/end ( editor -- start end )
    dup editor-mark* swap editor-caret* sort-pair ;

: (draw-selection) ( x1 x2 -- )
    2dup = [ 2 + ] when
    0.0 swap editor get line-height glRectd ;

: draw-selected-line ( start end n -- )
    [ start/end-on-line ] keep tuck
    >r >r editor get offset>x r> r>
    editor get offset>x
    (draw-selection) ;

: draw-selection ( -- )
    editor get selection-color>> set-color
    editor get selection-start/end
    over first [
        2dup [
            >r 2dup r> draw-selected-line
            1 translate-lines
        ] each-line 2drop
    ] with-editor-translation ;

M: editor draw-gadget*
    [ draw-selection draw-lines draw-caret ] with-editor ;

M: editor pref-dim*
    dup editor-font* swap control-value text-dim ;

: contents-changed ( model editor -- )
    swap
    over caret>> [ over validate-loc ] (change-model)
    over mark>> [ over validate-loc ] (change-model)
    drop relayout ;

: caret/mark-changed ( model editor -- )
    nip [ relayout-1 ] [ scroll>caret ] bi ;

M: editor model-changed
    {
        { [ 2dup model>> eq? ] [ contents-changed ] }
        { [ 2dup caret>> eq? ] [ caret/mark-changed ] }
        { [ 2dup mark>> eq? ] [ caret/mark-changed ] }
    } cond ;

M: editor gadget-selection?
    selection-start/end = not ;

M: editor gadget-selection
    [ selection-start/end ] keep model>> doc-range ;

: remove-selection ( editor -- )
    [ selection-start/end ] keep model>> remove-doc-range ;

M: editor user-input*
    [ selection-start/end ] keep model>> set-doc-range t ;

: editor-string ( editor -- string )
    model>> doc-string ;

: set-editor-string ( string editor -- )
    model>> set-doc-string ;

M: editor gadget-text* editor-string % ;

: extend-selection ( editor -- )
    dup request-focus dup caret>> click-loc ;

: mouse-elt ( -- element )
    hand-click# get {
        { 1 T{ one-char-elt } }
        { 2 T{ one-word-elt } }
    } at T{ one-line-elt } or ;

: drag-direction? ( loc editor -- ? )
    editor-mark* before? ;

: drag-selection-caret ( loc editor element -- loc )
    >r [ drag-direction? ] 2keep
    model>>
    r> prev/next-elt ? ;

: drag-selection-mark ( loc editor element -- loc )
    >r [ drag-direction? not ] 2keep
    nip dup editor-mark* swap model>>
    r> prev/next-elt ? ;

: drag-caret&mark ( editor -- caret mark )
    dup clicked-loc swap mouse-elt
    [ drag-selection-caret ] 3keep
    drag-selection-mark ;

: drag-selection ( editor -- )
    dup drag-caret&mark
    pick mark>> set-model
    swap caret>> set-model ;

: editor-cut ( editor clipboard -- )
    dupd gadget-copy remove-selection ;

: delete/backspace ( elt editor quot -- )
    over gadget-selection? [
        drop nip remove-selection
    ] [
        over >r >r dup editor-caret* swap model>>
        r> call r> model>> remove-doc-range
    ] if ; inline

: editor-delete ( editor elt -- )
    swap [ over >r rot next-elt r> swap ] delete/backspace ;

: editor-backspace ( editor elt -- )
    swap [ over >r rot prev-elt r> ] delete/backspace ;

: editor-select-prev ( editor elt -- )
    swap [ rot prev-elt ] change-caret ;

: editor-prev ( editor elt -- )
    dupd editor-select-prev mark>caret ;

: editor-select-next ( editor elt -- )
    swap [ rot next-elt ] change-caret ;

: editor-next ( editor elt -- )
    dupd editor-select-next mark>caret ;

: editor-select ( from to editor -- )
    tuck caret>> set-model mark>> set-model ;

: select-elt ( editor elt -- )
    over >r
    >r dup editor-caret* swap model>> r> prev/next-elt
    r> editor-select ;

: start-of-document ( editor -- ) T{ doc-elt } editor-prev ;

: end-of-document ( editor -- ) T{ doc-elt } editor-next ;

: position-caret ( editor -- )
    mouse-elt dup T{ one-char-elt } =
    [ drop dup extend-selection dup mark>> click-loc ]
    [ select-elt ] if ;

: insert-newline ( editor -- ) "\n" swap user-input ;

: delete-next-character ( editor -- ) 
    T{ char-elt } editor-delete ;

: delete-previous-character ( editor -- ) 
    T{ char-elt } editor-backspace ;

: delete-previous-word ( editor -- ) 
    T{ word-elt } editor-delete ;

: delete-next-word ( editor -- ) 
    T{ word-elt } editor-backspace ;

: delete-to-start-of-line ( editor -- ) 
    T{ one-line-elt } editor-delete ;

: delete-to-end-of-line ( editor -- ) 
    T{ one-line-elt } editor-backspace ;

editor "general" f {
    { T{ key-down f f "DELETE" } delete-next-character }
    { T{ key-down f { S+ } "DELETE" } delete-next-character }
    { T{ key-down f f "BACKSPACE" } delete-previous-character }
    { T{ key-down f { S+ } "BACKSPACE" } delete-previous-character }
    { T{ key-down f { C+ } "DELETE" } delete-previous-word }
    { T{ key-down f { C+ } "BACKSPACE" } delete-next-word }
    { T{ key-down f { A+ } "DELETE" } delete-to-start-of-line }
    { T{ key-down f { A+ } "BACKSPACE" } delete-to-end-of-line }
} define-command-map

: paste ( editor -- ) clipboard get paste-clipboard ;

: paste-selection ( editor -- ) selection get paste-clipboard ;

: cut ( editor -- ) clipboard get editor-cut ;

editor "clipboard" f {
    { T{ paste-action } paste }
    { T{ button-up f f 2 } paste-selection }
    { T{ copy-action } com-copy }
    { T{ button-up } com-copy-selection }
    { T{ cut-action } cut }
} define-command-map

: previous-character ( editor -- )
    dup gadget-selection? [
        dup selection-start/end drop
        over set-caret mark>caret
    ] [
        T{ char-elt } editor-prev
    ] if ;

: next-character ( editor -- )
    dup gadget-selection? [
        dup selection-start/end nip
        over set-caret mark>caret
    ] [
        T{ char-elt } editor-next
    ] if ;

: previous-line ( editor -- ) T{ line-elt } editor-prev ;

: next-line ( editor -- ) T{ line-elt } editor-next ;

: previous-word ( editor -- ) T{ word-elt } editor-prev ;

: next-word ( editor -- ) T{ word-elt } editor-next ;

: start-of-line ( editor -- ) T{ one-line-elt } editor-prev ;

: end-of-line ( editor -- ) T{ one-line-elt } editor-next ;

editor "caret-motion" f {
    { T{ button-down } position-caret }
    { T{ key-down f f "LEFT" } previous-character }
    { T{ key-down f f "RIGHT" } next-character }
    { T{ key-down f f "UP" } previous-line }
    { T{ key-down f f "DOWN" } next-line }
    { T{ key-down f { C+ } "LEFT" } previous-word }
    { T{ key-down f { C+ } "RIGHT" } next-word }
    { T{ key-down f f "HOME" } start-of-line }
    { T{ key-down f f "END" } end-of-line }
    { T{ key-down f { C+ } "HOME" } start-of-document }
    { T{ key-down f { C+ } "END" } end-of-document }
} define-command-map

: select-all ( editor -- ) T{ doc-elt } select-elt ;

: select-line ( editor -- ) T{ one-line-elt } select-elt ;

: select-word ( editor -- ) T{ one-word-elt } select-elt ;

: selected-word ( editor -- string )
    dup gadget-selection?
    [ dup select-word ] unless
    gadget-selection ;

: select-previous-character ( editor -- ) 
    T{ char-elt } editor-select-prev ;

: select-next-character ( editor -- ) 
    T{ char-elt } editor-select-next ;

: select-previous-line ( editor -- ) 
    T{ line-elt } editor-select-prev ;

: select-next-line ( editor -- ) 
    T{ line-elt } editor-select-next ;

: select-previous-word ( editor -- ) 
    T{ word-elt } editor-select-prev ;

: select-next-word ( editor -- ) 
    T{ word-elt } editor-select-next ;

: select-start-of-line ( editor -- ) 
    T{ one-line-elt } editor-select-prev ;

: select-end-of-line ( editor -- ) 
    T{ one-line-elt } editor-select-next ;

: select-start-of-document ( editor -- ) 
    T{ doc-elt } editor-select-prev ;

: select-end-of-document ( editor -- ) 
    T{ doc-elt } editor-select-next ;

editor "selection" f {
    { T{ button-down f { S+ } } extend-selection }
    { T{ drag } drag-selection }
    { T{ gain-focus } focus-editor }
    { T{ lose-focus } unfocus-editor }
    { T{ delete-action } remove-selection }
    { T{ select-all-action } select-all }
    { T{ key-down f { C+ } "l" } select-line }
    { T{ key-down f { S+ } "LEFT" } select-previous-character }
    { T{ key-down f { S+ } "RIGHT" } select-next-character }
    { T{ key-down f { S+ } "UP" } select-previous-line }
    { T{ key-down f { S+ } "DOWN" } select-next-line }
    { T{ key-down f { S+ C+ } "LEFT" } select-previous-word }
    { T{ key-down f { S+ C+ } "RIGHT" } select-next-word }
    { T{ key-down f { S+ } "HOME" } select-start-of-line }
    { T{ key-down f { S+ } "END" } select-end-of-line }
    { T{ key-down f { S+ C+ } "HOME" } select-start-of-document }
    { T{ key-down f { S+ C+ } "END" } select-end-of-document }
} define-command-map

! Multi-line editors
TUPLE: multiline-editor < editor ;

: <multiline-editor> ( -- editor )
    multiline-editor new-editor ;

multiline-editor "general" f {
    { T{ key-down f f "RET" } insert-newline }
    { T{ key-down f { S+ } "RET" } insert-newline }
    { T{ key-down f f "ENTER" } insert-newline }
} define-command-map

TUPLE: source-editor < multiline-editor ;

: <source-editor> ( -- editor )
    source-editor new-editor ;

! Fields wrap an editor and edit an external model
TUPLE: field < wrapper field-model editor ;

: field-theme ( gadget -- gadget )
    gray <solid> >>boundary ; inline

: <field-border> ( gadget -- border )
    2 <border>
        { 1 0 } >>fill
        field-theme ;

: <field> ( model -- gadget )
    <editor> dup <field-border> field new-wrapper
        swap >>editor
        swap >>field-model ;

M: field graft*
    [ [ field-model>> value>> ] [ editor>> ] bi set-editor-string ]
    [ dup editor>> model>> add-connection ]
    bi ;

M: field ungraft*
    dup editor>> model>> remove-connection ;

M: field model-changed
    nip [ editor>> editor-string ] [ field-model>> ] bi set-model ;
