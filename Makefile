CC = gcc
CFLAGS = -Wall

all: english

english.tab.c english.tab.h: english.y
	bison -d english.y

lex.yy.c: english.l english.tab.h
	flex english.l

english: english.tab.c lex.yy.c
	$(CC) $(CFLAGS) english.tab.c lex.yy.c -o english

clean:
	rm -f english english.tab.c english.tab.h lex.yy.c

test: english
	@./tests/run_tests.sh

.PHONY: all clean test
