parser:	mini_l.lex mini_l.y
	bison -v -d --file-prefix=y mini_l.y
	flex mini_l.lex
	g++ -o parser -x c++ y.tab.c lex.yy.c -lfl 
clean:
	rm -f *.o *~ lex.c lex.yy.c bison.c tok.h y.tab.c y.tab.h y.output parser 
