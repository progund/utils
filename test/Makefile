
PROGS=hello Hello.class

check: $(PROGS)
	./test.sh

hello: hello.c
	gcc $< -o hello


Hello.class: Hello.java
	javac $< 


clean:
	-rm -f *.o $(PROGS) *~ *.class a.out
