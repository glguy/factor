IN: present
USING: help.markup help.syntax kernel strings ;

ARTICLE: "present" "Converting objects to human-readable strings"
"A word for converting an object into a human-readable string:"
{ $subsection present } ;

HELP: present
{ $values { "object" object } { "string" string } }
{ $contract "Outputs a human-readable string from an object." }
{ $notes "New methods can be defined by user code. Most often, this is done so that the object can be used with various words in the " { $vocab-link "html.components" } " or " { $link "urls" } " vocabularies." } ;

ABOUT: "present"
