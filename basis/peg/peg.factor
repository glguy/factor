! Copyright (C) 2007, 2008 Chris Double.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences strings fry namespaces make math assocs
shuffle debugger io vectors arrays math.parser math.order
vectors combinators classes sets unicode.categories
compiler.units parser words quotations effects memoize accessors
locals effects splitting combinators.short-circuit
combinators.short-circuit.smart generalizations ;
IN: peg

USE: prettyprint

TUPLE: parse-result remaining ast ;
TUPLE: parse-error position messages ; 
TUPLE: parser peg compiled id ;

M: parser equal?    { [ [ class ] bi@ = ] [ [ id>> ] bi@ = ] } 2&& ;
M: parser hashcode* id>> hashcode* ;

C: <parse-result> parse-result
C: <parse-error>  parse-error

M: parse-error error.
  "Peg parsing error at character position " write dup position>> number>string write 
  "." print "Expected " write messages>> [ " or " write ] [ write ] interleave nl ;

SYMBOL: error-stack

: (merge-errors) ( a b -- c )
  {
    { [ over position>> not ] [ nip ] } 
    { [ dup  position>> not ] [ drop ] } 
    [ 2dup [ position>> ] bi@ <=> {
        { +lt+ [ nip ] }
        { +gt+ [ drop ] }
        { +eq+ [ messages>> over messages>> union [ position>> ] dip <parse-error> ] }
      } case 
    ]
  } cond ;

: merge-errors ( -- )
  error-stack get dup length 1 >  [
    dup pop over pop swap (merge-errors) swap push
  ] [
    drop
  ] if ;

: add-error ( remaining message -- )
  <parse-error> error-stack get push ;
  
SYMBOL: ignore 

: packrat ( id -- cache )
  #! The packrat cache is a mapping of parser-id->cache.
  #! For each parser it maps to a cache holding a mapping
  #! of position->result. The packrat cache therefore keeps
  #! track of all parses that have occurred at each position
  #! of the input string and the results obtained from that
  #! parser.
  \ packrat get [ drop H{ } clone ] cache ;

SYMBOL: pos
SYMBOL: input
SYMBOL: fail
SYMBOL: lrstack

: heads ( -- cache )
  #! A mapping from position->peg-head.	It maps a
  #! position in the input string being parsed to 
  #! the head of the left recursion which is currently
  #! being grown. It is 'f' at any position where
  #! left recursion growth is not underway.
  \ heads get ;

: failed? ( obj -- ? )
  fail = ;

: peg-cache ( -- cache )
  #! Holds a hashtable mapping a peg tuple to
  #! the parser tuple for that peg. The parser tuple
  #! holds a unique id and the compiled form of that peg.
  \ peg-cache get-global [
    H{ } clone dup \ peg-cache set-global
  ] unless* ;

: reset-pegs ( -- )
  H{ } clone \ peg-cache set-global ;

reset-pegs 

#! An entry in the table of memoized parse results
#! ast = an AST produced from the parse
#!       or the symbol 'fail'
#!       or a left-recursion object
#! pos = the position in the input string of this entry
TUPLE: memo-entry ans pos ;

TUPLE: left-recursion seed rule-id head next ; 
TUPLE: peg-head rule-id involved-set eval-set ;

: rule-id ( word -- id ) 
  #! A rule is the parser compiled down to a word. It has
  #! a "peg-id" property containing the id of the original parser.
  "peg-id" word-prop ;

: input-slice ( -- slice )
  #! Return a slice of the input from the current parse position
  input get pos get tail-slice ;

: input-from ( input -- n )
  #! Return the index from the original string that the
  #! input slice is based on.
  dup slice? [ from>> ] [ drop 0 ] if ;

: process-rule-result ( p result -- result )
  [
    nip [ ast>> ] [ remaining>> ] bi input-from pos set    
  ] [ 
    pos set fail
  ] if* ; 

: eval-rule ( rule -- ast )
  #! Evaluate a rule, return an ast resulting from it.
  #! Return fail if the rule failed. The rule has
  #! stack effect ( -- parse-result )
  pos get swap execute process-rule-result ; inline

: memo ( pos id -- memo-entry )
  #! Return the result from the memo cache. 
  packrat at 
!  "  memo result " write dup . 
  ;

: set-memo ( memo-entry pos id -- )
  #! Store an entry in the cache
  packrat set-at ;

: update-m ( ast m -- )
  swap >>ans pos get >>pos drop ;

: stop-growth? ( ast m -- ? )
  [ failed? pos get ] dip 
  pos>> <= or ;

: setup-growth ( h p -- )
  pos set dup involved-set>> clone >>eval-set drop ;

: (grow-lr) ( h p r: ( -- result ) m -- )
  >r >r [ setup-growth ] 2keep r> r>
  >r dup eval-rule r> swap
  dup pick stop-growth? [
    5 ndrop
  ] [
    over update-m
    (grow-lr)
  ] if ; inline recursive
 
: grow-lr ( h p r m -- ast )
  >r >r [ heads set-at ] 2keep r> r>
  pick over >r >r (grow-lr) r> r>
  swap heads delete-at
  dup pos>> pos set ans>>
  ; inline

:: (setup-lr) ( r l s -- )
  s head>> l head>> eq? [
    l head>> s (>>head)
    l head>> [ s rule-id>> suffix ] change-involved-set drop
    r l s next>> (setup-lr)
  ] unless ;

:: setup-lr ( r l -- )
  l head>> [
    r rule-id V{ } clone V{ } clone peg-head boa l (>>head)
  ] unless
  r l lrstack get (setup-lr) ;

:: lr-answer ( r p m -- ast )
  [let* |
          h [ m ans>> head>> ]
        |
    h rule-id>> r rule-id eq? [
      m ans>> seed>> m (>>ans)
      m ans>> failed? [
        fail
      ] [
        h p r m grow-lr
      ] if
    ] [
      m ans>> seed>>
    ] if
  ] ; inline

:: recall ( r p -- memo-entry )
  [let* |
          m [ p r rule-id memo ]
          h [ p heads at ]
        |
    h [
      m r rule-id h involved-set>> h rule-id>> suffix member? not and [
        fail p memo-entry boa
      ] [
        r rule-id h eval-set>> member? [
          h [ r rule-id swap remove ] change-eval-set drop
          r eval-rule
          m update-m
          m
        ] [ 
          m
        ] if
      ] if
    ] [
      m
    ] if
  ] ; inline

:: apply-non-memo-rule ( r p -- ast )
  [let* |
          lr  [ fail r rule-id f lrstack get left-recursion boa ]
          m   [ lr lrstack set lr p memo-entry boa dup p r rule-id set-memo ]
          ans [ r eval-rule ]
        |
    lrstack get next>> lrstack set
    pos get m (>>pos)
    lr head>> [
      ans lr (>>seed)
      r p m lr-answer
    ] [
      ans m (>>ans)
      ans
    ] if
  ] ; inline

: apply-memo-rule ( r m -- ast )
  [ ans>> ] [ pos>> ] bi pos set
  dup left-recursion? [ 
    [ setup-lr ] keep seed>>
  ] [
    nip
  ] if ; 

USE: prettyprint

: apply-rule ( r p -- ast )
!   2dup [ rule-id ] dip 2array "apply-rule: " write .
   2dup recall [
!     "  memoed" print
     nip apply-memo-rule
   ] [
!     "  not memoed" print
     apply-non-memo-rule
   ] if* ; inline

: with-packrat ( input quot -- result )
  #! Run the quotation with a packrat cache active.
  swap [ 
    input set
    0 pos set
    f lrstack set
    V{ } clone error-stack set
    H{ } clone \ heads set
    H{ } clone \ packrat set
  ] H{ } make-assoc swap bind ; inline


GENERIC: (compile) ( peg -- quot )

: process-parser-result ( result -- result )
  dup failed? [ 
    drop f 
  ] [
    input-slice swap <parse-result>
  ] if ;
    
: execute-parser ( word -- result )
  pos get apply-rule process-parser-result ; inline

: parser-body ( parser -- quot )
  #! Return the body of the word that is the compiled version
  #! of the parser.
  gensym 2dup swap peg>> (compile) 0 1 <effect> define-declared swap dupd id>> "peg-id" set-word-prop
  [ execute-parser ] curry ;

: preset-parser-word ( parser -- parser word )
  gensym [ >>compiled ] keep ;

: define-parser-word ( parser word -- )
  swap parser-body (( -- result )) define-declared ;

: compile-parser ( parser -- word )
  #! Look to see if the given parser has been compiled.
  #! If not, compile it to a temporary word, cache it,
  #! and return it. Otherwise return the existing one.
  #! Circular parsers are supported by getting the word
  #! name and storing it in the cache, before compiling, 
  #! so it is picked up when re-entered.
  dup compiled>> [
    nip
  ] [
    preset-parser-word [ define-parser-word ] keep
  ] if* ;

SYMBOL: delayed

: fixup-delayed ( -- )
  #! Work through all delayed parsers and recompile their
  #! words to have the correct bodies.
  delayed get [
    call compile-parser 1quotation 0 1 <effect> define-declared
  ] assoc-each ;

: compile ( parser -- word )
  [
    H{ } clone delayed [ 
      compile-parser fixup-delayed 
    ] with-variable
  ] with-compilation-unit ;

: compiled-parse ( state word -- result )
  swap [ execute [ error-stack get first throw ] unless* ] with-packrat ; inline 

: (parse) ( input parser -- result )
  dup word? [ compile ] unless compiled-parse ;

: parse ( input parser -- ast )
  (parse) ast>> ;

<PRIVATE

SYMBOL: id 

: next-id ( -- n )
  #! Return the next unique id for a parser
  id get-global [
    dup 1+ id set-global
  ] [
    1 id set-global 0
  ] if* ;

: wrap-peg ( peg -- parser )
  #! Wrap a parser tuple around the peg object.
  #! Look for an existing parser tuple for that
  #! peg object.
  peg-cache [
    f next-id parser boa 
  ] cache ;

TUPLE: token-parser symbol ;

: parse-token ( input string -- result )
  #! Parse the string, returning a parse result
  [ ?head-slice ] keep swap [
    <parse-result> f f add-error
  ] [
    >r drop pos get "token '" r> append "'" append 1vector add-error f
  ] if ;

M: token-parser (compile) ( peg -- quot )
  symbol>> '[ input-slice _ parse-token ] ;
   
TUPLE: satisfy-parser quot ;

: parse-satisfy ( input quot -- result )
  swap dup empty? [
    2drop f 
  ] [
    unclip-slice rot dupd call [
      <parse-result>
    ] [  
      2drop f
    ] if
  ] if ; inline


M: satisfy-parser (compile) ( peg -- quot )
  quot>> '[ input-slice _ parse-satisfy ] ;

TUPLE: range-parser min max ;

: parse-range ( input min max -- result )
  pick empty? [ 
    3drop f 
  ] [
    pick first -rot between? [
      unclip-slice <parse-result>
    ] [ 
      drop f
    ] if
  ] if ;

M: range-parser (compile) ( peg -- quot )
  [ min>> ] [ max>> ] bi '[ input-slice _ _ parse-range ] ;

TUPLE: seq-parser parsers ;

: ignore? ( ast -- bool )
  ignore = ;

: calc-seq-result ( prev-result current-result -- next-result )
  [
    [ remaining>> swap (>>remaining) ] 2keep
    ast>> dup ignore? [  
      drop
    ] [
      swap [ ast>> push ] keep
    ] if
  ] [
    drop f
  ] if* ;

: parse-seq-element ( result quot -- result )
  over [
    call calc-seq-result
  ] [
    2drop f
  ] if ; inline

M: seq-parser (compile) ( peg -- quot )
  [
    [ input-slice V{ } clone <parse-result> ] %
    [
      parsers>> unclip compile-parser 1quotation [ parse-seq-element ] curry ,
      [ compile-parser 1quotation [ merge-errors ] compose [ parse-seq-element ] curry , ] each 
    ] { } make , \ && , 
  ] [ ] make ;

TUPLE: choice-parser parsers ;

M: choice-parser (compile) ( peg -- quot )
  [ 
    [
      parsers>> [ compile-parser ] map 
      unclip 1quotation , [ 1quotation [ merge-errors ] compose , ] each
    ] { } make , \ || ,
  ] [ ] make ;

TUPLE: repeat0-parser p1 ;

: (repeat) ( quot: ( -- result ) result -- result )
  over call [
    [ remaining>> swap (>>remaining) ] 2keep 
    ast>> swap [ ast>> push ] keep
    (repeat) 
  ] [
    nip
  ] if* ; inline recursive

M: repeat0-parser (compile) ( peg -- quot )
  p1>> compile-parser 1quotation '[ 
    input-slice V{ } clone <parse-result> _ swap (repeat) 
  ] ; 

TUPLE: repeat1-parser p1 ;

: repeat1-empty-check ( result -- result )
  [
    dup ast>> empty? [ drop f ] when
  ] [
    f
  ] if* ;

M: repeat1-parser (compile) ( peg -- quot )
  p1>> compile-parser 1quotation '[ 
    input-slice V{ } clone <parse-result> _ swap (repeat) repeat1-empty-check  
  ] ; 

TUPLE: optional-parser p1 ;

: check-optional ( result -- result )
  [ input-slice f <parse-result> ] unless* ;

M: optional-parser (compile) ( peg -- quot )
  p1>> compile-parser 1quotation '[ @ check-optional ] ;

TUPLE: semantic-parser p1 quot ;

: check-semantic ( result quot -- result )
  over [
    over ast>> swap call [ drop f ] unless
  ] [
    drop
  ] if ; inline

M: semantic-parser (compile) ( peg -- quot )
  [ p1>> compile-parser 1quotation ] [ quot>> ] bi  
  '[ @ _ check-semantic ] ;

TUPLE: ensure-parser p1 ;

: check-ensure ( old-input result -- result )
  [ ignore <parse-result> ] [ drop f ] if ;

M: ensure-parser (compile) ( peg -- quot )
  p1>> compile-parser 1quotation '[ input-slice @ check-ensure ] ;

TUPLE: ensure-not-parser p1 ;

: check-ensure-not ( old-input result -- result )
  [ drop f ] [ ignore <parse-result> ] if ;

M: ensure-not-parser (compile) ( peg -- quot )
  p1>> compile-parser 1quotation '[ input-slice @ check-ensure-not ] ;

TUPLE: action-parser p1 quot ;

: check-action ( result quot -- result )
  over [
    over ast>> swap call >>ast
  ] [
    drop
  ] if ; inline

M: action-parser (compile) ( peg -- quot )
  [ p1>> compile-parser 1quotation ] [ quot>> ] bi '[ @ _ check-action ] ;

TUPLE: sp-parser p1 ;

M: sp-parser (compile) ( peg -- quot )
  p1>> compile-parser 1quotation '[ 
    input-slice [ blank? ] trim-left-slice input-from pos set @ 
  ] ;

TUPLE: delay-parser quot ;

M: delay-parser (compile) ( peg -- quot )
  #! For efficiency we memoize the quotation.
  #! This way it is run only once and the 
  #! parser constructed once at run time.
  quot>> gensym [ delayed get set-at ] keep 1quotation ; 

TUPLE: box-parser quot ;

M: box-parser (compile) ( peg -- quot )
  #! Calls the quotation at compile time
  #! to produce the parser to be compiled.
  #! This differs from 'delay' which calls
  #! it at run time.
  quot>> call compile-parser 1quotation ;

PRIVATE>

: token ( string -- parser )
  token-parser boa wrap-peg ;      

: satisfy ( quot -- parser )
  satisfy-parser boa wrap-peg ;

: range ( min max -- parser )
  range-parser boa wrap-peg ;

: seq ( seq -- parser )
  seq-parser boa wrap-peg ;

: 2seq ( parser1 parser2 -- parser )
  2array seq ;

: 3seq ( parser1 parser2 parser3 -- parser )
  3array seq ;

: 4seq ( parser1 parser2 parser3 parser4 -- parser )
  4array seq ;

: seq* ( quot -- paser )
  { } make seq ; inline 

: choice ( seq -- parser )
  choice-parser boa wrap-peg ;

: 2choice ( parser1 parser2 -- parser )
  2array choice ;

: 3choice ( parser1 parser2 parser3 -- parser )
  3array choice ;

: 4choice ( parser1 parser2 parser3 parser4 -- parser )
  4array choice ;

: choice* ( quot -- paser )
  { } make choice ; inline 

: repeat0 ( parser -- parser )
  repeat0-parser boa wrap-peg ;

: repeat1 ( parser -- parser )
  repeat1-parser boa wrap-peg ;

: optional ( parser -- parser )
  optional-parser boa wrap-peg ;

: semantic ( parser quot -- parser )
  semantic-parser boa wrap-peg ;

: ensure ( parser -- parser )
  ensure-parser boa wrap-peg ;

: ensure-not ( parser -- parser )
  ensure-not-parser boa wrap-peg ;

: action ( parser quot -- parser )
  action-parser boa wrap-peg ;

: sp ( parser -- parser )
  sp-parser boa wrap-peg ;

: hide ( parser -- parser )
  [ drop ignore ] action ;

: delay ( quot -- parser )
  delay-parser boa wrap-peg ;

: box ( quot -- parser )
  #! because a box has its quotation run at compile time
  #! it must always have a new parser wrapper created, 
  #! not a cached one. This is because the same box,
  #! compiled twice can have a different compiled word
  #! due to running at compile time.
  #! Why the [ ] action at the end? Box parsers don't get
  #! memoized during parsing due to all box parsers being
  #! unique. This breaks left recursion detection during the
  #! parse. The action adds an indirection with a parser type
  #! that gets memoized and fixes this. Need to rethink how
  #! to fix boxes so this isn't needed...
  box-parser boa f next-id parser boa [ ] action ;

ERROR: parse-failed input word ;

M: parse-failed error.
  "The " write dup word>> pprint " word could not parse the following input:" print nl
  input>> . ;

: PEG:
  (:)
  [let | def [ ] word [ ] |
    [
      [
        [let | compiled-def [ def call compile ] |
          [
            dup compiled-def compiled-parse
            [ ast>> ] [ word parse-failed ] ?if
          ]
          word swap define
        ]
      ] with-compilation-unit
    ] over push-all
  ] ; parsing
