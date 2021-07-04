.MODEL SMALL

.STACK 100H

.DATA

NEWLINE DB 13, 10, '$'

;int a,b,c[3];
; a WORD PTR[BP-2]
; b WORD PTR[BP-4]
; c WORD PTR[BP-10]

t0 DW ?
t1 DW ?
t2 DW ?

.CODE

; int main()

main PROC
MOV AX,@DATA
MOV DS,AX

PUSH BP
MOV BP,SP

; a = 1*(2+3)%3

MOV t0, 1

; 2+3

MOV t1, 2

MOV t2, 3

MOV AX, t1
ADD AX, t2
MOV t1, AX

MOV AX, t0
IMUL t1
MOV t0, AX

MOV t1, 3

CMP t0, 0
JL L0
MOV DX, 0
JMP L1
L0:
MOV DX, 0FFFFH
L1:
MOV AX, t0
IDIV t1
MOV t0, DX

MOV AX, t0
MOV WORD PTR[BP-2], AX

; b = 1<5

MOV t0, 1

MOV t1, 5

MOV AX, t0
CMP AX, t1
JL L2
MOV t0, 0
JMP L3
L2:
MOV t0, 1
L3:

MOV AX, t0
MOV WORD PTR[BP-4], AX

; c[0] = 2

; 0

MOV t0, 0

MOV t1, 2

MOV SI, t0
SHL SI, 1

MOV AX, t1
MOV WORD PTR[BP-10][SI], AX

MOV t0, AX

; a&&b

MOV AX, WORD PTR[BP-2]
MOV t0, AX

MOV AX, WORD PTR[BP-4]
MOV t1, AX

CMP t0, 0
JNE L4
MOV t0, 0
JMP L5
L4:
CMP t1, 0
JNE L6
MOV t0, 0
JMP L5
L6:
MOV t0, 1
L5:

; if(a&&b)

CMP t0, 0
JE L7
; c[0]++

; 0

MOV t1, 0

MOV SI, t1
SHL SI, 1

MOV AX, WORD PTR[BP-10][SI]

ADD WORD PTR[BP-10][SI], 1
MOV t1, AX

JMP L8
L7:
; c[1] = c[0]

; 1

MOV t1, 1

; 0

MOV t2, 0

MOV SI, t2
SHL SI, 1

MOV AX, WORD PTR[BP-10][SI]
MOV t2, AX

MOV SI, t1
SHL SI, 1

MOV AX, t2
MOV WORD PTR[BP-10][SI], AX

MOV t1, AX

L8:

; printf(a);

SUB SP, 10
PUSH WORD PTR[BP-2]
CALL printf
MOV SP, BP

; printf(b);

SUB SP, 10
PUSH WORD PTR[BP-4]
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
