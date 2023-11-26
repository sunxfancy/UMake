
%{
#include <cstdint>
#include <cstdio>
#include "parser.h"

extern int yylex(void*);
extern void yyerror(void* lexer, struct umake::parser* P, const char* msg);

using std::vector;
using std::map;
using std::string;
using std::make_pair;

%}

%define parse.trace
%define parse.error verbose
%locations

%union {
    std::vector<std::string>* ids;
    std::map<std::string, std::string>* attrs;
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

%token<str> ID STRING FILE_IN FILE_OUT DIR_IN DIR_OUT SHELL 

%type<b> and
%type<ids> IDs shell_blocks
%type rules
%type<rule> rule    
%type<attrs> attrs attributes
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

attrs: '[' attributes ']' { $$ = $2; }
    |  { $$ = nullptr; }
    ;

attributes: attributes ',' ID { $$->insert(make_pair($3, "")); }
          | attributes ',' ID '=' ID { $$->insert(make_pair($3, $5)); }
          | attributes ',' ID '=' STRING { $$->insert(make_pair($3, $5)); }
          | ID { $$ = new map<string, string>(); $$->insert(make_pair($1, "")); }
          | ID '=' ID { $$ = new map<string, string>(); $$->insert(make_pair($1, $3)); }
          | ID '=' STRING { $$ = new map<string, string>(); $$->insert(make_pair($1, $3)); }
          ;

rule: attrs IDs and ':' IDs '\n'  { $$ = new umake::Rule($2, $5, nullptr, $3, nullptr, $1); }
    | attrs IDs and ':' IDs  '|' IDs '\n'  { $$ = new umake::Rule($2, $5, $7, $3, nullptr, $1);  }
    | attrs IDs and ':' IDs shell_blocks { $$ = new umake::Rule($2, $5, nullptr, $3, $6, $1);  }
    | attrs IDs and ':' IDs  '|' IDs shell_blocks { $$ = new umake::Rule($2, $5, nullptr, $3, $8, $1);  }
    ;

IDs: IDs ID { $$->push_back(string($2)); free($2); }
   |  { $$ = new vector<string>(); }
   ;

shell_blocks:  shell_blocks shell_block { $$->push_back(*($2)); delete $2; }
             | shell_block { $$ = new vector<string>(); $$->push_back(*$1); delete $1; }
             ;

shell_block: shell_block SHELL { *($$) += $2; free($2); }
           | SHELL { $$ = new string($1); free($1); }
           ;

%%


void yyerror(void* lexer, struct umake::parser* P, const char* msg)
{
	fprintf(stderr, "Error: %s\n", msg);
    fprintf(stderr, "line %d: ", yylloc.first_line);
    const char* p = P->lexer_buffer;
    for (int i = 0; i < yylloc.first_line-1; ++i, ++p) {
        while(*p != '\n' && *p != '\0') ++p;
    }
    const char* start = p;
    while (*p != '\n' && *p != '\0') {
        fprintf(stderr, "%c", *p);
        ++p;
    }
    fprintf(stderr, "\n");
}