%{
#include "heading.h"
#include "y.tab.h"
int yyerror(char *s);
	int currLine = 1, currPos = 1;
%}

   
%%
function	currPos += yyleng; return FUNCTION; 
beginparams	currPos += yyleng; return BEGINPARAMS; 
endparams	currPos += yyleng; return ENDPARAMS; 
beginlocals	currPos += yyleng; return BEGINLOCALS;
endlocals	currPos += yyleng; return ENDLOCALS;
beginbody	currPos += yyleng; return BEGINBODY; 
endbody		currPos += yyleng; return ENDBODY; 
integer		currPos += yyleng; return INTEGER; 
array		currPos += yyleng; return ARRAY;
of		currPos += yyleng; return OF; 
if		currPos += yyleng; return IF; 
then		return THEN; currPos += yyleng;
endif		return ENDIF; currPos += yyleng;
else		return ELSE; currPos += yyleng;
while		return WHILE; currPos += yyleng;
do		return DO; currPos += yyleng;
beginloop	return BEGINLOOP; currPos += yyleng;
endloop		return ENDLOOP; currPos += yyleng;
continue	return CONTINUE; currPos += yyleng;
read		return READ; currPos += yyleng;
write		return WRITE; currPos += yyleng;
and		return AND; currPos += yyleng;
or		return OR; currPos += yyleng;
not		return NOT; currPos += yyleng;
true		return TRUE; currPos += yyleng;
false		return FALSE; currPos += yyleng;
return		return RETURN; currPos += yyleng;

"-"		currPos += yyleng; return SUB; 
"+"		currPos += yyleng; return ADD;
"*"		currPos += yyleng; return MULT; 
"/"		currPos += yyleng; return DIV;
"%"		currPos += yyleng; return MOD;

"=="		return EQ;currPos += yyleng;
"<>"		return NEQ;currPos += yyleng;
"<"		return LT;currPos += yyleng;
">"		return GT;currPos += yyleng;
"<="		return LTE;currPos += yyleng;
">="		return GTE;currPos += yyleng;


[##].*		currLine++; currPos=1;      
		
";"		return SEMICOLON; currPos += yyleng;
":"		return COLON; currPos += yyleng;
","		return COMMA; currPos += yyleng;
"("		return LPAREN; currPos += yyleng;
")"		return RPAREN; currPos += yyleng;
"["		return LSQUARE; currPos += yyleng;
"]"		return RSQUARE; currPos += yyleng;
":="		return ASSIGN; currPos += yyleng;

[0-9]+				       currPos += yyleng; yylval.val = atoi(yytext); return NUMBER;
[0-9_][a-zA-Z0-9_]*[a-zA-Z0-9_]        printf("Error at line %d, column %d: Identifier \"%s\" must begin with a letter\n",currLine,currPos,yytext); currPos += yyleng; exit(0);
[a-zA-Z][a-zA-Z0-9_]*[_]               printf("Error at line %d, column %d: Identifier \"%s\" cannot end with an underscore\n",currLine,currPos,yytext);currPos += yyleng;exit(0); 
[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]       currPos += yyleng; strcpy(yylval.idval,yytext); return IDENT;
[a-zA-Z][a-zA-Z0-9]*		       currPos += yyleng; strcpy(yylval.idval,yytext); return IDENT;

[ ]             currPos += yyleng;
[\t]+		currPos += yyleng;
"\n"		currLine+= yyleng;	currPos=1;

.		printf("Error at line %d, column %d :unrecognized symbol \"%s\"\n",currLine,currPos,yytext);	exit(0);
%%
