#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdint.h>
#include "utils.h"
#include "bison_ipp.h"

FILE *out;

char* strcopy(char* str){
	int size = strlen(str);
	char* output = malloc(sizeof(char)*(size+1));
	for(int i = 0; i < size; ++i) output[i] = str[i];
	output[size] = '\0';
	return output;
}

void new_var(environment* env, char* id, int type, int val){
	env_var* var = malloc(sizeof(env_var));
	var->id = strcopy(id);
	if (type == T_array){
		var->size = val;
		var->arr = malloc(sizeof(env_var*)*val);
	} else {
		var->val = val;
		var->size = 0;
	}
	var->type = type;
	env_add(env, var);
}

void new_func(environment_func* env, char* id, node* args, node* prog){
	env_func* func = malloc(sizeof(env_func));
	func->id = strcopy(id);
	func->args = args;
	func->prog = prog;
	func->env = new_env();
	//env_func_add(env, func);
}

environment* new_env(){
	environment* env = malloc(sizeof(environment));
	env->nb_var = 0;
	env->size = INITIAL_ENV_SIZE;
	env->vars = malloc(sizeof(env_var*)*INITIAL_ENV_SIZE);
	return env;
}

environment_func* new_env_func(){
	environment_func* env = malloc(sizeof(environment_func));
	env->nb_func = 0;
	env->size = INITIAL_ENV_SIZE;
	env->funcs = malloc(sizeof(env_func*)*INITIAL_ENV_SIZE);
	return env;
}

void env_add(environment* env, env_var* var){
	if (env->nb_var >= env->size-1){
		env->size *= 2;
		env->vars = realloc(env->vars, sizeof(env_var*)*env->size);
	}
	env->vars[env->nb_var] = var;
	++(env->nb_var);
}

int var_geti(environment* env, char* id){
	for(int i = 0; i < env->nb_var; ++i){
		if(strcmp(env->vars[i]->id, id) == 0) return i;
	}
	printf("Var not found\n");
	return -1;
}

void env_func_add(environment_func* env, env_func* func);
char* getToken(int tk){
	if (tk == T_boo) return "T_boo";
	if (tk == T_int) return "T_int";
	if (tk == T_array) return "T_array";
	if (tk == V_array) return "V_array";
	if (tk == Def) return "Def";
	if (tk == Dep) return "Dep";
	if (tk == Af) return "Af";
	if (tk == Sk) return "Sk";
	if (tk == true) return "true";
	if (tk == false) return "false";
	if (tk == Se) return "\n";
	if (tk == If) return "If";
	if (tk == Th) return "Th";
	if (tk == El) return "El";
	if (tk == Var) return "Var";
	if (tk == Wh) return "Wh";
	if (tk == Do) return "Do";
	if (tk == Pl) return "Pl";
	if (tk == Mo) return "Mo";
	if (tk == Mu) return "Mu";
	if (tk == And) return "And";
	if (tk == Or) return "Or";
	if (tk == Not) return "Not";
	if (tk == Lt) return "Lt";
	if (tk == Eq) return "Eq";
	if (tk == V) return "V";
	if (tk == I) return "I";
	if (tk == Na) return "Na";
	if (tk == Ta) return "Ta";
	if (tk == Po) return "Po";
	if (tk == Pc) return "Pc";
	if (tk == Co) return "Co";
	if (tk == Cc) return "Cc";
	if (tk == Ao) return "Ao";
	if (tk == Ac) return "Ac";
	if (tk == Dp) return "Dp";
	if (tk == Vg) return "Vg";
	return "UNKNOW_TOKEN";
}

void var_print(env_var* var){
	printf("variable %s DIM:%d, TYPE:%s, VAL:", var->id, var->size, getToken(var->type));
	if (var->type != T_array){
			printf("%d", var->val);
	} else {
		printf("[");
		for(int i = 0; i < var->size; ++i){
			printf("%d,", (var->arr[i])->val);
		}
		printf("]");
	}
}

void env_print(environment* env){
	printf("### Environnement ###\n");
	for(int i = 0; i < env->nb_var; ++i){
		var_print(env->vars[i]);
		printf("\n");
	}
}

void node_print_rec(node* n){
	if (n->l != NULL) {
		if (n->type != Se)printf("(");
		node_print_rec(n->l);
		if (n->type != Se)printf(")");
	}
	if (n->type == I){printf("%d", n->key.i);}
	else if (n->type == V){printf("%s", n->key.c);}
	else if (n->type == T_boo){printf("%s", n->key.c==0?"TRUE":"FALSE");}
	else printf("%s", getToken(n->type));

	if (n->r != NULL) {
		if (n->type != Se)printf("(");
		node_print_rec(n->r);
		if (n->type != Se)printf(")");
	}
}

void node_print(node* n){
	printf("### Programme ###\n");
	node_print_rec(n);
	printf("\n");
}

void* node_exec(environment* env, node* n){
	if(n==NULL) return (void*)-1;
	switch(n->type){
		case Se:{
			node_exec(env, n->l);
			node_exec(env, n->r);
			break;
		}
//		### Variables/Constantes ###
		case I:{
			return (void*)((intptr_t)n->key.i);
			break;
		}
		case T_boo:{
			return (void*)((intptr_t)n->key.i);
			break;
		}
		case V:{
			return (void*)env->vars[var_geti(env, n->key.c)];
			break;
		}
		case V_array:{
			int index = (intptr_t)(node_exec(env, n->r));
			return (void*)( (env->vars[var_geti(env, (n->l)->key.c)])->arr[index] );
			break;
		}
//		### Affectation ###
		case Af:{
			env_var* cvar = (env_var*)node_exec(env, n->l);

			if((n->r)->type == V) {
				cvar->val = ((env_var*)(node_exec(env, n->r)))->val;
			} else if((n->r)->type == Na) {
				cvar->size = (intptr_t)(node_exec(env, n->r));
				cvar->arr = malloc(sizeof(env_var*)*cvar->size);
				for(int i = 0; i < cvar->size; ++i){
					cvar->arr[i] = malloc(sizeof(env_var));
					(cvar->arr[i])->val = 0;
				}
			} else {
				cvar->val = (intptr_t)(node_exec(env, n->r));
			}
			break;
		}
		case Na:{
			return (void*)node_exec(env, n->r);
			break;
		}
//		### Op Logiques ###
		case Or:{
			int val1 = (intptr_t)(node_exec(env, n->l));
			int val2 = (intptr_t)(node_exec(env, n->r));
			return (void*)( (intptr_t)(val1|val2) );
			break;
		}
		case Not:{
			return (void*)( (intptr_t)!((intptr_t)(node_exec(env, n->l))) );
			break;
		}
		case And:{
			return (void*)( (intptr_t)(node_exec(env, n->l))&(intptr_t)(node_exec(env, n->r)) );
			break;
		}

	}
	return (void*)-1;
}


// ========== PP TO C3A ======================

nodeC3A* nCFirst = NULL;
nodeC3A* nCActual = NULL;
int nbVarC3A = 0;

void newNodeC3A(int etiq, enum operateur op, char* strOp, char* arg1, char* arg2, char* dest, nodeC3A* p){
	nodeC3A* new = (nodeC3A*)malloc(sizeof(nodeC3A));
	new->etiq = malloc(32*sizeof(char));
	sprintf(new->etiq, "ET%d", etiq);
	new->ope_i = op;
	new->ope_s = strOp;
	new->arg1 = arg1;
	new->arg2 = arg2;
	new->dest = dest;

	if(p != NULL){
		new->fils = p->fils;
		p->fils = new;
	} else {
		new->fils = nCFirst;
		nCFirst = new;
	}
	if(p == nCActual)
		nCActual = new;
}


// newNodeC3A(int etiq, enum operateur op, char* strOp, char* arg1, char* arg2,
//								 char* dest, nodeC3A* p){

char* PPtoC3A(environment* env, node* n){
	if(n==NULL)
		return (void*)-1;

	switch(n->type){
		case Se: //;
			PPtoC3A(env, n->l);
			PPtoC3A(env, n->r);
			break;
//		### Variables/Constantes ###
		case I: //Valeur
			char* name = malloc(32*sizeof(char));
			sprintf(name, "CT%d", nbVarC3A++);
			newNodeC3A(nbVarC3A++, oAfc, strdup("Afc")
										, itoa(n->key.i), strdup("")
										, name, nCActual);
			return name;
			break;

		case T_int:
			char* name = malloc(32*sizeof(char));
			sprintf(name, "CT%d", nbVarC3A++);
			newNodeC3A(nbVarC3A++, oAfc, strdup("Afc")
										, itoa(n->key.i), strdup("")
										, name, nCActual);
			return name;
			break;

		case T_boo: // Booleen
			char* name = malloc(32*sizeof(char));
			sprintf(name, "BL%d");
			newNodeC3A(nbVarC3A++, oAfc, strdup("Afc")
									, itoa(n->key.i), strdup("")
									, name, nCActual);
			return name;
			break;

		case V: // Identificateur
			//Retourne le nom de la variable.
			char* name = strdup(n->key.c);
			return name;
			break;

		case V_array:
			break;

//		### Affectation ###
		case Af:

			newNodeC3A(nbVarC3A++, oAf, strdup("Af")
								, strdup(n->l->key.c), PPtoC3A(env, n->r),
								 strdup(""), nCActual);

			return NULL;
			break;

		case Na:
			break;

// 		### Opérations Math ###
		case Pl:
			char* arg1 = PPtoC3A(env, n->l);
			char* arg2 = PPtoC3A(env, n->r);

			char* dest = malloc(32*sizeof(char));
			sprintf(dest, "VA%d", nbVarC3A++);

			newNodeC3A(nbVarC3A++, oPl, strdup("Pl")
									, arg1, arg2
									,	dest, nCActual);

			return dest;
			break;

		case Mo:
			char* arg1 = PPtoC3A(env, n->l);
			char* arg2 = PPtoC3A(env, n->r);

			char* dest = malloc(32*sizeof(char));
			sprintf(dest, "VA%d", nbVarC3A++);

			newNodeC3A(nbVarC3A++, oMo, strdup("Mo")
									, arg1, arg2
									,	dest, nCActual);

			return dest;
			break;

		case Mu:
			char* arg1 = PPtoC3A(env, n->l);
			char* arg2 = PPtoC3A(env, n->r);

			char* dest = malloc(32*sizeof(char));
			sprintf(dest, "VA%d", nbVarC3A++);

			newNodeC3A(nbVarC3A++, oMu, strdup("Mu")
									, arg1, arg2
									,	dest, nCActual);

			return dest;
			break;

		case

//		### Op Logiques ###
		case Or:
			break;

		case Not:
			break;

		case And:
			break;

	}
	return NULL;
}

char* printTreeIMP(){
	nodeC3A* n = nCFirst;
	while (n != NULL) {
		printf("%s\t\t:", n->etiq);
		printf("%s\t:", n->ope_s);
		printf("%s\t\t:", n->arg1);
		printf("%s\t\t:", n->arg2);
		printf("%s\n", n->dest);

		n = n->fils;
	}
}




node* first_node;

node* new_node_str(int type, char* key, node* l, node* r, node* c){
	node* output = malloc(sizeof(node));
	output->type = type;
	output->key.c = strcopy(key);
	output->l = l;
	output->r = r;
	output->condition = c;
	first_node = output;
}

node* new_node_val(int type, int key, node* l, node* r, node* c){
	node* output = malloc(sizeof(node));
	output->type = type;
	output->key.i = key;
	output->l = l;
	output->r = r;
	output->condition = c;
	first_node = output;
}

node* new_node(int type, node* l, node* r, node* c){
	node* output = malloc(sizeof(node));
	output->type = type;
	output->l = l;
	output->r = r;
	output->condition = c;
	first_node = output;
}
