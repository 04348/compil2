LIBS = -lfl
CCFLAGS = -g -Wall -std=c99
CC = gcc

all:
	make ipp
	make clean

ipp: ipp.y ipp.l utils.c
	bison ipp.y --defines=bison_ipp.h -o ipp.tab.c
	flex -o ipp.yy.c ipp.l
	gcc $(CCFLAGS) $(LIBS) -c ipp.tab.c
	gcc $(CCFLAGS) $(LIBS) -c ipp.yy.c
	gcc $(CCFLAGS) $(LIBS) -c utils.c
	gcc ipp.tab.o ipp.yy.o utils.o -o ipp

c3a: c3a.y c3a.l
	yacc --file-prefix=$@ -d $@.y
	cc  -c -o $@.tab.o $@.tab.c
	lex -o $@.c $@.l
	cc  -c -o $@.o $@.c
	$(CC) $(CCFLAGS) -o $@ $@.tab.o $@.o
	rm -rf $@.c $@.o $@.tab.c $@.tab.o $@.tab.h

clean:
	rm -f *.yy.c
	rm -f *.tab.c
	rm -f bison_ipp.h
	rm -f *.o
