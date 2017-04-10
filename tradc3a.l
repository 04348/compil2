%{
	#include "utils.h"
	#include "bison_ipp.h"
	#include <string.h>
%}
%option noyywrap

blank [ \t\n]+
i [0-9]+
v [a-zA-Z][a-zA-Z0-9]*

%%
boolean		{return(T_boo);}
integer		{return(T_int);}
defun		{return(Def);}
defpro		{return(Dep);}
:=			{return(Af);}
skip		{return(Sk);}
true		{return(true);}
false		{return(false);}
;			{return(Se);}
if			{return(If);}
then		{return(Th);}
else		{return(El);}
var			{return(Var);}
while		{return(Wh);}
do			{return(Do);}
\+			{return(Pl);}
\-			{return(Mo);}
\*			{return(Mu);}
and			{return(And);}
or			{return(Or);}
not			{return(Not);}
\<=			{return(Lt);}
\>=			{return(Gt);}
\<			{return(Lw);}
\>			{return(Gr);}
=			{return(Eq);}
new[ ]+array[ ]+of 	{return(Na);}
array[ ]+of			{return(Ta);}

\(			{return(Po);}
\)			{return(Pc);}
\[			{return(Co);}
\]			{return(Cc);}
\{			{return(Ao);}
\}			{return(Ac);}
:			{return(Dp);}
,			{return(Vg);}

{i}		{yylval = new_node_val(I, atoi(yytext), NULL, NULL, NULL); return(I);}
{v}		{yylval = new_node_str(V, yytext, NULL, NULL, NULL); return(V);}

{blank} {}

%%

/*
boolean		{printf("%s\n", yytext);return(T_boo);}
integer		{printf("%s\n", yytext);return(T_int);}
defun		{printf("%s\n", yytext);return(Def);}
defpro		{printf("%s\n", yytext);return(Dep);}
:=			{printf("%s\n", yytext);return(Af);}
skip		{printf("%s\n", yytext);return(Sk);}
true		{printf("%s\n", yytext);return(true);}
false		{printf("%s\n", yytext);return(false);}
;			{printf("%s\n", yytext);return(Se);}
if			{printf("%s\n", yytext);return(If);}
then		{printf("%s\n", yytext);return(Th);}
else		{printf("%s\n", yytext);return(El);}
var			{printf("%s\n", yytext);return(Var);}
while		{printf("%s\n", yytext);return(Wh);}
do			{printf("%s\n", yytext);return(Do);}
\+			{printf("%s\n", yytext);return(Pl);}
\-			{printf("%s\n", yytext);return(Mo);}
\*			{printf("%s\n", yytext);return(Mu);}
and			{printf("%s\n", yytext);return(And);}
or			{printf("%s\n", yytext);return(Or);}
not			{printf("%s\n", yytext);return(Not);}
\<=			{printf("%s\n", yytext);return(Lt);}
=			{printf("%s\n", yytext);return(Eq);}
new[ ]+array[ ]+of 	{printf("%s\n", yytext);return(Na);}
array[ ]+of			{printf("%s\n", yytext);return(Ta);}

\(			{printf("%s\n", yytext);return(Po);}
\)			{printf("%s\n", yytext);return(Pc);}
\[			{printf("%s\n", yytext);return(Co);}
\]			{printf("%s\n", yytext);return(Cc);}
\{			{printf("%s\n", yytext);return(Ao);}
\}			{printf("%s\n", yytext);return(Ac);}
:			{printf("%s\n", yytext);return(Dp);}
,			{printf("%s\n", yytext);return(Vg);}

{i}		{printf("%s\n", yytext);yylval = new_node_val(T_INT, 0, NULL, NULL, NULL); return(I);}
{v}		{printf("%s\n", yytext);yylval = new_node_str(10, yytext, NULL, NULL, NULL); return(V);}


###########################################

*/