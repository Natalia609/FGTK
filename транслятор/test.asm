mov r0, 81
mov [0], r0
mov r1, [0]
mov [1], r1
mov r2, 0
mov [2], r2
mov r3, 1073741824
mov [3], r3
L0:
mov r4, [3]
mov r5, [1]
jle r4, r5, L1
mov r6, [3]
mov r7, 4
mov r8, r6
div r8, r7
mov [3], r8
jmp L0
L1:
L2:
mov r9, [3]
mov r10, 0
je r9, r10, L3
mov r11, [1]
mov r12, [2]
mov r13, [3]
mov r14, r12
add r14, r13
jl r11, r14, L4
mov r15, [1]
mov r16, [2]
mov r17, [3]
mov r18, r16
add r18, r17
mov r19, r15
sub r19, r18
mov [1], r19
mov r20, [2]
mov r21, [3]
mov r22, 2
mov r23, r21
mul r23, r22
mov r24, r20
add r24, r23
mov [2], r24
mov r25, [2]
print r25
L4:
mov r26, [2]
mov r27, 2
mov r28, r26
div r28, r27
mov [2], r28
mov r29, [3]
mov r30, 4
mov r31, r29
div r31, r30
mov [3], r31
mov r32, [2]
print r32
jmp L2
L3:
mov r33, [2]
print r33
halt
