IN: biassocs
USING: help.markup help.syntax assocs kernel ;

HELP: biassoc
{ $class-description "The class of bidirectional assocs. Bidirectional assoc are implemented by combining two assocs, with one the transpose of the other." } ;

HELP: <biassoc>
{ $values { "exemplar" assoc } { "biassoc" biassoc } }
{ $description "Creates a new biassoc using a new assoc of the same type as " { $snippet "exemplar" } " for underlying storage." } ;

HELP: <bihash>
{ $values { "biassoc" biassoc } }
{ $description "Creates a new biassoc using a pair of hashtables for underlying storage." } ;

HELP: once-at
{ $values { "value" object } { "key" object } { "assoc" assoc } }
{ $description "If the assoc does not contain the given key, adds the key/value pair to the assoc, otherwise does nothing." } ;

ARTICLE: "biassocs" "Bidirectional assocs"
"A " { $emphasis "bidirectional assoc" } " combines a pair of assocs to form a data structure where both normal assoc opeartions (eg, " { $link at } "), as well as " { $link "assocs-values" } " (eg, " { $link value-at } ") run in sub-linear time."
$nl
"Bidirectional assocs implement the entire assoc protocol with the exception of " { $link delete-at } ". Duplicate values are allowed, however value lookups with " { $link value-at } " only return the first key that a given value was stored with."
{ $subsection biassoc }
{ $subsection biassoc? }
{ $subsection <biassoc> }
{ $subsection <bihash> } ;

ABOUT: "biassocs"
