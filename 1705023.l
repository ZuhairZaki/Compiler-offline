%option noyywrap yylineno

%x CMNT_START
%x MUL_CMNT
%x STR_START

%{
#include<bits/stdc++.h>
#include "SymbolTable.h"
#define YYSTYPE SymbolInfo*
#include "y.tab.h"

using namespace std;

extern YYSTYPE yylval;
extern SymbolTable* symTab;
void yyerror(char *);

int line_no;
int error_count = 0;

string token_name;
string hold_lexeme;

extern ofstream errorFile;
extern ofstream logFile;

void save_lexeme(){
	string s(yytext);
	hold_lexeme += s;
}

string convert(string s){
    int len = s.length();

    for(int i=0;;i++){
        if(i==len)
            break;

        char c1 = s[i];

        if(c1 == '\\'){

            if(i==len-1){
                s.erase(i,1);
                break;
            }

            char c2 = s[i+1];

            switch(c2){
                case 'n':
                    s.replace(i,2,"\n");
                    len--;
                    break;
                case 't':
                    s.replace(i,2,"\t");
                    len--;
                    break;
                case 'v':
                    s.replace(i,2,"\v");
                    len--;
                    break;
                case 'b':
                    s.replace(i,2,"\b");
                    len--;
                    break;
                case '\\':
                    s.replace(i,2,"\\");
                    len--;
                    break;
                case '\'':
                    s.replace(i,2,"'");
                    len--;
                    break;
                case '\"':
                    s.replace(i,2,"\"");
                    len--;
                    break;
                case 'a':
                    s.replace(i,2,"\a");
                    len--;
                    break;
                case 'f':
                    s.replace(i,2,"\f");
                    len--;
                    break;
                case 'r':
                    s.replace(i,2,"\r");
                    len--;
                    break;
                case '0':
                    s.replace(i,2,"\0");
                    len--;
                    break;
                case '\n':
                    s.erase(i,2);
                    i--;
                    len -= 2;
                    break;
                default:
                    s.erase(i,1);
                    i--;
                    len--;
                    break;
            }
        }
    }


    return s;
}

string convert_upper(const char* x)
{
    int len =  strlen(x);
    string s;

    for(int i=0;i<len;i++)
        s += toupper(x[i]);

    return s;
}


%}

DIGIT [0-9]
WHITESPACE [ \t\v\n]
NOT_WHITESPACE [^ \t\v\n]
Exp (E|e)[+-]?
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
FLOAT_NUM ({DIGIT}+[\.]?{DIGIT}*|{DIGIT}*[\.]?{DIGIT}+)  

%%
{WHITESPACE}+ {}

if {
		return IF;
   }
   
for {
		return FOR;
    }
    
else {
		return ELSE;
	 }
    
while {

			return WHILE;
	  }

do {	
		//return DO;
   }
    
break {

			//return BREAK;
	   }
    
int {
		return INT;
	}
    
char {

			//return CHAR;
	 }
    
float {

			return FLOAT;
	  } 

double {

			//return DOUBLE;
		}

void  {

			return VOID;
	  }	
    
return {	

			return RETURN;
		}
    
switch {	

			//return SWITCH;
		}
    
case {	
		//return CASE;
	 }
    
default {	

			//return DEFAULT;
		}
    
continue {	

			//return CONTINUE;
         }

println {	

			return PRINTLN;
		}
    
[+-] {
		token_name = "ADDOP";
		string s(yytext);

		SymbolInfo* symObj = new SymbolInfo(s,token_name);
		yylval = (YYSTYPE)symObj;

		return ADDOP;
     }
     
[\*/%] {
		token_name = "MULOP";
		string s(yytext);

		SymbolInfo* symObj = new SymbolInfo(s,token_name);
		yylval = (YYSTYPE)symObj;

		return MULOP;
       }
       
\+\+ {
		return INCOP;
	 }

\-\- {
		return DECOP;
	 }
	
= {
		return ASSIGNOP;
  }
  
! {
		return NOT;
  }
  
\( {
		return LPAREN;
   }
   
\) {
		return RPAREN;
   }
   
\{  {	
		symTab->enterScope();
		return LCURL;
   }
   
\}  {
		return RCURL;
   }
   
\[  {
		return LTHIRD;
   }
   
\]  {
		return RTHIRD;
   }
   
, {
		return COMMA;
  }
  
; {
		return SEMICOLON;
  }
	
(<|<=|>|>=|==|!=) {
			token_name = "RELOP";
			
			string s(yytext);

			SymbolInfo* symObj = new SymbolInfo(s,token_name);
			yylval = (YYSTYPE)symObj;

			return RELOP;
		   }
		   
(&&|\|\|) {
		token_name = "LOGICOP";
		
		string s(yytext);

		SymbolInfo* symObj = new SymbolInfo(s,token_name);
		yylval = (YYSTYPE)symObj;

		return LOGICOP;
	   }
       
' {	
	error_count++;
	
	errorFile<<"Error at line no "<<yylineno<<": ";
	errorFile<<"Unterminated character "<<yytext<<endl<<endl;
  }  

    
'' {	
	error_count++;
	
	errorFile<<"Error at line no "<<yylineno<<": ";
	errorFile<<"Empty character constant error "<<yytext<<endl<<endl;
   } 
   
'[^\t\n\v\\']' {	
			token_name = "CONST_CHAR";
			
		  	hold_lexeme += yytext[1];
			
			hold_lexeme.clear();
               }
               
'\\[tvrnafb0'"\\]' {
			token_name = "CONST_CHAR";
			
		  	hold_lexeme += yytext[1];
		  	hold_lexeme += yytext[2];
		  	hold_lexeme = convert(hold_lexeme);
			
			hold_lexeme.clear();
	           }
	          
'([^\n\v']+|\\') {	
			error_count++;
			
			errorFile<<"Error at line no "<<yylineno<<": ";
			errorFile<<"Unterminated character "<<yytext<<endl<<endl;
	         }
	   
'[^\n\v']+' {	
		error_count++;
		
		errorFile<<"Error at line no "<<yylineno<<": ";
		errorFile<<"Multi character constant error "<<yytext<<endl<<endl;
	    }
			    
{IDENTIFIER} {
			token_name = "ID";
			
			string lexeme(yytext);

			SymbolInfo* symObj = symTab->Lookup(lexeme);
			if(symObj == NULL){
				symObj = new SymbolInfo(lexeme,token_name);
			}
			yylval = (YYSTYPE)symObj;

			return ID;
        }				          
	    
\. {	
       error_count++;
       
       errorFile<<"Error at line no "<<yylineno<<": ";
       errorFile<<"Unrecognized character "<<yytext<<endl<<endl;
   }
    
{DIGIT}+ {
		token_name = "CONST_INT";
		
		string lexeme(yytext);

		SymbolInfo* symObj = new SymbolInfo(lexeme,token_name);
		yylval = (YYSTYPE)symObj;

		return CONST_INT;
	 }
	
{FLOAT_NUM}({Exp}{DIGIT}+)? {
				token_name = "CONST_FLOAT";
				
				string lexeme(yytext);

				SymbolInfo* symObj = new SymbolInfo(lexeme,token_name);
				yylval = (YYSTYPE)symObj;

				return CONST_FLOAT;
	     	}
	     		    
{FLOAT_NUM}({Exp}[\.0-9]+) {
				error_count++;
       
       			errorFile<<"Error at line no "<<yylineno<<": ";
				errorFile<<"Ill formed number "<<yytext<<endl<<endl;
			    }		     		    
	     		    
[\.0-9]+({Exp}[\.0-9]*)? {
			        error_count++;
       
					errorFile<<"Error at line no "<<yylineno<<": ";
					errorFile<<"Too many decimal points "<<yytext<<endl<<endl;
			  }
			  
[\.0-9]+([\.0-9a-zA-Z_]+|{Exp})+ {
				        error_count++;
       
						errorFile<<"Error at line no "<<yylineno<<": ";
						errorFile<<"Invalid prefix on ID or Invalid suffix on Number ";
						errorFile<<yytext<<endl<<endl;
				  }
				  
\/\/ {
		save_lexeme();
		BEGIN CMNT_START;
     }
     
<CMNT_START>[^\n](\\\n)? {
				save_lexeme();
		          }
<CMNT_START>\n {	
			token_name = "COMMENT";
			
			hold_lexeme.clear();
			BEGIN INITIAL;
		}
		
<CMNT_START><<EOF>> {
			token_name = "COMMENT";	
			
			hold_lexeme.clear();
			return 0;
		     }
		     
\/\* {
		save_lexeme();
		BEGIN MUL_CMNT;
     }
     
<MUL_CMNT>[^*]+ {
			save_lexeme();
		}
		
<MUL_CMNT>\*+[^/*] {
			save_lexeme();
		    }

<MUL_CMNT>\*+\/ {	
			save_lexeme();
			
			token_name = "COMMENT";
			
			hold_lexeme.clear();
			BEGIN INITIAL;
		 }
		 
<MUL_CMNT><<EOF>> {	
			error_count++;
			
			errorFile<<"Error at line no "<<line_no<<": ";
			errorFile<<"Unterminated Comment "<<hold_lexeme<<endl;
			
			hold_lexeme.clear();
			
			return 0;
		   }
		   
\" {
		save_lexeme();
		BEGIN STR_START;;
   }
   
<STR_START>[^\\"\n] {
			save_lexeme();
		   }
		   
<STR_START>\\["\\\n]?  {
			   save_lexeme();
		        }
			     
<STR_START>\" {	
			token_name = "STRING";
			save_lexeme();
			
			string formatted_str = convert(hold_lexeme);
			
			hold_lexeme.clear();
			BEGIN INITIAL;
	       }
	       
<STR_START>\n {	
			error_count++;
			
			errorFile<<"Error at line no "<<line_no<<": ";
			errorFile<<"Unterminated String "<<hold_lexeme<<endl<<endl;
			
			hold_lexeme.clear();
			BEGIN INITIAL;
	       }
	       
<STR_START><<EOF>> {
			error_count++;
			
			errorFile<<"Error at line no "<<line_no<<": ";
			errorFile<<"Unterminated String "<<hold_lexeme<<endl<<endl;
			
			hold_lexeme.clear();
			
			return 0;
		    }
	
. { 
       error_count++;
       
       errorFile<<"Error at line no "<<yylineno<<": ";
       errorFile<<"Unrecognized character "<<yytext<<endl<<endl;
  }
%%
