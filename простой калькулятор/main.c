#include <stdio.h>
#include "poly.h"
#include "y.tab.h"

FILE* yyin;
Poly var_table[26];
int var_initialized[26];
int line_error_flag = 0;

int main(int argc, char* argv[]) {
    for (int i = 0; i < 26; i++) var_initialized[i] = 0;
    const char* filename = "example.txt";
    if (argc > 1) filename = argv[1];
    yyin = fopen(filename, "r");
    if (!yyin) { perror("fopen"); return 1; }

    printf(">>>  <<<\n");
    yyparse();
    fclose(yyin);
    return 0;
}