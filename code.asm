.MODEL SMALL

.STACK 100H

.DATA

NEWLINE DB 13, 10, '$'

;int fib[10];
var0 DW 10 DUP (?)

;int x,i;
; x WORD PTR[BP-2]
; i WORD PTR[BP-4]

;int y;
; y WORD PTR[BP-6]

t0 DW ?
t1 DW ?
t2 DW ?
t3 DW ?

.CODE

; int fibonacci(int n)

fibonacci PROC
PUSH BP
MOV BP,SP

; fib[n-1]==0

MOV SI, t0
SHL SI, 1

MOV AX, var0[SI]
MOV t0, AX

MOV t1, 0

MOV AX, t0
CMP AX, t1
JE L0
MOV t0, 0
JMP L1
L0:
MOV t0, 1
L1:

; if(fib[n-1]==0)

CMP t0, 0
JE L2
MOV SI, t1
SHL SI, 1

MOV AX, t2
MOV var0[SI], AX

L2:

; fib[n-2]==0

MOV SI, t0
SHL SI, 1

MOV AX, var0[SI]
MOV t0, AX

MOV t1, 0

MOV AX, t0
CMP AX, t1
JE L3
MOV t0, 0
JMP L4
L3:
MOV t0, 1
L4:

; if(fib[n-2]==0)

CMP t0, 0
JE L5
MOV SI, t1
SHL SI, 1

MOV AX, t2
MOV var0[SI], AX

L5:

MOV SI, t0
SHL SI, 1

MOV AX, t1
MOV var0[SI], AX

; fib[n]

MOV SI, t0
SHL SI, 1

MOV AX, var0[SI]
MOV t0, AX

; return fib[n];

MOV AX, t0
JMP END_fibonacci

END_fibonacci:
POP BP
RET 2

fibonacci ENDP

; int main()

main PROC
MOV AX,@DATA
MOV DS,AX

PUSH BP
MOV BP,SP

MOV SI, t0
SHL SI, 1

MOV AX, t1
MOV var0[SI], AX

MOV SI, t0
SHL SI, 1

MOV AX, t1
MOV var0[SI], AX

; i = 2

MOV t0, 2

MOV AX, t0
MOV WORD PTR[BP-4], AX

; for(i = 2;i<10;i++)

JMP L8
L9:
MOV SI, t2
SHL SI, 1

MOV AX, t3
MOV var0[SI], AX

; i++

MOV AX, WORD PTR[BP-4]

ADD WORD PTR[BP-4], 1
MOV t1, AX

L8:
; i<10

MOV AX, WORD PTR[BP-4]
MOV t0, AX

MOV t1, 10

MOV AX, t0
CMP AX, t1
JL L6
MOV t0, 0
JMP L7
L6:
MOV t0, 1
L7:

CMP t0, 0
JNE L9

; x = 8

MOV t-1, 8

MOV AX, t-1
MOV WORD PTR[BP-2], AX

; x = fibonacci(x)

MOV AX, WORD PTR[BP-2]
MOV t-2, AX

; fibonacci(x)

SUB SP, 4
PUSH t-2
CALL fibonacci
MOV SP, BP
MOV t-2, AX

MOV AX, t-2
MOV WORD PTR[BP-2], AX

; i = 0

MOV t-3, 0

MOV AX, t-3
MOV WORD PTR[BP-4], AX

; for(i = 0;i<10;i++)

JMP L12
L13:
; y = fib[i]

MOV SI, t-1
SHL SI, 1

MOV AX, var0[SI]
MOV t-1, AX

MOV AX, t-1
MOV WORD PTR[BP-6], AX

; printf(y);

SUB SP, 6
PUSH WORD PTR[BP-6]
CALL printf
MOV SP, BP

; i++

MOV AX, WORD PTR[BP-4]

ADD WORD PTR[BP-4], 1
MOV t-2, AX

L12:
; i<10

MOV AX, WORD PTR[BP-4]
MOV t-3, AX

MOV t-2, 10

MOV AX, t-3
CMP AX, t-2
JL L10
MOV t-3, 0
JMP L11
L10:
MOV t-3, 1
L11:

CMP t-3, 0
JNE L13

; printf(x);

SUB SP, 4
PUSH WORD PTR[BP-2]
CALL printf
MOV SP, BP

END_main:
POP BP
MOV AH,4CH
INT 21H

main ENDP

; printf function

printf PROC

PUSH BP
MOV BP, SP

XOR CX, CX
MOV BX, 10

MOV AX, WORD PTR[BP+4]
CMP AX, 0
JGE GET_DIGITS
PUSH AX
MOV AH, 2
MOV DL, '-'
INT 21H
POP AX
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

printf ENDP

END MAIN