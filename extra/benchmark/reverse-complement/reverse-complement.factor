USING: io io.files io.streams.duplex kernel sequences
sequences.private strings vectors words memoize splitting
grouping hints tr continuations io.encodings.ascii
unicode.case ;
IN: benchmark.reverse-complement

TR: trans-map ch>upper "ACGTUMRYKVHDB" "TGCAAKYRMBDHV" ;

: translate-seq ( seq -- str )
    concat dup reverse-here dup trans-map-fast ;

: show-seq ( seq -- )
    translate-seq 60 <groups> [ print ] each ;

: do-line ( seq line -- seq )
    dup first ">;" memq?
    [ over show-seq print dup delete-all ] [ over push ] if ;

HINTS: do-line vector string ;

: (reverse-complement) ( seq -- )
    readln [ do-line (reverse-complement) ] [ show-seq ] if* ;

: reverse-complement ( infile outfile -- )
    ascii [
        ascii [
            500000 <vector> (reverse-complement)
        ] with-file-reader
    ] with-file-writer ;

: reverse-complement-in ( -- path )
    "reverse-complement-in.txt" temp-file ;

: reverse-complement-out ( -- path )
    "reverse-complement-out.txt" temp-file ;

: reverse-complement-main ( -- )
    reverse-complement-in
    reverse-complement-out
    reverse-complement ;

MAIN: reverse-complement-main
