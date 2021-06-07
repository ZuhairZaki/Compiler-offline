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
	if(s==NULL)
		return head;

	SymbolInfo* y = head;
	SymbolInfo* prev_y = NULL;
	int n;

	logFile<<"\n";
	while(y!=NULL){
		n = y->getArrSize();
		logFile<<y->getName();
		if(n>=0){
			logFile<<"["<<n<<"]";
		}
		logFile<<",";

		prev_y = y;
		y = y->nextInfoObj;
	}

	n = s->getArrSize();
	logFile<<s->getName();
	if(n>=0){
		logFile<<"["<<n<<"]";
	}
	logFile<<"\n\n";

	if(prev_y==NULL)
		head = s;
	else prev_y->nextInfoObj = s;

	return head;
}

SymbolInfo* paramInsert(SymbolInfo* head,SymbolInfo* s)
{	
	if(s==NULL)
		return head;

	SymbolInfo* y = head;
	SymbolInfo* prev_y = NULL;
	bool mulDec = false;
	string paramType;

	logFile<<"\n";
	while(y!=NULL){
		paramType = y->getDataType();
		if(paramType=="INT"){
			paramType = "int";
		}
		else if(paramType=="FLOAT"){
			paramType = "float";
		}
		else if(paramType=="VOID"){
			paramType = "void";
		}
		logFile<<paramType<<" ";
		if(y->getName()=="NO_NAME"){
			logFile<<",";
		}
		else logFile<<y->getName()<<",";

		if(y->getName()==s->getName() && s->getName()!="NO_NAME"){
			mulDec = true;
		}
		prev_y = y;
		y = y->nextInfoObj;
	}

	paramType = s->getDataType();
	if(paramType=="INT"){
		paramType = "int";
	}
	else if(paramType=="FLOAT"){
		paramType = "float";
	}
	else if(paramType=="VOID"){
		paramType = "void";
	}
	logFile<<paramType<<" ";
	if(s->getName()=="NO_NAME"){
		logFile<<"\n\n";
	}
	else logFile<<s->getName()<<"\n\n";

	if(mulDec){
		error_count++;
		errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<s->getName()<<" in parameter"<<endl<<endl;
		logFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<s->getName()<<" in parameter"<<endl<<endl;
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
				logFile<<"Line "<<yylineno-1<<": start : program"<<endl<<endl;
				
				symTab->printAllScope(logFile);

				logFile<<"Total lines : "<<yylineno-1<<endl;
				logFile<<"Total errors : "<<error_count<<endl;
			}
	;

program : program unit 
			{ 
				logFile<<"Line "<<yylineno<<": program : program unit"<<endl; 

				string s = $1->getName()+"\n"+$2->getName();
				$$ = new SymbolInfo(s,"proc");

				logFile<<"\n"<<s<<"\n\n";

				delete $1;
				delete $2;
			}
	| unit 
		{ 
			logFile<<"Line "<<yylineno<<": program : unit"<<endl; 

			string s = $1->getName();
			$$ = new SymbolInfo(s,"proc");

			logFile<<"\n"<<s<<"\n\n";

			delete $1;
		}
	;
	
unit : var_declaration 
		{ 
			logFile<<"Line "<<yylineno<<": unit : var_declaration"<<endl; 
			
			string s = $1->getName();
			$$ = new SymbolInfo(s,"unit");

			logFile<<"\n"<<s<<"\n\n";

			delete $1;
		}
     | func_declaration
		{	
			logFile<<"Line "<<yylineno<<": unit : func_declaration"<<endl; 

			string s = $1->getName();
			$$ = new SymbolInfo(s,"unit");

			logFile<<"\n"<<s<<"\n\n";
		}
     | func_definition 
	 	{	
		 	logFile<<"Line "<<yylineno<<": unit : func_definition"<<endl; 

			string s = $1->getName();
			$$ = new SymbolInfo(s+"\n","unit");

			logFile<<"\n"<<s<<"\n\n";
		}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
					{
						if($2->isFunc){
							error_count++;
							errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
							logFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
						}
						else{
							string varType = $2->getDataType();

							if(varType!="NO_TYPE"){
								error_count++;
								errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
								logFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
							}
							else{
								$2->isFunc = true;
								$2->setDataType($1->getName());
								$2->paramlist = $4;
								symTab->Insert($2);
							}
						}

						string s = "(";
						SymbolInfo* param_start = $4;
						while(param_start!=NULL){
							string paramType = param_start->getDataType();
							if(paramType=="INT"){
								s += "int ";
							}
							else if(paramType=="FLOAT"){
								s += "float ";
							}
							else if(paramType=="VOID"){
								s += "void ";
							}
							if(param_start->getName()!="NO_NAME"){
								s += param_start->getName();
							}
							param_start = param_start->nextInfoObj;
							if(param_start!=NULL)
									s += ",";
						}
						s += ");";

						string func_str = $1->getType()+" "+$2->getName()+s;
						$$ = new SymbolInfo(func_str,"func_dec");

						logFile<<"Line "<<yylineno<<": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON"<<endl;
						logFile<<"\n"<<func_str<<"\n\n";

						delete $1;
					}
		| type_specifier ID LPAREN RPAREN SEMICOLON
				{
					if($2->isFunc){
						error_count++;
						errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
						logFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
					}
					else{
						string varType = $2->getDataType();

						if(varType!="NO_TYPE"){
							error_count++;
							errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
							logFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
						}
						else{
							$2->isFunc = true;
							$2->setDataType($1->getName());
							symTab->Insert($2);
						}
					}

					string func_str = $1->getType()+" "+$2->getName()+"();";
					$$ = new SymbolInfo(func_str,"func_dec");

					logFile<<"Line "<<yylineno<<": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON"<<endl;
					logFile<<"\n"<<func_str<<"\n\n";

					delete $1;
				}
		;

func_def_start : type_specifier ID LPAREN parameter_list RPAREN LCURL
					{
						if($2->isFunc){
							if($2->isDefined){
								error_count++;
								errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
								logFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
							}
							else{
								if($2->getDataType()!=$1->getName()){
									error_count++;
									errorFile<<"Error at line "<<yylineno;
									errorFile<<": Return type mismatch with function declaration in function "<<$2->getName()<<endl<<endl;
									logFile<<"Error at line "<<yylineno;
									logFile<<": Return type mismatch with function declaration in function "<<$2->getName()<<endl<<endl;
								}

								SymbolInfo* funcParam = $2->paramlist;
								SymbolInfo* defParam = $4;
								if(funcParam==NULL){
									error_count++;
									errorFile<<"Error at line "<<yylineno;
									errorFile<<": Total number of arguments mismatch with declaration in function "<<$2->getName()<<endl<<endl;
									logFile<<"Error at line "<<yylineno;
									logFile<<": Total number of arguments mismatch with declaration in function "<<$2->getName()<<endl<<endl;
								}
								while(funcParam!=NULL && defParam!=NULL){
									if(funcParam->getDataType()!=defParam->getDataType()){
										error_count++;
										errorFile<<"Error at line "<<yylineno;
										errorFile<<": Parameter type mismatch with declaration in function"<<$2->getName()<<endl<<endl;
										logFile<<"Error at line "<<yylineno;
										logFile<<": Parameter type mismatch with declaration in function"<<$2->getName()<<endl<<endl;
										break;
									}
									funcParam = funcParam->nextInfoObj;
									defParam = defParam->nextInfoObj;

									if((funcParam==NULL&&defParam!=NULL)||(funcParam!=NULL&&defParam==NULL)){
										error_count++;
										errorFile<<"Error at line "<<yylineno;
										errorFile<<": Total number of arguments mismatch with declaration in function "<<$2->getName()<<endl<<endl;
										logFile<<"Error at line "<<yylineno;
										logFile<<": Total number of arguments mismatch with declaration in function "<<$2->getName()<<endl<<endl;
										break;
									}
								}

								$2->isDefined = true;
								$2->paramlist = $4;
							}
						}
						else{
							string varType = $2->getDataType();

							if(varType!="NO_TYPE"){
								error_count++;
								errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
								logFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
							}
							else{
								$2->isFunc = true;
								$2->setDataType($1->getName());
								$2->isDefined = true;
								$2->paramlist = $4;
								symTab->Insert($2);
							}
						}

						symTab->enterScope();

						SymbolInfo* funcParam = $4;
						while(funcParam!=NULL){
							if(funcParam->getName()=="NO_NAME"){
								error_count++;
								errorFile<<"Error at line "<<yylineno;
								errorFile<<": Parameter without name in definition of function "<<$2->getName()<<endl<<endl;
								logFile<<"Error at line "<<yylineno;
								logFile<<": Parameter without name in definition of function "<<$2->getName()<<endl<<endl;
							}
							else if(funcParam->getDataType()!="VOID"){
								SymbolInfo* paramObj = new SymbolInfo(funcParam->getName(),funcParam->getType());
								paramObj->setDataType(funcParam->getDataType());
								symTab->Insert(paramObj);
							}
							funcParam = funcParam->nextInfoObj;
						}

						$$ = new SymbolInfo($2->getName(),"ID");
						$$->setDataType($1->getName());
						$$->paramlist = $4;

						delete $1;
					}
				| type_specifier ID LPAREN RPAREN LCURL
					{
						if($2->isFunc){
							if($2->isDefined){
								error_count++;
								errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
								logFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
							}
							else{
								if($2->getDataType()!=$1->getName()){
									error_count++;
									errorFile<<"Error at line "<<yylineno;
									errorFile<<": Return type mismatch with function declaration in function "<<$2->getName()<<endl<<endl;
									logFile<<"Error at line "<<yylineno;
									logFile<<": Return type mismatch with function declaration in function "<<$2->getName()<<endl<<endl;
								}

								SymbolInfo* funcParam = $2->paramlist;
								if(funcParam!=NULL){
									error_count++;
									errorFile<<"Error at line "<<yylineno;
									errorFile<<": Total number of arguments mismatch with declaration in function "<<$2->getName()<<endl<<endl;
									logFile<<"Error at line "<<yylineno;
									logFile<<": Total number of arguments mismatch with declaration in function "<<$2->getName()<<endl<<endl;
								}
								$2->isDefined = true;
								$2->paramlist = NULL;
							}
						}
						else{
							string varType = $2->getDataType();

							if(varType!="NO_TYPE"){
								error_count++;
								errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
								logFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<$2->getName()<<endl<<endl;
							}
							else{
								$2->isFunc = true;
								$2->setDataType($1->getName());
								$2->isDefined = true;
								symTab->Insert($2);
							}
						}

						symTab->enterScope();

						$$ = new SymbolInfo($2->getName(),"ID");
						$$->setDataType($1->getName());

						delete $1;
					}
		 
func_definition : func_def_start compound_end
					{	
						string comp_str = "{\n"+$2->getName();
						logFile<<"\n"<<comp_str<<"\n\n";

						symTab->printAllScope(logFile);

						SymbolInfo* funcParam = $1->paramlist;

						string s="";
						string paramType = $1->getDataType();
						if(paramType=="INT"){
							s += "int ";
						}
						else if(paramType=="FLOAT"){
							s += "float ";
						}
						else if(paramType=="VOID"){
							s += "void ";
						}
						s += $1->getName();

						if(funcParam!=NULL){
							logFile<<"Line "<<yylineno<<": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"<<endl;
						}
						else{
							logFile<<"Line "<<yylineno<<": func_definition :type_specifier ID LPAREN RPAREN compound_statement"<<endl;
						}

						s += "(";
						while(funcParam!=NULL){
							string paramType = funcParam->getDataType();
							if(paramType=="INT"){
								s += "int ";
							}
							else if(paramType=="FLOAT"){
								s += "float ";
							}
							else if(paramType=="VOID"){
								s += "void ";
							}
							if(funcParam->getName()!="NO_NAME"){
								s += funcParam->getName();
							}
							funcParam = funcParam->nextInfoObj;
							if(funcParam!=NULL)
									s += ",";
						}
						s += ")";

						string func_str = s + comp_str;
						$$ = new SymbolInfo(func_str,"func_def");
						logFile<<"\n"<<func_str<<"\n\n";

						symTab->exitScope();
					}
 			;				


parameter_list  : parameter_list COMMA type_specifier ID
					{
						logFile<<"Line "<<yylineno<<": parameter_list  : parameter_list COMMA type_specifier ID"<<endl;

						string paramType = $3->getName();

						SymbolInfo* paramObj = new SymbolInfo($4->getName(),"ID");
						paramObj->setDataType(paramType);

						$$ = paramInsert($1,paramObj);

						if(paramType=="VOID"){
							error_count++;
							errorFile<<"Error at line "<<yylineno<<": Variable type cannot be Void"<<endl<<endl;
							logFile<<"Error at line "<<yylineno<<": Variable type cannot be Void"<<endl<<endl;
						}

						delete $3;

						if($4->getDataType()=="NO_TYPE")
							delete $4;
					}
		| parameter_list COMMA type_specifier
			{
				logFile<<"Line "<<yylineno<<": parameter_list  : parameter_list COMMA type_specifier"<<endl;

				string paramType = $3->getName();

				SymbolInfo* paramObj = new SymbolInfo("NO_NAME","ID");
				paramObj->setDataType(paramType);

				$$ = paramInsert($1,paramObj);

				if(paramType=="VOID"){
						error_count++;
						errorFile<<"Error at line "<<yylineno<<": Variable type cannot be Void"<<endl<<endl;
						logFile<<"Error at line "<<yylineno<<": Variable type cannot be Void"<<endl<<endl;
				}

				delete $3;
			}
 		| type_specifier ID
		 	{
				string paramType = $1->getName();
				if(paramType=="VOID"){
						error_count++;
						errorFile<<"Error at line "<<yylineno<<": Variable type cannot be Void"<<endl<<endl;
						logFile<<"Error at line "<<yylineno<<": Variable type cannot be Void"<<endl<<endl;
				}

				$$ = new SymbolInfo($2->getName(),"ID");
				$$->setDataType(paramType);

				logFile<<"Line "<<yylineno<<": parameter_list  : type_specifier ID"<<endl;
				logFile<<"\n"<<$1->getType()<<" "<<$2->getName()<<"\n\n";

				delete $1;

				if($2->getDataType()=="NO_TYPE")
						delete $2;
			}
		| type_specifier
			{
				string paramType = $1->getName();
				if(paramType=="VOID"){
						error_count++;
						errorFile<<"Error at line "<<yylineno<<": Variable type cannot be Void"<<endl<<endl;
						logFile<<"Error at line "<<yylineno<<": Variable type cannot be Void"<<endl<<endl;
				}

				$$ = new SymbolInfo("NO_NAME","ID");
				$$->setDataType(paramType);

				logFile<<"Line "<<yylineno<<": parameter_list  : type_specifier"<<endl;
				logFile<<"\n"<<$1->getType()<<"\n\n";

				delete $1;
			}

 		;

compound_start : LCURL {
							symTab->enterScope();
					   }
			;

compound_end : statements RCURL 
						{
							logFile<<"Line "<<yylineno<<": compound_statement : LCURL statements RCURL"<<endl;

							string s = $1->getName()+"\n}";
							$$ = new SymbolInfo(s,"comp");

							delete $1;
						}
 		    | RCURL
				{
					logFile<<"Line "<<yylineno<<": compound_statement : LCURL RCURL"<<endl;

					$$ = new SymbolInfo("}","comp");
				}
 		    ;

compound_statement : compound_start compound_end
						{
							string s = "{\n"+$2->getName();
							$$ = new SymbolInfo(s,"comp_stmt");

							logFile<<"\n"<<s<<"\n\n";

							delete $2;
						}
				;
 		    
var_declaration : type_specifier declaration_list SEMICOLON 
					{	
						string varType = $1->getName();
						string s = "";

						SymbolInfo* head = $2;

						if(varType=="VOID"){
							error_count++;

							errorFile<<"Error at line "<<yylineno<<": Variable type cannot be Void"<<endl<<endl;
							logFile<<"Error at line "<<yylineno<<": Variable type cannot be Void"<<endl<<endl;

							while($2!=NULL){
								s += head->getName();
								$2 = $2->nextInfoObj;
								delete head;
								head = $2;
								if(head!=NULL){
									s += ",";
								}
							}
						}
						else{
							while(head!=NULL){
								SymbolInfo* item = new SymbolInfo(head->getName(),head->getType());
								item->setDataType(varType);
								s += head->getName();

								int n = head->getArrSize();
								item->setArrSize(n);
								if(n>=0){
									s += "[";
									s += to_string(n);
									s += "]";
								}

								if(!symTab->Insert(item)){
									error_count++;

									errorFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<head->getName()<<endl<<endl;
									logFile<<"Error at line "<<yylineno<<": Multiple declaration of "<<head->getName()<<endl<<endl;
								}
								head = head->nextInfoObj;

								if(head!=NULL){
									s += ",";
								}
							}
						}

						string unit_name = $1->getType()+" "+s+";";
						$$ = new SymbolInfo(unit_name,"var_dec");

						logFile<<"Line "<<yylineno<<": var_declaration : type_specifier declaration_list SEMICOLON"<<endl;
						logFile<<"\n"<<unit_name<<"\n\n";

						delete $1;
					}
 		 ;
 		 
type_specifier	: INT {
							logFile<<"Line "<<yylineno<<": type_specifier : INT"<<endl;
							$$ = new SymbolInfo("INT","int");

							logFile<<"\nint\n\n";
					}
 		| FLOAT {
			 		logFile<<"Line "<<yylineno<<": type_specifier : FLOAT"<<endl;
					$$ = new SymbolInfo("FLOAT","float");

					logFile<<"\nfloat\n\n";
		 		}
 		| VOID {
			 		logFile<<"Line "<<yylineno<<": type_specifier : VOID"<<endl;
					$$ = new SymbolInfo("VOID","void");

					logFile<<"\nvoid\n\n";
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

					logFile<<"\n"<<$1->getName()<<"\n\n";
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

					logFile<<"\n"<<$1->getName()<<"["<<n<<"]"<<"\n\n";

					delete $3;
				}
 		  ;
 		  
statements : statement 
				{	
					logFile<<"Line "<<yylineno<<": statements : statement"<<endl;	

					string s = $1->getName();
					$$ = new SymbolInfo(s,"stmts");

					logFile<<"\n"<<s<<"\n\n";

					delete $1;
				}
	   | statements statement 
	   			{	  
					logFile<<"Line "<<yylineno<<": statements : statements statement"<<endl;	

					string s = $1->getName()+"\n"+$2->getName();
					$$ = new SymbolInfo(s,"stmts");

					logFile<<"\n"<<s<<"\n\n";

					delete $1;
					delete $2;
				}
	   ;
	   
statement : var_declaration 
		{ 
			logFile<<"Line "<<yylineno<<": statement : var_declaration"<<endl; 

			string s = $1->getName();
			$$ = new SymbolInfo(s,"stmt");

			logFile<<"\n"<<s<<"\n\n";

			delete $1;
		}
	  | expression_statement 
	  	{	
			logFile<<"Line "<<yylineno<<": statement : expression_statement"<<endl; 

			string s = $1->getName();
			$$ = new SymbolInfo(s,"stmt");

			logFile<<"\n"<<s<<"\n\n";

			delete $1;
		}
	  | compound_statement
	  	{   
			symTab->printAllScope(logFile);
			logFile<<"Line "<<yylineno<<": statement : compound_statement"<<endl; 

			string s = $1->getName();
			$$ = new SymbolInfo(s,"stmt");
			logFile<<"\n"<<s<<"\n\n";

			symTab->exitScope();

			delete $1;
		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  	{
			logFile<<"Line "<<yylineno;
			logFile<<": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"<<endl;  

			string s = "for( "+$3->getName()+" "+$4->getName()+" "+$5->getName()+" )\n"+$7->getName();
			$$ = new SymbolInfo(s,"stmt");

			logFile<<"\n"<<s<<"\n\n";

			delete $3;
			delete $4;
			delete $5;
			delete $7;
		}
	  | IF LPAREN expression RPAREN statement %prec THEN
	  		{
				logFile<<"Line "<<yylineno<<": statement : IF LPAREN expression RPAREN statement"<<endl;

				string s = "if( "+$3->getName()+" )\n"+$5->getName();
				$$ = new SymbolInfo(s,"stmt");

				logFile<<"\n"<<s<<"\n\n";

				delete $3;
				delete $5;
			}
	  | IF LPAREN expression RPAREN statement ELSE statement
	  		{
				logFile<<"Line "<<yylineno<<": statement : IF LPAREN expression RPAREN statement ELSE statement"<<endl;

				string s = "if( "+$3->getName()+" )\n"+$5->getName()+"\nelse "+$7->getName();
				$$ = new SymbolInfo(s,"stmt");

				logFile<<"\n"<<s<<"\n\n";

				delete $3;
				delete $5;
				delete $7;
			}
	  | WHILE LPAREN expression RPAREN statement
	  		{
				logFile<<"Line "<<yylineno<<": statement : WHILE LPAREN expression RPAREN statement"<<endl;

				string s = "while( "+$3->getName()+" )\n"+$5->getName();
				$$ = new SymbolInfo(s,"stmt");

				logFile<<"\n"<<s<<"\n\n";

				delete $3;
				delete $5;
			}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  		{
				logFile<<"Line "<<yylineno<<": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n"<<endl;

				string s = "printf("+$3->getName()+");";
				$$ = new SymbolInfo(s,"stmt");

				string varType = $3->getDataType();
				int n = $3->getArrSize();
				if(varType=="NO_TYPE"){
					error_count++;
					errorFile<<"Error at line "<<yylineno<<": Undeclared variable "<<$3->getName()<<endl<<endl;
					logFile<<"Error at line "<<yylineno<<": Undeclared variable "<<$3->getName()<<endl<<endl;

					delete $3;
				}
				else if(n>=0){
					error_count++;
					errorFile<<"Error at line "<<yylineno<<": Type mismatch, "<<$3->getName()<<" is an array"<<endl<<endl;
					logFile<<"Error at line "<<yylineno<<": Type mismatch, "<<$3->getName()<<" is an array"<<endl<<endl;
				}
				else if($3->isFunc){
					error_count++;
					errorFile<<"Error at line "<<yylineno<<": Function "<<$3->getName()<<" called without parentheses"<<endl<<endl;
					logFile<<"Error at line "<<yylineno<<": Function "<<$3->getName()<<" called without parentheses"<<endl<<endl;
				}

				logFile<<s<<"\n\n";
			}
	  | RETURN expression SEMICOLON
	  		{
				logFile<<"Line "<<yylineno<<": statement : RETURN expression SEMICOLON"<<endl;

				string s = "return "+$2->getName()+";";
				$$ = new SymbolInfo(s,"stmt");

				logFile<<"\n"<<s<<"\n\n";

				delete $2;
			}
	  ;
	  
expression_statement : SEMICOLON	
				{	
					logFile<<"Line "<<yylineno<<": expression_statement : SEMICOLON"<<endl;	

					$$ = new SymbolInfo(";","expr_stmt");
					logFile<<"\n;\n\n";
				}		
			| expression SEMICOLON 
				{	
					logFile<<"Line "<<yylineno<<": expression_statement : expression SEMICOLON"<<endl;	

					string s = $1->getName()+";";
					$$ = new SymbolInfo(s,"expr_stmt");
					$$->setDataType($1->getDataType());

					logFile<<"\n"<<s<<"\n\n";

					delete $1;
				}
			;
	  
variable : ID 
			{	
				logFile<<"Line "<<yylineno<<": variable : ID\n"<<endl;
				string varType = $1->getDataType();
				int n = $1->getArrSize();

				if(varType == "NO_TYPE"){
					error_count++;

					errorFile<<"Error at line "<<yylineno<<": Undeclared variable "<<$1->getName()<<endl<<endl;
					logFile<<"Error at line "<<yylineno<<": Undeclared variable "<<$1->getName()<<endl<<endl;
				}
				else if(n>=0){
					error_count++;

					errorFile<<"Error at line "<<yylineno<<": Type mismatch, "<<$1->getName()<<" is an array"<<endl<<endl;
					logFile<<"Error at line "<<yylineno<<": Type mismatch, "<<$1->getName()<<" is an array"<<endl<<endl;
				}
				else if($1->isFunc){
					error_count++;

					errorFile<<"Error at line "<<yylineno<<": Function "<<$1->getName()<<" called without parentheses"<<endl<<endl;
					logFile<<"Error at line "<<yylineno<<": Function "<<$1->getName()<<" called without parentheses"<<endl<<endl;
				}

				$$ = new SymbolInfo($1->getName(),"var");
				$$->setDataType(varType);
				$$->setArrSize(n);

				logFile<<$1->getName()<<"\n\n";

				if(varType=="NO_TYPE")
					delete $1;
			}		
	 | ID LTHIRD expression RTHIRD 
	 	{	
			logFile<<"Line "<<yylineno<<": variable : ID LTHIRD expression RTHIRD\n"<<endl;
			string varType = $1->getDataType();
			string expType = $3->getDataType();
			int n = $1->getArrSize();

			if(varType == "NO_TYPE"){
				error_count++;

				errorFile<<"Error at line "<<yylineno<<": Undeclared variable "<<$1->getName()<<endl<<endl;
				logFile<<"Error at line "<<yylineno<<": Undeclared variable "<<$1->getName()<<endl<<endl;
			}
			else if(n==-1){
				error_count++;

				errorFile<<"Error at line "<<yylineno<<": "<<$1->getName()<<" not an array"<<endl<<endl;
				logFile<<"Error at line "<<yylineno<<": "<<$1->getName()<<" not an array"<<endl<<endl;
			}
			else if(expType!="INT"){
				error_count++;

				errorFile<<"Error at line "<<yylineno<<": Expression inside third brackets not an integer"<<endl<<endl;
				logFile<<"Error at line "<<yylineno<<": Expression inside third brackets not an integer"<<endl<<endl;
			}

			string s = $1->getName()+"["+$3->getName()+"]";
			$$ = new SymbolInfo(s,"arr");
			$$->setDataType(varType);
			$$->setArrSize(n);

			logFile<<s<<"\n\n";

			if(varType=="NO_TYPE")
				delete $1;
		}
	 ;
	 
expression : logic_expression 
				{
					logFile<<"Line "<<yylineno<<": expression : logic_expression "<<endl;

					$$ = new SymbolInfo($1->getName(),"expr");
					$$->setDataType($1->getDataType());

					logFile<<"\n"<<$1->getName()<<"\n\n";

					delete $1;
				}
	   | variable ASSIGNOP logic_expression 
	   			{
					logFile<<"Line "<<yylineno<<": expression : variable ASSIGNOP logic_expression "<<endl;

					string varType = $1->getDataType();
					string expType = $3->getDataType();

					string s = $1->getName()+" = "+$3->getName();
					$$ = new SymbolInfo(s,"expr");
					$$->setDataType(expType);

					logFile<<"\n"<<s<<"\n\n";

					if(varType!="NO_TYPE"){
						if(expType=="VOID"){
							error_count++;
							errorFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
							logFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
						}
						else if(varType=="INT" && expType=="FLOAT"){
							error_count++;
							errorFile<<"Error at line "<<yylineno<<": Type mismatch"<<endl<<endl;
							logFile<<"Error at line "<<yylineno<<": Type mismatch"<<endl<<endl;
						}
					}
					else{
						delete $1;
					}
				}	
	   ;
			
logic_expression : rel_expression 	
					{
						logFile<<"Line "<<yylineno<<": logic_expression : rel_expression "<<endl;

						$$ = new SymbolInfo($1->getName(),"logic_expr");
						$$->setDataType($1->getDataType());

						logFile<<"\n"<<$1->getName()<<"\n\n";

						delete $1;
					}
		 | rel_expression LOGICOP rel_expression 	
		 			{
						logFile<<"Line "<<yylineno<<": logic_expression : rel_expression LOGICOP rel_expression\n"<<endl;

						string varType1 = $1->getDataType();
						string varType2 = $3->getDataType();
						
						string s = $1->getName()+$2->getName()+$3->getName();
						$$ = new SymbolInfo(s,"logic_expr");
						if(varType1=="VOID"||varType2=="VOID"){
							error_count++;
							errorFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
							logFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
							$$->setDataType("NO_TYPE");
						}
						else $$->setDataType("INT");

						logFile<<s<<"\n\n";

						delete $1;
						delete $2;
						delete $3;
					}
		 ;
			
rel_expression	: simple_expression 
					{
						logFile<<"Line "<<yylineno<<": rel_expression : simple_expression "<<endl;

						$$ = new SymbolInfo($1->getName(),"rel_expr");
						$$->setDataType($1->getDataType());

						logFile<<"\n"<<$1->getName()<<"\n\n";

						delete $1;
					}
		| simple_expression RELOP simple_expression	
					{
						logFile<<"Line "<<yylineno<<": rel_expression : simple_expression RELOP simple_expression\n"<<endl;

						string varType1 = $1->getDataType();
						string varType2 = $3->getDataType();
						
						string s = $1->getName()+$2->getName()+$3->getName();
						$$ = new SymbolInfo(s,"rel_expr");
						if(varType1=="VOID"||varType2=="VOID"){
							error_count++;
							errorFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
							logFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
							$$->setDataType("NO_TYPE");
						}
						else $$->setDataType("INT");

						logFile<<s<<"\n\n";

						delete $1;
						delete $2;
						delete $3;
					}
		;
				
simple_expression : term 
						{
							logFile<<"Line "<<yylineno<<": simple_expression : term"<<endl;

							$$ = new SymbolInfo($1->getName(),"simple_expr");
							$$->setDataType($1->getDataType());

							logFile<<"\n"<<$1->getName()<<"\n\n";

							delete $1;
						}
		  | simple_expression ADDOP term 
		  		{
					logFile<<"Line "<<yylineno<<": simple_expression : simple_expression ADDOP term\n"<<endl;

					string varType1 = $1->getDataType();
					string varType2 = $3->getDataType();
					
					string s = $1->getName()+$2->getName()+$3->getName();
					$$ = new SymbolInfo(s,"simple_expr");
					if(varType1=="VOID"||varType2=="VOID"){
						error_count++;
						errorFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
						logFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
						$$->setDataType("NO_TYPE");
					}
					else{
						if(varType1=="NO_TYPE"||varType2=="NO_TYPE"){
							$$->setDataType("NO_TYPE");
						}
						else if(varType1=="FLOAT"||varType2=="FLOAT"){
							$$->setDataType("FLOAT");
						}
						else $$->setDataType("INT");
					}

					logFile<<s<<"\n\n";

					delete $1;
					delete $2;
					delete $3;
				}
		  ;
					
term :	unary_expression 
			{
				logFile<<"Line "<<yylineno<<": term : unary_expression "<<endl;

				$$ = new SymbolInfo($1->getName(),"term");
				$$->setDataType($1->getDataType());

				logFile<<"\n"<<$1->getName()<<"\n\n";

				delete $1;
			}
     |  term MULOP unary_expression
	 		{
				logFile<<"Line "<<yylineno<<": term : term MULOP unary_expression\n"<<endl;

				string varType1 = $1->getDataType();
				string varType2 = $3->getDataType();
				string op = $2->getName();

				string s = $1->getName()+$2->getName()+$3->getName();
				$$ = new SymbolInfo(s,"term");
				if(varType1=="VOID"||varType2=="VOID"){
					error_count++;
					errorFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
					logFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
					$$->setDataType("NO_TYPE");
				}
				else if(op=="%"){
					if(varType1=="FLOAT"||varType2=="FLOAT"){
						error_count++;
						errorFile<<"Error at line "<<yylineno<<": Non-integer operands on modulus operator"<<endl<<endl;
						logFile<<"Error at line "<<yylineno<<": Non-integer operands on modulus operator"<<endl<<endl;
						$$->setDataType("NO_TYPE");
					}
					else {
						string objType = $3->getType();
						if(objType=="CONST_INT"){
							int objVal = stoi($3->getName());
							if(objVal==0){
								error_count++;
								errorFile<<"Error at line "<<yylineno<<": Modulus by Zero"<<endl<<endl;
								logFile<<"Error at line "<<yylineno<<": Modulus by Zero"<<endl<<endl;
								$$->setDataType("NO_TYPE");
							}
							else $$->setDataType(varType2);
						}
						else if(varType1=="NO_TYPE"||varType2=="NO_TYPE"){
							$$->setDataType("NO_TYPE");
						}
						else $$->setDataType("INT");
					}
				}
				else{
					if(varType1=="NO_TYPE"||varType2=="NO_TYPE"){
						 $$->setDataType("NO_TYPE");
					}
					else if(varType1=="FLOAT"||varType2=="FLOAT"){
						 $$->setDataType("FLOAT");
					}
					else $$->setDataType("INT");
				}

				logFile<<s<<"\n\n";

				delete $1;
				delete $2;
				delete $3;
			}
     ;

unary_expression : ADDOP unary_expression  
					{	
						logFile<<"Line "<<yylineno<<": unary_expression : ADDOP unary_expression\n"<<endl;

						string s = $1->getName()+$2->getName();
						$$ = new SymbolInfo(s,"unary_exp");
						string varType = $2->getDataType();

						if(varType=="VOID"){
							error_count++;
							errorFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
							logFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
							$$->setDataType("NO_TYPE");
						}
						else $$->setDataType(varType);

						logFile<<s<<"\n\n";

						delete $1;
						delete $2;
					}
		 | NOT unary_expression 
				{	
					logFile<<"Line "<<yylineno<<": unary_expression : NOT unary_expression\n"<<endl;

					string s = "!"+$2->getName();
					$$ = new SymbolInfo(s,"unary_exp");
					string varType = $2->getDataType();

					if(varType=="VOID"){
						error_count++;
						errorFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
						logFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
						$$->setDataType("NO_TYPE");
					}
					else if(varType=="NO_TYPE"){
						$$->setDataType("NO_TYPE");
					}
					else $$->setDataType("INT");

					logFile<<s<<"\n\n";

					delete $2;
				}
		 | factor 
		 		{	
					logFile<<"Line "<<yylineno<<": unary_expression : factor"<<endl;

					logFile<<"\n"<<$1->getName()<<"\n\n";

					string objType = $1->getType();
					if(objType=="CONST_INT"){
						$$ = $1;
					}
					else{
						$$ = new SymbolInfo($1->getName(),"unary_exp");
						$$->setDataType($1->getDataType());

						delete $1;
					}
				}
		 ;
	
factor  : variable {	
						logFile<<"Line "<<yylineno<<": factor : variable"<<endl;

						string varType = $1->getDataType();

						$$ = new SymbolInfo($1->getName(),"factor");
						$$->setDataType(varType);

						logFile<<"\n"<<$1->getName()<<"\n\n";

						if(varType=="NO_TYPE")
							delete $1;
				}
	| ID LPAREN argument_list RPAREN 
				{	
					logFile<<"Line "<<yylineno<<": factor : ID LPAREN argument_list RPAREN\n"<<endl;
					string varType = $1->getDataType();

					string s = "";
					SymbolInfo* arg_start = $3;
					while(arg_start!=NULL){
						s += arg_start->getName();
						arg_start = arg_start->nextInfoObj;
						if(arg_start!=NULL)
							s += ",";
					}
					string fac_name = $1->getName()+"("+s+")";
					$$ = new SymbolInfo(fac_name,"factor");

					if(varType=="NO_TYPE"){
						error_count++;
						errorFile<<"Error at line "<<yylineno<<": Undeclared function "<<$1->getName()<<endl<<endl;
						logFile<<"Error at line "<<yylineno<<": Undeclared function "<<$1->getName()<<endl<<endl;
						delete $1;
					}
					else if(!$1->isFunc){
						error_count++;
						errorFile<<"Error at line "<<yylineno;
						errorFile<<": Function call with non-function type identifier "<<$1->getName()<<endl<<endl;
						logFile<<"Error at line "<<yylineno;
						logFile<<": Function call with non-function type identifier "<<$1->getName()<<endl<<endl;
					}
					else{
						int pos = 1;
						SymbolInfo* funcParam = $1->paramlist;
						SymbolInfo* argslist = $3;
						if(funcParam==NULL||argslist==NULL){
							error_count++;
							errorFile<<"Error at line "<<yylineno;
							errorFile<<": Total number of arguments mismatch in function "<<$1->getName()<<endl<<endl;
							logFile<<"Error at line "<<yylineno;
							logFile<<": Total number of arguments mismatch in function "<<$1->getName()<<endl<<endl;
						}
						while(funcParam!=NULL && argslist!=NULL){
							string varType1 = funcParam->getDataType();
							string varType2 = argslist->getDataType();
							if(varType2=="VOID"){
								error_count++;
								errorFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
								logFile<<"Error at line "<<yylineno<<": Void function used in expression"<<endl<<endl;
							}
							else if(varType1=="VOID" || (varType1=="INT" && varType2=="FLOAT")){
								error_count++;
								errorFile<<"Error at line "<<yylineno<<": "<<pos<<"th argument mismatch in function "<<$1->getName()<<endl<<endl;
								logFile<<"Error at line "<<yylineno<<": "<<pos<<"th argument mismatch in function "<<$1->getName()<<endl<<endl;
								break;
							}
							funcParam = funcParam->nextInfoObj;
							argslist = argslist->nextInfoObj;
							pos++;

							if((funcParam==NULL&&argslist!=NULL)||(funcParam!=NULL&&argslist==NULL)){
								error_count++;
								errorFile<<"Error at line "<<yylineno;
								errorFile<<": Total number of arguments mismatch in function "<<$1->getName()<<endl<<endl;
								logFile<<"Error at line "<<yylineno;
								logFile<<": Total number of arguments mismatch in function "<<$1->getName()<<endl<<endl;
								break;
							}
						}
					}

					$$->setDataType(varType);

					logFile<<fac_name<<"\n\n";
				}
	| LPAREN expression RPAREN
				{	
					logFile<<"Line "<<yylineno<<": factor : LPAREN expression RPAREN"<<endl;

					string s = "("+$2->getName()+")";
					$$ = new SymbolInfo(s,"factor");
					$$->setDataType($2->getDataType());

					logFile<<"\n"<<s<<"\n\n";

					delete $2;
				}
	| CONST_INT 
			{	
				logFile<<"Line "<<yylineno<<": factor : CONST_INT"<<endl;

				$$ = $1;
				$$->setDataType("INT");

				logFile<<"\n"<<$1->getName()<<"\n\n";
			}
	| CONST_FLOAT
			{	
				logFile<<"Line "<<yylineno<<": factor : CONST_FLOAT"<<endl;

				$$ = $1;
				$$->setDataType("FLOAT");

				logFile<<"\n"<<$1->getName()<<"\n\n";
			}
	| variable INCOP 
			{	
				logFile<<"Line "<<yylineno<<": factor : variable INCOP"<<endl;

				string varType = $1->getDataType();

				string s = $1->getName()+"++";
				$$ = new SymbolInfo(s,"factor");
				$$->setDataType(varType);

				logFile<<"\n"<<s<<"\n\n";

				if(varType=="NO_TYPE")
						delete $1;
			}
	| variable DECOP
			{	
				logFile<<"Line "<<yylineno<<": factor : variable DECOP"<<endl;

				string varType = $1->getDataType();

				string s = $1->getName()+"--";
				$$ = new SymbolInfo(s,"factor");
				$$->setDataType(varType);

				logFile<<"\n"<<s<<"\n\n";

				if(varType=="NO_TYPE")
						delete $1;
			}
	;
	
argument_list : arguments 
					{	
						string s = "";
						SymbolInfo* arg_start = $1;
						while(arg_start!=NULL){
							s += arg_start->getName();
							arg_start = arg_start->nextInfoObj;
							if(arg_start!=NULL)
								s += ",";
						}

						logFile<<"Line "<<yylineno<<": argument_list : arguments"<<endl;
						logFile<<"\n"<<s<<"\n\n";
						$$ = $1;
					}
			  | 	{
						logFile<<"Line "<<yylineno<<": argument_list : \n"<<endl;
					}
			  ;
	
arguments : arguments COMMA logic_expression
				{
					logFile<<"Line "<<yylineno<<": arguments : arguments COMMA logic_expression"<<endl;
					$$ = insertItem($1,$3);	
				}
	      | logic_expression
		  	{
				$$ = new SymbolInfo($1->getName(),"args");
				$$->setDataType($1->getDataType());

				logFile<<"Line "<<yylineno<<": arguments : logic_expression"<<endl;
				logFile<<"\n"<<$1->getName()<<"\n\n";

				delete $1;				
			}
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
