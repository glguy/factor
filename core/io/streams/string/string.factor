! Copyright (C) 2003, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors io kernel math namespaces sequences sbufs
strings generic splitting continuations destructors
io.streams.plain io.encodings math.order growable ;
IN: io.streams.string

M: growable dispose drop ;

M: growable stream-write1 push ;
M: growable stream-write push-all ;
M: growable stream-flush drop ;

: <string-writer> ( -- stream )
    512 <sbuf> ;

: with-string-writer ( quot -- str )
    <string-writer> swap [ output-stream get ] compose with-output-stream*
    >string ; inline

M: growable stream-read1 [ f ] [ pop ] if-empty ;

: harden-as ( seq growble-exemplar -- newseq )
    underlying>> like ;

: growable-read-until ( growable n -- str )
    >fixnum dupd tail-slice swap harden-as dup reverse-here ;

: find-last-sep ( seq seps -- n )
    swap [ memq? ] curry find-last drop ;

M: growable stream-read-until
    [ find-last-sep ] keep over [
        [ swap 1+ growable-read-until ] 2keep [ nth ] 2keep
        set-length
    ] [
        [ swap drop 0 growable-read-until f like f ] keep
        delete-all
    ] if ;

M: growable stream-read
    [
        drop f
    ] [
        [ length swap - 0 max ] keep
        [ swap growable-read-until ] 2keep
        set-length
    ] if-empty ;

M: growable stream-read-partial
    stream-read ;

SINGLETON: null
M: null decode-char drop stream-read1 ;

: <string-reader> ( str -- stream )
    >sbuf dup reverse-here null <decoder> ;

: with-string-reader ( str quot -- )
    >r <string-reader> r> with-input-stream ; inline

INSTANCE: growable plain-writer

: format-column ( seq ? -- seq )
    [
        [ 0 [ length max ] reduce ] keep
        swap [ CHAR: \s pad-right ] curry map
    ] unless ;

: map-last ( seq quot -- seq )
    >r dup length <reversed> [ zero? ] r> compose 2map ; inline

: format-table ( table -- seq )
    flip [ format-column ] map-last
    flip [ " " join ] map ;

M: plain-writer stream-write-table
    [ drop format-table [ print ] each ] with-output-stream* ;

M: plain-writer make-cell-stream 2drop <string-writer> ;
