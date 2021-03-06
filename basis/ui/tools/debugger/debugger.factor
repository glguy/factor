! Copyright (C) 2006, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays ui ui.commands ui.gestures ui.gadgets
       ui.gadgets.worlds ui.gadgets.packs ui.gadgets.buttons
       ui.gadgets.labels ui.gadgets.panes ui.gadgets.presentations
       ui.gadgets.viewports ui.gadgets.lists ui.gadgets.tracks
       ui.gadgets.scrollers ui.gadgets.panes hashtables io kernel math
       models namespaces sequences sequences words continuations
       debugger prettyprint ui.tools.traceback help editors ;

IN: ui.tools.debugger

: <restart-list> ( restarts restart-hook -- gadget )
    [ name>> ] rot <model> <list> ;

TUPLE: debugger < track restarts ;

: <debugger-display> ( restart-list error -- gadget )
    <filled-pile>
        <pane>
            swapd tuck [ print-error ] with-pane
        add-gadget

        swap add-gadget ;

: <debugger> ( error restarts restart-hook -- gadget )
    { 0 1 } debugger new-track
        dup <toolbar> f track-add
        -rot <restart-list> >>restarts
        dup restarts>> rot <debugger-display> <scroller> 1 track-add ;

M: debugger focusable-child* restarts>> ;

: debugger-window ( error -- )
    #! No restarts for the debugger window
    f [ drop ] <debugger> "Error" open-window ;

[ debugger-window ] ui-error-hook set-global

M: world-error error.
    "An error occurred while drawing the world " write
    dup world>> pprint-short "." print
    "This world has been deactivated to prevent cascading errors." print
    error>> error. ;

debugger "gestures" f {
    { T{ button-down } request-focus }
} define-command-map

: com-traceback ( -- ) error-continuation get traceback-window ;

\ com-traceback H{ { +nullary+ t } } define-command

\ :help H{ { +nullary+ t } { +listener+ t } } define-command

\ :edit H{ { +nullary+ t } { +listener+ t } } define-command

debugger "toolbar" f {
    { T{ key-down f f "s" } com-traceback }
    { T{ key-down f f "h" } :help }
    { T{ key-down f f "e" } :edit }
} define-command-map
