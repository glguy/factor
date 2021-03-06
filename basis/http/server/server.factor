! Copyright (C) 2003, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel accessors sequences arrays namespaces splitting
vocabs.loader destructors assocs debugger continuations
combinators tools.vocabs tools.time math math.parser present
io vectors
io.sockets
io.sockets.secure
io.encodings
io.encodings.iana
io.encodings.utf8
io.encodings.ascii
io.encodings.binary
io.streams.limited
io.servers.connection
io.timeouts
fry logging logging.insomniac calendar urls urls.encoding
http
http.parsers
http.server.responses
http.server.remapping
html.templates
html.elements
html.streams ;
IN: http.server

\ parse-cookie DEBUG add-input-logging

: check-absolute ( url -- url )
    dup path>> "/" head? [ "Bad request: URL" throw ] unless ; inline

: read-request-line ( request -- request )
    read-crlf parse-request-line first3
    [ >>method ] [ >url check-absolute >>url ] [ >>version ] tri* ;

: read-request-header ( request -- request )
    read-header >>header ;

: parse-post-data ( post-data -- post-data )
    [ ] [ raw>> ] [ content-type>> ] tri
    "application/x-www-form-urlencoded" = [ query>assoc ] when
    >>content ;

: read-post-data ( request -- request )
    dup method>> "POST" = [
        [ ]
        [ "content-length" header string>number read ]
        [ "content-type" header ] tri
        <post-data> parse-post-data >>post-data
    ] when ;

: extract-host ( request -- request )
    [ ] [ url>> ] [ "host" header parse-host ] tri
    [ >>host ] [ >>port ] bi*
    drop ;

: extract-cookies ( request -- request )
    dup "cookie" header [ parse-cookie >>cookies ] when* ;

: read-request ( -- request )
    <request>
    read-request-line
    read-request-header
    read-post-data
    extract-host
    extract-cookies ;

GENERIC: write-response ( response -- )

GENERIC: write-full-response ( request response -- )

: write-response-line ( response -- response )
    dup
    [ "HTTP/" write version>> write bl ]
    [ code>> present write bl ]
    [ message>> write crlf ]
    tri ;

: unparse-content-type ( request -- content-type )
    [ content-type>> "application/octet-stream" or ]
    [ content-charset>> encoding>name ]
    bi
    [ "; charset=" swap 3append ] when* ;

: ensure-domain ( cookie -- cookie )
    [
        url get host>> dup "localhost" =
        [ drop ] [ or ] if
    ] change-domain ;

: write-response-header ( response -- response )
    #! We send one set-cookie header per cookie, because that's
    #! what Firefox expects.
    dup header>> >alist >vector
    over unparse-content-type "content-type" pick set-at
    over cookies>> [
        ensure-domain unparse-set-cookie
        "set-cookie" swap 2array over push
    ] each
    write-header ;

: write-response-body ( response -- response )
    dup body>> call-template ;

M: response write-response ( respose -- )
    write-response-line
    write-response-header
    flush
    drop ;

M: response write-full-response ( request response -- )
    dup write-response
    swap method>> "HEAD" = [
        [ content-charset>> encode-output ]
        [ write-response-body ]
        bi
    ] unless ;

M: raw-response write-response ( respose -- )
    write-response-line
    write-response-body
    drop ;

M: raw-response write-full-response ( response -- )
    write-response ;

: post-request? ( -- ? ) request get method>> "POST" = ;

SYMBOL: responder-nesting

SYMBOL: main-responder

SYMBOL: development?

SYMBOL: benchmark?

! path is a sequence of path component strings
GENERIC: call-responder* ( path responder -- response )

TUPLE: trivial-responder response ;

C: <trivial-responder> trivial-responder

M: trivial-responder call-responder* nip response>> clone ;

main-responder global [ <404> <trivial-responder> or ] change-at

: invert-slice ( slice -- slice' )
    dup slice? [ [ seq>> ] [ from>> ] bi head-slice ] [ drop { } ] if ;

: add-responder-nesting ( path responder -- )
    [ invert-slice ] dip 2array responder-nesting get push ;

: call-responder ( path responder -- response )
    [ add-responder-nesting ] [ call-responder* ] 2bi ;

: http-error. ( error -- )
    "Internal server error" [ ] [
        [ print-error nl :c ] with-html-writer
    ] simple-page ;

: <500> ( error -- response )
    500 "Internal server error" <trivial-response>
    swap development? get [ '[ _ http-error. ] >>body ] [ drop ] if ;

: do-response ( response -- )
    [ request get swap write-full-response ]
    [
        [ \ do-response log-error ]
        [
            utf8 [
                development? get
                [ http-error. ] [ drop "Response error" write ] if
            ] with-encoded-output
        ] bi
    ] recover ;

LOG: httpd-hit NOTICE

LOG: httpd-header NOTICE

: log-header ( headers name -- )
    tuck header 2array httpd-header ;

: log-request ( request -- )
    [ [ method>> ] [ url>> ] bi 2array httpd-hit ]
    [ { "user-agent" "x-forwarded-for" } [ log-header ] with each ]
    bi ;

: split-path ( string -- path )
    "/" split harvest ;

: init-request ( request -- )
    [ request set ] [ url>> url set ] bi
    V{ } clone responder-nesting set ;

: dispatch-request ( request -- response )
    url>> path>> split-path main-responder get call-responder ;

: prepare-request ( request -- )
    [
        local-address get
        [ secure? "https" "http" ? >>protocol ]
        [ port>> remap-port '[ _ or ] change-port ]
        bi
    ] change-url drop ;

: valid-request? ( request -- ? )
    url>> port>> remap-port
    local-address get port>> remap-port = ;

: do-request ( request -- response )
    '[
        _
        {
            [ prepare-request ]
            [ init-request ]
            [ log-request ]
            [ dup valid-request? [ dispatch-request ] [ drop <400> ] if ]
        } cleave
    ] [ [ \ do-request log-error ] [ <500> ] bi ] recover ;

: ?refresh-all ( -- )
    development? get-global [ global [ refresh-all ] bind ] when ;

LOG: httpd-benchmark DEBUG

: ?benchmark ( quot -- )
    benchmark? get [
        [ benchmark ] [ first ] bi url get rot 3array
        httpd-benchmark
    ] [ call ] if ; inline

TUPLE: http-server < threaded-server ;

M: http-server handle-client*
    drop
    [
        64 1024 * limit-input
        ?refresh-all
        [ read-request ] ?benchmark
        [ do-request ] ?benchmark
        [ do-response ] ?benchmark
    ] with-destructors ;

: <http-server> ( -- server )
    http-server new-threaded-server
        "http.server" >>name
        "http" protocol-port >>insecure
        "https" protocol-port >>secure ;

: httpd ( port -- )
    <http-server>
        swap >>insecure
        f >>secure
    start-server ;

: http-insomniac ( -- )
    "http.server" { "httpd-hit" } schedule-insomniac ;

USE: vocabs.loader

"http.server.filters" require
"http.server.dispatchers" require
"http.server.redirection" require
"http.server.static" require
"http.server.cgi" require
