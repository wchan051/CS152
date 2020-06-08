/* heading.h */
#ifndef _heading_h_
#define _heading_h_

#define YY_NO_UNPUT

#include <iostream>

#include <vector>
#include <stack>
#include <map>


#include <sstream>
#include <fstream>
#include <stdio.h>
#include <string>

using namespace std;

enum Type {INT,INT_ARR,FUNC};

struct Variable{ 
    string *place;
    string *value;
    string *offset;
    Type type;
    int length;
    string *index;
};

struct Loop{
    string *begin;
    string *parent;
    string *end;
};

struct Terminal{
   stringstream *code;
   string *place;
   string *value;
   string *offset;
   string *op;
   string *begin;
   string *parent;
   string *end;
   Type type;
   int length;
   string *index;
   vector<string> *ids;
   vector<Variable> *variables; 
};

#endif
