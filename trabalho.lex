%{
int yyrowno = 1;
void trata_folha();
void trata_aspas_simples();
%}
WS      [\t ]
DIGITO  [0-9]
LETRA   [A-Za-z_]
IDENTIFICADOR      {LETRA}({LETRA}|{DIGITO})*

IMPRIME			[Ii][Mm][Pp][Rr][Ii][Mm][Ee]
IMPRIMELN	[Ii][Mm][Pp][Rr][Ii][Mm][Ee][Ll][Nn]
LELN			[Ll][Ee][Ll][Nn]
LE				[Ll][Ee]
DECLARO			[D][E][C][L][A][R][O]
CAJADO			[C][A][J][A][D][O]
SE			[Ss][Ee]
ENTAO			[Ee][Nn][Tt][Aa][Oo]
SENAO			[Ss][Ee][Nn][Aa][Oo]
PARA			[Pp][Aa][Rr][Aa]
ATE			[Aa][Tt][Ee]
ENQUANTO  [Ee][Nn][Qq][Uu][Aa][Nn][Tt][Oo]
FACA			[Ff][Aa][Cc][Aa]
FUNCAO		[Ff][Uu][Nn][Cc][Aa][Oo]
RETORNO		[Rr][Ee][Tt][Oo][Rr][Nn][Oo]

INTEIRO		[Ii][Nn][Tt][Ee][Ii][Rr][Oo]
STRING		[Ss][Tt][Rr][Ii][Nn][Gg]
QUEBRADO	[Qq][Uu][Ee][Bb][Rr][Aa][Dd][Oo]
DUPLO		[Dd][Uu][Pp][Ll][Oo]
BOOLEANO	[Bb][Oo][Oo][Ll][Ee][Aa][Nn][Oo]
CARACTER	[Cc][Aa][Rr][Aa][Cc][Tt][Ee][Rr]

CONSTANTE_STRING	"'"([^'\n]|"''")*"'"
CONSTANTE_INTEIRO {DIGITO}+
CONSTANTE_QUEBRADO {DIGITO}+\.{DIGITO}+

%%
"\n" { yylineno++; yyrowno = 1; }
{WS} { yyrowno += 1; }

{IMPRIMELN} 	{ trata_folha(); return _IMPRIMELN; } 
{IMPRIME} 		{ trata_folha(); return _IMPRIME; }
{LELN}				{ trata_folha(); return _LELN; }
{LE}					{ trata_folha(); return _LE; }
{STRING} 			{ trata_folha(); return _STRING; }
{INTEIRO} 		{ trata_folha(); return _INTEIRO; }
{QUEBRADO}		{ trata_folha(); return _QUEBRADO; }
{DUPLO}				{ trata_folha(); return _DUPLO; }
{BOOLEANO} 		{ trata_folha(); return _BOOLEANO; }
{CARACTER}		{ trata_folha(); return _CARACTER; }
{DECLARO}			{ trata_folha(); return _DECLARO; }
{CAJADO}			{ trata_folha(); return _CAJADO; }
{SE}					{ trata_folha(); return _SE; }
{ENTAO}				{ trata_folha(); return _ENTAO; }
{SENAO} 			{ trata_folha(); return _SENAO; }
{PARA} 				{ trata_folha(); return _PARA; }
{ATE}					{ trata_folha(); return _ATE; }
{ENQUANTO}		{ trata_folha(); return _ENQUANTO; }
{FACA} 				{ trata_folha(); return _FACA; }
{FUNCAO}			{ trata_folha(); return _FUNCAO; }
{RETORNO}			{ trata_folha(); return _RETORNO; }

{CONSTANTE_STRING} 	{ trata_aspas_simples(); return _CONSTANTE_STRING; }
{CONSTANTE_INTEIRO} 	{ trata_folha(); return _CONSTANTE_INTEIRO; }
{CONSTANTE_QUEBRADO}    { trata_folha(); return _CONSTANTE_QUEBRADO; }

"<-"			{ trata_folha(); return _ATRIBUICAO; }
"="			{ trata_folha(); yylval.v = "=="; return '='; }

{IDENTIFICADOR}  { trata_folha(); return _IDENTIFICADOR; }

.     { trata_folha(); return yytext[0]; }

%%

void trata_folha() {
  yylval.v = yytext;
  yylval.t.nome = "";
  yylval.t.decl = "";
  yylval.t.fmt = "";
  yylval.c = "";
  yylval.lst.clear();
  
  yyrowno += strlen( yytext ); 
}

void trata_aspas_simples() {
  trata_folha(); 
  yylval.v = "\"" + yylval.v.substr( 1, yylval.v.length()-2 ) + "\""; 
}
