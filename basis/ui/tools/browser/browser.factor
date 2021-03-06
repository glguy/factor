! Copyright (C) 2006, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: debugger ui.tools.workspace help help.topics kernel
models models.history ui.commands ui.gadgets ui.gadgets.panes
ui.gadgets.scrollers ui.gadgets.tracks ui.gestures
ui.gadgets.buttons compiler.units assocs words vocabs
accessors ;
IN: ui.tools.browser

TUPLE: browser-gadget < track pane history ;

: show-help ( link help -- )
    dup history>> add-history
    >r >link r> history>> set-model ;

: <help-pane> ( browser-gadget -- gadget )
    history>> [ [ help ] curry try ] <pane-control> ;

: init-history ( browser-gadget -- )
    "handbook" >link <history> >>history drop ;

: <browser-gadget> ( -- gadget )
    { 0 1 } browser-gadget new-track
        dup init-history
        dup <toolbar> f track-add
        dup <help-pane> >>pane
        dup pane>> <scroller> 1 track-add ;

M: browser-gadget call-tool* show-help ;

M: browser-gadget tool-scroller
    pane>> find-scroller ;

M: browser-gadget graft*
    [ add-definition-observer ] [ call-next-method ] bi ;

M: browser-gadget ungraft*
    [ call-next-method ] [ remove-definition-observer ] bi ;

: showing-definition? ( defspec assoc -- ? )
    [ key? ] 2keep
    [ >r dup word-link? [ name>> ] when r> key? ] 2keep
    >r dup vocab-link? [ vocab ] when r> key?
    or or ;

M: browser-gadget definitions-changed ( assoc browser -- )
    history>>
    dup value>> rot showing-definition?
    [ notify-connections ] [ drop ] if ;

: help-action ( browser-gadget -- link )
    history>> value>> >link ;

: com-follow ( link -- ) browser-gadget call-tool ;

: com-back ( browser -- ) history>> go-back ;

: com-forward ( browser -- ) history>> go-forward ;

: com-documentation ( browser -- ) "handbook" swap show-help ;

: com-vocabularies ( browser -- ) "vocab-index" swap show-help ;

: browser-help ( -- ) "ui-browser" help-window ;

\ browser-help H{ { +nullary+ t } } define-command

browser-gadget "toolbar" f {
    { T{ key-down f { A+ } "b" } com-back }
    { T{ key-down f { A+ } "f" } com-forward }
    { T{ key-down f { A+ } "h" } com-documentation }
    { T{ key-down f { A+ } "v" } com-vocabularies }
    { T{ key-down f f "F1" } browser-help }
} define-command-map

browser-gadget "multi-touch" f {
    { T{ left-action } com-back }
    { T{ right-action } com-forward }
} define-command-map
