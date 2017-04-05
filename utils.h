#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

#define INITIAL_ENV_SIZE 10

//enum TYPES {T_INT, T_BOOL, T_ARRAY};

typedef struct s_node node;

struct s_node{
		int type;
		union {
			char* c;
			int i;
		} key;
		node* l;
		node* r;
		node* condition;
};

typedef struct s_var env_var;
struct s_var{
		char* id;
		int size;
		int type;
		int val;
		env_var** arr;
};

typedef struct s_env environment;
struct s_env{
		env_var** vars;
		int nb_var;
		int size;
};

typedef struct s_func env_func;
struct s_func{
		char* id;
		node* args;
		node* prog;
		environment* env;
};

typedef struct s_func_env environment_func;
struct s_func_env{
		env_func** funcs;
		int nb_func;
		int size;
};

enum operateur{oPl, oMo, oMu, oAnd, oOr, oInd, oNot, oAf, oAfc,
                oAfInd, oSk, oJp, oJz, oSt, oParam, oCall, oRet};

typedef struct nodeC3A nodeC3A;

struct nodeC3A{
		char* etiq; // Nom de l'étiquette

		enum operateur ope_i; // Opérateur de l'opération actuelle
		char* ope_s; // Nom de l'opérateur

		char* arg1; // Premier argument
		char* arg2; // Second argument
		char* dest; // Nom de la destination

		// le fils éventuel de cette nodeC3A (la ligne suivante)
		nodeC3A* fils;
};

/*
 *	Creer une node d'arbre de syntaxe abstrait.
 */
node* new_node_str(int type, char* key, node* l, node* r, node* c);

node* new_node_val(int type, int key, node* l, node* r, node* c);

node* new_node(int type, node* l, node* r, node* c);

void new_var(environment* env, char* id, int type, int val);

void new_func(environment_func* env, char* id, node* args, node* prog);

environment* new_env();

environment_func* new_env_func();

void env_add(environment* env, env_var* var);

void env_func_add(environment_func* env, env_func* func);

node* new_node_str(int type, char* key, node* l, node* r, node* c);

node* new_node_val(int type, int key, node* l, node* r, node* c);

void node_print(node* n);

void env_print(environment* env);

void* node_exec(environment* env, node* n);

int yylex();

int yyerror(char *s);

int yyparse();

int fileno();

char* beginPPtoC3A(environment* env, node* n);



extern node* first_node;
extern FILE *out;
