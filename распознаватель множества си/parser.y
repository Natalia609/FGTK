%{
#include <stdio.h>

int yylex(void);
void yyerror(const char* s);
void count_error(int line, const char* msg);
extern int yylineno;
%}

%token INT FLOAT CHAR VOID STRUCT CONST STATIC
%token IF ELSE WHILE DO FOR RETURN BREAK CONTINUE SWITCH CASE DEFAULT SIZEOF
%token ID NUMBER STRING CHAR_LIT
%token PLUS_ASSIGN MINUS_ASSIGN INC DEC EQ NE LE GE AND OR SHL SHR ARROW
%token TRUE FALSE

%right '=' PLUS_ASSIGN MINUS_ASSIGN
%left OR
%left AND
%left EQ NE
%left '<' '>' LE GE
%left SHL SHR   // <<  >> 
%left '+' '-'
%left '*' '/' '%'
%right '!' MINUS
%left INC DEC '[' '(' '.' ARROW

%nonassoc NO_ELSE
%nonassoc ELSE

%%

program:
      /* пусто */
    | program item
    ;

item:
      decl
    | func
    | STRUCT ID '{' fields '}' ';'
    | error ';'   { count_error(yylineno, "error in anounce"); yyerrok; }
    | error '}'   { count_error(yylineno, "error in function"); yyerrok; }
    ;

fields:
      decl
    | fields decl
    ;

type:
      INT
    | FLOAT
    | CHAR
    | VOID
    | STRUCT ID
    | CONST type
    | STATIC type
    ;

stars:
      /* пусто */
    | stars '*'
    ;

decl:
      type vars ';'
    ;

vars:
      var
    | vars ',' var
    ;

var:
      stars ID
    | stars ID '=' expr
    | stars ID '[' NUMBER ']'
    | stars ID '[' ']' 
    | stars ID '[' ']' '=' '{' args '}'
    | stars ID '[' NUMBER ']' '=' '{' args '}'
    ;

func:
      type stars ID '(' params ')' block
    | type stars ID '(' params ')' ';'
    ;

params:
      /* пусто */
    | param_list
    ;

param_list:
      param
    | param_list ',' param
    ;

param:
      type stars
    | type stars ID
    | type stars ID '[' ']'
    | type stars ID '[' NUMBER ']'
    ;

block:
      '{' stmts '}'
    ;

stmts:
      /* пусто */
    | stmts stmt
    ;

stmt:
      decl
    | expr ';'
    | block
    | IF '(' expr ')' stmt %prec NO_ELSE
    | IF '(' expr ')' stmt ELSE stmt
    | WHILE '(' expr ')' stmt
    | DO stmt WHILE '(' expr ')' ';'
    | FOR '(' maybe_expr ';' maybe_expr ';' maybe_expr ')' stmt
    | FOR '(' type vars ';' maybe_expr ';' maybe_expr ')' stmt
    | SWITCH '(' expr ')' stmt
    | CASE expr ':'
    | DEFAULT ':'
    | RETURN ';'
    | RETURN expr ';'
    | BREAK ';'
    | CONTINUE ';'
    | error ';'   { count_error(yylineno, "error in operator"); yyerrok; }
    ;

maybe_expr:
      /* пусто */
    | expr
    ;

expr:
      expr '=' expr
    | expr PLUS_ASSIGN expr // +=
    | expr MINUS_ASSIGN expr //-=
    | expr OR expr
    | expr AND expr
    | expr EQ expr // ==
    | expr NE expr // !=
    | expr '<' expr
    | expr '>' expr
    | expr LE expr  //<=
    | expr GE expr  //>=
    | expr SHL expr  //<<
    | expr SHR expr  //>>
    | expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
    | expr '%' expr
    | '!' expr
    | '-' expr %prec MINUS
    | '*' expr %prec MINUS
    | '&' expr %prec MINUS
    | INC expr %prec MINUS
    | DEC expr %prec MINUS
    | expr INC
    | expr DEC
    | expr '[' expr ']'
    | expr '(' ')'
    | expr '(' args ')'
    | expr '.' ID
    | expr ARROW ID
    | '(' expr ')'
    | '(' type stars ')' expr %prec MINUS   // (int*) ...
    | SIZEOF '(' type stars ')'
    | ID
    | NUMBER
    | STRING
    | CHAR_LIT
    | TRUE
    | FALSE
    ;

args:
      expr
    | args ',' expr
    ;

%%
