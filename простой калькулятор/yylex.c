#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "poly.h"
#include "y.tab.h"

extern FILE* yyin;
int yylineno = 1;
static int last_was_newline = 1;

int yylex(void) {
    int c;
    while (1) {
        c = fgetc(yyin);
        if (c == EOF) {
            if (!last_was_newline) { last_was_newline = 1; return NEWLINE; }
            return 0;
        }
        if (c == '\r') continue;      // Игнорируем Windows \r
        if (c == '\n') { yylineno++; last_was_newline = 1; return NEWLINE; }
        if (c == ' ' || c == '\t') continue;
        break; // Встретили значимый символ, выходим из цикла
    }
   

    if (c == '#') {
        while ((c = fgetc(yyin)) != '\n' && c != EOF);
        return yylex();
    }

    if (isdigit(c)) {
        long v = c - '0';
        while (isdigit(c = fgetc(yyin))) v = v * 10 + (c - '0');
        if (c != EOF) ungetc(c, yyin);
        yylval.num = v;
        last_was_newline = 0; 
        return NUM;
    }

    if (isalpha(c)) {
        char buf[32] = { 0 }; int i = 0;
        do { buf[i++] = c; c = fgetc(yyin); } while (isalpha(c) && i < 31);
        if (c != EOF) ungetc(c, yyin);
        buf[i] = '\0';

        if (strcmp(buf, "print") == 0) { last_was_newline = 0; return PRINT; }

        // Разрешаем ТОЛЬКО одиночные строчные буквы a-z
        if (i == 1 && buf[0] >= 'a' && buf[0] <= 'z') {
            yylval.var_char = buf[0];
            last_was_newline = 0;
            return VAR;
        }

        // Всё остальное (xx, sin, Ab) - ошибка
        line_error_flag = 1;
        fprintf(stderr, "Lexical error [line %d]: invalid identifier '%s'\n", yylineno, buf);
        fprintf(stderr, "  Hint: use only 'print' or single lowercase letters (a-z)\n");
        fflush(stderr);
        while ((c = fgetc(yyin)) != '\n' && c != EOF);
        if (c == '\n') yylineno++;
        last_was_newline = 1;
        return NEWLINE;
    }

    /*  ПЕРЕМЕННЫЕ $A..$Z (теперь поддерживают $EXP, $NEG и т.д.) */
    if (c == '$') {
        char buf[32] = { 0 }; int i = 0;
        int ch = fgetc(yyin);
        // Читаем все буквы подряд
        while (isalpha(ch) && i < 31) {
            buf[i++] = ch;
            ch = fgetc(yyin);
        }
        // Если сразу после букв идёт цифра - запрещаем
        if (isdigit(ch)) {
            line_error_flag = 1;
            fprintf(stderr, "Lexical error [line %d]: digits not allowed in $-variables\n", yylineno);
            fflush(stderr);
            while ((c = fgetc(yyin)) != '\n' && c != EOF);
            if (c == '\n') yylineno++;
            last_was_newline = 1;
            return NEWLINE;
        }
        if (ch != EOF) ungetc(ch, yyin);

        if (i == 0) {
            line_error_flag = 1;
            fprintf(stderr, "Lexical error [line %d]: expected letters after '$'\n", yylineno);
            fflush(stderr);
            while ((c = fgetc(yyin)) != '\n' && c != EOF);
            if (c == '\n') yylineno++;
            last_was_newline = 1;
            return NEWLINE;
        }

        // Индекс берём по ПЕРВОЙ букве (приводим к верхнему регистру для таблицы 0..25)
        char first = toupper((unsigned char)buf[0]);
        if (first >= 'A' && first <= 'Z') {
            yylval.var_idx = first - 'A';
            last_was_newline = 0;
            return DVAR;
        }

        line_error_flag = 1;
        fprintf(stderr, "Lexical error [line %d]: invalid $-variable name '%s'\n", yylineno, buf);
        fflush(stderr);
        while ((c = fgetc(yyin)) != '\n' && c != EOF);
        if (c == '\n') yylineno++;
        last_was_newline = 1;
        return NEWLINE;
    }
    

    switch (c) {
    case '+': last_was_newline = 0; return PLUS;
    case '-': last_was_newline = 0; return MINUS;
    case '*': last_was_newline = 0; return MUL;
    case '/': last_was_newline = 0; return DIV;
    case '^': last_was_newline = 0; return POWER;
    case '\'': last_was_newline = 0; return DERIV;
    case '=': last_was_newline = 0; return ASSIGN;
    case '(': last_was_newline = 0; return LPAREN;
    case ')': last_was_newline = 0; return RPAREN;
    default:
        line_error_flag = 1;
        fprintf(stderr, "Lexical error [line %d]: invalid character '%c'\n", yylineno, c);
        fflush(stderr);
        while ((c = fgetc(yyin)) != '\n' && c != EOF);
        if (c == '\n') yylineno++;
        last_was_newline = 1;
        return NEWLINE;
    }
}