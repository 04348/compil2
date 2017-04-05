%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <ctype.h>
	#include <unistd.h>
	int yylex();
	int yyerror(char *s);

	char var[512][256]; // Jusqu'à 512 var différentes, de 256 car. max
	int val[512];
	int nbVar = 0;
	char var_tmp[256][256]; // Jusqu'à 256 var différentes, de 256 car. max
	int val_tmp[256];
	int nbVarTmp = 0;

	// Jusqu'à 256 tableaux de 256 var différentes, de 256 car. max
	// Note : Pour var_array[X][0] = "Arg1", var_array[X][Y] = "Arg2"
	char var_array[256][256][256];
	int val_array[256][256];
	int nbArray = 0; // Nb de tableaux de variables
	int nbVarArray[256]; // Nb de variables dans chaque tableau

	enum operateur{oPl, oMo, oMu, oAnd, oOr, oInd, oNot, oAf, oAfc,
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

        nodeC3A* nCFirst = NULL;
        nodeC3A* nCActual = NULL;

	char* copynew(char* str);
	void proceedTree(nodeC3A* n);
	void finishOld(nodeC3A* n);

%}
%union {
	struct nodeC3A* nval;
	char* sval;
}

%token<sval> V

%left Pl Mo Mu And Or Ind Not Af Afc AfInd Sk Jp Jz St Param Call Ret
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
	
DEST: V NLINE ETI	{$$ = malloc(sizeof(nodeC3A)); $$->dest = $1; $$->fils = $3;}
	| V NLINE		{$$ = malloc(sizeof(nodeC3A)); $$->dest = $1; $$->fils = NULL;}
	| NLINE ETI			{$$ = malloc(sizeof(nodeC3A)); $$->dest = strdup("\0"); $$->fils = $2;}
	| NLINE				{$$ = malloc(sizeof(nodeC3A)); $$->dest = strdup("\0"); $$->fils = NULL;}
	| DEST NLINE		{$$ = $1;}
	;

%%
int find_var(char* s) {
	for (int i = 0 ; i < nbVar ; i++)
		if (strcmp(s, var[i]) == 0)	return i;
	return -1;
}

int find_var_tmp(char* s) {
	for (int i = 0 ; i < nbVarTmp ; i++)
		if (strcmp(s, var_tmp[i]) == 0)	return i;
	return -1;
}

int new_var(char* str) {
	val[nbVar] = 0;
	strcpy(var[nbVar], str);
	return nbVar++;
}

int new_var_tmp(char* str) {
	val_tmp[nbVarTmp] = 0;
	strcpy(var_tmp[nbVarTmp], str);
	return nbVarTmp++;
}

int get_value(char* str){
	if (isdigit(str[0]))	return atoi(str);
	int index = find_var(str);
	if (index != -1)	return val[index];

	index = find_var_tmp(str);
	if (index != -1)	return val_tmp[index];
	return 0;
}

int get_value_array(char* Arg1, char* Arg2){

	// Trouver le tableau d'Arg1
	int indexArr = -1; // indexArray
	for (int i = 0 ; i < nbArray ; i++)
		if (strcmp(Arg1, var_array[i][0]) == 0)	{indexArr = i; break;}

	if (indexArr == -1) return -1;

	// Maintenant, trouver la valeur correspondant à Arg2
	int indexVar = 0;
	for (int i = 1 ; i < nbVarArray[indexArr]+1 ; i++)
		if (strcmp(Arg2, var_array[indexArr][i]) == 0)	{indexVar = i; break;}

	if (indexVar == 0) return -1;
	
	return val_array[indexArr][indexVar];
}

int find_var_array1(char* Arg1){

	// Trouver le tableau d'Arg1
	for (int i = 0 ; i < nbArray ; i++)
		if (strcmp(Arg1, var_array[i][0]) == 0)	return i;
	return -1;
}

int find_var_array2(int index1, char* Arg2){

	// Trouver la position d'Arg2
	for (int i = 1 ; i < nbVarArray[index1]+1 ; i++)
		if (strcmp(Arg2, var_array[index1][i]) == 0)	{return i;}
	return -1;
}

void proceedTree(nodeC3A* racine){
	// operateur :	0 = Pl, 1 = Mo, 2 = Mu, 3 = Af, 4 = Afc, 5 = Sk,
	//			6 = Jp, 7 = Jz, 8 = St

	nodeC3A* actuel = racine;
	while(actuel != NULL){
		nodeC3A* suivant = actuel->fils;

		switch(actuel->ope_i) {
		case (oPl) : // Pl - Proceeds the addition
			{
				int v1 = get_value(actuel->arg1);
				int v2 = get_value(actuel->arg2);
				
				int index = find_var_tmp(actuel->dest);
				if (index == -1)	index = new_var_tmp(actuel->dest);
				val_tmp[index] = v1 + v2;
				break;
			}
		case (oMo) : // Mo - proceeds the substraction
			{
				int v1 = get_value(actuel->arg1);
				int v2 = get_value(actuel->arg2);
				
				int index = find_var_tmp(actuel->dest);
				if (index == -1)	index = new_var_tmp(actuel->dest);
				val_tmp[index] = v1 - v2;
				break;
			}
		case (oMu) : // Mu - proceeds the multiplication
			{
				int v1 = get_value(actuel->arg1);
				int v2 = get_value(actuel->arg2);
				
				int index = find_var_tmp(actuel->dest);
				if (index == -1)	index = new_var_tmp(actuel->dest);
				val_tmp[index] = v1 * v2;
				break;
			}
		case (oAnd) : // And - proceeds the conjonction
			{
				int v1 = get_value(actuel->arg1);
				int v2 = get_value(actuel->arg2);
				
				int index = find_var_tmp(actuel->dest);
				if (index == -1)	index = new_var_tmp(actuel->dest);
				val_tmp[index] = v1 && v2;
				break;
			}
		case (oOr) : // Or - proceeds the disjonction
			{
				int v1 = get_value(actuel->arg1);
				int v2 = get_value(actuel->arg2);
				
				int index = find_var_tmp(actuel->dest);
				if (index == -1)	index = new_var_tmp(actuel->dest);
				val_tmp[index] = v1 || v2;
				break;
			}
		case (oInd) : // Ind - get a value from a 2D array
			{
				char* Arg1 = actuel->arg1;
				char* Arg2 = actuel->arg2;
				
				int value = get_value_array(Arg1, Arg2);
				int index = find_var_tmp(actuel->dest);
				if (index == -1)	index = new_var_tmp(actuel->dest);
				val_tmp[index] = value;
				break;
			}
		case (oNot) : // And - proceeds the negation
			{
				int value = get_value(actuel->arg1);
				
				int index = find_var_tmp(actuel->dest);
				if (index == -1)	index = new_var_tmp(actuel->dest);

				if (value == 0)	val_tmp[index] = 1;
				else	val_tmp[index] = 0;
				break;
			}
		case (oAf) : // Af
			{
				int value = get_value(actuel->arg2);
				
				int index = find_var(actuel->arg1);
				if(index == -1) {
					index = new_var(actuel->arg1);
				}
				val[index] = value;
				break;
			}
		case (oAfc) : // Afc
			{
				int value = get_value(actuel->arg1);
				
				int index = new_var_tmp(actuel->dest);
				val_tmp[index] = value;
				break;
			}
		case (oAfInd) : // AfInd - put a value in a 2D array
			{
				char* Arg1 = actuel->arg1;
				char* Arg2 = actuel->arg2;
				int index1 = find_var_array1(Arg1);
				int index2 = find_var_array2(index1, Arg2);
				
				int index = find_var_tmp(actuel->dest);
				val_array[index1][index2] = val_tmp[index];
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
				int value = get_value(actuel->arg1);
				nodeC3A* nseek = nCFirst;
				while ( (nseek != NULL) && !(strcmp(nseek->etiq, dest_jmp)==0) ) {
					nseek = nseek->fils;
				}
				if ((nseek != NULL) && (value==0))	suivant = nseek;
				break;
			}
		case (oSt) : // St
			{
				for (int i = 0 ; i < nbVar ; i++)
					printf("(%s : %d) ", var[i], val[i]);
				printf("\n");
				return;
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
