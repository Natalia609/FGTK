#ifndef POLY_H
#define POLY_H
#include <string.h>
#include <stdio.h>

#define MAX_DEG 200
typedef struct {
    int deg;// Текущая степень полинома
    long c[MAX_DEG + 1];// коэфф
    char var;  /* 0 = константа, 'a'..'z' = имя переменной */
} Poly;

extern Poly var_table[26];
extern int var_initialized[26];
extern int yylineno;
extern int line_error_flag;

Poly make_const(long v);
Poly make_var(char c);
Poly poly_add(Poly a, Poly b);
Poly poly_sub(Poly a, Poly b);
Poly poly_mul(Poly a, Poly b);
Poly poly_pow(Poly base, int exp);
Poly poly_deriv(Poly p);
void print_poly(Poly p);
#endif