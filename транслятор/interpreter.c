#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_REGS   4096
#define MAX_MEM    4096
#define MAX_PROG   8192
#define MAX_LABELS 4096
#define MAX_LINE   512
#define MAX_ARGS   4

/* Память виртуальной машины */
long long regs[MAX_REGS];
long long mem[MAX_MEM];

/* Представление инструкции */
typedef struct {
    char name[16];
    char args[MAX_ARGS][32];
    int  nargs;
} Instruction;

Instruction program[MAX_PROG];
int prog_size = 0;
int label_pos[MAX_LABELS]; /* label_pos[i] = индекс инструкции для метки Li */

/* Парсинг операндов */
long long get_value(const char *s) {
    if (s[0] == 'r') return regs[atoi(s + 1)];
    if (s[0] == '[') return mem[atoi(s + 1)];
    return atoll(s); /* непосредственное значение */
}

void set_value(const char *s, long long val) {
    if (s[0] == 'r')       regs[atoi(s + 1)] = val;
    else if (s[0] == '[')  mem[atoi(s + 1)]  = val;
}

int get_label_target(const char *s) {
    int num = atoi(s + 1); /* пропустить 'L' */
    if (num < 0 || num >= MAX_LABELS || label_pos[num] < 0) {
        fprintf(stderr, "Ошибка: неизвестная метка %s\n", s);
        exit(1);
    }
    return label_pos[num];
}

int main(int argc, char *argv[]) {
    FILE *f = stdin;
    if (argc > 1) {
        f = fopen(argv[1], "r");
        if (!f) { perror("fopen"); return 1; }
    }

    /* Инициализация */
    memset(regs, 0, sizeof(regs));
    memset(mem,  0, sizeof(mem));
    for (int i = 0; i < MAX_LABELS; i++) label_pos[i] = -1;

    /* Проход 1: разбор программы и сбор меток */
    char line[MAX_LINE];
    while (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n\r")] = '\0';

        /* Заменить запятые на пробелы */
        for (int i = 0; line[i]; i++)
            if (line[i] == ',') line[i] = ' ';

        /* Пропуск пустых строк */
        char *p = line;
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '\0') continue;

        /* Проверка на метку (содержит ':') */
        char *colon = strchr(p, ':');
        if (colon && colon > p) {
            *colon = '\0';
            /* Ожидается формат "LN" */
            int lnum = atoi(p + 1);
            label_pos[lnum] = prog_size;
            continue;
        }

        /* Разбор инструкции */
        Instruction *inst = &program[prog_size];
        inst->nargs = 0;
        memset(inst->name, 0, sizeof(inst->name));
        memset(inst->args, 0, sizeof(inst->args));

        char *tok = strtok(p, " \t");
        if (tok) {
            strncpy(inst->name, tok, sizeof(inst->name) - 1);
            while ((tok = strtok(NULL, " \t")) != NULL && inst->nargs < MAX_ARGS) {
                strncpy(inst->args[inst->nargs], tok, sizeof(inst->args[0]) - 1);
                inst->nargs++;
            }
        }
        prog_size++;
    }
    if (f != stdin) fclose(f);

        /* Проход 2: выполнение */
    int pc = 0;
    while (pc >= 0 && pc < prog_size) {
        Instruction *inst = &program[pc];
        int next_pc = pc + 1;

        if (strcmp(inst->name, "mov") == 0) {
            set_value(inst->args[0], get_value(inst->args[1]));

        } else if (strcmp(inst->name, "add") == 0) {
            long long a = get_value(inst->args[0]);
            long long b = get_value(inst->args[1]);
            set_value(inst->args[0], a + b);

        } else if (strcmp(inst->name, "sub") == 0) {
            long long a = get_value(inst->args[0]);
            long long b = get_value(inst->args[1]);
            set_value(inst->args[0], a - b);

        } else if (strcmp(inst->name, "mul") == 0) {
            long long a = get_value(inst->args[0]);
            long long b = get_value(inst->args[1]);
            set_value(inst->args[0], a * b);

        } else if (strcmp(inst->name, "div") == 0) {
            long long a = get_value(inst->args[0]);
            long long b = get_value(inst->args[1]);
            if (b == 0) { fprintf(stderr, "Ошибка: деление на 0\n"); return 1; }
            set_value(inst->args[0], a / b);

        } else if (strcmp(inst->name, "jmp") == 0) {
            next_pc = get_label_target(inst->args[0]);

        } else if (strcmp(inst->name, "je") == 0) {
            if (get_value(inst->args[0]) == get_value(inst->args[1]))
                next_pc = get_label_target(inst->args[2]);

        } else if (strcmp(inst->name, "jne") == 0) {
            if (get_value(inst->args[0]) != get_value(inst->args[1]))
                next_pc = get_label_target(inst->args[2]);

        } else if (strcmp(inst->name, "jg") == 0) {
            if (get_value(inst->args[0]) > get_value(inst->args[1]))
                next_pc = get_label_target(inst->args[2]);

        } else if (strcmp(inst->name, "jge") == 0) {
            if (get_value(inst->args[0]) >= get_value(inst->args[1]))
                next_pc = get_label_target(inst->args[2]);

        } else if (strcmp(inst->name, "jl") == 0) {
            if (get_value(inst->args[0]) < get_value(inst->args[1]))
                next_pc = get_label_target(inst->args[2]);

        } else if (strcmp(inst->name, "jle") == 0) {
            if (get_value(inst->args[0]) <= get_value(inst->args[1]))
                next_pc = get_label_target(inst->args[2]);

        } else if (strcmp(inst->name, "print") == 0) {
            printf("%lld\n", get_value(inst->args[0]));

        } else if (strcmp(inst->name, "read") == 0) {
            long long val;
            if (scanf("%lld", &val) == 1)
                set_value(inst->args[0], val);

        } else if (strcmp(inst->name, "halt") == 0) {
            break;

        } else {
            fprintf(stderr, "Неизвестная инструкция: %s\n", inst->name);
            return 1;
        }

        pc = next_pc;
    }

    return 0;
}