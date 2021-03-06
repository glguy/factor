IN: checksums.openssl
USING: help.syntax help.markup ;

HELP: openssl-checksum
{ $class-description "The class of checksum algorithms implemented by OpenSSL. The exact set of algorithms supported depends on how the OpenSSL library was compiled; " { $snippet "md5" } " and " { $snippet "sha1" } " should be universally available." } ;

HELP: <openssl-checksum> ( name -- checksum )
{ $values { "name" "an EVP message digest name" } { "checksum" openssl-checksum } }
{ $description "Creates a new OpenSSL checksum object." } ;

HELP: openssl-md5
{ $description "The OpenSSL MD5 message digest implementation." } ;

HELP: openssl-sha1
{ $description "The OpenSSL SHA1 message digest implementation." } ;

HELP: unknown-digest
{ $error-description "Thrown by checksum words if they are passed an " { $link openssl-checksum } " naming a message digest not supported by OpenSSL." } ;

ARTICLE: "checksums.openssl" "OpenSSL checksums"
"The OpenSSL library provides a large number of efficient checksum (message digest) algorithms which may be used independently of its SSL functionality."
{ $subsection openssl-checksum }
"Constructing a checksum from a known name:"
{ $subsection <openssl-checksum> }
"Two utility words:"
{ $subsection openssl-md5 }
{ $subsection openssl-sha1 }
"An error thrown if the digest name is unrecognized:"
{ $subsection unknown-digest }
"An example where we compute the SHA1 checksum of a string using the OpenSSL implementation of SHA1:"
{ $example "USING: byte-arrays checksums checksums.openssl prettyprint ;" "\"hello world\" >byte-array openssl-sha1 checksum-bytes hex-string ." "\"2aae6c35c94fcfb415dbe95f408b9ce91ee846ed\"" }
"If we use the Factor implementation, we get the same result, just slightly slower:"
{ $example "USING: byte-arrays checksums checksums.sha1 prettyprint ;" "\"hello world\" >byte-array sha1 checksum-bytes hex-string ." "\"2aae6c35c94fcfb415dbe95f408b9ce91ee846ed\"" } ;

ABOUT: "checksums.openssl"
