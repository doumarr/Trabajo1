# English Grammar Parser

Author: (your name here)
Email: alandrp2@gmail.com

## Overview

This project uses Flex and Bison to recognize a small, artificial subset of
English. It does not understand meaning; it only decides whether a sentence
has a valid grammatical shape according to a fixed vocabulary and a
context-free grammar.

## How the tokens work (english.l)

Flex's job is only to chop the input stream into tokens -- it has no idea
what a "sentence" or a "subject" is. Each vocabulary word is matched by its
own literal pattern and mapped to a token category:

- `ARTICLE_A`, `ARTICLE_THE` -- "a", "the"
- `ADJ` -- "black", "orange", "big", "small"
- `NOUN_SG` -- "dog", "cat", "cow"
- `NOUN_PL` -- "dogs", "cats", "cows"
- `VERB_SG` -- "likes", "hates", "ignores", "irritates"
- `VERB_PL` -- "like", "hate", "ignore", "irritate"
- `AND` -- "and"
- `PERIOD` -- "."

Notice that number (singular vs. plural) is baked directly into the token
type. Flex can't do recursion or count agreement, so it can't tell us
whether a sentence agrees in number -- but it *can* tell us, at the lexical
level, "this specific word is the singular form" vs. "this specific word is
the plural form." That distinction is what lets Bison's grammar rules
enforce agreement later.

### Trailing context

Several vocabulary words are prefixes of other vocabulary words: "dog" is a
prefix of "dogs", "like" is a prefix of "likes", "a" is a prefix of "and".
Flex's normal maximal-munch rule (always take the longest match) already
resolves those particular cases correctly. But relying on maximal munch
alone is fragile: if a word from our fixed vocabulary happens to be a
prefix of some other string in the input that *isn't* one of our words
(e.g. a typo, or a real English word we didn't define, like "category"
starting with "cat"), Flex would still match the short vocabulary word as a
token and leave a meaningless leftover fragment behind, which produces a
confusing downstream error instead of a clean rejection of that word.

To guard against this, every word rule uses trailing context (the `/`
operator):

```
"cat"/{boundary}   { return NOUN_SG; }
```

This tells Flex: match `"cat"` only when it is immediately followed by a
`boundary` character (whitespace or a period), but do **not** consume that
boundary character -- it's left in the input stream so it can be matched by
its own rule afterward (whitespace is discarded, and `.` becomes the
`PERIOD` token). This is exactly the technique described in the assignment
for making sure words are only recognized when they stand on their own,
without accidentally swallowing (or being swallowed by) the punctuation
that follows them.

Two catch-all rules come last:
- `[a-zA-Z]+` reports a lexical error for any word not in the vocabulary.
- `.` reports a lexical error for any other unexpected character.

Both call `exit(1)`, so any lexical problem immediately produces a non-zero
exit code, as required.

## How the grammar works (english.y)

The grammar mirrors the assignment's description directly:

```
input     -> /* empty */ | input sentence
sentence  -> subject_sg VERB_SG object PERIOD
           | subject_pl VERB_PL object PERIOD

subject_sg -> np_sg
subject_pl -> np_pl | conj_np
object     -> np_sg | np_pl | conj_np

np_sg   -> ARTICLE_A   adj_opt NOUN_SG
         | ARTICLE_THE adj_opt NOUN_SG
np_pl   -> adj_opt NOUN_PL
         | ARTICLE_THE adj_opt NOUN_PL
adj_opt -> /* empty */ | ADJ

np_item -> np_sg | np_pl
conj_np -> np_item AND np_item
         | conj_np AND np_item
```

`input` accepts zero or more sentences, the same "list" pattern used in
`calculator.y`.

`np_sg` and `np_pl` are the two forms a simple noun phrase can take: a
singular noun phrase always requires an article ("a" or "the"), while a
plural noun phrase's article is optional and can only be "the" (never "a"),
matching the assignment's rule that "a dogs" is invalid. Both allow an
optional adjective via `adj_opt`.

`conj_np` handles noun phrases joined with "and". It is left-recursive
(`conj_np -> conj_np AND np_item`), which lets it accept chains of any
length, such as "the dog and the cat and the cow", not just exactly two
noun phrases.

### Where agreement is enforced

This is the most interesting/complex part of the grammar. Flex cannot
enforce subject/verb agreement -- it only knows individual words. Bison
can't do it with a single "verb" rule either, because a CFG rule like
`sentence -> subject VERB object PERIOD` would accept *any* subject with
*any* verb, singular or plural, regardless of whether they match.

The trick is to split the grammar into two completely separate paths based
on number, and never let them mix:

- `sentence -> subject_sg VERB_SG object PERIOD`
- `sentence -> subject_pl VERB_PL object PERIOD`

`subject_sg` can only ever be built from `np_sg` (a genuinely singular noun
phrase), and `subject_pl` can only be built from `np_pl` or `conj_np`
(a genuinely plural noun phrase, or a conjunction, which is always treated
as plural regardless of how many singular parts it combines). Because
`VERB_SG` and `VERB_PL` are distinct token types coming out of the lexer,
Bison is forced to pick the branch of `sentence` whose subject alternative
matches whichever verb form is actually next in the token stream. If the
subject was built as `np_sg` (e.g. "the dog") but the next token is
`VERB_PL` ("like"), neither `sentence` alternative can be completed, so
Bison reports a syntax error -- exactly the "the dog like the cat." case
that should be rejected. The same mechanism rejects "the dogs likes the
cat." in the other direction.

In other words, agreement isn't checked with semantic logic or extra C
code -- it falls directly out of the fact that the grammar has no
production that lets a singular noun-phrase derivation and a `VERB_PL`
token (or vice versa) appear in the same `sentence`.

The object noun phrase, by contrast, has no such restriction (`object ->
np_sg | np_pl | conj_np`), since the assignment only requires
subject/verb agreement, not object agreement with anything.

## Building and testing

```
make        # runs bison -d, flex, and gcc
make test   # feeds tests/valid.txt and tests/invalid.txt through ./english
```

`./english` reads sentences from stdin, prints `Valid sentence` and exits 0
for each syntactically valid run, or prints an error to stderr and exits
non-zero on the first invalid token or construct it finds.
