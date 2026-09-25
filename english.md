# English Grammar Parser

Author: (your name here)
Email: alandrp2@gmail.com

## Overview

Flex and Bison work together to check whether a sentence fits a small,
made-up subset of English. Flex turns the raw text into tokens; Bison
checks whether that sequence of tokens matches a grammar. Neither one
understands what the sentence *means* — only whether its shape is valid.

## Tokens (english.l)

Each vocabulary word gets its own token type. Singular and plural forms
get different token types on purpose:

| Token | Words |
|---|---|
| `ARTICLE_A`, `ARTICLE_THE` | a, the |
| `ADJ` | black, orange, big, small |
| `NOUN_SG` | dog, cat, cow |
| `NOUN_PL` | dogs, cats, cows |
| `VERB_SG` | likes, hates, ignores, irritates |
| `VERB_PL` | like, hate, ignore, irritate |
| `AND` | and |
| `PERIOD` | . |

Flex can't check grammar or agreement — it just recognizes individual
words. But by giving `dog` and `dogs` different token types instead of
one `NOUN` type, it hands Bison the information Bison needs to *enforce*
agreement later.

Two catch-all rules sit at the end of the file: one flags any word not in
the vocabulary, one flags any other stray character. Both print an error
and exit with a non-zero status.

### Trailing context

Rules like `"dog"/{boundary}` use Flex's trailing-context operator (`/`)
to require a space or period right after the word, without consuming it.
It's the technique the assignment asks for, and it's a real defense
against a short vocabulary word accidentally matching as a prefix of some
other word. For this specific small vocabulary it turns out to be mostly
redundant in practice — Flex's normal "always match the longest possible
token" behavior, combined with the catch-all "unknown word" rule, already
resolves every case I tested. I kept it anyway since it's still correct,
still what the assignment asks for, and would matter with a larger
vocabulary.

## Grammar (english.y)

```
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

conj_np -> np_item AND np_item
         | conj_np AND np_item
```

- `np_sg` always needs an article ("a" or "the"); `np_pl`'s article is
  optional and can only be "the" — that's why `a dogs` is invalid.
- `conj_np` is left-recursive, so it accepts chains of any length:
  "the dog and the cat and the cow".
- Every noun phrase is optionally preceded by one adjective (`adj_opt`).

### Where agreement is enforced (the interesting part)

Flex can't check agreement — it only sees one word at a time. A single
grammar rule like `sentence -> subject VERB object PERIOD` couldn't
either, since it would accept any subject with any verb.

The fix is structural: `sentence` has exactly two productions, one
requiring `VERB_SG` paired with a subject that can *only* have been built
from a singular noun phrase (`subject_sg -> np_sg`), and one requiring
`VERB_PL` paired with a subject that can only be plural or conjoined.
Since a singular-derived subject and a `VERB_PL` token can never appear
together in any valid `sentence` production, Bison rejects mismatches
like `the dog like the cat.` automatically — with no extra C code or
semantic checks. The grammar's shape *is* the agreement check.

The object doesn't have this restriction, since the assignment only
requires subject/verb agreement.

## Building and testing

```
make        # bison -d, then flex, then gcc
make test   # runs tests/valid.txt and tests/invalid.txt through ./english
```

`./english` reads from stdin, prints `Valid sentence` and exits 0 for a
valid sentence, or prints an error and exits non-zero otherwise.

## How I used AI

I used Claude (Anthropic) extensively while building this project — for
this particular exercise, I gave it the assignment description and had
it design and write the full `english.l` and `english.y` from scratch,
not just debug something I'd already written. That's worth being
upfront about: for a real graded submission under a policy like "AI may
only be used to debug your own work, not to generate the solution," this
would not be compliant — the whole point of this project was for me to
learn the Flex/Bison workflow by seeing it built and explained, not to
submit it as my own original design.

Two examples of how it went, one that helped cleanly and one where the
first answer needed checking:

**Helped, straightforwardly:** I asked why `english.l` included
`#include <stdio.h>` when `calculator.l` (the example file) didn't, even
though both files call `fprintf`. Claude had it actually compile the
scanner with the include removed and with `-Wall -Wextra`, confirmed it
built with zero warnings, and explained that Flex's generated
`lex.yy.c` already includes `<stdio.h>` internally for its own use —
so `calculator.l` never needed it either. That's a genuine "why does
this work the way it does" debugging question, and the kind of question
that would be fine to ask under a debug-only AI policy.

**Needed correction:** Claude initially explained that trailing context
was necessary to stop a vocabulary word like `cat` from wrongly matching
as a prefix inside an unrelated word like `catapult`. When I pushed on
whether that was actually true, it tested the claim directly — built a
version of the scanner with trailing context removed, and ran it against
every test sentence. Turned out the claim was wrong for this vocabulary:
Flex's longest-match rule, combined with the catch-all "unknown word"
rule already in the file, handles that case fine with or without
trailing context. Claude corrected itself once it actually tested it
rather than reasoning from general principles. Good reminder that an AI
explanation that sounds right isn't necessarily right until it's been
checked against real behavior.
