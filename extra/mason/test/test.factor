! Copyright (C) 2008 Eduardo Cavazos, Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel namespaces assocs io.files io.encodings.utf8
prettyprint help.lint benchmark tools.time bootstrap.stage2
tools.test tools.vocabs mason.common ;
IN: mason.test

: do-load ( -- )
    try-everything
    [ keys load-everything-vocabs-file to-file ]
    [ load-everything-errors-file utf8 [ load-failures. ] with-file-writer ]
    bi ;

: do-tests ( -- )
    run-all-tests
    [ keys test-all-vocabs-file to-file ]
    [ test-all-errors-file utf8 [ test-failures. ] with-file-writer ]
    bi ;

: do-help-lint ( -- )
    "" run-help-lint
    [ keys help-lint-vocabs-file to-file ]
    [ help-lint-errors-file utf8 [ typos. ] with-file-writer ]
    bi ;

: do-benchmarks ( -- )
    run-benchmarks benchmarks-file to-file ;

: do-all ( -- )
    ".." [
        bootstrap-time get boot-time-file to-file
        [ do-load ] benchmark load-time-file to-file
        [ do-tests ] benchmark test-time-file to-file
        [ do-help-lint ] benchmark help-lint-time-file to-file
        [ do-benchmarks ] benchmark benchmark-time-file to-file
    ] with-directory ;

MAIN: do-all