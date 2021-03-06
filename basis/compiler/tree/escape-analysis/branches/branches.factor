! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel namespaces sequences sets fry columns
stack-checker.branches
compiler.tree
compiler.tree.propagation.branches
compiler.tree.escape-analysis.nodes
compiler.tree.escape-analysis.allocations ;
IN: compiler.tree.escape-analysis.branches

M: #branch escape-analysis*
    [ in-d>> add-escaping-values ]
    [ live-children sift [ (escape-analysis) ] each ]
    bi ;

: (merge-allocations) ( values -- allocation )
    [
        dup [ allocation ] map sift [ drop f ] [
            dup [ t eq? not ] all? [
                dup [ length ] map all-equal? [
                    nip flip
                    [ (merge-allocations) ] [ [ merge-slots ] map ] bi
                    [ record-allocations ] keep
                ] [ drop add-escaping-values t ] if
            ] [ drop add-escaping-values t ] if
        ] if-empty
    ] map ;

: merge-allocations ( in-values out-values -- )
    [ [ remove-bottom ] map ] dip
    [ [ merge-values ] 2each ]
    [ [ (merge-allocations) ] dip record-allocations ]
    2bi ;

M: #phi escape-analysis*
    [ phi-in-d>> <flipped> ] [ out-d>> ] bi merge-allocations ;
