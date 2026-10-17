#ifndef AST_H
#define AST_H

typedef enum {
    NODE_PROGRAM,   // Корень всей программы (содержит список всех операторов)
    NODE_BLOCK,     // Блок кода { ... } (содержит последовательность операторов)
    NODE_VAR_DECL,  // Объявление переменной с инициализацией (int x = 5;)
    NODE_ASSIGN,    // Оператор присваивания (x = 10;)
    NODE_IF,        // Условный оператор if / if-else
    NODE_WHILE,     // Цикл с предусловием while
    NODE_PRINT,     // Оператор вывода printf(...)
    NODE_BINOP,     // Бинарная арифметическая операция (+, -, *, /)
    NODE_UNOP,      // Унарная операция (унарный минус -x)
    NODE_NUMBER,    // Числовая константа (лист дерева)
    NODE_IDENT,     // Идентификатор / имя переменной (лист дерева)
    NODE_CMP        // Операция сравнения (>, <, >=, <=, ==, !=)
} NodeType;

typedef struct ASTNode {
    NodeType type;
    union {
        /* NODE_NUMBER */
        long long num;  
      /* NODE_IDENT */
        char* name; 

        /*  NODE_BINOP  */
        struct {
            char op;                   
            struct ASTNode* left;      
            struct ASTNode* right;    
        } binop;

        /*  NODE_UNOP */
        struct {
            char op;                   
            struct ASTNode* child;     
        } unop;

        /*NODE_CMP  */
        struct {
            int op;                    
            struct ASTNode* left;      
            struct ASTNode* right;     
        } cmp;

        /* NODE_VAR_DECL и NODE_ASSIGN  */
        struct {
            char* name;                
            struct ASTNode* expr;   
        } assign;

        /*  NODE_IF  */
        struct {
            struct ASTNode* cond;      
            struct ASTNode* then_stmt; 
            struct ASTNode* else_stmt; 
        } if_stmt;

        /*  NODE_WHILE  */
        struct {
            struct ASTNode* cond;     
            struct ASTNode* body;      
        } while_stmt;

        /*  NODE_PRINT  */
        struct {
            struct ASTNode* expr;      
        } print_stmt;

        /*  NODE_PROGRAM и NODE_BLOCK  */
        struct {
            struct ASTNode** stmts;    /* Динамический массив указателей на дочерние узлы-операторы */
            int count;                 /* Текущее количество операторов в списке */
            int capacity;              /* Выделенная ёмкость массива  */
        } list;
    };
} ASTNode;

#endif