%{
	#include "utils.h"

	extern FILE *yyin;

%}

%define api.value.type {node*}
%token T_boo T_int T_array Fp Cfun Cpro Def Dep Af Sk true false Se If Th El Var Wh Do Pl Mo Mu And Or Not Lt Gt Lw Gr Eq V V_array I Na Ta Po Pc Co Cc Ao Ac Dp Vg Arg Carg Darg Type Ev

%%
MP: L_vart LD C		{setup_env(glob_env, $1);}

E: 	E Pl E			{$$ = new_node(Pl, $1, $3, NULL);}
	| E Mo E		{$$ = new_node(Mo, $1, $3, NULL);}
	| E Mu E		{$$ = new_node(Mu, $1, $3, NULL);}
	| E Or E		{$$ = new_node(Or, $1, $3, NULL);}
	| E Lt E		{$$ = new_node(Or, new_node(Lw, $1, $3, NULL), new_node(Eq, $1, $3, NULL), NULL);}
	| E Gt E		{$$ = new_node(Or, new_node(Lw, $3, $1, NULL), new_node(Eq, $1, $3, NULL), NULL);}
	| E Lw E		{$$ = new_node(Lw, $1, $3, NULL);}
	| E Gr E		{$$ = new_node(Lw, $3, $1, NULL);}
	| E Eq E		{$$ = new_node(Eq, $1, $3, NULL);}
	| E And E		{$$ = new_node(And, $1, $3, NULL);}
	| Not E			{$$ = new_node(Not, $2, NULL, NULL);}
	| Po E Pc		{$$ = $2;}
	| I				{$$ = $1;}
	| V				{$$ = $1;}
	| true			{$$ = new_node_val(T_boo, 0, NULL, NULL, NULL);}
	| false			{$$ = new_node_val(T_boo, 1, NULL, NULL, NULL);}
	| V Po L_args Pc{$$ = new_node(Fp, $1, $3, NULL);}
	| Na TP Co E Cc	{$$ = new_node(Na, $2, $4, NULL);} //Nouveau tableau
	| Et			{$$ = $1;}

Et: V Co E Cc		{$$ = new_node(V_array, $1, $3, NULL);} //tableau
	| Et Co E Cc	{$$ = new_node(V_array, $1, $3, NULL);} //tableau >1D

C: 	C Se C				{$$ = new_node(Se, $1, $3, NULL);}
	| Et Af E			{$$ = new_node(Af, $1, $3, NULL);}
	| V Af E			{$$ = new_node(Af, $1, $3, NULL);}
	| Sk				{$$ = NULL;}
	| Ao C Ac			{$$ = $2;}
	| If E Th C El C	{$$ = new_node(If, $4, $6, $2);}
	| Wh E Do C			{$$ = new_node(Wh, $4, NULL, $2);}
	| V Po L_args Pc	{$$ = new_node(Fp, $1, $3, NULL);}

L_args: %empty			{$$ = NULL;}
		| L_argsnn		{$$ = $1;}

L_argsnn: E				{$$ = $1;}
		| L_argsnn Vg E	{$$ = new_node(Carg, $1, $3, NULL);}

L_argt: %empty						{$$ = NULL;}
		| L_argtnn					{$$ = $1;}

L_argtnn: Argt						{$$ = $1;}
		| L_argtnn Vg Argt			{$$ = new_node(Darg, $1, $3, NULL);}

Argt: V Dp TP						{$$ = new_node(Arg, $1, $3, NULL);}

TP: T_boo							{$$ = new_node_val(Type, T_boo, NULL, NULL, NULL);}
	| T_int							{$$ = new_node_val(Type, T_int, NULL, NULL, NULL);}
	| Ta TP							{$$ = new_node_val(Type, T_array, $2, NULL, NULL);}

L_vart: %empty						{$$ = NULL;}
		| L_vartnn					{$$ = $1;}

L_vartnn: Var Argt					{$$ = $2;} //new_var(glob_env, ($2->key).c, $2->type, 0);
		| L_vartnn Vg Var Argt		{$$ = new_node(Ev, $1, $4, NULL);} //new_var(glob_env, ($4->key).c, $4->type, 0);

D_entp: Dep NPro Po L_argt Pc		{$$ = new_node_str(Dep, $2->key.c, $4, NULL, NULL);}

D_entf: Def NFon Po L_argt Pc Dp TP	{$$ = new_node_str(Def, $2->key.c, $4, $7, NULL);}

D: 	D_entp L_vart C					{new_prot(functions, $1->key.c, $1->l, $2, $3);} //Declaration protocole
	| D_entf L_vart C				{new_func(functions, $1->key.c, $1->l, $2, $3);} //Declaration fonction

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
	functions = new_env_func();
	yyparse();

	env_print(glob_env);
	func_print(functions);
	node_print(first_node);
	node_exec(glob_env , first_node);
	env_print(glob_env);

	beginPPtoC3A(glob_env, first_node);

	return 0;
}
