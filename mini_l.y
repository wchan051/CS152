%{
#include "heading.h"
int yyerror(const char* s);
extern int currLine;
extern int currPos;
int yylex(void);
stringstream *all_code;
FILE * intfile;
string code_gen(string *res, string op, string *value_1, string *value_2);
string toString(char* s);
string toString(int s);
string go_to(string *s);
void expression_code( Terminal &D1,  Terminal D2, Terminal D3, string op);
bool success = true;
bool no_main_function = false;
void push_map(string name, Variable vari);
bool map_check(string name);
void map_check_declaration(string name);
string label_declaration(string *s);
string temp_declaration(string *s);
map<string,Variable> var_map;
string *newTemp();
string *newLabel();
stack<Loop> loop_stack;
int temp = 0;
int temp_l = 0;

%}

%union{
    int       val;
    char     idval[256];

    struct {
        stringstream *code;
    }NonTerminal;

    struct Terminal Terminal;
}

%error-verbose

%token	FUNCTION BEGINPARAMS ENDPARAMS BEGINLOCALS ENDLOCALS BEGINBODY ENDBODY
%token  INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP 
%token  CONTINUE READ WRITE TRUE FALSE RETURN 
%token  SEMICOLON COLON COMMA LPAREN RPAREN LSQUARE RSQUARE EQUAL
%token <val> NUMBER
%token <idval> IDENT
%left MULT DIV MOD 
%left ADD SUB 
%left LT LTE GT GTE EQ NEQ
%right NOT
%left AND OR
%right ASSIGN
%type <NonTerminal> program
%type <Terminal> dec_loop statement_loop funct funct_2 dec dec_2 dec_3 statement statement_1 statement_2  statement_2_2 statement_3   statement_4   statement_5   statement_5_2  statement_6   statement_6_2  bool_exp      bool_exp2     relation_and_exp   relation_and_exp2  relation_exp   relation_exp_s comp          expression    expression_2  mult_expr     mult_expr_2   term          term_2        term_3        term_3_2       term_3_3       var           var_2 		b_loop 		b_func


%%

program:    funct program {
                $$.code = $1.code;
                *($$.code) << $2.code->str();
                if(!no_main_function) {
                    yyerror("ERROR: main function not defined.");
                }

                all_code = $$.code;
              } 
            | {
                $$.code = new stringstream();
              }
            ;

funct:   FUNCTION b_func SEMICOLON BEGINPARAMS dec_loop ENDPARAMS BEGINLOCALS dec_loop ENDLOCALS BEGINBODY statement SEMICOLON funct_2 {
                $$.code = new stringstream(); 
                string tmp = *$2.place;
                if( tmp.compare("main") == 0) {
                    no_main_function = true;
                }
                *($$.code)  << "func " << tmp << "\n" << $5.code->str() << $8.code->str();
                for(int i = 0; i < $5.variables->size(); ++i) {
                    if((*$5.variables)[i].type == INT_ARR) {
                        yyerror("Error: cannot pass arrays to function.");
                    }
                    else if((*$5.variables)[i].type == INT) {
                        *($$.code) << "= " << *((*$5.variables)[i].place) << ", " << "$"<< toString(i) << "\n";
                    }else{
                        yyerror("Error: invalid type");
                    }
                }
                 *($$.code) << $11.code->str() << $13.code->str();
            }
            ;
b_func: IDENT {
            string tmp = $1;
            Variable myf = Variable();
            myf.type = FUNC;
            if(!map_check(tmp)) {
                push_map(tmp,myf); 
            }
            $$.place = new string();
            *$$.place = tmp;
        };

funct_2: statement SEMICOLON funct_2 {
                $$.code = $1.code;
                *($$.code) << $3.code->str();
              } 
            | ENDBODY {
                $$.code = new stringstream();
                *($$.code) << "endfunc\n";
              }
            ;

dec_loop:  dec SEMICOLON dec_loop {
                $$.code = $1.code;
                $$.variables = $1.variables;
                for( int i = 0; i < $3.variables->size(); ++i) {
                    $$.variables->push_back((*$3.variables)[i]);
                }
                *($$.code) << $3.code->str();
                } 
            | {
                $$.code = new stringstream();
                $$.variables = new vector<Variable>();
              }
            ;

statement_loop:  statement SEMICOLON statement_loop {
                $$.code = $1.code;
                *($$.code) << $3.code->str();
              } 
            | {
                $$.code = new stringstream();
              }
            ;

dec:    IDENT dec_2 {
                    $$.code = $2.code;
                    $$.type = $2.type;
                    $$.length = $2.length;

                    $$.variables = $2.variables;
                    Variable vari = Variable();
                    vari.length = $2.length;
                    vari.type = $2.type;
                    vari.place = new string();
                    *vari.place = $1;
                    $$.variables->push_back(vari);
                    if($2.type == INT_ARR) {
                        if($2.length <= 0) {
                            yyerror("ERROR: invalid array size <= 0");
                        }
                        *($$.code) << ".[] " << $1 << ", " << $2.length << "\n";
                        string s = $1;
                        if(!map_check(s)) {
                            push_map(s,vari);
                        }
                        else{
                            string tmp = "Error: Symbol \"" + s + "\" is multiply-defined";
                            yyerror(tmp.c_str());
                        }
                    }

                    else if($2.type == INT) {
                        *($$.code) << ". " << $1 << "\n";
                        string s = $1;
                        if(!map_check(s)) {
                            push_map(s,vari);
                        }
                        else{
                            string tmp = "Error: Symbol \"" + s + "\" is multiply-defined";
                            yyerror(tmp.c_str());
                        }
                    }else{
                            yyerror("ERROR: invalid type");
                    }
                }
                ;

dec_2:  COMMA IDENT dec_2 {
                    $$.code = $3.code;
                    $$.type = $3.type;
                    $$.length = $3.length;
                    $$.variables = $3.variables;
                    Variable vari = Variable();
                    vari.length = $3.length;
                    vari.type = $3.type;
                    vari.place = new string();
                    *vari.place = $2;
                    $$.variables->push_back(vari);
                    if($3.type == INT_ARR) {
                        *($$.code) << ".[] " << $2 << ", " << $3.length << "\n";
                        string s = $2;
                        if(!map_check(s)) {
                            push_map(s,vari);
                        }
                        else{
                            string tmp = "Error: Symbol \"" + s + "\" is multiply-defined";
                            yyerror(tmp.c_str());
                        }
                    }
                    else if($3.type == INT) {
                        *($$.code) << ". " << $2 << "\n";
                        string s = $2;
                        if(!map_check(s)) {
                            push_map(s,vari);
                        }
                        else{
                            string tmp = "Error: Symbol \"" + s + "\" is multiply-defined";
                            yyerror(tmp.c_str());
                        }
                    }else{
                    }
                }
                | COLON dec_3 INTEGER {
                    $$.code = $2.code;
                    $$.type = $2.type;
                    $$.length = $2.length;
                    $$.variables = $2.variables;
                }
                ;

dec_3:  ARRAY LSQUARE NUMBER RSQUARE OF{
                    $$.code = new stringstream();
                    $$.variables = new vector<Variable>();
                    $$.type = INT_ARR;
                    $$.length = $3;
                }
                | {
                    $$.code = new stringstream();
                    $$.variables = new vector<Variable>();
                    $$.type = INT;
                    $$.length = 0;
                  }
                ;

statement:      statement_1 {
                    $$.code = $1.code;
                }
                | statement_2 {
                    $$.code = $1.code;
                }
                | statement_3 {
                    $$.code = $1.code;
                }
                | statement_4 {
                    $$.code = $1.code;
                }
                | statement_5 {
                    $$.code = $1.code;
                }
                | statement_6 {
                    $$.code = $1.code;
                }
                | CONTINUE{
                    $$.code = new stringstream();
                    if(loop_stack.size() <= 0) {
                        yyerror("ERROR: continue statement not within a loop");
                    }
                    else{
                        Loop l = loop_stack.top();
                        *($$.code) << ":= " << *l.parent << "\n";
                    }
                }
                | RETURN expression{
                    $$.code = $2.code;
                    $$.place = $2.place;
                    *($$.code) << "ret " << *$$.place << "\n";
                }

statement_1:    var ASSIGN expression{
                    $$.code = $1.code;
                    *($$.code) << $3.code->str();
                    if($1.type == INT && $3.type == INT) {
                       *($$.code) << "= " << *$1.place << ", " << *$3.place << "\n";
                    }
                    else if($1.type == INT && $3.type == INT_ARR) {
                        *($$.code) << code_gen($1.place, "=[]", $3.place, $3.index);
                    }
                    else if($1.type == INT_ARR && $3.type == INT && $1.value != NULL) {
                        *($$.code) << code_gen($1.value, "[]=", $1.index, $3.place);
                    }
                    else if($1.type == INT_ARR && $3.type == INT_ARR) {
                        string *tmp = newTemp();
                        *($$.code) << temp_declaration(tmp) << code_gen(tmp, "=[]", $3.place, $3.index);
                        *($$.code) << code_gen($1.value, "[]=", $1.index, tmp);
                    }
                    else {
                        yyerror("Error: expression is null.");
                    }
                }
                ;

statement_2:    IF bool_exp THEN statement_loop statement_2_2 ENDIF {
                    $$.code = new stringstream();
                    $$.begin = newLabel();
                    $$.end = newLabel();
                    *($$.code) << $2.code->str() << "?:= " << *$$.begin << ", " <<  *$2.place << "\n";
                    if($5.begin != NULL) {                       
                        *($$.code) << go_to($5.begin); 
                        *($$.code) << label_declaration($$.begin)  << $4.code->str() << go_to($$.end);
                        *($$.code) << label_declaration($5.begin) << $5.code->str();
                    }
                    else {
                        *($$.code) << go_to($$.end)<< label_declaration($$.begin)  << $4.code->str();
                    }
                    *($$.code) << label_declaration($$.end);
                }
                ;

statement_2_2:   {
                    $$.code = new stringstream();
                    $$.begin = NULL;
                }
                | ELSE statement_loop {
                    $$.code = $2.code;
                    $$.begin = newLabel();
                }
                ;

statement_3:    WHILE bool_exp b_loop BEGINLOOP statement_loop ENDLOOP{
                    $$.code = new stringstream();
                    $$.begin = $3.begin;
                    $$.parent = $3.parent;
                    $$.end = $3.end;
                    *($$.code) << label_declaration($$.parent) << $2.code->str() << "?:= " << *$$.begin << ", " << *$2.place << "\n" 
                    << go_to($$.end) << label_declaration($$.begin) << $5.code->str() << go_to($$.parent) << label_declaration($$.end);
                    loop_stack.pop();

                }
                ;

b_loop:         {
                    $$.code = new stringstream();
                    $$.begin = newLabel();
                    $$.parent = newLabel();
                    $$.end = newLabel();
                    Loop l = Loop();
                    l.parent = $$.parent;
                    l.begin = $$.begin;
                    l.end = $$.end;
                    loop_stack.push(l);
                };

statement_4:    DO b_loop BEGINLOOP statement_loop ENDLOOP WHILE bool_exp{
                    $$.code = new stringstream();
                    $$.begin = $2.begin;
                    $$.parent = $2.parent;
                    $$.end = $2.end;
                    *($$.code) << label_declaration($$.begin) << $4.code->str() << label_declaration($$.parent) << $7.code->str() << "?:= " << *$$.begin << ", " << *$7.place << "\n" << label_declaration($$.end);
                    loop_stack.pop();
                }
                ;

statement_5:    READ var statement_5_2{
                    $$.code = $2.code;
                    if($2.type == INT) {
                       *($$.code) << ".< " << *$2.place << "\n"; 
                    }
                    else{
                       *($$.code) << ".[]< " << *$2.place << ", " << $2.index << "\n"; 
                    }
                    *($$.code) << $3.code->str();
                }
                ;

statement_5_2:   COMMA var statement_5_2 {
                    $$.code = $2.code;
                    if($2.type == INT) {
                       *($$.code) << ".< " << *$2.place << "\n"; 
                    }
                    else{
                       *($$.code) << ".[]< " << *$2.place << ", " << $2.index << "\n"; 
                    }
                    *($$.code) << $3.code->str();
                }
                | {
                    $$.code = new stringstream();
                  }
                ;

statement_6:    WRITE var statement_6_2{
                    $$.code = $2.code;
                    if($2.type == INT) {
                       *($$.code) << ".> " << *$2.place << "\n"; 
                    }
                    else{
                       *($$.code) << ".[]> " << *$2.value << ", " << *$2.index << "\n"; 
                    }
                    *($$.code) << $3.code->str();
                  }
                ;

statement_6_2:   COMMA var statement_6_2{
                    $$.code = $2.code;
                    if($2.type == INT) {
                       *($$.code) << ".> " << *$2.place << "\n"; 
                    }
                    else{
                       *($$.code) << ".[]> " << *$2.value << ", " << *$2.index << "\n"; 
                    }
                    *($$.code) << $3.code->str();
                  }
                |{
                    $$.code = new stringstream();
                 }
                ;

bool_exp:       relation_and_exp bool_exp2{
                    $$.code = $1.code;
                    *($$.code) << $2.code->str();
                    if($2.op != NULL && $2.place != NULL)
                    {                        
                        $$.place = newTemp();
                       *($$.code) << temp_declaration($$.place) << code_gen($$.place, *$2.op, $1.place, $2.place);
                    }
                    else{
                        $$.place = $1.place;
                        $$.op = $1.op;
                    }
                }
                ;

bool_exp2:      OR relation_and_exp bool_exp2{
                    expression_code($$,$2,$3,"||");


                }
                |{
                    $$.code = new stringstream();
                    $$.op = NULL;
                 }
                ; 

relation_and_exp:    relation_exp relation_and_exp2{
                    $$.code = $1.code;
                    *($$.code) << $2.code->str();
                    if($2.op != NULL && $2.place != NULL)
                    {                        
                        $$.place = newTemp();
                       *($$.code) << temp_declaration($$.place) << code_gen($$.place, *$2.op, $1.place, $2.place);
                    }
                    else{
                        $$.place = $1.place;
                        $$.op = $1.op;
                    }
                }
                ;

relation_and_exp2:   AND relation_exp relation_and_exp2{
                    expression_code($$,$2,$3,"&&");

                }
                |{
                    $$.code = new stringstream();
                    $$.op = NULL;
                 }
                ;

relation_exp:   relation_exp_s{
                    $$.code = $1.code;
                    $$.place = $1.place; 
                }
                | NOT relation_exp_s{
                    $$.code = $2.code;
                    $$.place = newTemp();
                    *($$.code) << temp_declaration($$.place) << code_gen($$.place, "!", $2.place, NULL);
                }
                ;

relation_exp_s: expression comp expression{

                    $$.code = $1.code;
                    *($$.code) << $2.code->str();
                    *($$.code) << $3.code->str();
                    $$.place = newTemp();
                    *($$.code)<< temp_declaration($$.place) << code_gen($$.place, *$2.op, $1.place, $3.place);
                }
                | TRUE{                    

                    $$.code = new stringstream();
                    $$.place = new string();
                    *$$.place = "1";
                    }
                | FALSE{

                    $$.code = new stringstream();
                    $$.place = new string();
                    *$$.place = "0";
                  }
                | LPAREN bool_exp RPAREN{
                    $$.code = $2.code;
                    $$.place = $2.place;
                }
                ;

comp:           EQ{
                    $$.code = new stringstream();
                    $$.op = new string();
                    *$$.op = "==";
                  }
                | NEQ{
                    $$.code = new stringstream();
                    $$.op = new string();
                    *$$.op = "!=";
                  }
                | LT{
                    $$.code = new stringstream();
                    $$.op = new string();
                    *$$.op = "<";
                  }
                | GT{
                    $$.code = new stringstream();
                    $$.op = new string();
                    *$$.op = ">";
                  }
                | LTE{
                    $$.code = new stringstream();
                    $$.op = new string();
                    *$$.op = "<=";
                  }
                | GTE{
                    $$.code = new stringstream();
                    $$.op = new string();
                    *$$.op = ">=";
                  }
                ;

expression:     mult_expr expression_2{
                    $$.code = $1.code;
                    *($$.code) << $2.code->str();
                    if($2.op != NULL && $2.place != NULL)
                    {                        
                        $$.place = newTemp();
                       *($$.code)<< temp_declaration($$.place) << code_gen($$.place, *$2.op, $1.place, $2.place);
                    }
                    else{
                        $$.place = $1.place;
                        $$.op = $1.op;
                    }
                    $$.type = INT;
                  }
                ;

expression_2:   ADD mult_expr expression_2 {
                    expression_code($$,$2,$3,"+");

                  }
                | SUB mult_expr expression_2{
                    expression_code($$,$2,$3,"-");
                  }
                | {
                    $$.code = new stringstream();
                    $$.op = NULL;
                  }
                ;

mult_expr:      term mult_expr_2{
                    $$.code = $1.code;
                    *($$.code) << $2.code->str();
                    if($2.op != NULL && $2.place != NULL)
                    {                        
                        $$.place = newTemp();
                       *($$.code)<< temp_declaration($$.place)<< code_gen($$.place, *$2.op, $1.place, $2.place);
                    }
                    else{
                        $$.place = $1.place;
                        $$.op = $1.op;
                    }
                  }
                ;


mult_expr_2:    MULT term mult_expr_2{
                    expression_code($$,$2,$3,"*");

                  }
                | DIV term mult_expr_2{
                    expression_code($$,$2,$3,"/");
                  }
                | MOD term mult_expr_2{
                    expression_code($$,$2,$3,"%");
                  }
                |{
                    $$.code = new stringstream();
                    $$.op = NULL;
                 }
                ;

term:           SUB term_2{
                    $$.code = $2.code;
                    $$.place = newTemp();
                    string tmp = "-1";
                    *($$.code)<< temp_declaration($$.place) << code_gen($$.place, "*",$2.place, &tmp );
                  }
                | term_2{
                    $$.code = $1.code;
                    $$.place = $1.place;
                  }
                | term_3{
                    $$.code = $1.code;
                    $$.place = $1.place;
                  }
                ;

term_2:         var{
                    $$.code = $1.code;
                    $$.place= $1.place;
                    $$.index = $1.index;
                  }
                | NUMBER{
                    $$.code = new stringstream();
                    $$.place = new string();
                    *$$.place = toString($1);
                  }
                | LPAREN expression RPAREN{
                    $$.code = $2.code;
                    $$.place = $2.place;
                  }
                ;

term_3:         IDENT LPAREN term_3_2 RPAREN{
                    $$.code = $3.code;
                    $$.place = newTemp();
                    *($$.code) << temp_declaration($$.place)<< "call " << $1 << ", " << *$$.place << "\n";
                    string tmp = $1;
                    map_check_declaration(tmp);
                }
                ;

term_3_2:        expression term_3_3{
                    $$.code = $1.code;
                    *($$.code) << $2.code->str();
                    *($$.code) << "param " << *$1.place << "\n";
                } 
                | {
                    $$.code = new stringstream(); 
                  }
                ;
term_3_3:        COMMA term_3_2{
                    $$.code = $2.code;
                } 
                | {
                    $$.code = new stringstream();
                  }

var:            IDENT var_2{
                    $$.code = $2.code;
                    $$.type = $2.type;
                    string tmp = $1;
                    map_check_declaration(tmp);
                    if(map_check(tmp) && var_map[tmp].type != $2.type) {
                        if($2.type == INT_ARR) {
                            string output ="Error: used variable \"" + tmp + "\" is not an array.";
                            yyerror(output.c_str());
                        }
                        else if($2.type == INT) {
                            string output ="Error: used array variable \"" + tmp + "\" is missing a specified index.";
                            yyerror(output.c_str());
                        }
                    }

                    if($2.index == NULL) {
                        $$.place = new string();
                        *$$.place = $1;
                    }
                    else{
                        $$.index = $2.index;
                        $$.place = newTemp();
                        string* tmp = new string();
                        *tmp = $1;
                        *($$.code) << temp_declaration($$.place) << code_gen($$.place, "=[]", tmp,$2.index);
                        $$.value = new string();
                        *$$.value = $1;
                    }
                }
                ;

var_2:          LSQUARE  expression RSQUARE {
                    $$.code = $2.code;
                    $$.place = NULL;
                    $$.index = $2.place;
                    $$.type = INT_ARR;
                }
                |{
                    $$.code = new stringstream();
                    $$.index = NULL;
                    $$.place = NULL;
                    $$.type = INT;
                 }
                ;
            
%%

string toString(char* s) {
    ostringstream c;
    c << s;
    return c.str();
}

string toString(int s) {
    ostringstream c;
    c << s;
    return c.str();
}

string go_to(string *s) {
    return ":= "+ *s + "\n"; 
}

string code_gen(string *res, string op, string *value_1, string *value_2) {
    if(op == "!") {
        return op + " " + *res + ", " + *value_1 + "\n";
    }
    else {
        return op + " " + *res + ", " + *value_1 + ", "+ *value_2 +"\n";
    }
}
 
 void expression_code( Terminal &D1, Terminal D2, Terminal D3, string op) {
    D1.code = D2.code;
    *(D1.code) << D3.code->str();
    if(D3.op == NULL) {
        D1.place = D2.place;
        D1.op = new string();
        *D1.op = op;
    }
    else {
        D1.place = newTemp();
        D1.op = new string();
        *D1.op = op;

        *(D1.code) << temp_declaration(D1.place)<< code_gen(D1.place , *D3.op, D2.place, D3.place);
    } 
}

void push_map(string name, Variable vari) {
    if(var_map.find(name) == var_map.end()) {
        var_map[name] = vari;
    }
    else {
        string tmp = "ERROR: " + name + " already exists";
        yyerror(tmp.c_str());
    }
}

bool map_check(string name) {
    if(var_map.find(name) == var_map.end()) {
        return false;
    }
    return true;
}

void map_check_declaration(string name) {
    if(!map_check(name)) {
        string tmp = "ERROR: \"" + name + "\" does not exist";
        yyerror(tmp.c_str());
    }
}

string label_declaration(string *s) {
    return ": " +*s + "\n"; 
}

string temp_declaration(string *s) {
    return ". " +*s + "\n"; 
}

string *newTemp() {
    string *t = new string();
    ostringstream tempostring;
    tempostring << temp;
    *t = "__temp__"+ tempostring.str();
    temp++;
    return t;
}

string *newLabel() {
    string *t = new string();
    ostringstream tempostring;
    tempostring << temp_l;
    *t = "__label__"+ tempostring.str();
    temp_l++;
    return t;
}

int yyerror(const char *s) {
   success = false;
   printf("** Line %d, position %d: %s\n", currLine, currPos, s);
   return -1;
}

int main(int argc, char **argv) {

    if((argc > 1) && (intfile = fopen(argv[1],"r")) == NULL) {
        printf("syntax: %s filename\n", argv[0]);
        return 1;
    }

    yyparse();

    if(success) {
        ofstream file;
        file.open("mil_code.mil");
        file << all_code->str();
        file.close();
    }
    else {
        cout << "***Errors exist, fix to compile code***" << endl;
    }
	
    return 0;
}
