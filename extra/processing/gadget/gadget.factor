
USING: kernel namespaces combinators
       ui.gestures accessors ui.gadgets.frame-buffer ;

IN: processing.gadget

! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

TUPLE: processing-gadget < frame-buffer button-down button-up key-down key-up ;

: <processing-gadget> ( -- gadget ) processing-gadget new-frame-buffer ;

! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

SYMBOL: mouse-pressed-value
SYMBOL: key-pressed-value

SYMBOL: button-value
SYMBOL: key-value

: key-pressed?   ( -- ? ) key-pressed-value   get ;
: mouse-pressed? ( -- ? ) mouse-pressed-value get ;

: key    ( -- key ) key-value    get ;
: button ( -- val ) button-value get ;

! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

M: processing-gadget handle-gesture ( gesture gadget -- ? )
   swap
   {
     {
       [ dup key-down? ]
       [
         sym>> key-value set
         key-pressed-value on
         key-down>> dup [ call ] [ drop ] if
         t
       ]
     }
     {
       [ dup key-up?   ]
       [
         key-pressed-value off
         drop
         key-up>> dup [ call ] [ drop ] if
         t
       ] }
     {
       [ dup button-down? ]
       [
         #>> button-value set
         mouse-pressed-value on
         button-down>> dup [ call ] [ drop ] if
         t
       ]
     }
     {
       [ dup button-up? ]
       [
         mouse-pressed-value off
         drop
         button-up>> dup [ call ] [ drop ] if
         t
       ]
     }
     { [ t ] [ 2drop t ] }
   }
   cond ;
