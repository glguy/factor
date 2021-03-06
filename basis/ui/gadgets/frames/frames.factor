! Copyright (C) 2005, 2007 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays generic kernel math namespaces sequences words
splitting grouping math.vectors ui.gadgets.grids ui.gadgets
math.geometry.rect ;
IN: ui.gadgets.frames

! A frame arranges gadgets in a 3x3 grid, where the center
! gadgets gets left-over space.
TUPLE: frame < grid ;

: <frame-grid> ( -- grid ) 9 [ <gadget> ] replicate 3 group ;

: @center 1 1 ;
: @left 0 1 ;
: @right 2 1 ;
: @top 1 0 ;
: @bottom 1 2 ;

: @top-left 0 0 ;
: @top-right 2 0 ;
: @bottom-left 0 2 ;
: @bottom-right 2 2 ;

: new-frame ( class -- frame )
    <frame-grid> swap new-grid ; inline

: <frame> ( -- frame )
    frame new-frame ;

: (fill-center) ( vec n -- )
    over first pick third v+ [v-] 1 rot set-nth ;

: fill-center ( horiz vert dim -- )
    tuck (fill-center) (fill-center) ;

M: frame layout*
    dup compute-grid
    [ rot rect-dim fill-center ] 3keep
    grid-layout ;
