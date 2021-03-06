IN: advice
USING: help.markup help.syntax tools.annotations words ;

HELP: make-advised
{ $values { "word" "a word to annotate in preparation of advising" } }
{ $description "Prepares a word for being advised.  This is done by: "
    { $list
        { "Annotating it to call the appropriate words before, around, and after the original body " }
        { "Adding " { $snippet "before" } ", " { $snippet "around" } ", and " { $snippet "after" } " properties, which will contain the advice" }
        { "Adding an " { $snippet "advised" } "property, which can later be used to determine if a given word is defined (see " { $link advised? } ")" }
    }
}
{ $see-also advised? annotate } ;

HELP: advised?
{ $values { "word" "a word" } { "?" "t or f, indicating if " { $snippet "word" } " is advised" } }
{ $description "Determines whether or not the given word has any advice on it." } ;

ARTICLE: "advice" "Advice"
"Advice is a simple way of adding additition functionality to words by adding 'hooks' to a word, which can act before, after, or around the calling of the word." ;

ABOUT: "advice"