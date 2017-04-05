%option noyywrap
/* Variables globales */
%{
	#include "c3a.tab.h"
	#include <string.h>
	#define YY_DECL int yylex()
%}
/* Partie définitions*/
/* ident = Identificateur */
/* arg = Argument */
/* ope = Operateur */

sep                 [ \t]
seps                {sep}*
lettre              [a-zA-Z]
num                 [0-9]
nums                0|([1-9]{num}*)
alnum               {lettre}|{num}

numeral				{nums}|[+-]{nums}
ident			{lettre}{alnum}*
variable			{numeral}|{ident}

/* Partie règles v */
%%

"Pl"			{return Pl;}
"Mo"			{return Mo;}
"Mu"			{return Mu;}
"And"			{return And;}
"Or"			{return Or;}
"Ind"			{return Ind;}
"Not"			{return Not;}
"Af"			{return Af;}
"Afc"			{return Afc;}
"AfInd"			{return AfInd;}
"Sk"			{return Sk;}
"Jp"			{return Jp;}
"Jz"			{return Jz;}
"St"			{return St;}
"Param"			{return Param;}
"Call"			{return Call;}
"Ret"			{return Ret;}

":"				{return SEP;}
"\n"			{return NLINE;}

{variable}		{yylval.sval = strdup(yytext); return V;}

[ \t]			{;}
<<EOF>>			{return 0;}

%%

