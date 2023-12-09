CXX = clang++
FLEX = win_flex
BISON = win_bison
ARGS = -c -std=c++20 -Isrc -Ibuild
LINK_ARGS = -std=c++20

all: build/main.o build/parser.o build/bison.tab.o build/lex.o build/library.o
	$(CXX) $(LINK_ARGS) $^ -o build/umake

build/lex.cpp: src/lex.ll
	$(FLEX) -o build/lex.cpp src/lex.ll

build/bison.tab.cpp build/bison.tab.hpp: src/bison.yy
	$(BISON) -d -o build/bison.tab.cpp src/bison.yy

build/bison.tab.o: build/bison.tab.cpp src/parser.h 
	$(CXX) $(ARGS) build/bison.tab.cpp -o build/bison.tab.o

build/parser.o: src/parser.cpp build/bison.tab.hpp src/parser.h
	$(CXX) $(ARGS) src/parser.cpp -o build/parser.o 

build/lex.o: build/lex.cpp src/parser.h build/bison.tab.hpp
	$(CXX) $(ARGS) build/lex.cpp -o build/lex.o

build/main.o: src/main.cpp src/parser.h
	$(CXX) $(ARGS) src/main.cpp -o build/main.o

build/library.cpp: etc/library.mk
	echo "const char* templateStr = R\"templateStr(" > build/library.cpp
	cat etc/library.mk >> build/library.cpp
	echo ")templateStr\";" >> build/library.cpp

build/library.o: build/library.cpp
	$(CXX) $(ARGS) build/library.cpp -o build/library.o

clean:
	rm -rf build/*