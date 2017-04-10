#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdint.h>
#include "utils.h"
#include "bison_ipp.h"

FILE *out;
node* first_node;
environment_func *functions;
environment *glob_env;

int get_type(node* n){
	if(n->type == Pl
		|| n->type == Mo
		|| n->type == Mu
		|| n->type == T_int
		|| n->type == I) return T_int;
	if(n->type == Or
		|| n->type == And
		|| n->type == Not
		|| n->type == T_boo) return T_boo;
	if(n->type == V_array){
		return -1;
		/*node* at = n->l;
		int f_type = 0;
		while (at->type != V && at->l != NULL){
			at = at->l;
		}
		return get_type(at);*/
	}
		//|| n->type == T_array
	if(n->type == Na) return -1;
	return -1;
}

void check_type(node* n1, node* n2){
	/*if(n1->type == V){
		if(get_vari(glob_env)
	} else if(n1->type == V_array){
		return
	} */
	//printf("Check type : %s & %s\n", getToken(get_type(n1)), getToken(get_type(n2)));
	if(get_type(n1)==-1 || get_type(n2)==-1) return;
	if(get_type(n1)==get_type(n2)) return;
	printf("Erreur de typage\n");
	//exit(0);
}

char* strcopy(char* str){
	if (str == NULL) return NULL;
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

void new_func(environment_func* envf, char* id, node* args, node* nenv, node* prog){
	env_func* func = malloc(sizeof(env_func));
	func->id = strcopy(id);
	func->args = args;
	func->prog = prog;
	func->type = Cfun;
	func->nenv = nenv;
	env_func_add(envf, func);
}

void new_prot(environment_func* envf, char* id, node* args, node* nenv, node* prog){
	env_func* func = malloc(sizeof(env_func));
	func->id = strcopy(id);
	func->args = args;
	func->prog = prog;
	func->type = Cpro;
	func->nenv = nenv;
	env_func_add(envf, func);
}

environment* new_env(){
	environment* env = malloc(sizeof(environment));
	env->nb_var = 0;
	env->size = INITIAL_ENV_SIZE;
	env->vars = malloc(sizeof(env_var*)*INITIAL_ENV_SIZE);
	return env;
}

void setup_env(environment* env, node* n){
	if(n==NULL) return;
	if(n->type == Ev){
		setup_env(env, n->l);
		setup_env(env, n->r);
	} else if (n->type == Arg){
		new_var(env, (n->l)->key.c, (n->r)->key.i, 0);
	}
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
	return -1;
}

env_func* getFunc(environment_func* env, char* id){
	for(int i = 0; i < env->nb_func; ++i){
		if(strcmp(env->funcs[i]->id, id) == 0) return env->funcs[i];
	}
	printf("Fonction %s n'existe pas.\n", id);
	exit(0);
}

void env_func_add(environment_func* env, env_func* func){
	if (env->nb_func >= env->size-1){
		env->size *= 2;
		env->funcs = realloc(env->funcs, sizeof(env_var*)*env->size);
	}
	env->funcs[env->nb_func] = func;
	++(env->nb_func);
}

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
	if (tk == Lt) return "<=";
	if (tk == Gt) return ">=";
	if (tk == Lw) return "<";
	if (tk == Gr) return ">";
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
	if (tk == Fp) return "Fp";
	if (tk == Arg) return "Arg";
	if (tk == Carg) return "Carg";
	if (tk == Darg) return "Darg";
	if (tk == Type) return "Type";
	if (tk == Ev) return "Ev";
	return "UNKNOW_TOKEN";
}

void var_print_v(env_var* var){
	if (var->type != T_array){
			printf("%d,", var->val);
	} else {
		printf("[");
		for(int i = 0; i < var->size; ++i){
			var_print_v((var->arr[i]));
		}
		printf("]");
	}
}

void var_print(env_var* var){
	printf("variable %s DIM:%d, TYPE:%s, VAL:", var->id, var->size, getToken(var->type));
	if (var->type != T_array){
			printf("%d", var->val);
	} else {
		printf("[");
		for(int i = 0; i < var->size; ++i){
			var_print_v((var->arr[i]));
		}
		printf("]");
	}
}

void arg_print(node* n){
	if(n == NULL) return;
	if(n->type == Darg){
		arg_print(n->l);
		arg_print(n->r);
	} else {
		printf("%s:%s, ", (n->l)->key.c, getToken((n->r)->key.i));
	}
}

void env_print(environment* env){
	printf("### Environnement ###\n");
	for(int i = 0; i < env->nb_var; ++i){
		var_print(env->vars[i]);
		printf("\n");
	}
}

void func_print(environment_func* env){
	printf("### Fonctions ###\n");
	for(int i = 0; i < env->nb_func; ++i){
		//var_print(env->vars[i]);
		printf("%s : ", (env->funcs[i])->id);
		arg_print( (env->funcs[i])->args );
		printf("\n");
		node_print_rec((env->funcs[i])->prog);
		printf("\n\n");
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
	else if (n->type == If){
		printf("(If(");
		node_print_rec(n->condition);
		printf(")");
	} else if (n->type == Wh){
		printf("Wh(");
		node_print_rec(n->condition);
		printf(")");
	} else printf("%s", getToken(n->type));

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

int ret_val(environment* env, node* n){
	if (n == NULL) return -1;
	if(n->type == V){
		return ((env_var*)(node_exec(env, n)))->val;
	} else {
		return (intptr_t)(node_exec(env, n));
	}
}

environment* merge_env(environment* e1, environment* e2){
	environment* e = new_env();
	e->size = e1->size + e2->size;
	e->vars = malloc(sizeof(env_var*)*e->size);
	int nb_var = 0;
	for(int i = 0; i < e1->nb_var; ++i){
		e->vars[nb_var] = e1->vars[i];
		nb_var++;
	}
	for(int i = 0; i < e2->nb_var; ++i){
		e->vars[nb_var] = e2->vars[i];
		nb_var++;
	}
	e->nb_var = nb_var;
	return e;
}

void setup_fun_env(environment* env, environment* fenv, node* c, node* d){
	if(c == NULL || d == NULL) return;
	if(c->type == Carg && d->type == Darg){
		setup_fun_env(env, fenv, c->l, d->l);
		setup_fun_env(env, fenv, c->r, d->r);
	} else if (d->type == Arg) {
		new_var(fenv, (d->l)->key.c, (d->r)->key.i, ret_val(env, c));
		if(d->r->key.i == T_array) {
			env_var* dv = fenv->vars[var_geti(fenv, (d->l)->key.c)];
			env_var* cv = env->vars[var_geti(env, c->key.c)];
			dv->arr = cv->arr;
			dv->size = cv->size;
		}
	}
	return;
}
/*
void setup_fun_env(node* c, node* d){
	if(c == NULL || d == NULL) return;
	if(c->type == Carg && d->type == Darg){
		setup_fun_env(c->l, d->l);
		setup_fun_env(c->r, d->r);
	} else if (d->type == Arg) {
		Param + (d->l)->key.c + PP_ToC3A(c);
	}
	return;
}*/

void* node_exec(environment* env, node* n){
	if(n==NULL) return (void*)-1;
	//printf("%s\n", getToken(n->type));
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
			int index = ret_val(env, n->r);
			env_var* var = (env_var*)node_exec(env, n->l);
			if(var->size <= index){
				printf("Erreur de segmentation, %s[%d] (DIM:%d)\n", var->id, index, var->size);
				exit(0);
			}
			return (void*)( var->arr[index] );
			break;
		}
//		### Affectation ###
		case Af:{
			env_var* cvar = (env_var*)node_exec(env, n->l);

			if((n->r)->type == Na) { //Affectation d'un nouveau tableau'
				cvar->size = (intptr_t)(ret_val(env, (n->r)->r));
				cvar->arr = malloc(sizeof(env_var*)*cvar->size);
				cvar->type = T_array;
				for(int i = 0; i < cvar->size; ++i){
					cvar->arr[i] = malloc(sizeof(env_var));
					(cvar->arr[i])->val = 0;
				}
			} else if((n->r)->type == V_array) { //Affectation de la valeur d'un tableau'
				env_var* var = (env_var*)node_exec(env, n->r);
				if(var->type == V_array || var->type == T_array){
					cvar->arr = var->arr;
					cvar->size = var->size;
				} else {
					cvar->val = var->val;
				}
			} else { //Affectation de valeur
				cvar->val = ret_val(env, n->r);
			}
			break;
		}
		case Na:{
			node_exec(env, n->l);
			return (void*)node_exec(env, n->r);
			break;
		}
//		### Boucles & Conditions ###
		case If:{
			if(ret_val(env, n->condition) == 0){
				node_exec(env, n->l);
			} else {
				node_exec(env, n->r);
			}
			break;
		}
		case Wh:{
			if(ret_val(env, n->condition) == 0){
				node_exec(env, n->l);
			}
			break;
		}
		case Fp:{
			env_func* f = getFunc(functions, (n->l)->key.c);
			if(f->type == Cfun){ //Fonction
				environment* fenv = new_env();
				new_var(fenv, (n->l)->key.c, T_int, 0);
				setup_env(fenv, f->nenv);
				setup_fun_env(env, fenv, n->r, f->args);
				//env_print(fenv);
				node_exec(fenv, f->prog);
				return (void*)( (intptr_t)(fenv->vars[var_geti(fenv, (n->l)->key.c)])->val);
			} else { //Protocole
				environment* fenv = new_env();
				setup_env(fenv, f->nenv);
				setup_fun_env(env, fenv, n->r, f->args);
				//env_print(fenv);
				node_exec(merge_env(fenv, glob_env), f->prog);
			}
			break;
		}
//		### Op Arithmetiques ###
		case Mo:{
			return (void*)( (intptr_t)(ret_val(env, n->l) - ret_val(env, n->r)) );
			break;
		}
		case Pl:{
			return (void*)( (intptr_t)(ret_val(env, n->l) + ret_val(env, n->r)) );
			break;
		}
		case Mu:{
			return (void*)( (intptr_t)(ret_val(env, n->l) * ret_val(env, n->r)) );
			break;
		}
//		### Op Logiques ###
		case Or:{
			int val1 = (intptr_t)(node_exec(env, n->l));
			int val2 = (intptr_t)(node_exec(env, n->r));
			return (void*)( (intptr_t)(!val1|!val2)?(intptr_t)0:(intptr_t)1);
			break;
		}
		case Not:{
			return (void*)( (intptr_t)!((intptr_t)(node_exec(env, n->l)))?(intptr_t)0:(intptr_t)1);
			break;
		}
		case And:{
			return (void*)( (intptr_t)(node_exec(env, n->l))&(intptr_t)(node_exec(env, n->r)) ?(intptr_t)0:(intptr_t)1);
			break;
		}
		case Lw:{
			return (void*)(
				(intptr_t)(ret_val(env, n->l))<(intptr_t)(ret_val(env, n->r))?(intptr_t)0:(intptr_t)1
				);
			break;
		}
		case Eq:{
			return (void*)(
				(intptr_t)(ret_val(env, n->l))==(intptr_t)(ret_val(env, n->r))?(intptr_t)0:(intptr_t)1
			);
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

void newFuncC3A(char* etiq, enum operateur op, char* strOp, char* arg1, char* arg2, char* dest, nodeC3A* p){
	nodeC3A* new = (nodeC3A*)malloc(sizeof(nodeC3A));
	new->etiq = etiq;
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

void setup_fun_c3a(environment* env, node* c, node* d, int* nb){
	if(c == NULL || d == NULL)	return;
	if(c->type == Carg && d->type == Darg){
		setup_fun_c3a(env, c->l, d->l, nb);
		setup_fun_c3a(env, c->r, d->r, nb);
	} else if(d->type == Arg){
			*nb+=1;
			char* arg = PPtoC3A(env, c);
			newNodeC3A(nbVarC3A++, oParam, strcopy("Param")
									, strcopy((d->l)->key.c), arg
									, strcopy(""), nCActual
								);

	}

}

void printTreeIMP(nodeC3A* first){
	nodeC3A* n = first;
	while (n != NULL) {
		printf("%s\t\t:", n->etiq);
		printf("%s\t:", n->ope_s);
		printf("%s\t\t:", n->arg1);
		printf("%s\t\t:", n->arg2);
		printf("%s\n", n->dest);

		n = n->fils;
	}
}

nodeC3A* beginPPtoC3A(environment* env, node* n){
	PPtoC3A(env, n);

	newNodeC3A(nbVarC3A++, oSt, strcopy("St")
							, strcopy(""), strcopy("")
							, strcopy(""), nCActual);

	for(int i = 0; i < functions->nb_func; i++){
		char* name = malloc(32*sizeof(char));
		sprintf(name, "%s", functions->funcs[i]->id);
		//Début de fonction...
		newFuncC3A(name, oSk, strcopy("Sk")
								, strcopy(""), strcopy("")
								, strcopy(""), nCActual
							);
		//Code de la fonction...
		PPtoC3A(env, functions->funcs[i]->prog);

		//Fin de fonction.
		newNodeC3A(nbVarC3A++, oRet, strcopy("Ret")
								, strcopy(""), strcopy("")
								, strcopy(""), nCActual
							);
	}

	printTreeIMP(nCFirst);

	return nCFirst;
}

// newNodeC3A(int etiq, enum operateur op, char* strOp, char* arg1, char* arg2,
//								 char* dest, nodeC3A* p){

char* PPtoC3A(environment* env, node* n){
	if(n==NULL)
		return (void*)-1;

	char* name;
	switch(n->type){
		case Se:{ //;
			PPtoC3A(env, n->l);
			PPtoC3A(env, n->r);
			break;}
//		### Variables/Constantes ###
		case I:{ //Valeur
			name = malloc(32*sizeof(char));
			sprintf(name, "CT%d", nbVarC3A++);

			char* num = malloc(32*sizeof(char));
			sprintf(num, "%d", n->key.i);

			newNodeC3A(nbVarC3A++, oAfc, strcopy("Afc")
										, strcopy(num), strcopy("")
										, name, nCActual);
			return name;
			break;
		}
		case T_int:{
			name = malloc(32*sizeof(char));
			sprintf(name, "CT%d", nbVarC3A++);

			char* num = malloc(32*sizeof(char));
			sprintf(num, "%d", n->key.i);

			newNodeC3A(nbVarC3A++, oAfc, strcopy("Afc")
										, strcopy(num), strcopy("")
										, name, nCActual);
			return name;
			break;
		}

		case T_boo:{ // Booleen
			name = malloc(32*sizeof(char));
			sprintf(name, "BL%d", nbVarC3A);

			char* num = malloc(32*sizeof(char));
			sprintf(num, "%d", n->key.i);

			newNodeC3A(nbVarC3A++, oAfc, strcopy("Afc")
									, strcopy(num), strcopy("")
									, name, nCActual);
			return name;
			break;
		}

		case V:{ // Identificateur
			//Retourne le nom de la variable.
			name = strcopy(n->key.c);
			return name;
			break;
		}

//		### Affectation ###
		case Af:{
			char* right = PPtoC3A(env, n->r);//La valeur qui doit être affecté

			if(right != NULL){
				// On fait une affectation à une adr array
				if(n->l->type == V_array){
					char* ori = PPtoC3A(env, (n->l)->l);
					char* ind = PPtoC3A(env, (n->l)->r);//index
					newNodeC3A(nbVarC3A++, oAfInd, strcopy("AfInd")
											, ori, ind
											, right, nCActual);
				  //return right;

				} else { //On fait une affectation normale..
						newNodeC3A(nbVarC3A++, oAf, strcopy("Af")
											, PPtoC3A(env, n->l), right,
											 strcopy(""), nCActual);
				}
			}

			return right;
			break;
		}

		case Na:{//New array
			return strcopy("");
			break;
		}

// 		### Opérations Math ###
		/* + */
		case Pl:{
			char* arg1 = PPtoC3A(env, n->l);
			char* arg2 = PPtoC3A(env, n->r);

			char* dest = malloc(32*sizeof(char));
			sprintf(dest, "VA%d", nbVarC3A++);

			newNodeC3A(nbVarC3A++, oPl, strcopy("Pl")
									, arg1, arg2
									,	dest, nCActual);

			return dest;
			break;
		}

		/* - */
		case Mo:{
			char* arg1 = PPtoC3A(env, n->l);
			char* arg2 = PPtoC3A(env, n->r);

			char* dest = malloc(32*sizeof(char));
			sprintf(dest, "VA%d", nbVarC3A++);

			newNodeC3A(nbVarC3A++, oMo, strcopy("Mo")
									, arg1, arg2
									,	dest, nCActual);

			return dest;
			break;
		}

		/* x */
		case Mu:{
			char* arg1 = PPtoC3A(env, n->l);
			char* arg2 = PPtoC3A(env, n->r);

			char* dest = malloc(32*sizeof(char));
			sprintf(dest, "VA%d", nbVarC3A++);

			newNodeC3A(nbVarC3A++, oMu, strcopy("Mu")
									, arg1, arg2
									,	dest, nCActual);

			return dest;
			break;
		}

//		### CONDITIONS	###
		case If:{
			char* cond = PPtoC3A(env, n->condition);
			nodeC3A* thenNode = nCActual;
			PPtoC3A(env, n->r);

			nodeC3A* elseNode = nCActual;
			PPtoC3A(env, n->l);

			newNodeC3A(nbVarC3A++, oSk, strcopy("Sk")
									, strcopy(""), strcopy(""),
									 	strcopy(""), nCActual
									);

			newNodeC3A(nbVarC3A++, oJz, strcopy("Jz")
									, cond, strcopy(""),
									 	elseNode->fils->etiq, thenNode
									);

			newNodeC3A(nbVarC3A++, oJp, strcopy("Jp")
									, strcopy(""), strcopy(""),
									 	nCActual->etiq, elseNode
									);

			return strcopy("");

			break;
		}

		case Wh:{

			nodeC3A* before = nCActual;
			PPtoC3A(env, n->l);
			nodeC3A* present = nCActual;

			char* cond = PPtoC3A(env, n->condition);
			nodeC3A* whNode = nCActual;

			newNodeC3A(nbVarC3A++, oJz, strcopy("Jz")
									, cond, strcopy("")
									, before->fils->etiq, nCActual
							);

			newNodeC3A(nbVarC3A++, oJp, strcopy("Jp")
							, strcopy(""), strcopy("")
							, present->fils->etiq, before
						);

			return strcopy("");
			break;
		}

//		### Op Logiques ###

		case Lw:{// x1 < x2
			char* left = PPtoC3A(env, n->l);
			char* right = PPtoC3A(env, n->r);
			char* dest = malloc(32*sizeof(char));

			sprintf(dest, "VA%d", nbVarC3A++);

			newNodeC3A(nbVarC3A++, oLt, strcopy("Lt")
									, left, right
									, dest, nCActual);

			return dest;
			break;
		}

		case Eq:{ // pas fini.
			name = malloc(32*sizeof(char));
			sprintf(name, "VA%d", nbVarC3A++);
			char* left = PPtoC3A(env, n->l);
			char* right = PPtoC3A(env, n->r);

			newNodeC3A(nbVarC3A++, oMo, strcopy("Mo")
										, left, right
										, name, nCActual);

			return name;
			break;
		}

		case Not:{
			name = malloc(32*sizeof(char));
			sprintf(name, "VA%d", nbVarC3A++);
			char* left = PPtoC3A(env, n->l);

			newNodeC3A(nbVarC3A++, oNot, strcopy("Not")
									,	left, strcopy("")
									, name, nCActual);

			return name;
			break;
		}

		case Or:{
			name = malloc(32*sizeof(char));
			sprintf(name, "VA%d", nbVarC3A++);
			char* left = PPtoC3A(env, n->l);
			char* right = PPtoC3A(env, n->r);

			newNodeC3A(nbVarC3A++, oOr, strcopy("Or")
									, left, right
									, name, nCActual);

		  return name;
			break;
		}

		case And:{
			name = malloc(32*sizeof(char));
			sprintf(name, "VA%d", nbVarC3A++);
			char* left = PPtoC3A(env, n->l);
			char* right = PPtoC3A(env, n->r);

			newNodeC3A(nbVarC3A++, oAnd, strcopy("And")
									, left, right
									, name, nCActual);

		  return name;
			break;
		}

		// ##### Acces Tableau .... ##########

		case V_array:{//Ind
			name = malloc(32*sizeof(char));
			sprintf(name, "VA%d", nbVarC3A++);
			char* left = PPtoC3A(env, n->l);
			char* right = PPtoC3A(env, n->r);

			newNodeC3A(nbVarC3A++, oInd, strcopy("Ind")
		 									,	left, right
										 	, name, nCActual);
			return name;
			break;
		}

		// ########-----    Functions -------------############

		case Type:{

			break;
		}

		case Carg:{
			char* left = PPtoC3A(env, n->l);
			char* right = PPtoC3A(env, n->r);

			return strcopy(left);
			break;
		}

		case Fp:{ //Fonction Protocole
			char* left = n->l->key.c; // Nom de fonction
			env_func* f = getFunc(functions, left);
			int nbParam = 0;
			setup_fun_c3a(env, n->r, f->args, &nbParam);

			char* nb = malloc(32*sizeof(char));
			sprintf(nb, "%d", nbParam);

			newNodeC3A(nbVarC3A++, oCall, strcopy("Call")
									, left, nb
									,	strcopy(""), nCActual
								);
			//a finir
			return strcopy(left);
			break;
		}

		/*case Cargs:{

			break;
		}*/

		default:{
			//fprintf(stderr, "No type found : %s\n", getToken(n->type));
			return strcopy("");
		}

	}
	//printTreeIMP(nCFirst);
	//fprintf(stderr, "No type found : %s", getToken(n->type));
	return NULL;
}



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
