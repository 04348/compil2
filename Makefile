LIBS = -lfl
CCFLAGS = -std=c99 -g

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

clean:
	rm -f *.yy.c
	rm -f *.tab.c
	rm -f bison_ipp.h
	rm -f *.o