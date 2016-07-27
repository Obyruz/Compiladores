//Lucas Chaves Balabram 113088945
//Lucas Asth Assuncao 113087606
//José Roberto Espíndola 113050633

%{
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <map>
#include <vector>

using namespace std;

struct Range { 
  int fim;
};

struct Tipo {
  string nome;  // O nome na sua linguagem
  string decl;  // A declaração correspondente em c-assembly
  string fmt;   // O formato para "printf"
  vector< Range > dim; // Dimensões (se não for array, fica vazio)
};

Tipo Inteiro = 	   { "inteiro", "int", "d" };
Tipo Quebrado =    { "quebrado", "float", "f" };
Tipo Duplo =       { "duplo", "double", "lf" };
Tipo Booleano =    { "booleano", "int", "d" };
Tipo String =      { "string", "char", "s" };
Tipo Caracter =    { "caracter", "char", "c" };

struct Atributo {
  string v, c;
  Tipo t;
  vector<string> lst;
}; 

#define YYSTYPE Atributo

int yylex();
int yyparse();
void yyerror(const char *);
void erro( string );

// Tabela d Símbolos (variáveis)
vector < map<string, Tipo > > ts;
map<string, Tipo>  tf;

map< string, map< string, Tipo > > tro; // tipo_resultado_operacao;

// contadores para variáveis temporariras
map< string, int > temp_global;
map< string, int > temp_local;
map< string, int > nlabel;
bool escopo_local = false;

string toString( int n ) {
  char buf[256] = "";
  
  sprintf( buf, "%d", n );
  
  return buf;
}

int toInt( string valor ) {
  int aux = 0;
  
  sscanf( valor.c_str(), "%d", &aux );
  
  return aux;
}

void empilha_nova_tabela_de_simbolos() {
	ts.push_back( map< string, Tipo >() );
}

void desempilha_tabela_de_simbolos() {
	ts.pop_back();
}

string gera_nome_var( Tipo t ) {
  return "t_" + t.nome + "_" + toString( ++(escopo_local ? temp_local : temp_global)[t.nome] );
}

string gera_nome_label( string cmd ) {
  return "L_" + cmd + "_" + toString( ++nlabel[cmd] );
}

ostream& operator << ( ostream& o, const vector<string>& st ) {
  cout << "[ ";
  for( vector<string>::const_iterator itr = st.begin();
       itr != st.end(); ++itr )
    cout << *itr << " "; 
       
  cout << "]";

  return o;     
}

string trata_dimensoes_decl_var( Tipo t ) {
  string aux;
  
  for( int i = 0; i < t.dim.size(); i++ )
    aux += "[" + toString( t.dim[i].fim + 1 )+ "]";
           
  return aux;         
}

// 'Atributo&': o '&' significa passar por referência (modifica).
void declara_variavel( Atributo& ss, vector<string> lst, Tipo tipo) {
  ss.c = "";
  for( int i = 0; i < lst.size(); i++ ) {
    if( ts[ts.size()-1].find( lst[i] ) != ts[ts.size()-1].end() ) 
      erro( "Variável já declarada: " + lst[i] );
    else {
      ts[ts.size()-1][ lst[i] ] = tipo; 
      ss.c += tipo.decl + " " + lst[i] + trata_dimensoes_decl_var( tipo ) + ";\n"; 
    }
  }
}

void declara_parametro( Atributo& ss, vector<string> lst, Tipo tipo) {
  ss.c = "";

  for( int i = 0; i < lst.size(); i++ ) {
    if( ts[ts.size()-1].find( lst[i] ) != ts[ts.size()-1].end() ) 
      erro( "Parametro já declarado: " + lst[i] );
    else {
      ts[ts.size()-1][ lst[i] ] = tipo; 
      ss.c += tipo.decl + " " + lst[i] + trata_dimensoes_decl_var( tipo ) + ", "; 
    }
  }
}

void declara_variavel( Atributo& ss, string nome, Tipo tipo ) {
  vector<string> lst;
  lst.push_back( nome );
  declara_variavel( ss, lst, tipo );
}

void busca_tipo_da_variavel( Atributo& ss, const Atributo& s1 ) {
  if( ts[ts.size()-1].find( s1.v ) == ts[ts.size()-1].end() ) {
		if( ts[0].find( s1.v ) == ts[0].end() ){
      erro( "Variável não declarada: " + s1.v );
		}
	  else {
	    ss.t = ts[0][ s1.v ];
	    ss.v = s1.v;
 	  }
	}
  else {
    ss.t = ts[ts.size()-1][ s1.v ];
    ss.v = s1.v;
  }
	
}

void gera_codigo_atribuicao( Atributo& ss, const Atributo& s1, const Atributo& s3 ) {
  if( (s1.t.nome != "string" || (s3.t.nome != "string")) &&
	 ((s1.t.nome == s3.t.nome || s1.t.nome == Quebrado.nome && s3.t.nome == Inteiro.nome ) || 
      (s3.t.nome == Quebrado.nome && s1.t.nome == Inteiro.nome ))) {
      ss.c = s1.c + s3.c + "  " + s1.v + " = " + s3.v + ";\n";
   }
   else if( s1.t.nome == "string" && s3.t.nome == "string" ) {
      ss.c = s1.c + s3.c + "  " + "strncpy( " + s1.v + ", " + s3.v + ", " + toString(s1.t.dim[0].fim) +" );\n";
   }
}

void gera_codigo_lista( Atributo& ss, const Atributo& s2, const Atributo& s3, const Atributo& s5) {
	if( s2.t.nome == "inteiro" ) {
		ss.c = s2.t.decl + s3.v + "[" + s5.v + "];\n";
	}
}	

string par( Tipo a, Tipo b ) {
  return a.nome + "," + b.nome;  
}

void gera_codigo_operador( Atributo& ss, 
                           const Atributo& s1, 
                           const Atributo& s2, 
                           const Atributo& s3 ) {
  if( tro.find( s2.v ) != tro.end() ) {
    if( tro[s2.v].find( par( s1.t, s3.t ) ) != tro[s2.v].end() ) {
      ss.t = tro[s2.v][par( s1.t, s3.t )];
      ss.v = gera_nome_var( ss.t );      
      ss.c = s1.c + s3.c + "  " + ss.v + " = " + s1.v + s2.v + s3.v + ";\n";
    }
    else
      erro( "O operador '" + s2.v + "' não está definido para os tipos " + s1.t.nome + " e " + s3.t.nome + "." );
  }
  else
    erro( "Operador '" + s2.v + "' não definido." );
}

string declara_nvar_temp( Tipo t, int qtde ) {
  string aux = "";
   
  for( int i = 1; i <= qtde; i++ )
    aux += t.decl + " t_" + t.nome + "_" + toString( i ) + ";\n";
    
  return aux;  
}

string declara_var_temp( map< string, int >& temp ) {
    string decls = "" + 
    declara_nvar_temp( Inteiro, temp[Inteiro.nome] ) +
    declara_nvar_temp( Quebrado, temp[Quebrado.nome] ) +
    declara_nvar_temp( Duplo, temp[Duplo.nome] ) +
    declara_nvar_temp( String, temp[String.nome] ) +
    declara_nvar_temp( Caracter, temp[Caracter.nome] ) +
    declara_nvar_temp( Booleano, temp[Booleano.nome] ) +
    "\n";
  
  temp.clear();
  
  return decls;
}

Atributo& gera_codigo_operador_menor( Atributo& ss, 
                           const Atributo& s1, 
                           const Atributo& s3 ) {
  if( tro.find( "<" ) != tro.end() ) {
    if( tro["<"].find( par( s1.t, s3.t ) ) != tro["<"].end() ) {
      ss.t = tro["<"][par( s1.t, s3.t )];
      ss.v = gera_nome_var( ss.t );      
      ss.c = s1.c + s3.c + "  " + ss.v + " = " + s1.v + "<" + s3.v 
             + ";\n";
			return ss;
    }
    else
      erro( "O operador '<' não está definido para os tipos " + s1.t.nome + " e " + s3.t.nome + "." );
  }
  else
    erro( "Operador '<' não definido." );
}

void gera_cmd_for(   Atributo& ss,
										 const Atributo& exp,
										 const Atributo& expFinal,
										 const Atributo& cmd_faca ) {
	string lbl_inicio_for = gera_nome_label( "inicio_for" );
	string lbl_faca = gera_nome_label( "faca" );
	string lbl_fim_for = gera_nome_label( "fim_for" );

	Atributo& menor =	gera_codigo_operador_menor( ss, exp, expFinal );
	ss.c = menor.c + exp.c +
				 lbl_inicio_for + ":;" +
				 "\n  if( " + ss.v + " ) goto " + lbl_faca + ";\n" +
				 lbl_faca + ":;\n" +
				 cmd_faca.c + 
				 "  " + exp.v + " = " + exp.v + "+ 1;\n" +
				 "  goto " + lbl_inicio_for + ";\n\n" +
				 lbl_fim_for + ":;\n";
}

void gera_cmd_while( Atributo& ss,
										 const Atributo& exp,
										 const Atributo& cmd_faca ) {
	string lbl_inicio_while = gera_nome_label( "inicio_while" );
	string lbl_faca = gera_nome_label( "faca" );
	string lbl_fim_while = gera_nome_label( "fim_while" );

	if( exp.t.nome != Booleano.nome )
		erro( "A expressão do ENQUANTO deve ser booleana!" );
	
	ss.c = exp.c +
				 lbl_inicio_while + ":;" +
				 "\n  if( " + exp.v + " ) goto " + lbl_faca + ";\n" +
				 lbl_faca + ":;\n" +
				 cmd_faca.c + 
				 "  goto " + lbl_inicio_while + ";\n\n" +
				 lbl_fim_while + ":;\n";
}

void gera_cmd_if( Atributo& ss, 
                  const Atributo& exp, 
                  const Atributo& cmd_entao ) { 
  string lbl_entao = gera_nome_label( "entao" );
  string lbl_fim_if = gera_nome_label( "fim_if" );
  
  if( exp.t.nome != Booleano.nome )
    erro( "A expressão do SE deve ser booleana!" );
    
  ss.c = exp.c + 
         "\nif( " + exp.v + " ) goto " + lbl_entao + ";\n" +
         lbl_entao + ":;\n" + 
         cmd_entao.c + "\n" +
         lbl_fim_if + ":;\n"; 
}

void gera_cmd_if_then( Atributo& ss, 
                  const Atributo& exp, 
                  const Atributo& cmd_entao, 
                  const Atributo& cmd_senao ) { 
  string lbl_entao = gera_nome_label( "entao" );
  string lbl_fim_if = gera_nome_label( "fim_if" );
  
  if( exp.t.nome != Booleano.nome )
    erro( "A expressão do SE deve ser booleana!" );
    
  ss.c = exp.c + 
         "\nif( " + exp.v + " ) goto " + lbl_entao + ";\n" +
         cmd_senao.c + "  goto " + lbl_fim_if + ";\n\n" +
         lbl_entao + ":;\n" + 
         cmd_entao.c + "\n" +
         lbl_fim_if + ":;\n"; 
}

void gera_codigo_funcao( Atributo& ss,
												 string nome,
												 string params,
												 Tipo retorno,
												 string bloco ) {
	ss.c = retorno.decl + " " + nome + "( " + params + " )" +
				 "{\n" +
				 declara_var_temp ( temp_local ) +
				 bloco +
				 "}\n";
}

void gera_bloco_com_retorno(Atributo& ss, Atributo& s1, Atributo& s3) {
		ss.c = s1.c + s3.c + ";\n";
}

void gera_retorno( Atributo& ss, Atributo& s2) {
	ss.c = s2.c + "\n" + "return " + s2.v;
}

void inicializa_tipo(Atributo& ss, Atributo& s2) {
	Range r = { toInt( s2.v ) };

	if( ss.t.dim == 0 ){
		cout << "entrei auqi";
		Range aux = ss.t.dim.back();
		ss.t.dim.pop_back();
		
		r.fim = r.fim * aux.fim;
	}  

  
  ss.t.dim.push_back( r );
}

%}	

%token _IDENTIFICADOR _PROGRAM _IMPRIMELN _IMPRIME _LELN _LE _DECLARO _CAJADO _SE _ENTAO _SENAO
%token _PARA _ATE _ENQUANTO _FACA _ATRIBUICAO _FUNCAO _RETORNO
%token _INTEIRO _STRING _QUEBRADO _DUPLO _BOOLEANO _CARACTER

%token _CONSTANTE_STRING _CONSTANTE_INTEIRO _CONSTANTE_QUEBRADO

%nonassoc '>' '<' '='
%left '+' '-'
%left '*' '/' '%'

%start EXPRESSAO_INICIAL

%%

EXPRESSAO_INICIAL : CABECALHO MEIOS EXPRESSAO_PRINCIPAL 
  { cout << $1.c << declara_var_temp( temp_global ) << $2.c << $3.c << endl; }
  ;
   
CABECALHO : 
       { $$.c = "#include <stdlib.h>\n"
								"#include <string.h>\n"
                "#include <stdio.h>\n\n";
       }              
     ;   
   
MEIOS : MEIO MEIOS 
         { $$.c = $1.c + $2.c; }
       | 
         { $$.c = ""; }
       ;
       
MEIO : VARIAVEIS  
      | FUNCAO 
      ;          
   
FUNCAO : _FUNCAO TIPO '~' _IDENTIFICADOR { escopo_local = true; 
			 	 															     empilha_nova_tabela_de_simbolos(); } 
			 '(' PARAMETROS ')' BLOCO_COM_RETORNO
			 { gera_codigo_funcao($$, $4.v, $7.c = $7.c.substr(0, $7.c.size()-2) , $2.t, $9.c );
			 	 escopo_local = false; desempilha_tabela_de_simbolos(); }
       | _FUNCAO TIPO '~' _IDENTIFICADOR { escopo_local = true; empilha_nova_tabela_de_simbolos(); } BLOCO_COM_RETORNO
			 { gera_codigo_funcao($$, $4.v, "", $2.t, $6.c );
			   escopo_local = false; desempilha_tabela_de_simbolos(); }					
	 		 | _FUNCAO _IDENTIFICADOR BLOCO
       ;    

BLOCO_COM_RETORNO : '{' COMANDOS RETORNO '}'
										{ gera_bloco_com_retorno($$, $2, $3); }
		  						;

RETORNO : _RETORNO EXPRESSAO ';'
					{ gera_retorno($$, $2); }
				;

PARAMETROS : PARAMETRO ',' PARAMETROS { $$.c = $1.c + $3.c; }
           | PARAMETRO { $$.c = $1.c; }
           ;         

PARAMETRO : TIPO '~' IDENTIFICADOR { declara_parametro( $$, $3.lst, $1.t ); }
					;

VARIAVEIS : DECLARACOES { $$.c = $1.c; }
		      ;
     
DECLARACOES : _DECLARO DECLARACAO ';' DECLARACOES { $$.c = $2.c + $4.c; }
     				| _CAJADO DECLARACAO ';' { $$.c = $2.c; }
			      ;   
     
DECLARACAO : TIPO '~' IDENTIFICADORES { declara_variavel( $$, $3.lst, $1.t ); }       
			     ;
     
TIPO : _INTEIRO TAM_INTEIROS { $$.t = $2.t; }	
     | _QUEBRADO TAM_QUEBRADOS { $$.t = $2.t; }
     | _DUPLO TAM_DUPLOS { $$.t = $2.t; }
     | _BOOLEANO { $$.t = Booleano; }
     | _CARACTER { $$.t = Caracter; }
     | _STRING TAM_STRINGS { $$.t = $2.t; }
     ;

TAM_STRINGS : TAM_STRING
						| TAM_STRING TAM_STRING
            | { $$.v = ""; }
						;
     
TAM_STRING : '[' _CONSTANTE_INTEIRO ']' 
             { $$.t = String; $$.t.dim[0].fim = toInt( $2.v ); }
           ;

TAM_INTEIROS : TAM_INTEIRO
						| TAM_INTEIRO TAM_INTEIRO
						| { $$.v = "0"; $$.t = Inteiro; }
						 ;

TAM_INTEIRO : '[' _CONSTANTE_INTEIRO ']'
							{ $$.t = Inteiro; inicializa_tipo($$, $2); }
						;

TAM_QUEBRADOS : TAM_QUEBRADO
							| TAM_QUEBRADO TAM_QUEBRADO
							| { $$.v = "0.0"; $$.t = Quebrado; }
							;

TAM_QUEBRADO : '[' _CONSTANTE_INTEIRO ']'
							{ $$.t = Quebrado; inicializa_tipo($$, $2); }
						;								

TAM_DUPLOS : TAM_DUPLO
						| TAM_DUPLO TAM_DUPLO
						| { $$.v = "0.0"; $$.t = Duplo; }
					 ;

TAM_DUPLO : '[' _CONSTANTE_INTEIRO ']'
							{ $$.t = Duplo; inicializa_tipo($$, $2); }
						;								

IDENTIFICADORES : IDENTIFICADORES ',' _IDENTIFICADOR { $$.lst = $1.lst; $$.lst.push_back( $3.v ); }
    | IDENTIFICADOR
    ;       
   
IDENTIFICADOR : _IDENTIFICADOR { $$.lst.push_back( $1.v ); }
							;

EXPRESSAO_PRINCIPAL : '{' COMANDOS '}'
            { $$.c = "int main() {\n" + $2.c + "}\n"; }
          ;
          
COMANDOS : COMANDO COMANDOS { $$.c = $1.c + $2.c; }
     | { $$.c = ""; }
     ;                   
 
COMANDO : SAIDA
		| ENTRADA
		| VARIAVEIS
    | COMANDO_SE
    | COMANDO_PARA
		| COMANDO_ENQUANTO
		| BLOCO
    | ATRIBUICAO
    ;
    
ATRIBUICAO : VALOR_ESQUERDA INDICE _ATRIBUICAO EXPRESSAO ';'
	   | VALOR_ESQUERDA _ATRIBUICAO EXPRESSAO ';'
	     { gera_codigo_atribuicao( $$, $1, $3); } 
           ;    

VALOR_ESQUERDA : _IDENTIFICADOR { busca_tipo_da_variavel( $$, $1 ); }
       ;    
          
INDICE : '[' EXPRESSOES ']''['EXPRESSOES']'
       | '[' EXPRESSOES ']'
       ;         

EXPRESSOES : EXPRESSAO ',' EXPRESSOES
     | EXPRESSAO
     ;        

COMANDO_ENQUANTO : _ENQUANTO '(' EXPRESSAO ')' COMANDO { gera_cmd_while ( $$, $3, $5 ); }
								 ;

COMANDO_PARA : _PARA '(' ATRIBUICAO EXPRESSAO _ATE EXPRESSAO ')' COMANDO
							 { gera_cmd_for ( $$, $4, $6, $8 ) ; }
		         ;
    
BLOCO : '{' COMANDOS '}' { $$ = $2; }
      ;    
    
COMANDO_SE : _SE '(' EXPRESSAO ')' COMANDO { gera_cmd_if( $$, $3, $5 ); }
       | _SE '(' EXPRESSAO ')' COMANDO _SENAO COMANDO
         { gera_cmd_if_then( $$, $3, $5, $7); }
       ;    
    
SAIDA : _IMPRIME '(' EXPRESSAO ')' ';'
        { $$.c = "  printf( \"%"+ $3.t.fmt + "\", " + $3.v + " );\n"; }
      | _IMPRIMELN '(' EXPRESSAO ')' ';'
        { $$.c = "  printf( \"%"+ $3.t.fmt + "\\n\", " + $3.v + " );\n"; }
      ;
   
ENTRADA : _LELN '(' VALOR_ESQUERDA ')' ';'
					{ $$.c = "  scanf( \"%" + $3.t.fmt + "\\n\" , &" + $3.v + " );\n"; }
				| _LE '(' VALOR_ESQUERDA ')' ';'
					{ $$.c = "  scanf( \"%" + $3.t.fmt + "\", &" + $3.v + " );\n"; }
				;

EXPRESSAO : EXPRESSAO '+' EXPRESSAO { gera_codigo_operador( $$, $1, $2, $3 ); }
  | EXPRESSAO '-' EXPRESSAO         { gera_codigo_operador( $$, $1, $2, $3 ); }
  | EXPRESSAO '*' EXPRESSAO 	    { gera_codigo_operador( $$, $1, $2, $3 ); }
  | EXPRESSAO '/' EXPRESSAO 	    { gera_codigo_operador( $$, $1, $2, $3 ); }
  | EXPRESSAO '%' EXPRESSAO 	    { gera_codigo_operador( $$, $1, $2, $3 ); }
  | EXPRESSAO '>' EXPRESSAO 	    { gera_codigo_operador( $$, $1, $2, $3 ); }
  | EXPRESSAO '<' EXPRESSAO 	    { gera_codigo_operador( $$, $1, $2, $3 ); }
  | EXPRESSAO '=' EXPRESSAO				{ gera_codigo_operador( $$, $1, $2, $3 ); }
  | F
  ;
  
F : _CONSTANTE_STRING   { $$ = $1; $$.t = String; }
  | _CONSTANTE_INTEIRO  { $$ = $1; $$.t = Inteiro; }
  | _CONSTANTE_QUEBRADO { $$ = $1; $$.t = Quebrado; }
  | _IDENTIFICADOR      { busca_tipo_da_variavel( $$, $1 );  }
  | '(' EXPRESSAO ')'   { $$ = $2; } 
	| _IDENTIFICADOR '(' EXPRESSAO ')' //{ $$.c = $3.c + "  " + $1.v + "( " + $3.t + " );\n"; }
  ;     
 
%%

#include "lex.yy.c"

void erro( string st ) {
  yyerror( st.c_str() );
  exit( 1 );
}

void yyerror( const char* st )
{
   if( strlen( yytext ) == 0 )
     fprintf( stderr, "%s\nNo final do arquivo\n", st );
   else  
     fprintf( stderr, "%s\nProximo a: %s\nlinha/coluna: %d/%d\n", st, 
              yytext, yylineno, yyrowno - (int) strlen( yytext ) );
}

void inicializa_tabela_de_resultado_de_operacoes() {
  map< string, Tipo > r;
  
  // OBS: a ordem é muito importante!!  
  r[par(Inteiro, Inteiro)] = Inteiro;
  tro[ "%" ] = r;

  r[par(Inteiro, Quebrado)] = Quebrado;    
  r[par(Inteiro, Duplo)] = Duplo;    
  r[par(Quebrado, Inteiro)] = Quebrado;    
  r[par(Quebrado, Quebrado)] = Quebrado;    
  r[par(Quebrado, Duplo)] = Duplo;    
  r[par(Duplo, Inteiro)] = Duplo;    
  r[par(Duplo, Quebrado)] = Duplo;    
  r[par(Duplo, Duplo)] = Duplo;    

  tro[ "-" ] = r; 
  tro[ "*" ] = r; 
  tro[ "/" ] = r; 

  r[par(Caracter, Caracter)] = String;      
  r[par(String, Caracter)] = String;      
  r[par(Caracter, String)] = String;    
  r[par(String, String)] = String;    
  tro[ "+" ] = r; 

  r.clear();
  r[par(Inteiro, Inteiro)] = Booleano; 
  r[par(Quebrado, Quebrado)] = Booleano;    
  r[par(Quebrado, Duplo)] = Booleano;
	r[par(Quebrado, Inteiro)] = Booleano;
  r[par(Duplo, Quebrado)] = Booleano;    
  r[par(Duplo, Duplo)] = Booleano;    
  r[par(Caracter, Caracter)] = Booleano;      
  r[par(String, Caracter)] = Booleano;      
  r[par(Caracter, String)] = Booleano;    
  r[par(String, String)] = Booleano;    
  r[par(Booleano, Booleano)] = Booleano;    
  tro["=="] = r;
  tro["!="] = r;
  tro[">="] = r;
  tro[">"] = r;
  tro["<"] = r;
  tro["<="] = r;
}

void inicializa_tipos() {
  Range r = { 255 };
  
  String.dim.push_back( r );
}

int main( int argc, char* argv[] )
{
  inicializa_tipos();
  inicializa_tabela_de_resultado_de_operacoes();
	empilha_nova_tabela_de_simbolos();
  yyparse();
}
