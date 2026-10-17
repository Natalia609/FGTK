%{
#include "ast.h"      
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Глобальный счётчик строк */
int current_line = 1;
%}

%option noyywrap

%%
"main"      { return MAIN; }
"int"       { return INT; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"printf"    { return PRINTF; }

[0-9]+      { yylval.num = atoll(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return IDENT; }

">="        { return GE; }
"<="        { return LE; }
"=="        { return EQ; }
"!="        { return NE; }
">"         { return GT; }
"<"         { return LT; }

"+"         { return '+'; }
"-"         { return '-'; }
"*"         { return '*'; }
"/"         { return '/'; }
"="         { return '='; }
"("         { return '('; }
")"         { return ')'; }
"{"         { return '{'; }
"}"         { return '}'; }
";"         { return ';'; }
","         { return ','; }

\n          { current_line++; }
[ \t\r]+    { /* пропуск пробелов и табуляций */ }
.           { fprintf(stderr, "Неизвестный символ: '%c'\n", yytext[0]); }

%%