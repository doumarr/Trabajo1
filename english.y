%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
%}

%token ARTICLE_A ARTICLE_THE AND ADJ
%token NOUN_SG NOUN_PL
%token VERB_SG VERB_PL
%token PERIOD

%%

input:
      /* empty */
    | input sentence
    ;

/* A sentence is a subject, a verb, and an object, ending in a period.
   The subject and verb must agree in number: a singular subject can
   only take a singular verb, and a plural subject can only take a
   plural verb. The object can be singular, plural, or conjoined --
   there is no agreement requirement on the object. */
sentence:
      subject_sg VERB_SG object PERIOD
    | subject_pl VERB_PL object PERIOD
    ;

subject_sg:
      np_sg
    ;

/* A plural subject is either a simple plural noun phrase, or two or
   more noun phrases joined with "and" (which is always plural,
   regardless of the number of its parts). */
subject_pl:
      np_pl
    | conj_np
    ;

object:
      np_sg
    | np_pl
    | conj_np
    ;

/* Singular noun phrase: a required article ("a" or "the"), an
   optional adjective, and a singular noun. e.g. "a dog", "the black cat" */
np_sg:
      ARTICLE_A adj_opt NOUN_SG
    | ARTICLE_THE adj_opt NOUN_SG
    ;

/* Plural noun phrase: an optional "the" (never "a"), an optional
   adjective, and a plural noun. e.g. "dogs", "the black cats" */
np_pl:
      adj_opt NOUN_PL
    | ARTICLE_THE adj_opt NOUN_PL
    ;

adj_opt:
      /* empty */
    | ADJ
    ;

/* A single component of a conjunction: either a singular or a
   plural noun phrase. */
np_item:
      np_sg
    | np_pl
    ;

/* Two or more noun phrases joined by "and". This is left-recursive
   so that chains like "the dog and the cat and the cow" are allowed. */
conj_np:
      np_item AND np_item
    | conj_np AND np_item
    ;

%%

int main(void)
{
    if (yyparse() == 0) {
        printf("Valid sentence\n");
        return 0;
    }
    return 1;
}

void yyerror(const char *s)
{
    fprintf(stderr, "Syntax error: %s\n", s);
}
