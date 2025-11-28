PROJ=pcm
ROOTDIR =$(shell pwd)

CFLAGS  +=  -I$(ROOTDIR)/
SRC     +=  $(ROOTDIR)/$(PROJ).c

default: all

all: clean
	($(CC) $(CFLAGS) ${SRC}	-o $(PROJ)) 
clean:
	rm -rf *.o
	rm -rf $(PROJ)
