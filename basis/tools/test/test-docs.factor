USING: help.markup help.syntax kernel quotations io ;
IN: tools.test

ARTICLE: "tools.test.write" "Writing unit tests"
"Assert that a quotation outputs a specific set of values:"
{ $subsection unit-test }
"Assert that a quotation throws an error:"
{ $subsection must-fail }
{ $subsection must-fail-with }
"Assert that a quotation or word has a specific static stack effect (see " { $link "inference" } "):"
{ $subsection must-infer }
{ $subsection must-infer-as } ;

ARTICLE: "tools.test.run" "Running unit tests"
"The following words run test harness files; any test failures are collected and printed at the end:"
{ $subsection test }
{ $subsection test-all } ;

ARTICLE: "tools.test.failure" "Handling test failures"
"Most of the time the words documented in " { $link "tools.test.run" } " are used because they print all test failures in human-readable form. Some tools inspect the test failures and takes some kind of action instead, for example, " { $vocab-link "mason" } "."
$nl
"The following words output an association list mapping vocabulary names to sequences of failures; a failure is an array having the shape " { $snippet "{ error test continuation }" } ", and the elements are as follows:"
{ $list
    { { $snippet "error" } " - the error thrown by the unit test" }
    { { $snippet "test" } " - a pair " { $snippet "{ output input }" } " containing expected output and a unit test quotation which didn't produce this output" }
    { { $snippet "continuation" } " - the traceback at the point of the error" }
}
"The following words run test harness files and output failures:"
{ $subsection run-tests }
{ $subsection run-all-tests }
"The following word prints failures:"
{ $subsection test-failures. } ;

ARTICLE: "tools.test" "Unit testing"
"A unit test is a piece of code which starts with known input values, then compares the output of a word with an expected output, where the expected output is defined by the word's contract."
$nl
"For example, if you were developing a word for computing symbolic derivatives, your unit tests would apply the word to certain input functions, comparing the results against the correct values. While the passing of these tests would not guarantee the algorithm is correct, it would at least ensure that what used to work keeps working, in that as soon as something breaks due to a change in another part of your program, failing tests will let you know."
$nl
"Unit tests for a vocabulary are placed in test files in the same directory as the vocabulary source file (see " { $link "vocabs.loader" } "). Two possibilities are supported:"
{ $list
    { "Tests can be placed in a file named " { $snippet { $emphasis "vocab" } "-tests.factor" } "." }
    { "Tests can be placed in files in the " { $snippet "tests" } " subdirectory." }
}
"The latter is used for vocabularies with more extensive test suites."
$nl
"If the test harness needs to define words, they should be placed in a vocabulary named " { $snippet { $emphasis "vocab" } ".tests" } " where " { $emphasis "vocab" } " is the vocab being tested."
{ $subsection "tools.test.write" }
{ $subsection "tools.test.run" }
{ $subsection "tools.test.failure" } ;

ABOUT: "tools.test"

HELP: unit-test
{ $values { "output" "a sequence of expected stack elements" } { "input" "a quotation run with an empty stack" } }
{ $description "Runs a quotation with an empty stack, comparing the resulting stack with " { $snippet "output" } ". Elements are compared using " { $link = } ". Throws an error if the expected stack does not match the resulting stack." } ;

HELP: must-fail
{ $values { "quot" "a quotation run with an empty stack" } }
{ $description "Runs a quotation with an empty stack, expecting it to throw an error. If the quotation throws an error, this word returns normally. If the quotation does not throw an error, this word " { $emphasis "does" } " raise an error." }
{ $notes "This word is used to test boundary conditions and fail-fast behavior." } ;

HELP: must-fail-with
{ $values { "quot" "a quotation run with an empty stack" } { "pred" "a quotation with stack effect " { $snippet "( error -- ? )" } } }
{ $description "Runs a quotation with an empty stack, expecting it to throw an error which must satisfy " { $snippet "pred" } ". If the quotation does not throw an error, or if the error does not match the predicate, the unit test fails." }
{ $notes "This word is used to test error handling code, ensuring that errors thrown by code contain the relevant debugging information." } ;

HELP: must-infer
{ $values { "word/quot" "a quotation or a word" } }
{ $description "Ensures that the quotation or word has a static stack effect without running it." }
{ $notes "This word is used to test that code will compile with the optimizing compiler for optimum performance. See " { $link "compiler" } "." } ;

HELP: must-infer-as
{ $values { "effect" "a pair with shape " { $snippet "{ inputs outputs }" } } { "quot" quotation } }
{ $description "Ensures that the quotation has the indicated stack effect without running it." }
{ $notes "This word is used to test that code will compile with the optimizing compiler for optimum performance. See " { $link "compiler" } "." } ;

HELP: test
{ $values { "prefix" "a vocabulary name" } }
{ $description "Runs unit tests for the vocabulary named " { $snippet "prefix" } " and all of its child vocabularies." } ;

HELP: run-tests
{ $values { "prefix" "a vocabulary name" } { "failures" "an association list of unit test failures" } }
{ $description "Runs unit tests for the vocabulary named " { $snippet "prefix" } " and all of its child vocabularies. Outputs unit test failures as documented in " { $link "tools.test.failure" } "." } ;

HELP: test-all
{ $description "Runs unit tests for all loaded vocabularies." } ;

HELP: run-all-tests
{ $values { "prefix" "a vocabulary name" } { "failures" "an association list of unit test failures" } }
{ $description "Runs unit tests for all loaded vocabularies and outputs unit test failures as documented in " { $link "tools.test.failure" } "." } ;

HELP: test-failures.
{ $values { "assoc" "an association list of unit test failures" } }
{ $description "Prints unit test failures output by " { $link run-tests } " or " { $link run-all-tests } " to " { $link output-stream } "." } ;
