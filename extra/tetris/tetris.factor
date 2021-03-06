! Copyright (C) 2006, 2007, 2008 Alex Chapman
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alarms arrays calendar kernel make math math.geometry.rect math.parser namespaces sequences system tetris.game tetris.gl ui.gadgets ui.gadgets.labels ui.gadgets.worlds ui.gadgets.status-bar ui.gestures ui.render ui ;
IN: tetris

TUPLE: tetris-gadget < gadget { tetris tetris } { alarm } ;

: <tetris-gadget> ( tetris -- gadget )
    tetris-gadget new-gadget swap >>tetris ;

M: tetris-gadget pref-dim* drop { 200 400 } ;

: update-status ( gadget -- )
    dup tetris>> [
        "Level: " % dup level>> #
        " Score: " % score>> #
    ] "" make swap show-status ;

M: tetris-gadget draw-gadget* ( gadget -- )
    [
        dup rect-dim [ first ] [ second ] bi rot tetris>> draw-tetris
    ] keep update-status ;

: new-tetris ( gadget -- gadget )
    [ <new-tetris> ] change-tetris ;

tetris-gadget H{
    { T{ key-down f f "UP" }     [ tetris>> rotate-right ] }
    { T{ key-down f f "d" }      [ tetris>> rotate-left ] }
    { T{ key-down f f "f" }      [ tetris>> rotate-right ] }
    { T{ key-down f f "e" }      [ tetris>> rotate-left ] } ! dvorak d
    { T{ key-down f f "u" }      [ tetris>> rotate-right ] } ! dvorak f
    { T{ key-down f f "LEFT" }   [ tetris>> move-left ] }
    { T{ key-down f f "RIGHT" }  [ tetris>> move-right ] }
    { T{ key-down f f "DOWN" }   [ tetris>> move-down ] }
    { T{ key-down f f " " }      [ tetris>> move-drop ] }
    { T{ key-down f f "p" }      [ tetris>> toggle-pause ] }
    { T{ key-down f f "n" }      [ new-tetris drop ] }
} set-gestures

: tick ( gadget -- )
    [ tetris>> ?update ] [ relayout-1 ] bi ;

M: tetris-gadget graft* ( gadget -- )
    [ [ tick ] curry 100 milliseconds every ] keep (>>alarm) ;

M: tetris-gadget ungraft* ( gadget -- )
    [ cancel-alarm f ] change-alarm drop ;

: tetris-window ( -- ) 
    [
        <default-tetris> <tetris-gadget>
        "Tetris" open-status-window
    ] with-ui ;

MAIN: tetris-window
