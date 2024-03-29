# Write the name of the compile target here, will be used in "make run"
override COMPILE_TARGET ?= test_files/valid/SemanticValidMethodCall.java


VERSION = std=c2x
COMPILE_FLAGS = -g -O0 -Wall -Wextra
COMPILE_FLAGS_EXTRA =

TIDY_FLAGS = -*,clang-diagnostic-*,clang-analyzer-*,readability-*,bugprone-*


LEX_TARGET = lexer.lex
BISON_TARGET = parser
TREE_TARGET = tree
ST_TARGET = st
CFG_TARGET = cfg
APP_NAME = compiler
OUTPUT_FNAME = program.bc
INTERPRETER_NAME = interpreter

all: compile lex.o symboltable.o cfg.o node.o parser.o semantic.o bytecodegeneration.o main.o
	clang $(COMPILE_FLAGS) -o $(APP_NAME) main.o BytecodeGeneration.o SymbolTable.o CFG.o Semantic.o lex.yy.o Node.o $(BISON_TARGET).tab.o $(COMPILE_FLAGS_EXTRA)


interpreter: interpreter.o interlib.o
	clang $(COMPILE_FLAGS) -o $(INTERPRETER_NAME) interpreter.o interlib.o $(COMPILE_FLAGS_EXTRA)

interpreter.o: interpreter.c
	clang -c $(COMPILE_FLAGS) interpreter.c $(COMPILE_FLAGS_EXTRA)

interlib.o: interlib.c
	clang -c $(COMPILE_FLAGS) interlib.c $(COMPILE_FLAGS_EXTRA)


compile: lex lex.yy.c bison $(BISON_TARGET).tab.c

main.o:
	clang -c $(COMPILE_FLAGS) main.c $(COMPILE_FLAGS_EXTRA)
lex.o:
	clang -c $(COMPILE_FLAGS) lex.yy.c $(COMPILE_FLAGS_EXTRA)
node.o:
	clang -c $(COMPILE_FLAGS) Node.c $(COMPILE_FLAGS_EXTRA)
parser.o:
	clang -c $(COMPILE_FLAGS) $(BISON_TARGET).tab.c $(COMPILE_FLAGS_EXTRA)
symboltable.o:
	clang -c $(COMPILE_FLAGS) SymbolTable.c $(COMPILE_FLAGS_EXTRA)
semantic.o:
	clang -c $(COMPILE_FLAGS) Semantic.c $(COMPILE_FLAGS_EXTRA)
cfg.o:
	clang -c $(COMPILE_FLAGS) CFG.c $(COMPILE_FLAGS_EXTRA)
bytecodegeneration.o:
	clang -c $(COMPILE_FLAGS) BytecodeGeneration.c $(COMPILE_FLAGS_EXTRA)

lex:
	flex $(LEX_TARGET)

bison:
	bison $(BISON_TARGET).y

tree:
	dot -Tpdf $(TREE_TARGET).dot -o$(TREE_TARGET).pdf

st:
	dot -Tpdf $(ST_TARGET).dot -o$(ST_TARGET).pdf

cfg:
	dot -Tpdf $(CFG_TARGET).dot -o$(CFG_TARGET).pdf

format:
	clang-format $(wildcard *.c) -style=file --verbose

tidy:
	clang-tidy $(wildcard *.c) -checks=$(TIDY_FLAGS)

run: clean all interpreter
	./$(APP_NAME) $(COMPILE_TARGET) $(OUTPUT_FNAME)
	./$(INTERPRETER_NAME) $(OUTPUT_FNAME)

clean:
	-rm *.o $(BISON_TARGET).tab.c $(BISON_TARGET).tab.h lex.yy.c $(APP_NAME) $(OUTPUT_FNAME) $(INTERPRETER_NAME) tree.dot tree.pdf st.dot st.pdf cfg.dot cfg.pdf interpreter
