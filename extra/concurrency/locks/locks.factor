! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: dlists kernel threads continuations math
concurrency.conditions ;
IN: concurrency.locks

! Simple critical sections
TUPLE: lock threads owner reentrant? ;

: <lock> ( -- lock )
    <dlist> f f lock construct-boa ;

: <reentrant-lock> ( -- lock )
    <dlist> f t lock construct-boa ;

<PRIVATE

: acquire-lock ( lock timeout -- )
    over lock-owner
    [ 2dup >r lock-threads r> "lock" wait ] when drop
    self swap set-lock-owner ;

: release-lock ( lock -- )
    f over set-lock-owner
    lock-threads notify-1 ;

: do-lock ( lock timeout quot acquire release -- )
    >r >r pick rot r> call ! use up  timeout acquire
    swap r> curry [ ] cleanup ; inline

: (with-lock) ( lock timeout quot -- )
    [ acquire-lock ] [ release-lock ] do-lock ; inline

PRIVATE>

: with-lock-timeout ( lock timeout quot -- )
    pick lock-reentrant? [
        pick lock-owner self eq? [
            2nip call
        ] [
            (with-lock)
        ] if
    ] [
        (with-lock)
    ] if ; inline

: with-lock ( lock quot -- )
    f swap with-lock-timeout ; inline

! Many-reader/single-writer locks
TUPLE: rw-lock readers writers reader# writer ;

: <rw-lock> ( -- lock )
    <dlist> <dlist> 0 f rw-lock construct-boa ;

<PRIVATE

: acquire-read-lock ( lock timeout -- )
    over rw-lock-writer
    [ 2dup >r rw-lock-readers r> "read lock" wait ] when drop
    dup rw-lock-reader# 1+ swap set-rw-lock-reader# ;

: notify-writer ( lock -- )
    rw-lock-writers notify-1 ;

: release-read-lock ( lock -- )
    dup rw-lock-reader# 1- dup pick set-rw-lock-reader#
    zero? [ notify-writer ] [ drop ] if ;

: acquire-write-lock ( lock timeout -- )
    over rw-lock-writer pick rw-lock-reader# 0 > or
    [ 2dup >r rw-lock-writers r> "write lock" wait ] when drop
    self swap set-rw-lock-writer ;

: release-write-lock ( lock -- )
    f over set-rw-lock-writer
    dup rw-lock-readers dlist-empty?
    [ notify-writer ] [ rw-lock-readers notify-all ] if ;

: do-reentrant-rw-lock ( lock timeout quot quot' -- )
    >r pick rw-lock-writer self eq? [ 2nip call ] r> if ; inline

PRIVATE>

: with-read-lock-timeout ( lock timeout quot -- )
    [
        [ acquire-read-lock ] [ release-read-lock ] do-lock
    ] do-reentrant-rw-lock ; inline

: with-read-lock ( lock quot -- )
    f swap with-read-lock-timeout ; inline

: with-write-lock-timeout ( lock timeout quot -- )
    [
        [ acquire-write-lock ] [ release-write-lock ] do-lock
    ] do-reentrant-rw-lock ; inline

: with-write-lock ( lock quot -- )
    f swap with-write-lock-timeout ; inline