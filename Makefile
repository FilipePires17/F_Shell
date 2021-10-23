mysh: y.tab.c lex.yy.c shell.y shell.l myshell.o queue.o 
	gcc -Wall -I. -g y.tab.c lex.yy.c queue.o myshell.o -o mysh

y.tab.c: lex.yy.c shell.y shell.l shell.h
	yacc --defines shell.y

lex.yy.c: shell.l
	lex shell.l

myshell.o: myshell.c shell.h
	gcc -Wall -I. -g -c myshell.c

queue.o: queue.c queue.h
	gcc -Wall -I. -g -c queue.c

# Clean up!
clean:
	rm -f *~
	rm -f \#*
	rm -f *.bak *.o core
	rm -f y.tab.c mysh lex.yy.c y.tab.h shell.c
