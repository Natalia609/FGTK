%{
#include <stdio.h>
#include "parser.h"

extern FILE* out_file;
void token_output(const char* token);
void count_error(int line, const char* msg);
%}

%option noyywrap
%option yylineno

%x COMMENT

%%

"/*"            { BEGIN(COMMENT); }
<COMMENT>"*/"   { BEGIN(INITIAL); }
<COMMENT>\n     { }
<COMMENT>.      { }

"//".*          { }

^[ \t]*#.*      { if (out_file) fprintf(out_file, "%s\n", yytext); }

[ \t\r]+        { }
\n              { }

"int"           { token_output(yytext); return INT; }
"float"         { token_output(yytext); return FLOAT; }
"char"          { token_output(yytext); return CHAR; }
"void"          { token_output(yytext); return VOID; }
"struct"        { token_output(yytext); return STRUCT; }
"const"         { token_output(yytext); return CONST; }
"static"        { token_output(yytext); return STATIC; }
"if"            { token_output(yytext); return IF; }
"else"          { token_output(yytext); return ELSE; }
"while"         { token_output(yytext); return WHILE; }
"do"            { token_output(yytext); return DO; }
"for"           { token_output(yytext); return FOR; }
"return"        { token_output(yytext); return RETURN; }
"break"         { token_output(yytext); return BREAK; }
"continue"      { token_output(yytext); return CONTINUE; }
"switch"        { token_output(yytext); return SWITCH; }
"case"          { token_output(yytext); return CASE; }
"default"       { token_output(yytext); return DEFAULT; }
"sizeof"        { token_output(yytext); return SIZEOF; }
"true"          { token_output(yytext); return TRUE; }
"false"         { token_output(yytext); return FALSE; }

"+="            { token_output(yytext); return PLUS_ASSIGN; }
"-="            { token_output(yytext); return MINUS_ASSIGN; }
"++"            { token_output(yytext); return INC; }
"--"            { token_output(yytext); return DEC; }
"=="            { token_output(yytext); return EQ; }
"!="            { token_output(yytext); return NE; }
"<="            { token_output(yytext); return LE; }
">="            { token_output(yytext); return GE; }
"&&"            { token_output(yytext); return AND; }
"||"            { token_output(yytext); return OR; }
"<<"            { token_output(yytext); return SHL; }
">>"            { token_output(yytext); return SHR; }
"->"            { token_output(yytext); return ARROW; }

"+"             { token_output(yytext); return '+'; }
"-"             { token_output(yytext); return '-'; }
"*"             { token_output(yytext); return '*'; }
"/"             { token_output(yytext); return '/'; }
"%"             { token_output(yytext); return '%'; }
"="             { token_output(yytext); return '='; }
"<"             { token_output(yytext); return '<'; }
">"             { token_output(yytext); return '>'; }
"!"             { token_output(yytext); return '!'; }
"&"             { token_output(yytext); return '&'; }
"("             { token_output(yytext); return '('; }
")"             { token_output(yytext); return ')'; }
"{"             { token_output(yytext); return '{'; }
"}"             { token_output(yytext); return '}'; }
"["             { token_output(yytext); return '['; }
"]"             { token_output(yytext); return ']'; }
";"             { token_output(yytext); return ';'; }
","             { token_output(yytext); return ','; }
":"             { token_output(yytext); return ':'; }
"."             { token_output(yytext); return '.'; }

[0-9]+"."[0-9]+         { token_output(yytext); return NUMBER; }
[0-9]+                  { token_output(yytext); return NUMBER; }

\"(\\.|[^"\\\n])*\"     { token_output(yytext); return STRING; }
\'(\\.|[^'\\\n])\'      { token_output(yytext); return CHAR_LIT; }

[a-zA-Z_][a-zA-Z0-9_]*  { token_output(yytext); return ID; }

.               { count_error(yylineno, "dont know what it is"); }

%%
