USING: help.markup help.syntax vocabs.loader io.files strings
definitions quotations compiler.units ;
IN: source-files

ARTICLE: "source-files" "Source files"
"Words in the " { $vocab-link "source-files" } " vocabulary are used to keep track of loaded source files. This is used to implement " { $link "tools.vocabs" } "."
$nl
"The source file database:"
{ $subsection source-files }
"The class of source files:"
{ $subsection source-file }
"Words intended for the parser:"
{ $subsection record-checksum }
{ $subsection record-form }
{ $subsection xref-source }
{ $subsection unxref-source }
"Removing a source file from the database:"
{ $subsection forget-source }
"Updating the database:"
{ $subsection reset-checksums }
"The " { $link pathname } " class implements the definition protocol by working with the corresponding source file; see " { $link "definitions" } "." ;

ABOUT: "source-files"

HELP: source-files
{ $var-description "An assoc mapping pathname strings to " { $link source-file } " instances, representing loaded source files." } ;

HELP: source-file
{ $values { "path" "a pathname string" } { "source-file" source-file } }
{ $description "Outputs the source file associated to a path name, creating the source file first if it doesn't exist. Source files are retained in the " { $link source-files } " variable." }
{ $class-description "Instances retain information about loaded source files, and have the following slots:"
    { $list
        { { $snippet "path" } " - a pathname string." }
        { { $snippet "checksum" } " - the CRC32 checksum of the source file's contents at the time it was most recently loaded." }
        { { $snippet "uses" } " - an assoc whose keys are words referenced from this source file's top level form." }
        { { $snippet "definitions" } " - a pair of assocs, containing definitions and classes defined in this source file, respectively" }
    }
} ;

HELP: record-checksum
{ $values { "source-file" source-file } { "lines" "a sequence of strings" } }
{ $description "Records the CRC32 checksm of the source file's contents." } 
$low-level-note ;

HELP: xref-source
{ $values { "source-file" source-file } }
{ $description "Adds the source file to the " { $link crossref } " graph enabling words to find source files which reference them in their top level forms." }
$low-level-note ;

HELP: unxref-source
{ $values { "source-file" source-file } }
{ $description "Removes the source file from the " { $link crossref } " graph." }
$low-level-note ;

HELP: xref-sources
{ $description "Adds all loaded source files to the " { $link crossref } " graph. This is done during bootstrap." }
$low-level-note ;

HELP: record-form
{ $values { "quot" quotation } { "source-file" source-file } }
{ $description "Records usage information for a source file's top level form." }
$low-level-note ;

HELP: reset-checksums
{ $description "Resets recorded modification times and CRC32 checksums for all loaded source files, creating a checkpoint for " { $link "tools.vocabs" } "." } ;

HELP: forget-source
{ $values { "path" "a pathname string" } }
{ $description "Forgets all information known about a source file." }
{ $notes "This word must be called from inside " { $link with-compilation-unit } "." } ;

HELP: record-definitions
{ $values { "file" source-file } }
{ $description "Records that all " { $link new-definitions } " were defined in " { $snippet "file" } "." } ;

HELP: rollback-source-file
{ $values { "file" source-file } }
{ $description "Records information to the source file after an incomplete parse which ended with an error." } ;

HELP: file
{ $var-description "Stores the " { $link source-file } " being parsed. The " { $snippet "path" } " of this object comes from the input parameter to " { $link with-source-file } "." } ;
