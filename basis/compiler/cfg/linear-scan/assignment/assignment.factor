! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel math assocs namespaces sequences heaps
fry make combinators
cpu.architecture
compiler.cfg.def-use
compiler.cfg.registers
compiler.cfg.instructions
compiler.cfg.linear-scan.live-intervals ;
IN: compiler.cfg.linear-scan.assignment

! A vector of live intervals. There is linear searching involved
! but since we never have too many machine registers (around 30
! at most) and we probably won't have that many live at any one
! time anyway, it is not a problem to check each element.
SYMBOL: active-intervals

: add-active ( live-interval -- )
    active-intervals get push ;

: lookup-register ( vreg -- reg )
    active-intervals get [ vreg>> = ] with find nip reg>> ;

! Minheap of live intervals which still need a register allocation
SYMBOL: unhandled-intervals

: add-unhandled ( live-interval -- )
    dup split-before>> [
        [ split-before>> ] [ split-after>> ] bi
        [ add-unhandled ] bi@
    ] [
        dup start>> unhandled-intervals get heap-push
    ] if ;

: init-unhandled ( live-intervals -- )
    [ add-unhandled ] each ;

: insert-spill ( live-interval -- )
    [ reg>> ] [ vreg>> reg-class>> ] [ spill-to>> ] tri
    dup [ _spill ] [ 3drop ] if ;

: expire-old-intervals ( n -- )
    active-intervals get
    swap '[ end>> _ = ] partition
    active-intervals set
    [ insert-spill ] each ;

: insert-reload ( live-interval -- )
    [ reg>> ] [ vreg>> reg-class>> ] [ reload-from>> ] tri
    dup [ _reload ] [ 3drop ] if ;

: activate-new-intervals ( n -- )
    #! Any live intervals which start on the current instruction
    #! are added to the active set.
    unhandled-intervals get dup heap-empty? [ 2drop ] [
        2dup heap-peek drop start>> = [
            heap-pop drop [ add-active ] [ insert-reload ] bi
            activate-new-intervals
        ] [ 2drop ] if
    ] if ;

GENERIC: (assign-registers) ( insn -- )

M: vreg-insn (assign-registers)
    dup
    [ defs-vregs ] [ uses-vregs ] bi append
    active-intervals get swap '[ vreg>> _ member? ] filter
    [ [ vreg>> ] [ reg>> ] bi ] { } map>assoc
    >>regs drop ;

M: insn (assign-registers) drop ;

: init-assignment ( live-intervals -- )
    V{ } clone active-intervals set
    <min-heap> unhandled-intervals set
    init-unhandled ;

: assign-registers ( insns live-intervals -- insns' )
    [
        init-assignment
        [
            [ activate-new-intervals ]
            [ drop [ (assign-registers) ] [ , ] bi ]
            [ expire-old-intervals ]
            tri
        ] each-index
    ] { } make ;
