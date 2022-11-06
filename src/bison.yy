
%{
#include <cstdint>
#include <cstdio>
#include "parser.h"
extern int yylex(void*);
extern void yyerror(void* lexer, struct umake::parser* P, const char* msg);
%}

%define parse.trace
%define parse.error verbose

%union {
    std::vector<std::string>* ids;
    struct umake::Rule* rule;
    char *str;
    std::string* string;
    bool b;
}

/* The driver is passed by reference to the parser and to the scanner. This
 * provides a simple but effective pure interface, not relying on global
 * variables. */
%lex-param {void *scanner} 
%parse-param {void *scanner} {struct umake::parser* P} 

%token<str> ID FILE_IN FILE_OUT DIR_IN DIR_OUT SHELL 

%type<b> and
%type<ids> IDs shell_blocks
%type rules
%type<rule> rule    
%type<string> shell_block
%start rules 

%%

rules: rules rule empty_lines { P->add($2); }
      | empty_lines rule empty_lines  { P->add($2); }
      ;

empty_lines: | empty_lines '\n' ;


and: '&' { $$ = true; }
    |  { $$ = false; }
    ;

rule: IDs and ':' IDs '\n'  { $$ = new umake::Rule($1, $4, nullptr, $2, nullptr); }
    | IDs and ':' IDs  '|' IDs '\n'  { $$ = new umake::Rule($1, $4, $6, $2, nullptr);  }
    | IDs and ':' IDs shell_blocks { $$ = new umake::Rule($1, $4, nullptr, $2, $5);  }
    | IDs and ':' IDs  '|' IDs shell_blocks { $$ = new umake::Rule($1, $4, nullptr, $2, $7);  }
    ;

IDs: IDs ID { $$->push_back(std::string($2)); free($2); }
   |  { $$ = new std::vector<std::string>(); }
   ;

shell_blocks:  shell_blocks shell_block { $$->push_back(*($2)); delete $2; }
             | shell_block { $$ = new std::vector<std::string>(); $$->push_back(*$1); delete $1; }
             ;

shell_block: shell_block SHELL { *($$) += $2; free($2); }
           | SHELL { $$ = new std::string($1); free($1); }
           ;

%%


void yyerror(void* lexer, struct umake::parser* P, const char* msg)
{
	fprintf(stderr, "Error: %s\n", msg);
}