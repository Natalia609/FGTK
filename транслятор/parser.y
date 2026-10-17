%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"

extern int yylex();
void yyerror(const char *s);

extern int current_line;


/* ПОСТРОЕНИЯ AST */


ASTNode *make_node(NodeType type) {
    ASTNode *n = calloc(1, sizeof(ASTNode));
    n->type = type;
    return n;
}

ASTNode *make_number(long long num) {
    ASTNode *n = make_node(NODE_NUMBER);
    n->num = num;
    return n;
}

ASTNode *make_ident(const char *name) {
    ASTNode *n = make_node(NODE_IDENT);
    n->name = strdup(name);
    return n;
}

ASTNode *make_binop(char op, ASTNode *l, ASTNode *r) {
    ASTNode *n = make_node(NODE_BINOP);
    n->binop.op = op;
    n->binop.left = l;
    n->binop.right = r;
    return n;
}

ASTNode *make_unop(char op, ASTNode *c) {
    ASTNode *n = make_node(NODE_UNOP);
    n->unop.op = op;
    n->unop.child = c;
    return n;
}

ASTNode *make_cmp(int op, ASTNode *l, ASTNode *r) {
    ASTNode *n = make_node(NODE_CMP);
    n->cmp.op = op;
    n->cmp.left = l;
    n->cmp.right = r;
    return n;
}

ASTNode *make_var_decl(const char *name, ASTNode *expr) {
    ASTNode *n = make_node(NODE_VAR_DECL);
    n->assign.name = strdup(name);
    n->assign.expr = expr;
    return n;
}

ASTNode *make_assign(const char *name, ASTNode *expr) {
    ASTNode *n = make_node(NODE_ASSIGN);
    n->assign.name = strdup(name);
    n->assign.expr = expr;
    return n;
}

ASTNode *make_if(ASTNode *c, ASTNode *t, ASTNode *e) {
    ASTNode *n = make_node(NODE_IF);
    n->if_stmt.cond = c;
    n->if_stmt.then_stmt = t;
    n->if_stmt.else_stmt = e;
    return n;
}

ASTNode *make_while(ASTNode *c, ASTNode *b) {
    ASTNode *n = make_node(NODE_WHILE);
    n->while_stmt.cond = c;
    n->while_stmt.body = b;
    return n;
}

ASTNode *make_print(ASTNode *e) {
    ASTNode *n = make_node(NODE_PRINT);
    n->print_stmt.expr = e;
    return n;
}

ASTNode *make_list() {
    ASTNode *n = make_node(NODE_BLOCK);
    n->list.capacity = 8;
    n->list.stmts = malloc(sizeof(ASTNode*) * n->list.capacity);
    n->list.count = 0;
    return n;
}

void list_append(ASTNode *list, ASTNode *stmt) {
    if (list->list.count >= list->list.capacity) {
        list->list.capacity *= 2;
        list->list.stmts = realloc(list->list.stmts,
                                   sizeof(ASTNode*) * list->list.capacity);
    }
    list->list.stmts[list->list.count++] = stmt;
}


#define MAX_VARS 256
char *var_names[MAX_VARS];
int var_count = 0;

int get_var_addr(const char *name) {
    for (int i = 0; i < var_count; i++)
        if (strcmp(var_names[i], name) == 0) return i;
    var_names[var_count] = strdup(name);
    return var_count++;
}

/* ГЕНЕРАТОР (обход AST)  */

int reg_count = 0, label_count = 0;
int new_reg()   { return reg_count++; }
int new_label() { return label_count++; }

int gen_expr(ASTNode *node);
int gen_cond(ASTNode *node);
void gen_stmt(ASTNode *node);

int invert_op(int op) {
    switch (op) {
        case 1: return 4;  // >   <=
        case 2: return 3;  // <   >=
        case 3: return 2;  // >=  <
        case 4: return 1;  // <=  >
        case 5: return 6;  // ==  !=
        case 6: return 5;  // != ==
    }
    return op;
}

const char *op_to_str(int op) {
    switch (op) {
        case 1: return "jg";  
        case 2: return "jl";
        case 3: return "jge"; 
        case 4: return "jle";
        case 5: return "je";  
        case 6: return "jne";
    }
    return "jmp";
}

int gen_expr(ASTNode *node) {
    if (!node) return -1;
    switch (node->type) {
        case NODE_NUMBER: {
        int r = new_reg();
        printf("mov r%d, %lld\n", r, node->num);  
        return r;
    }
        case NODE_IDENT: {
            int r = new_reg();
            int addr = get_var_addr(node->name);
            printf("mov r%d, [%d]\n", r, addr);
            return r;
        }
        case NODE_BINOP: {
            int rl = gen_expr(node->binop.left);
            int rr = gen_expr(node->binop.right);
            int r = new_reg();
            printf("mov r%d, r%d\n", r, rl);
            switch (node->binop.op) {
                case '+': printf("add r%d, r%d\n", r, rr); break;
                case '-': printf("sub r%d, r%d\n", r, rr); break;
                case '*': printf("mul r%d, r%d\n", r, rr); break;
                case '/': printf("div r%d, r%d\n", r, rr); break;
            }
            return r;
        }
        case NODE_UNOP: {
            int rc = gen_expr(node->unop.child);
            int r = new_reg();
            printf("mov r%d, 0\n", r);
            printf("sub r%d, r%d\n", r, rc);
            return r;
        }
        default:
            fprintf(stderr, "gen_expr: unknown node %d\n", node->type);
            exit(1);
    }
}

int gen_cond(ASTNode *node) {
    if (node->type != NODE_CMP) {
        fprintf(stderr, "gen_cond: expected CMP\n"); exit(1);
    }
    int rl = gen_expr(node->cmp.left);
    int rr = gen_expr(node->cmp.right);
    int l = new_label();
    printf("%s r%d, r%d, L%d\n", op_to_str(invert_op(node->cmp.op)), rl, rr, l);
    return l;
}

void gen_stmt(ASTNode *node) {
    if (!node) return;
    switch (node->type) {
        case NODE_BLOCK:
        case NODE_PROGRAM:
            for (int i = 0; i < node->list.count; i++)
                gen_stmt(node->list.stmts[i]);
            break;
        case NODE_VAR_DECL:
        case NODE_ASSIGN: {
            int r = gen_expr(node->assign.expr);
            int addr = get_var_addr(node->assign.name);
            printf("mov [%d], r%d\n", addr, r);
            break;
        }
        case NODE_IF: {
            int l_else = gen_cond(node->if_stmt.cond);
            gen_stmt(node->if_stmt.then_stmt);
            if (node->if_stmt.else_stmt) {
                int l_end = new_label();
                printf("jmp L%d\n", l_end);
                printf("L%d:\n", l_else);
                gen_stmt(node->if_stmt.else_stmt);
                printf("L%d:\n", l_end);
            } else {
                printf("L%d:\n", l_else);
            }
            break;
        }
        case NODE_WHILE: {
            int l_begin = new_label();
            printf("L%d:\n", l_begin);
            int l_end = gen_cond(node->while_stmt.cond);
            gen_stmt(node->while_stmt.body);
            printf("jmp L%d\n", l_begin);
            printf("L%d:\n", l_end);
            break;
        }
        case NODE_PRINT: {
            int r = gen_expr(node->print_stmt.expr);
            printf("print r%d\n", r);
            break;
        }
        default:
            fprintf(stderr, "gen_stmt: unknown node %d\n", node->type);
            exit(1);
    }
}


/* ПЕЧАТЬ AST   */


void print_indent(int d) {
    for (int i = 0; i < d; i++) fprintf(stderr, "  ");
}

void dump_ast(ASTNode *n, int d) {
    if (!n) { print_indent(d); fprintf(stderr, "(null)\n"); return; }
    print_indent(d);
    switch (n->type) {
        case NODE_PROGRAM:
            fprintf(stderr, "PROGRAM (%d stmts)\n", n->list.count);
            for (int i = 0; i < n->list.count; i++) dump_ast(n->list.stmts[i], d+1);
            break;
        case NODE_BLOCK:
            fprintf(stderr, "BLOCK (%d stmts)\n", n->list.count);
            for (int i = 0; i < n->list.count; i++) dump_ast(n->list.stmts[i], d+1);
            break;
        case NODE_VAR_DECL:
            fprintf(stderr, "VAR_DECL %s\n", n->assign.name);
            dump_ast(n->assign.expr, d+1); break;
        case NODE_ASSIGN:
            fprintf(stderr, "ASSIGN %s\n", n->assign.name);
            dump_ast(n->assign.expr, d+1); break;
        case NODE_IF:
            fprintf(stderr, "IF\n");
            print_indent(d+1); fprintf(stderr, "COND:\n"); dump_ast(n->if_stmt.cond, d+2);
            print_indent(d+1); fprintf(stderr, "THEN:\n"); dump_ast(n->if_stmt.then_stmt, d+2);
            if (n->if_stmt.else_stmt) {
                print_indent(d+1); fprintf(stderr, "ELSE:\n"); dump_ast(n->if_stmt.else_stmt, d+2);
            }
            break;
        case NODE_WHILE:
            fprintf(stderr, "WHILE\n");
            print_indent(d+1); fprintf(stderr, "COND:\n"); dump_ast(n->while_stmt.cond, d+2);
            print_indent(d+1); fprintf(stderr, "BODY:\n"); dump_ast(n->while_stmt.body, d+2);
            break;
        case NODE_PRINT:
            fprintf(stderr, "PRINT\n"); dump_ast(n->print_stmt.expr, d+1); break;
        case NODE_BINOP:
            fprintf(stderr, "BINOP '%c'\n", n->binop.op);
            dump_ast(n->binop.left, d+1); dump_ast(n->binop.right, d+1); break;
        case NODE_UNOP:
            fprintf(stderr, "UNOP '%c'\n", n->unop.op);
            dump_ast(n->unop.child, d+1); break;
        case NODE_NUMBER: fprintf(stderr, "NUMBER %lld\n", n->num); break;
        case NODE_IDENT:  fprintf(stderr, "IDENT %s\n", n->name); break;
        case NODE_CMP: {
            const char *ops[] = {"?", ">", "<", ">=", "<=", "==", "!="};
            fprintf(stderr, "CMP %s\n", ops[n->cmp.op]);
            dump_ast(n->cmp.left, d+1); dump_ast(n->cmp.right, d+1); break;
        }
    }
}

ASTNode *root_ast = NULL;
%}

%define parse.error verbose

%union {
    long long      num;
    char    *str;
    ASTNode *node;
    int      op;
}

%token MAIN INT IF ELSE WHILE PRINTF
%token <num> NUMBER
%token <str> IDENT
%token GE LE EQ NE GT LT

%left '+' '-'
%left '*' '/'
%right UMINUS
%nonassoc THEN
%nonassoc ELSE

%type <node> program stmt_list stmt block var_decl assignment
%type <node> if_stmt while_stmt print_stmt condition
%type <node> expr term factor
%type <op>   comp_op

%%

program
    : MAIN '(' ')' '{' stmt_list '}' {
        ASTNode *root = make_node(NODE_PROGRAM);
        root->list.stmts    = $5->list.stmts;
        root->list.count    = $5->list.count;
        root->list.capacity = $5->list.capacity;
        free($5);
        $$ = root;
        root_ast = root;
    }
    ;

stmt_list
    : stmt {
        $$ = make_list();
        list_append($$, $1);
    }
    | stmt_list stmt {
        list_append($1, $2);
        $$ = $1;
    }
    ;

stmt
    : var_decl     { $$ = $1; }
    | assignment   { $$ = $1; }
    | if_stmt      { $$ = $1; }
    | while_stmt   { $$ = $1; }
    | print_stmt   { $$ = $1; }
    | block        { $$ = $1; }
    ;

block
    : '{' stmt_list '}' { $$ = $2; }
    ;

var_decl
    : INT IDENT '=' expr ';' { $$ = make_var_decl($2, $4); }
    ;

assignment
    : IDENT '=' expr ';' { $$ = make_assign($1, $3); }
    ;

condition
    : expr comp_op expr { $$ = make_cmp($2, $1, $3); }
    ;

if_stmt
    : IF '(' condition ')' stmt %prec THEN {
        $$ = make_if($3, $5, NULL);
    }
    | IF '(' condition ')' stmt ELSE stmt {
        $$ = make_if($3, $5, $7);
    }
    ;

while_stmt
    : WHILE '(' condition ')' stmt {
        $$ = make_while($3, $5);
    }
    ;

print_stmt
    : PRINTF '(' expr ')' ';' { $$ = make_print($3); }
    ;

expr
    : expr '+' term { $$ = make_binop('+', $1, $3); }
    | expr '-' term { $$ = make_binop('-', $1, $3); }
    | term          { $$ = $1; }
    ;

term
    : term '*' factor { $$ = make_binop('*', $1, $3); }
    | term '/' factor { $$ = make_binop('/', $1, $3); }
    | factor          { $$ = $1; }
    ;

factor
    : NUMBER             { $$ = make_number($1); }
    | IDENT              { $$ = make_ident($1); }
    | '(' expr ')'       { $$ = $2; }
    | '-' factor %prec UMINUS { $$ = make_unop('-', $2); }
    ;

comp_op
    : GT { $$ = 1; } | LT { $$ = 2; }
    | GE { $$ = 3; } | LE { $$ = 4; }
    | EQ { $$ = 5; } | NE { $$ = 6; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "ERROR in line %d: %s\n", current_line, s);
}

int main(int argc, char *argv[]) {
    int dump = (argc > 1 && strcmp(argv[1], "--dump") == 0);

    if (yyparse() != 0) return 1;
    if (!root_ast) {
        fprintf(stderr, "AST не построен\n");
        return 1;
    }

    if (dump) {
        fprintf(stderr, "===== AST =====\n");
        dump_ast(root_ast, 0);
        fprintf(stderr, "===============\n\n");
    }

    gen_stmt(root_ast);
    printf("halt\n");
    return 0;
}