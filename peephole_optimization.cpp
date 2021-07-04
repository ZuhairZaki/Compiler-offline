#include <bits/stdc++.h>

using namespace std;

ofstream ofs("optimized_Code.asm");

void optimizeCode(ifstream& ifs)
{
    string line;
    string instruction,reg1,reg2;


    while(getline(ifs,line)){
        string tmp,r1,r2;

        if(line.empty()){
            ofs<<line<<endl;
            continue;
        }

        stringstream ss(line);
        ss>>instruction;

        if(instruction[0]==';'){
            ofs<<line<<endl;
            continue;
        }

        if(instruction == "MOV"){
            getline(ss,tmp,',');

            stringstream stemp(tmp);
            stemp>>r1;
            if(r1=="WORD")
                stemp>>r1;

            ss>>r2;
            if(r2=="WORD")
                ss>>r2;

            if(!((r1==reg1&&r2==reg2)||(r1==reg2&&r2==reg1))){
                reg1=r1;
                reg2=r2;

                ofs<<line<<endl;
            }
        }
        else{
            reg1 = "";
            reg2 = "";

            ofs<<line<<endl;
        }
    }
}

int main()
{
    ifstream ifs("code.asm");

    optimizeCode(ifs);

    ifs.close();
    ofs.close();
    return 0;
}
