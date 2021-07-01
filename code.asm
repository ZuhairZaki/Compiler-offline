.MODEL SMALL

.STACK 100H

.DATA

;int a,b,c,i;

t0 DW ?
t1 DW ?
t2 DW ?
t3 DW ?
t4 DW ? 

NEWLINE DB 13, 10, '$'

.CODE   

PRINT_NUMBER PROC 
    
    PUSH BP
    MOV BP,SP
    
    XOR CX, CX
    MOV BX, 10 
           
        MOV AX, WORD PTR[BP+4]
        CMP AX, 0
        JGE GET_DIGITS  
        SUB SP,2
        MOV WORD PTR[BP-2],AX
        MOV AH, 2
        MOV DL, '-'
        INT 21H 
        MOV AX, WORD PTR[BP-2]
        ADD SP,2
        NEG AX
    GET_DIGITS:
        XOR DX, DX
        DIV BX
        PUSH DX
        INC CX
        CMP AX, 0
        JNE GET_DIGITS
        MOV AH, 2
    PRINT_DIGITS:
        POP DX
        ADD DL, 30H
        INT 21H
        LOOP PRINT_DIGITS
        MOV AH, 9
        LEA DX, NEWLINE 
        INT 21H
        POP BP
        RET 2    
    
PRINT_NUMBER ENDP

main PROC
MOV AX,@DATA
MOV DS,AX

PUSH BP
MOV BP,SP

; b = 0

MOV t0, 0

MOV AX, t0
MOV WORD PTR[BP-4], AX

; c = 1

MOV t0, 1

MOV AX, t0
MOV WORD PTR[BP-6], AX

; i = 0

MOV t0, 0

MOV AX, t0
MOV WORD PTR[BP-8], AX

; for(i = 0;i<4;i++)

JMP L4
L5:
; a = 3

MOV t3, 3

MOV AX, t3
MOV WORD PTR[BP-2], AX

; while(a--)

JMP L2
L3:
; b++

ADD WORD PTR[BP-4], 1
MOV AX, WORD PTR[BP-4]
MOV t4, AX

L2:
; a--

SUB WORD PTR[BP-2], 1  
MOV AX, WORD PTR[BP-2]
MOV t3, AX

CMP t3, 0
JNE L3

; i++ 

ADD WORD PTR[BP-8], 1 
MOV AX, WORD PTR[BP-8]
MOV t2, AX

L4:
; i<4

MOV AX, WORD PTR[BP-8]
MOV t1, AX

MOV t2, 4

MOV AX, t1
CMP AX, t2
JL L0
MOV t1, 0
JMP L1
L0:
MOV t1, 1
L1:

CMP t1, 0
JNE L5   


SUB SP,8
PUSH WORD PTR[BP-2] 
CALL PRINT_NUMBER
MOV SP,BP   

SUB SP,8
PUSH WORD PTR[BP-6] 
CALL PRINT_NUMBER
MOV SP,BP  

SUB SP,8
PUSH WORD PTR[BP-8] 
CALL PRINT_NUMBER
MOV SP,BP

END_main:
POP BP
MOV AH,4CH
INT 21H

main ENDP

END MAIN