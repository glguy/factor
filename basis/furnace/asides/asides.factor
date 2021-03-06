! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: namespaces assocs kernel sequences accessors hashtables
urls db.types db.tuples math.parser fry logging combinators
html.templates.chloe.syntax
http http.server http.server.filters http.server.redirection
furnace
furnace.cache
furnace.sessions
furnace.redirection ;
IN: furnace.asides

TUPLE: aside < server-state
session method url post-data ;

: <aside> ( id -- aside )
    aside new-server-state ;

aside "ASIDES" {
    { "session" "SESSION" BIG-INTEGER +not-null+ }
    { "method" "METHOD" { VARCHAR 10 } }
    { "url" "URL" URL }
    { "post-data" "POST_DATA" FACTOR-BLOB }
} define-persistent

: aside-id-key "__a" ;

TUPLE: asides < server-state-manager ;

: <asides> ( responder -- responder' )
    asides new-server-state-manager ;

SYMBOL: aside-id

: get-aside ( id -- aside )
    dup [ aside get-state ] when check-session ;

: request-aside-id ( request -- id )
    aside-id-key swap request-params at string>number ;

: request-aside ( request -- aside )
    request-aside-id get-aside ;

: set-aside ( aside -- )
    [ id>> aside-id set ] when* ;

: init-asides ( asides -- )
    asides set
    request get request-aside-id
    get-aside
    set-aside ;

M: asides call-responder*
    [ init-asides ] [ asides set ] [ call-next-method ] tri ;

: touch-aside ( aside -- )
    asides get touch-state ;

: begin-aside ( url -- )
    f <aside>
        swap >>url
        session get id>> >>session
        request get method>> >>method
        request get post-data>> >>post-data
    [ touch-aside ] [ insert-tuple ] [ set-aside ] tri ;

: end-aside-post ( aside -- response )
    [ url>> ] [ post-data>> ] bi
    request [
        clone
            swap >>post-data
            over >>url
    ] change
    [ url set ] [ path>> split-path ] bi
    asides get responder>> call-responder ;

\ end-aside-post DEBUG add-input-logging

ERROR: end-aside-in-get-error ;

: move-on ( id -- response )
    post-request? [ end-aside-in-get-error ] unless
    dup method>> {
        { "GET" [ url>> <redirect> ] }
        { "HEAD" [ url>> <redirect> ] }
        { "POST" [ end-aside-post ] }
    } case ;

: end-aside ( default -- response )
    aside-id get aside-id off get-aside [ move-on ] [ <redirect> ] ?if ;

M: asides link-attr ( tag -- )
    drop
    "aside" optional-attr {
        { "none" [ aside-id off ] }
        { "begin" [ url get begin-aside ] }
        { "current" [ ] }
        { f [ ] }
    } case ;

M: asides modify-query ( query asides -- query' )
    drop
    aside-id get [
        aside-id-key associate assoc-union
    ] when* ;

M: asides modify-form ( asides -- )
    drop
    aside-id get
    aside-id-key
    hidden-form-field ;
