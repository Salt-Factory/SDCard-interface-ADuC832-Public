;*********************************************************************************************
; Subroutine om een FAT entry aan te passen
;
; Input: clusternummer van de te wijzigen entry (stackframe van 2 bytes, MSB eerst. Wegens limitaties, enkel de eerste twee bytes mogelijk)
;	    clusternummer van de cluster die we willen toevoegen (stackframe van 4 bytes, MSB eerst)
;
; Output: geen
;
;*********************************************************************************************
edit_FAT:	push	acc
			push	b	
			push 	psw
			
			mov	a,r0			;opslaan van registers die we gaan gebruiken op stackframe,
			push	acc			;zodat we deze niet overschrijven
			mov	a,r1
			push	acc
			mov	a,r2
			push 	acc
			mov	a,r3
			push	acc
			mov	a,r4
			push	acc
			mov	a,r7
			push	acc
			
			mov 	a,sp
			subb	a,#16		;16 bytes onder huidige stackpointer bevindt zich de MSB van eerste stackframe
			mov	r0,a			;(1 PSW, 1 b, 1 acc, 2 return bytes, 6 registers opslaan, 6 bytes op stackframe)
			
			mov	a,@r0
			mov	r1,a 			;r1 bevat nu de MSB van de te schrijven entry

			inc	r0
			mov	a,@r0
			mov	r2,a			;r2 bevat nu de 2de byte van de te schrijven entry
			inc	r0
			
			mov	a,r0
			mov	r7,a			;r7 bevat nu de pointer naar de te schrijven waarden
			mov	a,r2
			mov	r0,a			;r0 bevat nu de 2de byte van de te schrijven entry
			
			mov	r4,#04h
			

			
			
			lcall		mul816		;vermenigvuldig het clusternummer met 4
								;r2,r1 en r0 bevatten nu de uitkomst
								;op dit byteadres moeten we de nieuwe waarde schrijven
								;indien de nieuwe waarde groter is dan 512, moet de volgende FAT ingeladen worden
								
;TODO: nakijken of nieuwe FAT nodig is
			
			mov		dph,r1
			mov		dpl,r0
			
			mov		a,r7
			mov		r0,a
			
			mov		a,@r0		;de vier bytes overschrijven in FAT
			movx	@DPTR,a
			
			inc		r0
			inc		DPTR
			
			mov		a,@r0
			movx	@DPTR,a
			
			inc		r0
			inc		DPTR
			
			mov		a,@r0
			movx	@DPTR,a
			
			inc		r0
			inc		DPTR
			
			mov		a,@r0
			movx	@DPTR,a
			
;FAT wegschrijven naar SD

			mov		a,FAT3
			push	acc
			mov		a,FAT2
			push	acc
			mov		a,FAT1
			push	acc
			mov		a,FAT0
			push	acc
			
			mov 	a,#00h
			lcall		sd_write_block
			
			

			pop		acc			;stackframe weer in registers plaatsen
			mov		r7,a
			pop		acc
			mov		r4,a
			pop		acc
			mov		r3,a
			pop		acc
			mov		r2,a
			pop		acc
			mov		r1,a
			pop		acc
			mov		r0,a

			pop 		psw
			pop		b
			pop		acc
			ret
