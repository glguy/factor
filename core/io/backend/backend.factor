! Copyright (C) 2007, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: init kernel system namespaces io io.encodings
io.encodings.utf8 init assocs splitting ;
IN: io.backend

SYMBOL: io-backend

SINGLETON: c-io-backend

c-io-backend io-backend set-global

HOOK: init-io io-backend ( -- )

HOOK: (init-stdio) io-backend ( -- stdin stdout stderr )

: init-stdio ( -- )
    (init-stdio)
    [ utf8 <decoder> input-stream set-global ]
    [ utf8 <encoder> output-stream set-global ]
    [ utf8 <encoder> error-stream set-global ] tri* ;

HOOK: io-multiplex io-backend ( ms -- )

HOOK: normalize-directory io-backend ( str -- newstr )

HOOK: normalize-path io-backend ( str -- newstr )

M: object normalize-directory normalize-path ;

: set-io-backend ( io-backend -- )
    io-backend set-global init-io init-stdio
    "io.files" init-hooks get at call ;

[ init-io embedded? [ init-stdio ] unless ]
"io.backend" add-init-hook
