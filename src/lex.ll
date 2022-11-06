
%option reentrant noyywrap nounput

%{
#include <cstdint>
#include "parser.h"
#include "bison.tab.hpp"

char* maketoken(const char* data, int len);
#define SAVE_TOKEN     yylval.str = maketoken(yytext, yyleng)
%}


ID [a-zA-Z0-9\-/_%$()\.]*

%%

"#".*               ; 
"\n"                return '\n'; 
{ID}                SAVE_TOKEN; return ID;
"<FI"[^>\n>]*">"    SAVE_TOKEN; return FILE_IN;
"<FO"[^>\n>]*">"    SAVE_TOKEN; return FILE_OUT;
"<DI"[^>\n>]*">"    SAVE_TOKEN; return DIR_IN;
"<DO"[^>\n>]*">"    SAVE_TOKEN; return DIR_OUT;

[&|:]                 return *yytext;;
\n\t.+              SAVE_TOKEN; return SHELL;

[ \t\v\r\f]         ;

%%

char* maketoken(const char* data, int len) {
    char* str = (char*) malloc(len+1);
    strncpy(str, data, len);
    str[len] = 0;
    return str;
}

void umake_scan_string(const char* str, struct umake::parser* P)
{
    yy_switch_to_buffer(yy_scan_string(str, P->lexer), P->lexer);
}