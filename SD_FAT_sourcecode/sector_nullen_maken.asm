;*********************************************************************************************
; Subroutine om een sector volledig te vullen met nullen
;
; Input: LBA begin (op stackframe), aantal sectoren
;
; Output: geen
;
;*********************************************************************************************
sector_nullen_maken:
		
		push 	acc
		push	b
		push	psw
		
		mov		a,r0
		push	acc
		mov		a,r1
		push	acc
		
		
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
		mov		dph,#06h
		mov		dpl,#00h
		
		
		
nietnul1:	mov		a,#00h
		movx	@DPTR,a		
		inc 		DPTR
		
		dec		r0			;kleine teller decrementeren
		mov		a,r0
		jz		kleinenul		;als kleine teller = 0, springen naar kleinenul. Anders terug aan loop beginnen, tot kleine teller = 0
		jmp		nietnul1
		
kleinenul:
		mov		a,r1		
		jz		grotenul		;naar grotenul indien zowel r1 als r0 nul zijn, dan is namelijk loop klaar en sector volledig nul!
		dec		r1			;als grotenul niet nul, dan decrementeren van r1 en het resetten van de waarde in r0
		mov		r0,#0FFh
		jmp		nietnul1
		
grotenul:						;grotenul wanneer alles nul is!
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
		
		mov		a,sector3
		push	acc
		mov		a,sector2
		push	acc
		mov		a,sector1
		push	acc
		mov		a,sector0
		push	acc
		mov		a,#03h
		
		lcall 		sd_write_block
		
;		mov	a,#040h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,#69h
;		lcall	outbytelcd
		
		pop		acc
		mov		r1,a
		pop		acc
		mov		r0,a
		
		pop 		psw
		pop		b
		pop		acc
		ret