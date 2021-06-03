%{
#include <bits/stdc++.h>
#include "SymbolTable.h"
#define YYSTYPE SymbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);

FILE *fp;
extern FILE *yyin;
extern int yylineno;

extern int line_no;
extern int error_count;

int n = 30;
ScopeTable* globalScope = new ScopeTable(n);
SymbolTable* symTab = new SymbolTable(n,globalScope);

ofstream errorFile("error.txt");
ofstream logFile("log.txt");

void yyerror(char *str)
{
	cout<<"Syntax error"<<endl;
}

SymbolInfo* insertItem(SymbolInfo* head,SymbolInfo* s)
{
	SymbolInfo* y = head;
	SymbolInfo* prev_y = NULL;

	while(y!=NULL){
		prev_y = y;
		y = y->nextInfoObj;
	}

	if(prev_y==NULL)
		head = s;
	else prev_y->nextInfoObj = s;

	return head;
}


%}

%token IF ID LPAREN RPAREN SEMICOLON COMMA LCURL RCURL INT FLOAT VOID
%token LTHIRD RTHIRD CONST_INT CONST_FLOAT FOR WHILE RETURN PRINTLN
%token ASSIGNOP LOGICOP RELOP ADDOP MULOP INCOP DECOP NOT

%nonassoc THEN
%nonassoc ELSE

%%

start : program 
			{
				symTab->printAllScope(logFile);

				logFile<<"Total lines : "<<yylineno<<endl;
				logFile<<"Total error : "<<error_count<<endl;
			}
	;

program : program unit 
	| unit
	;
	
unit : var_declaration
     | func_declaration
     | func_definition
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		| type_specifier ID LPAREN RPAREN SEMICOLON
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
		| type_specifier ID LPAREN RPAREN compound_statement 
			{
				logFile<<"Line "<<yylineno<<": type_specifier ID LPAREN RPAREN compound_statement"<<endl;

				string varType = $2->getDataType();

				if(varType=="NO_TYPE"){
					$2->isFunc = true;
					symTab->Insert($2);
					$2->setDataType($1->getName());
				}
				else{
					error_count++;
					if($2->isFunc){
						errorFile<<"Error at line "<<yylineno<<": "<<$2->getName()<<" is already declared as a function"<<endl;
					}
					else{
						errorFile<<"Error at line "<<yylineno<<": "<<$2->getName()<<" is already declared as a variable"<<endl;
					}
				}

				delete $1;
			}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		| parameter_list COMMA type_specifier
 		| type_specifier ID
		| type_specifier
 		;

 		
compound_statement : LCURL statements RCURL
 		    | LCURL RCURL
			 {
				 logFile<<"Line "<<yylineno<<": compound_statement : LCURL RCURL"<<endl;
			 }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON 
					{	
						logFile<<"Line "<<yylineno<<": var_declaration : type_specifier declaration_list SEMICOLON"<<endl;

						string varType = $1->getName();

						SymbolInfo* head = $2;

						if(varType=="VOID"){
							error_count++;

							errorFile<<"Error at line "<<yylineno<<": Variable type cannot be VOID"<<endl;

							while($2!=NULL){
								$2 = $2->nextInfoObj;
								delete head;
								head = $2;
							}
						}
						else{
							while(head!=NULL){
								SymbolInfo* item = new SymbolInfo(head->getName(),head->getType());
								item->setDataType(varType);

								if(!symTab->Insert(item)){
									error_count++;

									errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<head->getName()<<endl;
								}
								head = head->nextInfoObj;
							}
						}

						delete $1;
					}
 		 ;
 		 
type_specifier	: INT {
							logFile<<"Line "<<yylineno<<": type_specifier : INT"<<endl;
							$$ = new SymbolInfo("INT","KEYWORD");
					}
 		| FLOAT {
			 		logFile<<"Line "<<yylineno<<": type_specifier : FLOAT"<<endl;
					$$ = new SymbolInfo("FLOAT","KEYWORD");
		 		}
 		| VOID {
			 		logFile<<"Line "<<yylineno<<": type_specifier : VOID"<<endl;
					$$ = new SymbolInfo("VOID","KEYWORD");
		 	}
 		;
 		
declaration_list : declaration_list COMMA ID 
					{	
						logFile<<"Line "<<yylineno<<": declaration_list : declaration_list COMMA ID "<<endl;

						SymbolInfo* idObj = new SymbolInfo($3->getName(),$3->getType());

						$$ = insertItem($1,idObj);
					}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD 
					{	
						logFile<<"Line "<<yylineno<<": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl;

						int n = stoi($5->getName());
						SymbolInfo* idObj = new SymbolInfo($3->getName(),$3->getType());
						idObj->setArrSize(n);

						$$ = insertItem($1,idObj);
					}
 		  | ID {	
			   		logFile<<"Line "<<yylineno<<": declaration_list : ID "<<endl;
			   		string varType = $1->getDataType();

					if(varType=="NO_TYPE"){
						$$ = $1;
					}
					else{
						$$ = new SymbolInfo($1->getName(),$1->getType());
					}
		   	   }
 		  | ID LTHIRD CONST_INT RTHIRD 
				{
					logFile<<"Line "<<yylineno<<": declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl;

					string varType = $1->getDataType();
					int n = stoi($3->getName());

					if(varType=="NO_TYPE"){
						$$ = $1;
					}
					else{
						$$ = new SymbolInfo($1->getName(),$1->getType());
					}

					$$->setArrSize(n);

					delete $3;
				}
 		  ;
 		  
statements : statement
	   | statements statement
	   ;
	   
statement : var_declaration
	  | expression_statement
	  | compound_statement
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  | IF LPAREN expression RPAREN statement %prec THEN
	  | IF LPAREN expression RPAREN statement ELSE statement
	  | WHILE LPAREN expression RPAREN statement
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  | RETURN expression SEMICOLON
	  ;
	  
expression_statement 	: SEMICOLON			
			| expression SEMICOLON 
			;
	  
variable : ID 
			{	
				logFile<<"Line "<<yylineno<<": variable : ID"<<endl;

				string varType = $1->getDataType();

				if(varType == "NO_TYPE"){
					error_count++;

					errorFile<<"Error at line "<<yylineno<<": Undeclared variable "<<$1->getName()<<endl;
				}
				else if(n>=0){
					error_count++;

					errorFile<<"Error at line "<<yylineno<<": Array "<<$1->getName()<<" used without an index"<<endl;
				}

				$$ = $1;
			}		
	 | ID LTHIRD expression RTHIRD 
	 	{	
			logFile<<"Line "<<yylineno<<": variable : ID LTHIRD expression RTHIRD "<<endl;

			string varType = $1->getDataType();
			int n = $1->getArrSize();

			if(varType == "NO_TYPE"){
				error_count++;

				errorFile<<"Error at line "<<yylineno<<": Undeclared variable "<<$1->getName()<<endl;
			}
			else if(n==-1){
				error_count++;

				errorFile<<"Error at line "<<yylineno<<": "<<$1->getName()<<" not an array"<<endl;
			}

			$$ = $1;
		}
	 ;
	 
 expression : logic_expression	
	   | variable ASSIGNOP logic_expression 	
	   ;
			
logic_expression : rel_expression 	
		 | rel_expression LOGICOP rel_expression 	
		 ;
			
rel_expression	: simple_expression 
		| simple_expression RELOP simple_expression	
		;
				
simple_expression : term 
		  | simple_expression ADDOP term 
		  ;
					
term :	unary_expression
     |  term MULOP unary_expression
     ;

unary_expression : ADDOP unary_expression  
					{	
						logFile<<"Line no "<<yylineno<<": unary_expression : ADDOP unary_expression"<<endl;

						$$ = new SymbolInfo("unary_exp","NON_TERMINAL");
						$$->setDataType($2->getDataType());
					}
		 | NOT unary_expression 
				{	
					logFile<<"Line no "<<yylineno<<": unary_expression : NOT unary_expression"<<endl;

					$$ = new SymbolInfo("unary_exp","NON_TERMINAL");
					$$->setDataType($2->getDataType());
				}
		 | factor 
		 		{	
					logFile<<"Line no "<<yylineno<<": unary_expression : factor"<<endl;

					$$ = new SymbolInfo("unary_exp","NON_TERMINAL");
					$$->setDataType($1->getDataType());
				}
		 ;
	
factor  : variable {	
						logFile<<"Line no "<<yylineno<<": factor : variable"<<endl;

						$$ = new SymbolInfo("factor","NON_TERMINAL");
						$$->setDataType($1->getDataType());
				}
	| ID LPAREN argument_list RPAREN 
				{	
					logFile<<"Line no "<<yylineno<<": factor : ID LPAREN argument_list RPAREN"<<endl;

					string varType = $1->getDataType();
					$$ = new SymbolInfo("factor","NON_TERMINAL");

					if(varType=="NO_TYPE"){
						error_count++;
						errorFile<<"Error at line no "<<yylineno<<": Undeclared function "<<$1->getName()<<endl;
					}
					else if(!$1->isFunc){
						error_count++;
						errorFile<<"Error at line no "<<yylineno<<": "<<$1->getName()<<" is not a function"<<endl;
					}

					$$->setDataType(varType);
				}
	| LPAREN expression RPAREN
				{	
					logFile<<"Line no "<<yylineno<<": factor : LPAREN expression RPAREN"<<endl;

					$$ = new SymbolInfo("factor","NON_TERMINAL");
					$$->setDataType($2->getDataType());
				}
	| CONST_INT 
			{	
				logFile<<"Line no "<<yylineno<<": factor : CONST_INT"<<endl;

				$$ = new SymbolInfo("factor","NON_TERMINAL");
				$$->setDataType("INT");
			}
	| CONST_FLOAT
			{	
				logFile<<"Line no "<<yylineno<<": factor : CONST_FLOAT"<<endl;

				$$ = new SymbolInfo("factor","NON_TERMINAL");
				$$->setDataType("FLOAT");
			}
	| variable INCOP 
			{	
				logFile<<"Line no "<<yylineno<<": factor : variable INCOP"<<endl;

				$$ = new SymbolInfo("factor","NON_TERMINAL");
				$$->setDataType($1->getDataType());
			}
	| variable DECOP
			{	
				logFile<<"Line no "<<yylineno<<": factor : variable DECOP"<<endl;

				$$ = new SymbolInfo("factor","NON_TERMINAL");
				$$->setDataType($1->getDataType());
			}
	;
	
argument_list : arguments
			  |
			  ;
	
arguments : arguments COMMA logic_expression
	      | logic_expression
	      ;
 

%%
int main(int argc,char *argv[])
{
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}
	

	yyin=fp;
	yyparse();
	
	return 0;
}
