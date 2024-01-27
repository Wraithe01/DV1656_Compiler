# Write the name of the compile target here, will be used in "make run"
override COMPILE_TARGET ?= test_files/lexical_errors/UnknownSymbol.java


VERSION = std=c2x
COMPILE_FLAGS = -g -O0 -Wall -Wextra
COMPILE_FLAGS_EXTRA =

TIDY_FLAGS = -*,clang-diagnostic-*,clang-analyzer-*,readability-*,bugprone-*


LEX_TARGET = lexer.lex
APP_NAME = compiler

all: compile
	clang $(COMPILE_FLAGS) -o $(APP_NAME) $(wildcard *.o) $(COMPILE_FLAGS_EXTRA)

compile: lex lex.yy.c
	clang -c $(COMPILE_FLAGS) $(wildcard *.c) $(COMPILE_FLAGS_EXTRA)

lex:
	flex $(LEX_TARGET)

format:
	clang-format $(wildcard *.c) -style=file --verbose

tidy:
	clang-tidy $(wildcard *.c) -checks=$(TIDY_FLAGS)

run: all
	./$(APP_NAME) $(COMPILE_TARGET)
clean:
	rm *.o lex.yy.c $(APP_NAME)
