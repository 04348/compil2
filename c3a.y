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

	void proceedTree(nodeC3A* n);

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
COMMAND	: ETI			{nCFirst = $1; proceedTree($1);}
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
	env_var* env_new = malloc(sizeof(env_var));
	env_new->id = strdup(str);
	env_new->size = env_old->size;
	env_new->type = env_old->type;
	env_new->val = env_old->val;
	env_new->arr = env_old->arr;
	return env_new;
}

heap* new_heap(environment* env, char* str) {
	heap* new = malloc(sizeof(heap));
	new->variable = new_env_var_vide(str);
	new->next = env->first;
	env->first = new;
	return new;
}

heap* find_heap(environment* env, char* s) {
	if (env == NULL)	return NULL;
	heap* h = env->first;
	heap* test = h;
	while (h != NULL) {
		if (h->variable == NULL)	return NULL;
		if (strcmp(s, h->variable->id) == 0)	return h;
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
	if (array->type != 1)	return NULL;// Erreur?(type = 1):(do_nothing)
	if (array->size <= index) {
		array->arr = realloc(array->arr, (index+1)*sizeof(env_var*));
		while (array->size < index+1) {
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
	array->arr[index] = clone_env_var(src, array->arr[index]->id);
}

int get_value_env(environment* env, char* str){
	if (isdigit(str[0]))	return atoi(str);
	env_var* v = get_env_var(env, str);
	return v->val;
}

void print_env_var(env_var* eVar) {
	if (eVar->type == 0) {
		printf("(%s:%d) ", eVar->id, eVar->val);
		return;
	}
	printf("%s:[", eVar->id); 
	for (int i = 0 ; i < eVar->size ; i++)
		print_env_var(eVar->arr[i]);
	printf("], ");
}

void proceedTree(nodeC3A* racine){

	nodeC3A* actuel = racine;
	env_local = malloc(sizeof(environment));
	while(actuel != NULL){
		nodeC3A* suivant = actuel->fils;

		// printf("%d %d\n", actuel->ope_i, oInd);
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
		case (oInd) : // Ind - get a value from a 2D array
			{
				char* Arg1 = actuel->arg1;
				int Arg2 = get_value_env(env_local, actuel->arg2);
				
				env_var* array = get_env_var(env_local, Arg1);
				env_var* value = get_env_var_array(array, Arg2);
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);
				h->variable = clone_env_var(value, h->variable->id);
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
		case (oAfInd) : // AfInd - put a value in a 2D array
			{
				char* Arg1 = actuel->arg1;
				int Arg2 = get_value_env(env_local, actuel->arg2);

				env_var* array = get_env_var(env_local, Arg1);
				heap* h = find_heap(env_local, actuel->dest);
				if (h == NULL)	h = new_heap(env_local, actuel->dest);
				set_env_var_array(array, Arg2, h->variable);
				
				break;
			}
		case (oSk) : // Sk
			{
				break;
			}
		case (oJp) : // Jp
			{
				char* dest_jmp = actuel->dest;
				nodeC3A* nseek = nCFirst;
				while ( (nseek != NULL) && !(strcmp(nseek->etiq, dest_jmp)==0) ) {
					nseek = nseek->fils;
				}
				if (nseek != NULL)	suivant = nseek;
				break;
			}
		case (oJz) : // Jz
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
		case (oSt) : // St
			{
				heap* h = env_local->first;
				while (h != NULL) {
					if((h->variable->id[0] != 'V' && h->variable->id[1] != 'A')
					&& (h->variable->id[0] != 'C' && h->variable->id[1] != 'T')
					&& (h->variable->id[0] != 'B' && h->variable->id[1] != 'L'))
						print_env_var(h->variable);
					h = h->next;
				}
				printf("\n");
				//return;
			}
		case (oParam) : // Param
			{	// TODO Param Call Ret
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
