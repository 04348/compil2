%{
	#include "utils.h"

	extern FILE *yyin;

	environment *glob_env;
%}

%define api.value.type {node*}

%token T_boo
%token T_int
%token Def
%token Dep
%token Af
%token Sk
%token true
%token false
%token Se
%token If
%token Th
%token El
%token Var
%token Wh
%token Do
%token Pl
%token Mo
%token Mu
%token And
%token Or
%token Not
%token Lt
%token Eq
%token V
%token I
%token Na
%token Ta
%token Po
%token Pc
%token Co
%token Cc
%token Ao
%token Ac
%token Dp
%token Vg


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
	| false			{$$ = new_node_val(T_boo, 404, NULL, NULL, NULL);}
	| V Po L_args Pc{/*  */}
	| Na TP Co E Cc	{/* New Array */}
	| Et			{$$ = $1;}

Et: V Co E Cc
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

L_argsnn: E
		| E Vg L_argsnn

L_argt: %empty
		| L_argtnn

L_argtnn: Argt					
		| L_argtnn Vg Argt		

Argt: V Dp TP						{$$ = new_node_str($3->type, ($1->key).c, $3, NULL, NULL);}

TP: T_boo							{$$ = new_node_str(T_BOOL, ($1->key).c, NULL, NULL, NULL);}
	| T_int							{$$ = new_node_str(T_INT, ($1->key).c, NULL, NULL, NULL);}
	| Ta TP							{$$ = new_node_str(T_ARRAY, ($1->key).c, $2, NULL, NULL);}

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
	return 0;
}