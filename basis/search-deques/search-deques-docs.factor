IN: search-deques
USING: help.markup help.syntax kernel dlists hashtables
deques assocs ;

ARTICLE: "search-deques" "Search deques"
"A search deque is a data structure with constant-time insertion and removal of elements at both ends, and constant-time membership tests. Inserting an element more than once has no effect. Search deques implement all deque operations in terms of an underlying deque, and membership testing with " { $link deque-member? } " is implemented with an underlying assoc. Search deques are defined in the " { $vocab-link "search-deques" } " vocabulary."
$nl
"Creating a search deque:"
{ $subsection <search-deque> }
"Default implementation:"
{ $subsection <hashed-dlist> } ;

ABOUT: "search-deques"

HELP: <search-deque> ( assoc deque -- search-deque )
{ $values { "assoc" assoc } { "deque" deque } { "search-deque" search-deque } }
{ $description "Creates a new " { $link search-deque } "." } ;

HELP: <hashed-dlist> ( -- search-deque )
{ $values { "search-deque" search-deque } }
{ $description "Creates a new " { $link search-deque } " backed by a " { $link dlist } ", with a " { $link hashtable } " for fast membership tests." } ;
