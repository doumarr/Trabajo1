%{
#include <stdio.h>
#include <stdlib.h>
#include "english.tab.h"
%}

%option noyywrap

/* A "boundary" is whatever legally follows a word in our language:
   whitespace or the end-of-sentence period. Every word token below
   uses this as trailing context (the "/" operator) so Flex checks
   that the boundary is there WITHOUT consuming it -- the boundary
   character is left in the input for the next token (e.g. the
   period still needs to be matched on its own as PERIOD). */
boundary [ \t\r\n.]

%%

"a"/{boundary}         { return ARTICLE_A; }
"the"/{boundary}       { return ARTICLE_THE; }
"and"/{boundary}       { return AND; }

"black"/{boundary}     { return ADJ; }
"orange"/{boundary}    { return ADJ; }
"big"/{boundary}       { return ADJ; }
"small"/{boundary}     { return ADJ; }

"dog"/{boundary}       { return NOUN_SG; }
"cat"/{boundary}       { return NOUN_SG; }
"cow"/{boundary}       { return NOUN_SG; }

"dogs"/{boundary}      { return NOUN_PL; }
"cats"/{boundary}      { return NOUN_PL; }
"cows"/{boundary}      { return NOUN_PL; }

"likes"/{boundary}     { return VERB_SG; }
"hates"/{boundary}     { return VERB_SG; }
"ignores"/{boundary}   { return VERB_SG; }
"irritates"/{boundary} { return VERB_SG; }

"like"/{boundary}      { return VERB_PL; }
"hate"/{boundary}      { return VERB_PL; }
"ignore"/{boundary}    { return VERB_PL; }
"irritate"/{boundary}  { return VERB_PL; }

"."                    { return PERIOD; }

[ \t\r\n]+              { /* ignore whitespace */ }

[a-zA-Z]+ {
    fprintf(stderr, "Lexical error: unknown word '%s'\n", yytext);
    exit(1);
}

. {
    fprintf(stderr, "Lexical error: unexpected character '%s'\n", yytext);
    exit(1);
}

%%
