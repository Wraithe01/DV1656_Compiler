%defines
%define parse.error verbose

%code requires{
#include "settings.h"
#include "Node.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct Ident
{
  const char* identifier;
  int lineno;
}Ident_s;
}

%code{
Node_s* root;
Node_s* classes;
extern int yylineno;
extern int yylex(void);
extern int lex_colno;
void yyerror (char const * s)  /* Called by yyparse on error */
{
  fprintf(stderr, "[-] \t@error at line %d: %s\n", yylineno, s);
}
}

%union {
  int intval;
  const char* strval;
  Node_s* nodeval;
  Ident_s ident;
}

%token <intval> PUBLIC CLASS STATIC VOID MAIN STRING RETURN INT BOOL IF ELSE WHILE PRINTLN AND OR EQUAL LENGTH TRUE FALSE THIS NEW INTEGER_LITERAL IDENTIFIER

%right then ELSE
%left '='
%left OR
%left AND
%left EQUAL
%left '>' '<'
%left '-' '+'
%left '*' '/'
%left '!'
%left '.' '['
%left '('

%start Goal

%type <nodeval> ParametersExp RecParamExp Expression RecStatement Statement VarDeclaration RecParameter Parameters RecMethodBody MethodDeclaration RecVarDecl RecMethodDecl ClassDeclaration RecMain MainClass RecClassDecl Goal VariableDeclarations MethodDeclarations
%type <strval> Type
%type <ident> Identifier

%%
Goal:
          RecClassDecl { $$ = root = initNodeTree("ROOT", "", yylineno, lex_colno);
                                        addSubTree($$, $1);}
;

RecClassDecl:
          MainClass              { $$ = initNodeTree("CLASSES", "", yylineno, lex_colno);
                                          addSubTree($$, $1); }
        | RecClassDecl ClassDeclaration { $$ = $1;
                                          addSubTree($$, $2); }
;

RecMain:
          Statement         { $$ = $1; }
        | RecMain Statement { $$ = $2;
                              addSubTree($$, $1); }
;
MainClass:
          PUBLIC CLASS Identifier
          '{'
            PUBLIC STATIC VOID MAIN '(' STRING '[' ']' Identifier ')'
            '{'
              RecMain
            '}'
          '}'                                                           { $$ = initNodeTreeRecord("MAIN CLASS", $3.identifier, $3.lineno, lex_colno, classRecord);
                                                                          Node_s* node1 = initNodeTree("METHODS", "", yylineno, lex_colno);
                                                                          Node_s* node2 = initNodeTreeRecord("METHOD DECLARATION", "main", yylineno, lex_colno, methodRecord);
                                                                          Node_s* node3 = initNodeTree("PARAMETERS", "", yylineno, lex_colno);
                                                                          Node_s* node4 = initNodeTree("METHOD BODY", "", yylineno, lex_colno);

                                                                          addSubTree(node2, initNodeTree("RETURN TYPE", "VOID", yylineno, lex_colno));
                                                                          addSubTree(node3, initNodeTreeRecord("STRING ARRAY", $13.identifier, yylineno, lex_colno, variableRecord));
                                                                          addSubTree(node2, node3);
                                                                          addSubTree(node4, $16);
                                                                          addSubTree(node2, node4);
                                                                          addSubTree(node1, node2);
                                                                          addSubTree($$, node1); }
;

RecVarDecl:
          VarDeclaration            { $$ = initNodeTree("VARIABLES", "", yylineno, lex_colno);
                                      addSubTree($$, $1); }
        | RecVarDecl VarDeclaration { $$ = $1;
                                      addSubTree($$, $2); }
;
VariableDeclarations:
          /* empty */ { $$ = NULL; }
        | RecVarDecl  { $$ = $1; }
;
RecMethodDecl:
          MethodDeclaration               { $$ = initNodeTree("METHODS", "", yylineno, lex_colno);
                                            addSubTree($$, $1); }
        | RecMethodDecl MethodDeclaration { $$ = $1;
                                            addSubTree($$, $2); }
;
MethodDeclarations:
          /* empty */   { $$ = NULL; }
        | RecMethodDecl { $$ = $1; }
;
ClassDeclaration:
          CLASS Identifier
          '{'
              VariableDeclarations
              MethodDeclarations
          '}'                 { $$ = initNodeTreeRecord("CLASS DECLARATION", $2.identifier, $2.lineno, lex_colno, classRecord);
                                addSubTree($$, $4);
                                addSubTree($$, $5); }
;

RecParameter:
          Type Identifier                   { $$ = initNodeTree("PARAMETERS", "", yylineno, lex_colno);
                                              Node_s* node = initNodeTreeRecord($1, $2.identifier, $2.lineno, lex_colno, variableRecord);
                                              addSubTree($$, node); }
        | RecParameter ',' Type Identifier  { $$ = $1;
                                              Node_s* node = initNodeTreeRecord($3, $4.identifier, $4.lineno, lex_colno, variableRecord);
                                              addSubTree($$, node); }
;
Parameters:
          /* empty */     { $$ = NULL; }
        |  RecParameter   { $$ = $1; }
;
RecMethodBody:
          /* empty */                   { $$ = initNodeTree("METHOD BODY", "", yylineno, lex_colno); }
        | RecMethodBody VarDeclaration  { $$ = $1;
                                          addSubTree($$, $2); }
        | RecMethodBody Statement       { $$ = $1;
                                          addSubTree($$, $2); }
;
MethodDeclaration:
          PUBLIC Type Identifier '(' Parameters ')'
          '{'
            RecMethodBody
            RETURN Expression ';'
          '}'                                       { $$ = initNodeTreeRecord("METHOD DECLARATION", $3.identifier, $3.lineno, lex_colno, methodRecord);
                                                      addSubTree($$, initNodeTree("RETURN TYPE", $2, yylineno, lex_colno));
                                                      addSubTree($$, $5);
                                                      addSubTree($$, $8);
                                                      Node_s* node = initNodeTree("RETURN EXPRESSION", "", yylineno, lex_colno);
                                                      addSubTree(node, $10);
                                                      addSubTree($$, node); }
;

VarDeclaration:
          Type Identifier ';' { $$ = initNodeTree("VARIABLE DECLARATION", "", yylineno, lex_colno);
                                addSubTree($$, initNodeTreeRecord($1, $2.identifier, yylineno, lex_colno, variableRecord)); }
;

Type:
          INT '[' ']' { $$ = "INTEGER ARRAY"; }
        | BOOL        { $$ = "BOOLEAN"; }
        | INT         { $$ = "INTEGER"; }
        | Identifier  { $$ = $1.identifier; }
;

RecStatement:
          /* empty */             { $$ = NULL; }
        | RecStatement Statement  { $$ = $2;
                                    addSubTree($$, $1); }
;
Statement:
          '{' RecStatement '}'                                    { $$ = $2; }
        | IF '(' Expression ')' Statement              %prec then { $$ = initNodeTree("IF STATEMENT OPEN", "", yylineno, lex_colno);
                                                                    addSubTree($$, $3);
                                                                    addSubTree($$, $5); }
        | IF '(' Expression ')' Statement ELSE Statement          { $$ = initNodeTree("IF STATEMENT CLOSED", "", yylineno, lex_colno);
                                                                    addSubTree($$, $3);
                                                                    addSubTree($$, $5);
                                                                    addSubTree($$, $7); }
        | WHILE '(' Expression ')' Statement                      { $$ = initNodeTree("WHILE LOOP", "", yylineno, lex_colno);
                                                                    addSubTree($$, $3);
                                                                    addSubTree($$, $5); }
        | PRINTLN '(' Expression ')' ';'                          { $$ = initNodeTree("PRINT LINE", "", yylineno, lex_colno);
                                                                    addSubTree($$, $3); }
        | Identifier '=' Expression ';'                           { $$ = initNodeTree("ASSIGN", $1.identifier, yylineno, lex_colno);
                                                                    addSubTree($$, $3); }
        | Identifier '[' Expression ']' '=' Expression ';'        { $$ = initNodeTree("ASSIGN INDEX", $1.identifier, yylineno, lex_colno);
                                                                    addSubTree($$, $3);
                                                                    addSubTree($$, $6); }
;

RecParamExp:
          Expression                    { $$ = initNodeTree("INPUT PARAMETERS", "", yylineno, lex_colno);
                                          addSubTree($$, $1); }
        | RecParamExp ',' Expression   { $$ = $1;
                                          addSubTree($$, $3); }
;
ParametersExp:
          /* empty */     { $$ = NULL; }
        |  RecParamExp  { $$ = $1; }
;
Expression:
        Expression AND Expression                                 { $$ = initNodeTree("AND", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1);
                                                                    addSubTree($$, $3); }
      | Expression OR Expression                                  { $$ = initNodeTree("OR", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1);
                                                                    addSubTree($$, $3); }
      | Expression '<' Expression                                 { $$ = initNodeTree("LESS THAN", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1);
                                                                    addSubTree($$, $3); }
      | Expression '>' Expression                                 { $$ = initNodeTree("GREATER THAN", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1);
                                                                    addSubTree($$, $3); }
      | Expression EQUAL Expression                               { $$ = initNodeTree("EQUAL", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1);
                                                                    addSubTree($$, $3); }
      | Expression '+' Expression                                 { $$ = initNodeTree("ADDITION", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1);
                                                                    addSubTree($$, $3); }
      | Expression '-' Expression                                 { $$ = initNodeTree("SUBTRACTION", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1);
                                                                    addSubTree($$, $3); }
      | Expression '*' Expression                                 { $$ = initNodeTree("MULTIPLICATION", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1);
                                                                    addSubTree($$, $3); }
      | Expression '/' Expression                                 { $$ = initNodeTree("DIVISION", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1);
                                                                    addSubTree($$, $3); }
      | Expression '[' Expression ']'                             { $$ = initNodeTree("INDEXATION", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1);
                                                                    addSubTree($$, $3); }
      | Expression '.' LENGTH                                     { $$ = initNodeTree("LENGTH", "", yylineno, lex_colno);
                                                                    addSubTree($$, $1); }
      | Expression '.' Identifier '(' ParametersExp ')'           { $$ = $1;
                                                                    Node_s* node = initNodeTree("FUNCTION CALL", $3.identifier, yylineno, lex_colno);
                                                                    addSubTree(node, $5);
                                                                    addSubTree($$, node); }
      | INTEGER_LITERAL                                           { $$ = initNodeTree("", yylval.strval, yylineno, lex_colno); }
      | TRUE                                                      { $$ = initNodeTree("TRUE", "", yylineno, lex_colno); }
      | FALSE                                                     { $$ = initNodeTree("FALSE", "", yylineno, lex_colno); }
      | Identifier                                                { $$ = initNodeTree("", $1.identifier, yylineno, lex_colno); }
      | THIS                                                      { $$ = initNodeTree("THIS", "", yylineno, lex_colno); }
      | NEW INT '[' Expression ']'                                { $$ = initNodeTree("ARRAY INSTANTIATION", "", yylineno, lex_colno);
                                                                    addSubTree($$, $4); }
      | NEW Identifier '(' ')'                                    { $$ = initNodeTree("CLASS INSTANTIATION", $2.identifier, yylineno, lex_colno); }
      | '!' Expression                                            { $$ = initNodeTree("NEGATION", "", yylineno, lex_colno);
                                                                    addSubTree($$, $2); }
      | '(' Expression ')'                                        { $$ = $2; }
;

Identifier:
      IDENTIFIER  { Ident_s id;
                    id.identifier = yylval.strval;
                    id.lineno = yylineno;
                    $$ = id; }
;
/* End of grammar */
%%
