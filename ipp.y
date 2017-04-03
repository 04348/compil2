%{
	#include "utils.h"

	extern FILE *yyin;

	environment *glob_env;
%}

%define api.value.type {node*}
%token T_boo T_int T_array Def Dep Af Sk true false Se If Th El Var Wh Do Pl Mo Mu And Or Not Lt Eq V V_array I Na Ta Po Pc Co Cc Ao Ac Dp Vg


%%
MP: L_vart LD C

E: 	E Pl E			{$$ = new_node(Pl, $1, $3, NULL);}
	| E Mo E		{$$ = new_node(Mo, $1, $3, NULL);}
	| E Mu E		{$$ = new_node(Mu, $1, $3, NULL);}
	| E Or E		{$$ = new_node(Or, $1, $3, NULL);}
	| E Lt E		{$$ = new_node(Lt, $1, $3, NULL);}
	| E Eq E		{$$ = new_node(Eq, $1, $3, NULL);}
	| E And E		{$$ = new_node(And, $1, $3, NULL);}
	| Not E			{$$ = new_node(Not, $2, NULL, NULL);}
	| Po E Pc		{$$ = $2;}
	| I				{$$ = $1;}
	| V				{$$ = $1;}
	| true			{$$ = new_node_val(T_boo, 0, NULL, NULL, NULL);}
	| false			{$$ = new_node_val(T_boo, 1, NULL, NULL, NULL);}
	| V Po L_args Pc{/*  */}
	| Na TP Co E Cc	{$$ = new_node(Na, $2, $4, NULL);} //Nouveau tableau
	| Et			{$$ = $1;}

Et: V Co E Cc		{$$ = new_node(V_array, $1, $3, NULL);} //tableau
	| Et Co E Cc

C: 	C Se C				{$$ = new_node(Se, $1, $3, NULL);}
	| Et Af E			{$$ = new_node(Af, $1, $3, NULL);}
	| V Af E			{$$ = new_node(Af, $1, $3, NULL);}
	| Sk				{$$ = NULL;}
	| Ao C Ac			{$$ = $2;}
	| If E Th C El C	{$$ = new_node(If, $4, $6, $2);}
	| Wh E Do C			{$$ = new_node(Wh, $4, NULL, $2);}
	| V Po L_args Pc	{/* new func */}

L_args: %empty
		| L_argsnn

L_argsnn: E				{$$ = $1;}
		| E Vg L_argsnn	{$$ = new_node(Vg, $1, $3, NULL);}

L_argt: %empty
		| L_argtnn

L_argtnn: Argt
		| L_argtnn Vg Argt

Argt: V Dp TP						{$$ = new_node_str($3->type, ($1->key).c, $3, NULL, NULL);}

TP: T_boo							{$$ = new_node_str(T_boo, ($1->key).c, NULL, NULL, NULL);}
	| T_int							{$$ = new_node_str(T_int, ($1->key).c, NULL, NULL, NULL);}
	| Ta TP							{$$ = new_node_str(T_array, ($1->key).c, $2, NULL, NULL);}

L_vart: %empty
		| L_vartnn

L_vartnn: Var Argt					{new_var(glob_env, ($2->key).c, $2->type, 0);}
		| L_vartnn Vg Var Argt		{new_var(glob_env, ($4->key).c, $4->type, 0);}

D_entp: Dep NPro Po L_argt Pc

D_entf: Def NFon Po L_argt Pc Dp TP

D: 	D_entp L_vart C
	| D_entf L_vart C

LD: %empty
	| LD D

NFon: V

NPro: V

%%

int yyerror(char *s){
	fprintf( stderr, "*** ERROR: %s\n", s );
	return 0;
}

int main(int argc, char *argv[]){
	glob_env = new_env();
	yyparse();
	env_print(glob_env);
	node_print(first_node);
	node_exec(glob_env , first_node);
	env_print(glob_env);

	PPtoC3A(glob_env, first_node);

	return 0;
}
