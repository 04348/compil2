%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <ctype.h>
	#include <unistd.h>
	int yylex();
	int yyerror(char *s);

	enum operateur{oPl, oMo, oMu, oAnd, oOr, oLt, oInd, oNot, oAf, oAfc,
			oAfInd, oSk, oJp, oJz, oSt, oParam, oCall, oRet};

	typedef struct nodeC3A nodeC3A;
	typedef struct nodeC3A{
		char* etiq; // Nom de l'étiquette

		enum operateur ope_i; // Opérateur de l'opération actuelle
		char* ope_s; // Nom de l'opérateur

		char* arg1; // Premier argument
		char* arg2; // Second argument
		char* dest; // Nom de la destination

		// le fils éventuel de cette nodeC3A (la ligne suivante)
		nodeC3A* fils;
	} nodeC3A;

	typedef struct s_var env_var;
	struct s_var{
		char* id;
		int size;
		int type;
		int val;
		env_var** arr;
	};

	typedef struct heap heap;
	typedef struct heap {
		char* name;
		env_var* variable;
		heap* next;
	} heap;
	
	typedef struct environment environment;
	typedef struct environment {
		heap* first;
		environment* old;
	}
	environment;

	nodeC3A* nCFirst = NULL;
	nodeC3A* nCActual = NULL;

	environment* env_global = NULL;
	environment* env_local = NULL;
	environment* env_param = NULL;

	void init_environments();
	void proceedTree(nodeC3A* n, char* func_name);

%}
%union {
	struct nodeC3A* nval;
	char* sval;
}

%token<sval> V

%left Pl Mo Mu And Or Ind Not Af Afc AfInd Sk Jp Jz St Param Call Ret Lt
%right SEP NLINE

%type<nval> COMMAND ETI OPE ARG1 ARG2 DEST


%start COMMAND
%%
COMMAND	: ETI			{nCFirst = $1; init_environments(); proceedTree($1, "main");}
		;

ETI	: V SEP OPE		{$$ = $3; $$->etiq = $1;}
	| SEP OPE			{$$ = $2; $$->etiq = strdup('\0');}
	;
	
OPE	: Pl SEP ARG1		{$$ = $3; $$->ope_i = oPl;}
	| Mo SEP ARG1		{$$ = $3; $$->ope_i = oMo;}
	| Mu SEP ARG1		{$$ = $3; $$->ope_i = oMu;}
	| And SEP ARG1		{$$ = $3; $$->ope_i = oAnd;}
	| Or SEP ARG1		{$$ = $3; $$->ope_i = oOr;}
	| Lt SEP ARG1		{$$ = $3; $$->ope_i = oLt;}
	| Not SEP ARG1		{$$ = $3; $$->ope_i = oNot;}
	| Ind SEP ARG1		{$$ = $3; $$->ope_i = oInd;}
	| Af SEP ARG1		{$$ = $3; $$->ope_i = oAf;}
	| Afc SEP ARG1		{$$ = $3; $$->ope_i = oAfc;}
	| AfInd SEP ARG1	{$$ = $3; $$->ope_i = oAfInd;}
	| Sk SEP ARG1		{$$ = $3; $$->ope_i = oSk;}
	| Jp SEP ARG1		{$$ = $3; $$->ope_i = oJp;}
	| Jz SEP ARG1		{$$ = $3; $$->ope_i = oJz;}
	| St SEP ARG1		{$$ = $3; $$->ope_i = oSt;}
	| Param SEP ARG1	{$$ = $3; $$->ope_i = oParam;}
	| Call SEP ARG1		{$$ = $3; $$->ope_i = oCall;}
	| Ret SEP ARG1		{$$ = $3; $$->ope_i = oRet;}
	;
	
ARG1: V SEP ARG2		{$$ = $3; $$->arg1 = $1;}
	| SEP ARG2			{$$ = $2; $$->arg1 = strdup("");}
	;
	
ARG2: V SEP DEST		{$$ = $3; $$->arg2 = $1;}
	| SEP DEST			{$$ = $2; $$->arg2 = strdup("");}
	;
	
DEST: V NNLINE ETI	{$$ = malloc(sizeof(nodeC3A)); $$->dest = $1; $$->fils = $3;}
	| V NNLINE		{$$ = malloc(sizeof(nodeC3A)); $$->dest = $1; $$->fils = NULL;}
	| NNLINE ETI			{$$ = malloc(sizeof(nodeC3A)); $$->dest = strdup("\0"); $$->fils = $2;}
	| NNLINE				{$$ = malloc(sizeof(nodeC3A)); $$->dest = strdup("\0"); $$->fils = NULL;}
	| DEST NNLINE		{$$ = $1;}
	;

NNLINE: NLINE
	| NLINE NNLINE
	;

%%

environment* new_environment(){
	return malloc(sizeof(environment));
}

void init_environments() {
	env_global = new_environment();
	env_local = env_global;
	env_param = new_environment();
}

env_var* new_env_var_vide(char* str) {
	env_var* variable = malloc(sizeof(env_var));
	variable->id = strdup(str);
	variable->type = 0;
	variable->val = 0;
	variable->arr = NULL;
	return variable;
}

env_var* clone_env_var(env_var* env_old, char* str) {
	if (env_old == NULL)	return new_env_var_vide(str);
	//env_old->id = strdup(str);
	//return env_old;
	env_var* env_new = malloc(sizeof(env_var));
	env_new->id = strdup(env_old->id);
	env_new->size = env_old->size;
	env_new->type = env_old->type;
	env_new->val = env_old->val;
	env_new->arr = env_old->arr;
	return env_new;
}

// env != NULL
heap* new_heap(environment* env, char* str) {
	heap* new = malloc(sizeof(heap));
	new->name = strdup(str);
	new->variable = new_env_var_vide(str);
	new->next = env->first;
	env->first = new;
	return new;
}

heap* find_heap(environment* env, char* s) {
	if (env == NULL)	return NULL;
	heap* h = env->first;
	while (h != NULL) {
		//if (h->variable == NULL)	return NULL;// debug
		if (strcmp(s, h->name) == 0)	return h;
		h = h->next;
	}
	return NULL;
}

env_var* get_env_var(environment* env, char* str){
	heap* h = find_heap(env_param, str);
	if (h == NULL)	h = find_heap(env_local, str);
	if (h == NULL)	h = find_heap(env_global, str);
	if (h == NULL)	h = new_heap(env, str);
	return h->variable;
}

env_var* get_env_var_array(env_var* array, int index){
	if (array == NULL)	return NULL;
	if (array->type != 1)	array->type = 1;// Erreur?(type = 1):(return NULL)
	if (array->size <= index) {
		array->arr = realloc(array->arr, (index+1)*sizeof(env_var*));
		while (array->size <= index) {
			char str[10];
			snprintf(str, 10, "%d", array->size);
			array->arr[array->size++] = new_env_var_vide(str);
		}
	}
	return array->arr[index];
}

void set_env_var_array(env_var* array, int index, env_var* src){
	if (array == NULL)	return;
	if (array->type != 1)	array->type = 1;
	if (array->size <= index) {
		array->arr = realloc(array->arr, (index+1)*sizeof(env_var*));
		while (array->size < index+1) {
			char str[10];
			snprintf(str, 10, "%d", array->size);
			array->arr[array->size++] = new_env_var_vide(str);
		}
	}
	src->id = array->arr[index]->id;
	array->arr[index] = src;
//	array->arr[index] = clone_env_var(src, array->arr[index]->id);
}

int get_value_env(environment* env, char* str){
	if (isdigit(str[0]))	return atoi(str);
	env_var* v = get_env_var(env, str);
	return v->val;
}

void print_env_var(env_var* eVar, int is_root, char* str) {
	if (eVar->type == 0) {
		printf("(%s:%d) ", str, eVar->val);
		return;
	}
	printf("%s:[", str); 
	for (int i = 0 ; i < eVar->size ; i++) {
		char str_new[10];
		snprintf(str_new, 10, "%d", i);
		print_env_var(eVar->arr[i], 1, str_new);
	}
	printf("] ");
}

void print_heap(heap* h) {
	if((h->name[0] == 'V' && h->name[1] == 'A')
	|| (h->name[0] == 'C' && h->name[1] == 'T')
	|| (h->name[0] == 'B' && h->name[1] == 'L')
	|| (isdigit(h->name[0])))
		return;
	env_var* eVar = h->variable;
	print_env_var(eVar, 0, h->name);
}

void proceedTree(nodeC3A* racine, char* func_name){

	nodeC3A* actuel = racine;
	while(actuel != NULL){
		nodeC3A* suivant = actuel->fils;

		//printf("%d %d\n", actuel->ope_i, oCall);
		switch(actuel->ope_i) {
		case (oPl) : // Pl - Proceeds the addition
			{
				int v1 = get_value_env(env_local, actuel->arg1);
				int v2 = get_value_env(env_local, actuel->arg2);
				
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);
				h->variable->val = v1 + v2;
				break;
			}
		case (oMo) : // Mo - proceeds the substraction
			{
				int v1 = get_value_env(env_local, actuel->arg1);
				int v2 = get_value_env(env_local, actuel->arg2);
				
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);
				h->variable->val = v1 - v2;
				break;
			}
		case (oMu) : // Mu - proceeds the multiplication
			{
				int v1 = get_value_env(env_local, actuel->arg1);
				int v2 = get_value_env(env_local, actuel->arg2);
				
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);
				h->variable->val = v1 * v2;
				break;
			}
		case (oAnd) : // And - proceeds the conjonction
			{
				int v1 = get_value_env(env_local, actuel->arg1);
				int v2 = get_value_env(env_local, actuel->arg2);
				
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);
				if (v1 == 0 && v2 == 0)
					h->variable->val = 0;
				else
					h->variable->val = 1;
				break;
			}
		case (oOr) : // Or - proceeds the disjonction
			{
				int v1 = get_value_env(env_local, actuel->arg1);
				int v2 = get_value_env(env_local, actuel->arg2);
				
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);
				if (v1 == 0 || v2 == 0)
					h->variable->val = 0;
				else
					h->variable->val = 1;
				break;
			}
		case (oLt) : // Lt - returns a boolean ("Arg1<Arg2" -> 1, else 0) in dest
			{
				int v1 = get_value_env(env_local, actuel->arg1);
				int v2 = get_value_env(env_local, actuel->arg2);
				
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);
				if (v1 < v2)
					h->variable->val = 0;
				else
					h->variable->val = 1;
				break;
			}
		case (oInd) : // Ind - get a value from an array
			{
				char* Arg1 = actuel->arg1;
				int Arg2 = get_value_env(env_local, actuel->arg2);
				
				env_var* array = get_env_var(env_local, Arg1);
				env_var* value = get_env_var_array(array, Arg2);
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);
				value->id = h->variable->id;
				h->variable = value;
				//h->variable = clone_env_var(value, h->variable->id);
				break;
			}
		case (oNot) : // Not - proceeds the negation
			{
				int value = get_value_env(env_local, actuel->arg1);
				
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);

				if (value == 0)	h->variable->val = 1;
				else	h->variable->val = 0;
				break;
			}
		case (oAf) : // Af
			{
				env_var* var = get_env_var(env_local, actuel->arg2);
				
				heap* h = find_heap(env_local, actuel->arg1);
				if(h == NULL) {
					h = new_heap(env_local, actuel->arg1);
				}
				h->variable = clone_env_var(var, actuel->arg1);
				break;
			}
		case (oAfc) : // Afc
			{
				int value = get_value_env(env_local, actuel->arg1);
				
				heap* h = new_heap(env_local, actuel->dest);
				h->variable->val = value;
				break;
			}
		case (oAfInd) : // AfInd - put a value in an array
			{
				char* Arg1 = actuel->arg1;
				int Arg2 = get_value_env(env_local, actuel->arg2);

				env_var* array = get_env_var(env_local, Arg1);
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);
				set_env_var_array(array, Arg2, h->variable);
				
				break;
			}
		case (oSk) : // Sk - do nothing
			{
				break;
			}
		case (oJp) : // Jp - Jump to a specified location
			{
				char* dest_jmp = actuel->dest;
				nodeC3A* nseek = nCFirst;
				while ( (nseek != NULL) && !(strcmp(nseek->etiq, dest_jmp)==0) ) {
					nseek = nseek->fils;
				}
				if (nseek != NULL)	suivant = nseek;
				break;
			}
		case (oJz) : // Jz - Jump to a specified location if Arg1==0
			{
				char* dest_jmp = actuel->dest;
				int value = get_value_env(env_local, actuel->arg1);
				nodeC3A* nseek = nCFirst;
				while ( (nseek != NULL) && !(strcmp(nseek->etiq, dest_jmp)==0) ) {
					nseek = nseek->fils;
				}
				if ((nseek != NULL) && (value==0))	suivant = nseek;
				break;
			}
		case (oSt) : // St - Halt, end of the program
			{
				printf("Etat du main : ");
				heap* h = env_local->first;
				while (h != NULL) {
					print_heap(h);
					h = h->next;
				}
				printf("\n");
				//return;
				suivant = NULL;
				break;
			}
		case (oParam) : // Param - Enter parameters for the next function called
			{	// TODO Vérifier que c'est bon
				char* Arg1 = actuel->arg1;
				env_var* Arg2 = get_env_var(env_local, actuel->arg2);
				
				heap* h = new_heap(env_param, Arg1);
				h->variable = Arg2;
				break;
			}
		case (oCall) : // Call - Calls a function
			{
				int Arg2 = atoi(actuel->arg2); // nombre de paramètres
				
				// ca1
				// P'l
				environment* new_env_local = new_environment();
				new_env_local->old = env_local;
				env_local = new_env_local;
				//P'l =  Pp
				heap* params = NULL;
				if (Arg2>0)	params = env_param->first;
				env_local->first = params;

				// ca2
				for (int i = 1 ; i < Arg2 ; i++)
					params = params->next;
				if (Arg2>0)	{
					env_param->first = params->next;
					params->next = NULL;
				}
				else	env_param->first = NULL;

				// ca3
				environment* new_env_param = new_environment();
				new_env_param->old = env_param;
				env_param = new_env_param;

				// ca4
				char* dest_jmp = actuel->arg1;
				nodeC3A* nseek = nCFirst;
				while ( (nseek != NULL) && !(strcmp(nseek->etiq, dest_jmp)==0) ) {
					nseek = nseek->fils;
				}
				proceedTree(nseek, strdup(actuel->arg1));
				break;
			}
		case (oRet) : // Ret - Leave the actual function
			{	
				heap* h = env_local->first;
				printf("Etat de la fonction %s : ", func_name);
				while (h != NULL) {
					print_heap(h);
					h = h->next;
				}
				printf("\n");


				heap* result = env_local->first;
				env_local = env_local->old;
				env_param = env_param->old;
				if ((result != NULL)
				&& ((strcmp(result->name, func_name) == 0)
				|| (strcmp(result->name, "RETFUN") == 0))) {
					h = find_heap(env_local, result->name);
					h->variable = result->variable;
				}
				return;
			}
		}

		actuel = suivant;
	}
}

int yyerror(char *s){
	fprintf( stderr, "*** ERROR: %s\n", s );
	return 0;
}
int main(){
	yyparse();
	return 0;
}
