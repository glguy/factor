IN: mason.child.tests
USING: mason.child mason.config tools.test namespaces ;

[ { "make" "clean" "winnt-x86-32" } ] [
    [
        "winnt" target-os set
        "x86.32" target-cpu set
        make-cmd
    ] with-scope
] unit-test

[ { "make" "clean" "macosx-x86-32" } ] [
    [
        "macosx" target-os set
        "x86.32" target-cpu set
        make-cmd
    ] with-scope
] unit-test

[ { "gmake" "clean" "netbsd-ppc" } ] [
    [
        "netbsd" target-os set
        "ppc" target-cpu set
        make-cmd
    ] with-scope
] unit-test

[ { "./factor" "-i=boot.macosx-ppc.image" "-no-user-init" } ] [
    [
        "macosx" target-os set
        "ppc" target-cpu set
        boot-cmd
    ] with-scope
] unit-test
