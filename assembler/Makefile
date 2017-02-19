CC = gcc

.PHONY: all
kasm: lex.yy.c y.tab.c
	${CC} $^ -DYYERROR_VERBOSE -ly -ll -o kasm

lex.yy.c : shino.l
	flex -l $^

y.tab.c y.tab.h : shino.y
	bison -dv -y $^

.PHONY: clean
clean:
	rm -f lex.yy.c y.tab.c y.tab.h y.output kasm
