.486 ; 386 Processor Instruction Set

.model flat,stdcall ; Flat memory model and stdcall method

option casemap:none ; Case Sensitive

;Libaries and Include files used in this project

; Windows.inc defines alias (such as NULL and STD_OUTPUT_HANDLE in this code
include \masm32\include\windows.inc 

; Functions that we use (GetStdHandle, WriteConsole, and ExitProcess)
; Listing of all available functions in kernel32.lib
include \masm32\include\kernel32.inc 
; Actuall byte code available of the functions
includelib \masm32\lib\kernel32.lib  

;6 registers, 0x00 - 0x06", 0ah,
;pushc - 0x00, {DWORD}
;pushr - 0x01, {0x00-0x05}
;popv  - 0x02 {0x00-0x05} pop data on stack to register
;add   - 0x04 {0x00-0x05}, {0x00-0x05} - Adds two registers, stores result in stack
;sub   - 0x05 {0x00-0x05}, {0x00-0x05} - Subtracts 2 operand from 1 operand, result in stack
;jnz   - 0x06 {DWORD} - Pops value from stack and jumps VP by operand if not zero
;exit  - 0x09 exits vm, coppies register 0 over to eax          
;popmb - 0x0A {0x00-0x05} pops data from stacck as a byte pointer
;dec   - 0x0B {0x00-0x05} decrements 1 from register
;r5 is considered the stack pointer

.data
; Labels that with the allocated data (in this case Hello World!...) that are aliases to memory.
output_intro db "This application demonstrates obfuscation by virtualization.", 0h
output_author db "Written by Jeremy Wildsmith. Hosted at the following GitHub URL: https://github.com/JeremyWildsmith/StackLang", 0ah, 0h

output_incorrect_password db "Incorrect password, sorry! Persistence is key.", 0h

output_correct_password db "Congrats, you provided the correct password!", 0ah, 0h

output_provide_password db "You must provide a password to be checked against in the command line arguments.", 0ah, 0h

;argument, pointer to string
vm_computeCorrectPassword db 02h, 02h ;pop address of string to register 2 
							 
							 ;Initialize r4 to 0 - dont need to
							 
							 ;push constant 4
						  db 00h, 00h, 00h, 00h, 05h ;pushc 4
						  db 02h, 01h ; popv r1
						   
						  ;Loop, instruction index 9
						  db 0Bh, 01h ; dec r1
						  db 04h, 01h, 02h ; Add r1, r2 -> stack
						  db 0Ah, 03h ; popmb r3
							 
						  db 04h, 04h, 03h ; Add r3, r4
						  db 02h, 04h ; popv r4
							 
						  db 01h, 01h ; pushr r1 (index) to stack
					
						  db 06h, 0ffh, 0ffh, 0ffh, 0f2h ; jnz, go back 14 bytes
							 
							 ;Compare computed hash to pre-computed valid hash.
						  db 00h, 00h, 00h, 02h, 014h ; pushc 0x1b4
						  db 02h, 00h ; popv r0
							 
						  db 05h, 04h, 00h ; sub r4, r0
						  db 02h, 00h ; popv r0
						  db 09h; exit, copy r0 to eax, return to invoker
							 

.code 

helloString db "hello", 0h

vm_pushc:
	push ebp
	mov ebp, esp
	
	;Add to VP by instruction size
	mov eax, [ebx]
	inc eax
	mov ecx, dword ptr [eax] ;Put operand in ecx
	bswap ecx ; Swap endianess
	add eax, 4
	mov [ebx], eax
	
	mov eax, [ebx + 4 * 6] ;Access r5 /stack pointer
	sub eax, 4
	mov [eax], ecx
	mov [ebx + 4 * 6], eax ; Increment stack pointer
	
	xor eax, eax
	pop ebp
	ret

vm_pushr:
	push ebp
	mov ebp, esp
	
	;Add to VP by instruction size
	mov ecx, [ebx]
	inc ecx
	xor eax, eax ;Clear eax register
	mov al, byte ptr [ecx] ;Put operand in ecx
	inc ecx
	mov [ebx], ecx ; Update VP
	
	inc eax ;r0 starts at offset 1
	mov ecx, 4
	mul ecx
	
	add eax, ebx ;Calculate offset to register
	mov ecx, dword ptr [eax]
	
	;push register value to the stack
	mov eax, [ebx + 4 * 6] ;Access r5 /stack pointer
	sub eax, 4
	mov [eax], ecx
	mov [ebx + 4 * 6], eax ; Increment stack pointer
	
	xor eax, eax
	pop ebp
	ret

vm_popv:
	push ebp
	mov ebp, esp
	
	;Add to VP by instruction size
	mov ecx, [ebx]
	inc ecx
	xor eax, eax ;Clear eax register
	mov al, byte ptr [ecx] ;Put operand in ecx
	inc ecx
	mov [ebx], ecx ; Update VP
	
	inc eax ;r0 starts at offset 1
	mov ecx, 4
	mul ecx
	
	add eax, ebx ;Calculate offset to register
	
	;Pop value from stack into register
	mov ecx, [ebx + 4 * 6] ;Access r5 /stack pointer
	mov edx, dword ptr [ecx] ;Get value at stack pointer
	mov dword ptr [eax], edx ;put value into register
	add ecx, 4				 
	mov [ebx + 4 * 6], ecx ; Increment stack pointer

	xor eax, eax
	pop ebp
	ret
	
	
vm_add:
	push ebp
	mov ebp, esp
	
	;Add to VP by instruction size
	mov ecx, [ebx]
	inc ecx
	xor eax, eax ;Clear eax register
	mov al, byte ptr [ecx] ;Put operand in al
	inc ecx
	xor edx, edx
	mov dl, byte ptr [ecx] ;Put operand in dl
	inc ecx
	mov [ebx], ecx ; Update VP
	
	inc eax ;r0 starts at offset 1
	inc edx ; ^
	mov ecx, 4
	
	push edx
	mul ecx
	pop edx
	
	xchg eax, edx
	
	push edx
	mul ecx
	pop edx
	
	add eax, ebx ;Calculate offset to register
	add edx, ebx ; ^
	
	;At this point, EDX contains address of operand 0, and EAX contains address of operand 1
	mov edx, dword ptr [edx]
	add edx, dword ptr [eax]
	
	;Push result to stack
	mov eax, [ebx + 4 * 6] ;Access r5 /stack pointer
	sub eax, 4
	mov [eax], edx
	mov [ebx + 4 * 6], eax ; Increment stack pointer
	
	xor eax, eax
	pop ebp
	ret
	
vm_sub:
	push ebp
	mov ebp, esp
	
	;Add to VP by instruction size
	mov ecx, [ebx]
	inc ecx
	xor eax, eax ;Clear eax register
	mov al, byte ptr [ecx] ;Put operand in al
	inc ecx
	xor edx, edx
	mov dl, byte ptr [ecx] ;Put operand in dl
	inc ecx
	mov [ebx], ecx ; Update VP
	
	inc eax ;r0 starts at offset 1
	inc edx ; ^
	mov ecx, 4
	
	push edx
	mul ecx
	pop edx
	
	xchg eax, edx
	
	push edx
	mul ecx
	pop edx
	
	add eax, ebx ;Calculate offset to register
	add edx, ebx ; ^
	
	;At this point, EDX contains address of operand 0, and EAX contains address of operand 1
	mov edx, dword ptr [edx]
	sub edx, dword ptr [eax]
	
	;Push result to stack
	mov eax, [ebx + 4 * 6] ;Access r5 /stack pointer
	sub eax, 4
	mov [eax], edx
	mov [ebx + 4 * 6], eax ; Increment stack pointer
	
	xor eax, eax
	pop ebp
	ret
	

vm_jnz:
	push ebp
	mov ebp, esp
	
	;Pop value from stack into register
	mov ecx, [ebx + 4 * 6] ;Access r5 /stack pointer
	mov edx, dword ptr [ecx] ;Get value at stack pointer
	add ecx, 4				 
	mov [ebx + 4 * 6], ecx ; Increment stack pointer

	cmp edx, 0
	je vm_jnz_nextInstr
	;If not zero, perform jump
	
	;Get operand
	mov eax, [ebx]
	mov ecx, [eax + 1] ; get operand
	bswap ecx ;Swap endianess
	add eax, ecx ;Add to virtual pointer.
	mov [ebx], eax ; Update vp
	jmp vm_jnz_end
	
	vm_jnz_nextInstr:
	;Add to VP by instruction size
	mov eax, [ebx]
	add eax, 5
	mov [ebx], eax
	
	vm_jnz_end:
	xor eax, eax
	pop ebp
	ret

vm_exit:
	mov eax, 1
	ret
	
vm_popmb:

	push ebp
	mov ebp, esp
	
	;Add to VP by instruction size
	mov ecx, [ebx]
	inc ecx
	xor eax, eax
	mov al, byte ptr[ecx] ;Extract register destination to al
	inc ecx
	mov [ebx], ecx
	;EAX contains register number
	
	;Pop value from stack into register
	mov ecx, [ebx + 4 * 6] ;Access r5 /stack pointer
	mov edx, dword ptr [ecx] ;Get value at stack pointer
	add ecx, 4				 
	mov [ebx + 4 * 6], ecx ; Increment stack pointer
	
	;Treat stack data as a byte pointer, dereference it to get the byte
	mov dl, byte ptr [edx]
	and edx, 0ffh ;Apply mask to just get byte
	
	inc eax ;R0 starts at offset 1
	mov ecx, 4
	
	push edx
	mul eax
	pop edx
	
	add eax, ebx
	
	mov [eax], edx ;Copy value into register
	
	xor eax, eax
	pop ebp
	ret
	
vm_dec:
	push ebp
	mov ebp, esp
	
	;Add to VP by instruction size
	mov ecx, [ebx]
	inc ecx
	xor eax, eax ;Clear eax register
	mov al, byte ptr [ecx] ;Put operand in ecx
	inc ecx
	mov [ebx], ecx ; Update VP
	
	inc eax ;r0 starts at offset 1
	mov ecx, 4
	mul ecx
	
	add eax, ebx ;Calculate offset to register
	mov ecx, dword ptr [eax]
	dec ecx ;Decrement register
	mov dword ptr [eax], ecx ;put value back into register.
	
	xor eax, eax
	pop ebp
	ret
	
vm_handlers_jump_table:
	dd vm_pushc, vm_pushr, vm_popv, 0, vm_add, vm_sub, vm_jnz, 0, 0, vm_exit, vm_popmb, vm_dec

loopVm:
	push ebp
	mov ebp, esp
	
	mov ebx, [ebp + 8h]
	
	loopVm_execLoop:
	mov ecx, dword ptr[ebx]
	;Gets instruction code.
	xor eax, eax
	mov al, byte ptr [ecx]
	
	;Multiply by size of DWORD
	mov ecx, 4
	mul ecx
	add eax, vm_handlers_jump_table
	
	call dword ptr [eax]
	
	cmp eax, 0
	je loopVm_execLoop
	
	mov eax, [ebx + 4]
	
	pop ebp
	ret

initVm:
	push ebp
	mov ebp, esp
	
	push 0BADF00Dh
	mov eax, [ebp + 12]
	push eax
	mov ecx, esp
	sub esp, 30 * 4 ; 30 dword of stack space
		
	push ecx ;r5 / stack pointer
	push 0 ;offset 20, r4
	push 0 ;offset 16, r3
	push 0 ;offset 12, r2
	push 0 ;offset 8, r1
	push 0 ;offset 4, r0
	push [ebp + 8h] ;offset 0, push vp on to stack
	
	push esp
	call loopVm
	
	add esp, 8*4 ; Clean-up stack
	add esp, 30*4 ;Clean-up vm stack space
	add esp, 4 * 2 ; Clean-up badfood constant.
	
	pop ebp
	ret

start: 

invoke GetStdHandle, STD_OUTPUT_HANDLE
invoke WriteConsole, eax, addr output_intro, sizeof output_intro, ebx, NULL

invoke GetStdHandle, STD_OUTPUT_HANDLE
invoke WriteConsole, eax, addr output_author, sizeof output_author, ebx, NULL

call GetCommandLineA

mov ecx, ' '

cmp byte ptr [eax], '"'
jne find_args
mov ecx, '"'

find_args:
inc eax
cmp byte ptr [eax], 0
je provide_password
cmp byte ptr [eax], cl
jne find_args
inc eax

cmp byte ptr [eax], 0
je provide_password

inc eax ; Move past white space character.

push eax
push offset vm_computeCorrectPassword
call initVm
cmp eax, 0
je correct_password

invoke GetStdHandle, STD_OUTPUT_HANDLE
invoke WriteConsole, eax, addr output_incorrect_password, sizeof output_incorrect_password, ebx, NULL
invoke ExitProcess, 0
; --------------------------------------------------------------------------------------------------------------------------------------

provide_password:
invoke GetStdHandle, STD_OUTPUT_HANDLE
invoke WriteConsole, eax,  addr output_provide_password, sizeof output_provide_password, ebx, NULL
invoke ExitProcess, 0

correct_password:

invoke GetStdHandle, STD_OUTPUT_HANDLE
invoke WriteConsole, eax,  addr output_correct_password, sizeof output_correct_password, ebx, NULL
invoke ExitProcess, 0

end start