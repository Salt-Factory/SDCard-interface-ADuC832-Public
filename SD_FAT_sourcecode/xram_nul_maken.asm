;*********************************************************************************************
; Subroutine om een block in het XRAM volledig te vullen met nullen
;
; Input: block in het xram, in accumulator
;
; Output: geen
;
;*********************************************************************************************
xram_nul_maken:

		push 	acc
		push		b
		push	psw

		mov		a,r0
		push	acc
		mov		a,r1
		push	acc

		mov		a,sp
		subb	a,#4 	;2 registers, 1 PSW & 1 b om accumulator te vinden
		mov		r0,a
		mov		a,@r0	;de waarde (0,1,2 of 3) vermenigvuldigen met 4 om zo het DPH te bepalen
		mov		b,#02h
		mul		AB		;vermenigvuldigd acc met b-register

		mov		dph,a	;a bevat de laagste bytes (we gaan uit van geen overflow, anders error!)
		mov		dpl,#00h

;		mov		a,#040h
;		orl		a,#10000000b
;		lcall		outcharlcd
;		mov		a,root0
;		lcall		outbytelcd

;vullen van de werksector met nullen, door gebruik te maken van een lus
;werksector = sector 3, dus beginnen vanaf 600
;nul wegschrijven naar DPTR moet 512 keer gebeuren, dus een 16 bits teller nodig. r0 voor de LSB's, r1 voor de MSB's.
;r0 moet twee keer volledig ffh aflopen om 512 keer 0 geschreven te hebben.
;
		mov		r0,#0FFh
		mov		r1,#01h


xram_nul_maken0:
		mov		a,#00h
		movx	@DPTR,a
		inc 		DPTR

		dec		r0			;kleine teller decrementeren
		mov		a,r0
		jz		xram_nul_maken1		;als kleine teller = 0, springen naar kleinenul. Anders terug aan loop beginnen, tot kleine teller = 0
		jmp		xram_nul_maken0

xram_nul_maken1:
		mov		a,r1
		jz		xram_nul_maken2	;naar grotenul indien zowel r1 als r0 nul zijn, dan is namelijk loop klaar en sector volledig nul!
		dec		r1			;als grotenul niet nul, dan decrementeren van r1 en het resetten van de waarde in r0
		mov		r0,#0FFh
		jmp		xram_nul_maken0

xram_nul_maken2:						;grotenul wanneer alles nul is!
		mov		a,#00h		;nog twee keer nul wegschrijven, dan is heel de sector gevuld.
		movx	@DPTR,a
		inc		DPTR
		movx	@DPTR,a

;sector is nu volledig nul!
;volgende stap is sector wegschrijven naar het juiste sectoradres

;		mov	a,#000h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,sector3
;		lcall	outbytelcd
;		mov	a,#002h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,sector2
;		lcall	outbytelcd
;		mov	a,#004h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,sector1
;		lcall	outbytelcd
;		mov	a,#006h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,sector0
;		lcall	outbytelcd

		pop		acc
		mov		r1,a
		pop		acc
		mov		r0,a

		pop 		psw
		pop		b
		pop		acc
		ret
