#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.h"

extern int yyparse(void);
extern FILE *yyin;
FILE* out_file = NULL;
extern int yylineno;

int error_count = 0;
int indent_level = 0;
int need_newline = 1; //нужно ли печатать отступ перед следующим токеном
int need_space = 0;
int in_for_header = 0;  // внутри заголовка цикла for (между 'for' и ')')

char prev_token[256] = "";
char prev_prev_token[256] = "";

// Проверяет, является ли токен именем типа
int is_type_token(const char* t) {
    return (strcmp(t, "int") == 0 || strcmp(t, "float") == 0 ||
        strcmp(t, "char") == 0 || strcmp(t, "void") == 0 ||
        strcmp(t, "struct") == 0 || strcmp(t, "const") == 0 ||
        strcmp(t, "static") == 0);
}

int is_binary_op(const char* t) {
    return (strcmp(t, "=") == 0 || strcmp(t, "+=") == 0 || strcmp(t, "-=") == 0 ||
        strcmp(t, "+") == 0 || strcmp(t, "-") == 0 || strcmp(t, "/") == 0 ||
        strcmp(t, "%") == 0 || strcmp(t, "<") == 0 || strcmp(t, ">") == 0 ||
        strcmp(t, "<=") == 0 || strcmp(t, ">=") == 0 || strcmp(t, "==") == 0 ||
        strcmp(t, "!=") == 0 || strcmp(t, "&&") == 0 || strcmp(t, "||") == 0 ||
        strcmp(t, "<<") == 0 || strcmp(t, ">>") == 0);
}

int is_kw_paren(const char* t) {
    return (strcmp(t, "if") == 0 || strcmp(t, "while") == 0 ||
        strcmp(t, "for") == 0 || strcmp(t, "switch") == 0 ||
        strcmp(t, "return") == 0);
}

void token_output(const char* token) {
    if (!out_file) return;

    // for(...) 
    if (strcmp(token, "for") == 0) in_for_header = 1;
    else if (in_for_header && strcmp(token, ")") == 0) in_for_header = 0;

    //ОТСТУП 
    if (need_newline) {
        for (int i = 0; i < indent_level; i++)
            fprintf(out_file, "    ");
        need_newline = 0;
        need_space = 0;
    }

    //ЯВЛЯЕТСЯ ЛИ * / & УНАРНЫМ 
    int is_ptr = (strcmp(token, "*") == 0 || strcmp(token, "&") == 0);
    int unary = 0;
    if (is_ptr) {
        unary = (is_type_token(prev_token) ||
            strcmp(prev_token, "*") == 0 || strcmp(prev_token, "&") == 0 ||
            strcmp(prev_token, "(") == 0 || strcmp(prev_token, "[") == 0 ||
            strcmp(prev_token, "=") == 0 || strcmp(prev_token, "+=") == 0 ||
            strcmp(prev_token, "-=") == 0 || strcmp(prev_token, "return") == 0 ||
            strcmp(prev_token, "+") == 0 || strcmp(prev_token, "-") == 0 ||
            strcmp(prev_token, "/") == 0 || strcmp(prev_token, "%") == 0 ||
            strcmp(prev_token, "==") == 0 || strcmp(prev_token, "!=") == 0 ||
            strcmp(prev_token, "<") == 0 || strcmp(prev_token, ">") == 0 ||
            strcmp(prev_token, "<=") == 0 || strcmp(prev_token, ">=") == 0 ||
            strcmp(prev_token, "&&") == 0 || strcmp(prev_token, "||") == 0 ||
            strcmp(prev_token, "!") == 0 || strcmp(prev_token, "~") == 0 ||
            strcmp(prev_token, ";") == 0 || strcmp(prev_token, "{") == 0 ||
            strcmp(prev_token, "}") == 0 ||
            // struct IDENTIFIER * — это указатель 
            (strcmp(prev_prev_token, "struct") == 0 && !is_type_token(prev_token)) ||
            prev_token[0] == '\0');
    }

    // ПРОБЕЛ ПЕРЕД ТОКЕНОМ
    int no_sp = (strcmp(token, ";") == 0 || strcmp(token, ",") == 0 ||
        strcmp(token, ")") == 0 || strcmp(token, "]") == 0 ||
        strcmp(token, ":") == 0 || strcmp(token, ".") == 0 ||
        strcmp(token, "->") == 0 || strcmp(token, "++") == 0 ||
        strcmp(token, "--") == 0 || strcmp(token, "[") == 0 ||
        strcmp(token, "(") == 0);

    if (strcmp(token, "(") == 0 && is_kw_paren(prev_token)) {
        // if (, while (, for ( — пробел обязателен 
        fprintf(out_file, " ");
    }
    else if (is_binary_op(token)) {
        // Бинарные операторы: пробел перед 
        fprintf(out_file, " ");
    }
    else if (is_ptr && unary) {
        // Унарные * &: пробел перед, ЕСЛИ prev не ( [ * & 
        if (strcmp(prev_token, "*") != 0 && strcmp(prev_token, "&") != 0 &&
            strcmp(prev_token, "(") != 0 && strcmp(prev_token, "[") != 0 &&
            prev_token[0] != '\0') {
            fprintf(out_file, " ");
        }
    }
    else if (need_space && !no_sp) {
        fprintf(out_file, " ");
    }

    fprintf(out_file, "%s", token);

    // СОСТОЯНИЕ ПОСЛЕ ТОКЕНА 
    if (strcmp(token, "\n") == 0) {
        need_newline = 1; need_space = 0;
    }
    else if (strcmp(token, ";") == 0) {
        if (in_for_header) {
            fprintf(out_file, " ");
            need_newline = 0; need_space = 0;
        }
        else {
            fprintf(out_file, "\n");
            need_newline = 1; need_space = 0;
        }
    }
    else if (strcmp(token, "{") == 0) {
        fprintf(out_file, "\n");
        indent_level++; need_newline = 1; need_space = 0;
    }
    else if (strcmp(token, "}") == 0) {
        if (indent_level > 0) indent_level--;
        fprintf(out_file, "\n");
        need_newline = 1; need_space = 0;
    }
    else if (strcmp(token, ",") == 0 || strcmp(token, ":") == 0) {
        need_space = 1;
    }
    else if (strcmp(token, "(") == 0 || strcmp(token, "[") == 0 ||
        strcmp(token, ".") == 0 || strcmp(token, "->") == 0) {
        need_space = 0;
    }
    else if (strcmp(token, "++") == 0 || strcmp(token, "--") == 0) {
        need_space = 0;
    }
    else if (is_ptr && unary) {
        // После унарных * &: пробел НЕ нужен 
        need_space = 0;
    }
    else if (is_binary_op(token)) {
        need_space = 1;
    }
    else {
        need_space = 1;
    }

    // Сдвигаем историю токенов 
    strncpy(prev_prev_token, prev_token, sizeof(prev_prev_token) - 1);
    prev_prev_token[sizeof(prev_prev_token) - 1] = '\0';
    strncpy(prev_token, token, sizeof(prev_token) - 1);
    prev_token[sizeof(prev_token) - 1] = '\0';
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <source.c>\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1], "r");
    if (!f) {
        perror("Cannot open file");
        return 1;
    }
    yyin = f;

    out_file = fopen("formatted_output.c", "w");
    if (!out_file) {
        perror("Failed to open output file");
        fclose(yyin);
        return 1;
    }


    yyparse();

    printf("\n finished \n");
    printf("Total errors detected: %d\n", error_count);

    fclose(f);
    return error_count > 0 ? 1 : 0;
}

/* без неё ругается*/
void yyerror(const char *s) {
    /* всё  считаeтся в parser.y */
}

/* Функция для явного подсчёта ошибок */
void count_error(int line, const char *msg) {
    error_count++;
    fprintf(stderr, "[Error at line %d]: %s\n", line, msg);
}