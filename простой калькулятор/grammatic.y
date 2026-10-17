%{
#include "poly.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);
%}



%union { 
    long num; 
    int var_idx;    /* для $A..$Z */
    char var_char;  /* для a..z */
    Poly poly; 
}

%token <num> NUM
%token <var_idx> DVAR
%token <var_char> VAR    /*  Один токен для всех строчных букв */
%token PRINT PLUS MINUS MUL DIV POWER DERIV LPAREN RPAREN ASSIGN NEWLINE UMINUS
%type <poly> expr term factor implicit


%left PLUS MINUS      /* сложение/вычитание: левая ассоциативность */
%left MUL             /* умножение: левая ассоциативность */
%right POWER DERIV    /* степень и производная: правая ассоциативность */
%nonassoc UMINUS      /* унарный минус: неассоциативный, высший приоритет */

%%

/* Программа = последовательность операторов. */
program:
    program stmt
  | /* пусто */
  ;


stmt:
    expr NEWLINE {
        /* Если на строке не возникало лексических/семантических ошибок, выводим результат */
        if (!line_error_flag) { print_poly($1); printf("\n"); }
        line_error_flag = 0;
    }
  | PRINT expr NEWLINE {
        if (!line_error_flag) { print_poly($2); printf("\n"); }
        line_error_flag = 0;
    }
     | DVAR ASSIGN expr NEWLINE {
        /*  Проверяем флаг после вычисления expr */
        if (line_error_flag) {
            /* Если в выражении была ошибка — не присваиваем переменную */
            fprintf(stderr, "  [Line %d] Assignment skipped due to error\n", yylineno);
            line_error_flag = 0;
        } else if ($3.deg > 50) {
            fprintf(stderr, "Semantic error [line %d]: degree %d exceeds limit (50)\n", yylineno, $3.deg);
            fflush(stderr); 
            line_error_flag = 1;
        } else {
            var_table[$1] = $3; 
            var_initialized[$1] = 1;
        }
    }
  | NEWLINE { line_error_flag = 0; }
  /* пропускаем ошибочную строку и продолжаем разбор */
  | error NEWLINE { yyerrok; yyclearin; line_error_flag = 0; }
  ;

/* Сложение и вычитание (левая ассоциативность: a-b-c = (a-b)-c) */
expr:
    term
  | expr PLUS term  { $$ = poly_add($1, $3); }
  | expr MINUS term { $$ = poly_sub($1, $3); }
  ;

/* Умножение: явное (*) и неявное */
term:
    factor
  | term MUL factor { $$ = poly_mul($1, $3); }
  | term implicit   %prec MUL { $$ = poly_mul($1, $2); }
  ;

/* Правая часть неявного умножения. 
   Содержит только "положительные" элементы, чтобы выражение x-x не парсилось как x*(-x).*/
implicit:
    NUM              { $$ = make_const($1); }
    
  /*  Обработка любой строчной буквы a..z как переменной */
  | VAR              { $$ = make_var($1); }  /* $1 — это char 'a'..'z' */
  
  /* Запрет смежных переменных: aa, ab, ax, a$B и т.д. */
  | VAR VAR {
        line_error_flag = 1;
        fprintf(stderr, "Lexical error [line %d]: adjacent variables not allowed (e.g., 'ab')\n", yylineno);
        fprintf(stderr, "  Hint: use '*' for multiplication: 'a * b'\n");
        fflush(stderr);
        $$ = make_const(0);  /* Обязательно: возвращаем Poly */
    }
    
  /*  Переменные $A..$Z */
  | DVAR {
        if (!var_initialized[$1]) {
            fprintf(stderr, "Semantic error [line %d]: variable $%c is not initialized\n", yylineno, 'A'+$1);
            fflush(stderr); line_error_flag = 1;
        }
        $$ = var_table[$1];
    }
    
  /*  Скобки */
  | LPAREN expr RPAREN { $$ = $2; }
  
  /* Возведение в степень: любой implicit (число, переменная, выражение в скобках) */
  | implicit POWER implicit {
        int base_is_const = ($1.deg == 0);
        if ($3.deg != 0) {
            fprintf(stderr, "Semantic error [line %d]: exponent must be a constant integer\n", yylineno);
            fflush(stderr); line_error_flag = 1; $$ = $1;
        } else {
            long e = $3.c[0];
            if (e < 0) {
                fprintf(stderr, "Semantic error [line %d]: negative exponent %ld is not allowed\n", yylineno, e);
                fprintf(stderr, "  Hint: polynomial powers must be >= 0\n");
                fflush(stderr); line_error_flag = 1; $$ = $1;
            } else if (!base_is_const && e > 50) {
                fprintf(stderr, "Semantic error [line %d]: degree %ld exceeds limit (50)\n", yylineno, e);
                fflush(stderr); line_error_flag = 1; $$ = $1;
            }
            else {
                $$ = poly_pow($1, (int)e);
            }
        }
    }
  
  /*  Производная */
  | implicit DERIV { $$ = poly_deriv($1); }
  ;
/* Фактор с поддержкой унарного минуса (-x, -(x+1)). 
   %prec UMINUS явно задаёт высший приоритет для этого оператора. */
factor:
    implicit
  | PLUS factor %prec UMINUS { $$ = $2; }           /*  +x обрабатывается как x */
  | MINUS factor %prec UMINUS { $$ = poly_sub(make_const(0), $2); }
  ;

%%

Poly make_const(long v) {
    Poly p = {0}; memset(p.c, 0, sizeof(p.c));
    p.c[0] = v; p.var = 0;
    return p;
}

Poly make_var(char c) {
    Poly p = {0}; memset(p.c, 0, sizeof(p.c));
    p.deg = 1; p.c[1] = 1; p.var = c;
    return p;
}

/*  Нормализация: если полином стал константой, сбрасываем var */
static void normalize_poly(Poly *p) {
    int has_var_terms = 0;
    for (int i = 1; i <= p->deg; i++) {
        if (p->c[i] != 0) {
            has_var_terms = 1;
            break;
        }
    }
    /* Если нет членов со степенью > 1  это константа */
    if (!has_var_terms) {
        p->var = 0;
    }
}

Poly poly_add(Poly a, Poly b) {
    if (a.var != 0 && b.var != 0 && a.var != b.var) {
        fprintf(stderr, "Semantic error [line %d]: cannot add different variables '%c' and '%c'\n", 
                yylineno, a.var, b.var);
        fprintf(stderr, "  Hint: expressions must use only one variable (e.g., 'x+x', not 'x+y')\n");
        fflush(stderr);
        line_error_flag = 1;
    }
    Poly r = {0}; memset(r.c, 0, sizeof(r.c));
    
    if (a.deg > b.deg) {
        r.deg = a.deg;
    } else {
        r.deg = b.deg;
    }
    
    for(int i = 0; i <= r.deg; i++) r.c[i] = a.c[i] + b.c[i];
    
    if (a.var != 0) {
        r.var = a.var;
    } else {
        r.var = b.var;
    }
    
    normalize_poly(&r);
    return r;
}


Poly poly_sub(Poly a, Poly b) {
    if (a.var != 0 && b.var != 0 && a.var != b.var) {
        fprintf(stderr, "Semantic error [line %d]: cannot subtract different variables '%c' and '%c'\n", 
                yylineno, a.var, b.var);
        fprintf(stderr, "  Hint: expressions must use only one variable (e.g., 'x-x', not 'x-y')\n");
        fflush(stderr);
        line_error_flag = 1;
    }
    Poly r = {0}; memset(r.c, 0, sizeof(r.c));
    
    if (a.deg > b.deg) {
        r.deg = a.deg;
    } else {
        r.deg = b.deg;
    }
    
    for(int i = 0; i <= r.deg; i++) r.c[i] = a.c[i] - b.c[i];
    
    if (a.var != 0) {
        r.var = a.var;
    } else {
        r.var = b.var;
    }
    
    normalize_poly(&r);
    return r;
}

Poly poly_mul(Poly a, Poly b) {
    if (a.var != 0 && b.var != 0 && a.var != b.var) {
        fprintf(stderr, "Semantic error [line %d]: cannot multiply different variables '%c' and '%c'\n", 
                yylineno, a.var, b.var);
        fprintf(stderr, "  Hint: use the same variable on both sides (e.g., 'x*x', not 'x*y')\n");
        fflush(stderr);
        line_error_flag = 1;
    }
    Poly r = {0}; memset(r.c, 0, sizeof(r.c));
    r.deg = a.deg + b.deg;
    for(int i = 0; i <= a.deg; i++)
        for(int j = 0; j <= b.deg; j++)
            r.c[i+j] += a.c[i] * b.c[j];
    if (a.var != 0) {
        r.var = a.var;
    } else {
        r.var = b.var;
    }
    normalize_poly(&r);  
    return r;
}

Poly poly_pow(Poly base, int e) {
    if (e < 0) {
        line_error_flag = 1;
        return base;
    }
    if (base.deg == 0 && base.c[0] == 0) return make_const(0);
    if (e == 0) {
        Poly r = make_const(1); r.var = base.var; 
        normalize_poly(&r);  
        return r;
    }
    Poly r = make_const(1); r.var = base.var;
    for(int i=0; i<e; i++) r = poly_mul(r, base);
    return r;
}

Poly poly_deriv(Poly p) {
    Poly r = {0}; memset(r.c, 0, sizeof(r.c));
    if (p.deg == 0) { r.var = 0; return r; }
    r.deg = p.deg - 1;
    for(int i=1; i<=p.deg; i++) r.c[i-1] = p.c[i] * i;
    r.var = p.var;
    normalize_poly(&r);  
    return r;
}

void print_poly(Poly p) {
    int is_zero = 1;
    for (int i = 0; i <= p.deg; i++) {
        if (p.c[i] != 0) { is_zero = 0; break; }
    }
    if (is_zero) { printf("0"); return; }

    int first = 1;
    char v;
    if (p.var != 0) {
        v = p.var;
    } else {
        v = 'x';
    }
    for (int i = p.deg; i >= 0; i--) {
        if (p.c[i] == 0) continue;
        if (!first && p.c[i] > 0) printf("+");
        if (p.c[i] == -1 && i > 0) printf("-");
        else if (p.c[i] != 1 || i == 0) printf("%ld", p.c[i]);
        if (i == 1) printf("%c", v);
        else if (i > 1) printf("%c^%d", v, i);
        first = 0;
    }
}

void yyerror(const char *s) {
    if (line_error_flag) { line_error_flag = 0; return; }
    int l = yylineno;
    if (strcmp(s, "syntax error") == 0) l--;
    fprintf(stderr, "Syntax error [line %d]: %s\n", l, s);
    fflush(stderr); line_error_flag = 1;
}