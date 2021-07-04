#include <bits/stdc++.h>

using namespace std;

class SymbolInfo
{
    string Name, Type;
    string dataType;
    int arrSize;

public:
    string code;
    string idx;
    string var_symbol;
    string var_scope;
    int addr;

    bool isFunc;
    bool isDefined;
    SymbolInfo* nextInfoObj;
    SymbolInfo* paramlist;

    SymbolInfo() {  
        nextInfoObj = NULL; dataType="NO_TYPE"; 
        arrSize = -1;
        isFunc = false;
        isDefined = false;
        paramlist = NULL;
        
        code = "";
        idx = "";
        var_symbol = "no_address";
        var_scope = "no_scope";
        addr = -1;
    }

    SymbolInfo(string name,string type){
        this->Name = name;
        this->Type = type;
        nextInfoObj = NULL;
        dataType = "NO_TYPE";
        arrSize = -1;
        isFunc = false;
        isDefined = false;
        paramlist = NULL;

        code = "";
        idx = "";
        var_symbol = "no_address";
        var_scope = "no_scope";
        addr = -1;
    }

    void setName(string new_name){
        Name = new_name;
    }
    void setType(string new_type){
        Type = new_type;
    }
    void setDataType(string new_type){
        dataType = new_type;
    }

    void setArrSize(int n){
        arrSize = n;
    }
    
    string getName()
    {
        return Name;
    }

    string getType()
    {
        return Type;
    }

    string getDataType()
    {
        return dataType;
    }

    int getArrSize(){
        return arrSize;
    }

    ~SymbolInfo(){
        while(paramlist!=NULL){
            SymbolInfo* x = paramlist;
            paramlist = paramlist->nextInfoObj;
            delete x;
        }
    }
};

class ScopeTable
{
    int Hsize;
    int id;
    SymbolInfo** table;

public:
    ScopeTable* parentScope;

    ScopeTable()
    {
        id = 0;
        Hsize = 0;
        table = NULL;
        parentScope = NULL;
    }

    ScopeTable(int n)
    {
        id = 0;
        Hsize = n;
        table = new SymbolInfo*[Hsize];
        for(int i=0;i<Hsize;i++)
            table[i]= NULL;
        parentScope = NULL;
    }

    void setID(int new_id)
    {
        id = new_id;
    }

    int getID()
    {
        return id;
    }

    string constructID()
    {
        if(parentScope == NULL)
            return to_string(id);
        return parentScope->constructID() + "."  + to_string(id);
    }

    void setTableSize(int new_size)
    {
        Hsize = new_size;
    }

    int getTableSize()
    {
        return Hsize;
    }

    int hash_func(string key)
    {
        int hash_val = 0;
        for(int i=0;i<key.size();i++)
            hash_val += key[i];
        hash_val %= Hsize;

        return hash_val;
    }

    bool Insert(SymbolInfo* x)
    {
        int idx = hash_func(x->getName());
        int pos = 0;

        SymbolInfo* y = table[idx];
        SymbolInfo* prev_y = NULL;
        while(y!=NULL){
            if(x->getName() == y->getName())
                return false;
            prev_y = y;
            y = y->nextInfoObj;
            pos++;
        }

        if(prev_y == NULL)
            table[idx] = x;
        else
            prev_y->nextInfoObj = x;
        return true;
    }

    SymbolInfo* Lookup(string symbol)
    {
        int idx = hash_func(symbol);
        int pos = 0;

        SymbolInfo* x = table[idx];
        while(x!=NULL){
            if(x->getName() == symbol){
                return x;
            }
            x = x->nextInfoObj;
            pos++;
        }
        return NULL;
    }

    bool Delete(string symbol)
    {
        int idx = hash_func(symbol);
        int pos = 0;

        SymbolInfo* x = table[idx];
        SymbolInfo* prev_x = NULL;
        while(x!=NULL){
            if(x->getName() == symbol){
                if(prev_x==NULL)
                    table[idx] = x->nextInfoObj;
                else prev_x->nextInfoObj = x->nextInfoObj;

                delete x;

                return true;
            }
            prev_x = x;
            x = x->nextInfoObj;
            pos++;
        }
        return false;
    }

    void printTable(ofstream& ofs)
    {
        ofs<<"ScopeTable # "<<constructID()<<endl;
        for(int i=0;i<Hsize;i++){
            SymbolInfo* x = table[i];
            
            if(x!=NULL){
            ofs<<" "<<i<<" --> ";
            while(x!=NULL){
                ofs<<"< ";
                ofs<<x->getName();
                ofs<<" : ";
                ofs<<x->getType();
                ofs<<"> ";

                x = x->nextInfoObj;
            }
            ofs<<endl;
            }
            
        }
    }

    ~ScopeTable()
    {
        for(int i=0;i<Hsize;i++){
            SymbolInfo* x = table[i];
            while(x!=NULL){
                SymbolInfo* y = x;
                x = x->nextInfoObj;
                delete y;
            }
        }

        delete[] table;
    }
};

class SymbolTable
{
    int bucketSize;
    ScopeTable* currScope;
    stack<int> lvlSerial;

public:

    SymbolTable()
    {
        bucketSize = 0;
        currScope = NULL;
    }

    SymbolTable(int n,ScopeTable* gScope)
    {
        bucketSize = n;
        currScope = gScope;
        currScope->setID(1);
    }

    void setBucketSize(int new_size)
    {
        bucketSize = new_size;
    }

    int getBucketSize()
    {
        return bucketSize;
    }

    bool isGlobal(){
        return currScope->parentScope == NULL;
    }

    void enterScope()
    {
        int scope_id;
        if(lvlSerial.empty()){
            scope_id = 1;
        }
        else{
            scope_id = lvlSerial.top() + 1;
            lvlSerial.pop();
        }

        ScopeTable* new_scope = new ScopeTable(bucketSize);
        new_scope->setID(scope_id);
        new_scope->parentScope = currScope;
        currScope = new_scope;
    }

    void exitScope()
    {
        if(currScope == NULL)
            return;

        ScopeTable* exited_scope = currScope;
        currScope = exited_scope->parentScope;

        if(!lvlSerial.empty())
            lvlSerial.pop();
        lvlSerial.push(exited_scope->getID());

        delete exited_scope;
    }

    bool Insert(SymbolInfo* new_entry)
    {
        if(currScope == NULL)
            return false;

        return currScope->Insert(new_entry);
    }

    bool Remove(string symbol)
    {
        if(currScope == NULL)
            return false;
        return currScope->Delete(symbol);
    }

    SymbolInfo* Lookup(string symbol)
    {
        if(currScope == NULL)
            return NULL;

        ScopeTable* temp_scope = currScope;
        while(temp_scope!=NULL){
            SymbolInfo* x = temp_scope->Lookup(symbol);
            if(x!=NULL)
                return x;
            temp_scope = temp_scope->parentScope;
        }
        return NULL;
    }

    void printCurrScope(ofstream& ofs)
    {
        if(currScope == NULL)
            return;
        currScope->printTable(ofs);
    }

    void printAllScope(ofstream& ofs)
    {
        if(currScope == NULL)
            return;
        ScopeTable* temp_scope = currScope;
        while(temp_scope!=NULL){
            temp_scope->printTable(ofs);
            temp_scope = temp_scope->parentScope;
            ofs<<endl;
        }
    }
};

