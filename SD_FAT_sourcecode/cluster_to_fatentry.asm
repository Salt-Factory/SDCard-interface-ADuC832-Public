;*********************************************************************************************
; Subroutine om clusteradres om te zetten naar fatadres
; vermenigvuldigen met 4
;
; Input: Clusteradres (in fatentry3 tem fatentry0)
;
; Output: fatadres (in fatentry3 tem fatentry0)
;
;*********************************************************************************************

cluster_to_fatentry:
		push 	acc
		push	b
		push	psw
		
		mov		a,r0			;opslaan van registers die we gaan gebruiken op stackframe,
		push	acc			;zodat we deze niet overschrijven
		mov		a,r1
		push	acc
		mov		a,r2
		push 	acc
		mov		a,r3
		push	acc
		mov		a,r4
		push	acc
		mov		a,r5
		push	acc
		mov		a,r6
		push	acc
		mov		a,r7
		push	acc
		
		
		clr		c
		
		;nu onze waarde opgeslagen staat in r0 tem r3, moeten we hier 2 van af trekken
		mov		r7,#00h
		mov		r6,#00h
		mov		r5,#00h
		mov		r4,#00h
		mov		r3,FATentry3
		mov		r2,FATentry2
		mov		r1,FATentry1
		mov		r0,FATentry0		
		;Nadat we twee hebben afgetrokken, moeten we deze waarde vermenigvuldigen met secperclust.
		;Dit doen we door eerst de laagste twee bytes te vermenigvuldigen, dan de hoogste twee bytes te vermenigvuldigen, en vervolgens deze op te tellen.
		
		mov 	a,r3
		mov		r7,a
		mov		a,r2		;de hoogste twee bytes tijdelijk wegschrijven zodat we deze niet overschrijven.
		mov		r6,a
		
		mov		r5,#0h
		mov		r4,#04h	;r5r4 * r1r0 = r3r2r1r0
		mov		r3,#0h
		mov		r2,#0h
		lcall		mul16	;nu vermenigvuldigen we de LSB's met 04h, deze worden opgeslagen in r3,r2,r1,r0

;print als test		
;		mov	a,#040h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,r3
;		lcall	outbytelcd
;		mov	a,r2
;		lcall	outbytelcd
;		mov	a,r1
;		lcall	outbytelcd
;		mov	a,r0
; 		lcall	outbytelcd	
		
		mov		a,r3
		push	acc
		mov		a,r2
		push	acc
		mov		a,r1
		push	acc
		mov		a,r0
		push	acc		;onze eerste waarde staat nu handig opgeslagen als stackframe
		
		mov		a,r7
		mov		r1,a
		mov		a,r6
		mov		r0,a		;nu zitten onze MSB's in r1 & r0
		
		mov		r2,#0h
		mov		r3,#0h
		
		lcall		mul16	;nu zitten de vermenigvuldigde waaren in r3 tem r0, we hebben enkel r1 & r0 nodig (overflow kan ze kussen!)
		
;print als test		
;		mov	a,#040h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,r3
;		lcall	outbytelcd
;		mov	a,r2
;		lcall	outbytelcd
;		mov	a,r1
;		lcall	outbytelcd
;		mov	a,r0
 ;		lcall	outbytelcd
		
		mov		a,r0
		mov		r2,a
		mov		a,r1
		mov		r3,a
		mov		r0,#00h
		mov		r1,#00h	;r3 tem r0 bevatten nu MSB1 MSB0 00 00
		;nu moeten we de vorige waarde er bij optellen op MSB1 MSB0 LSB0 LSB1 uit te komen
		
		pop		acc
		mov		r4,a
		pop		acc
		mov		r5,a
		pop		acc
		mov		r6,a
		pop		acc
		mov		r7,a
		
		lcall		add32	;r3 tem r0 bevat nu eindelijk onze waarde, vervolgens tellen we de rootfolder erbij op en wij zijn klaar!
		
;print als test		
;		mov	a,#040h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,r3
;		lcall	outbytelcd
;		mov	a,r2
;		lcall	outbytelcd
;		mov	a,r1
;		lcall	outbytelcd
;		mov	a,r0
;		lcall	outbytelcd
;printen root

 ;		mov	a,#040h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,root3
;		lcall	outbytelcd
;		mov	a,root2
;		lcall	outbytelcd
;		mov	a,root1
;		lcall	outbytelcd
;		mov	a,root0
;		lcall	outbytelcd
 
		mov		FATentry3,r3
		mov		FATentry2,r2
		mov		FATentry1,r1
		mov		FATentry0,r0

;printen resultaat		
;		mov	a,#40h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,sector3
;		lcall	outbytelcd
;		mov	a,#042h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,sector2
;		lcall	outbytelcd
;		mov	a,#044h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,sector1
;		lcall	outbytelcd
;		mov	a,#046h
;		orl	a,#10000000b
;		lcall	outcharlcd
;		mov	a,sector0
;		lcall	outbytelcd	

		pop		acc			;stackframe weer in registers plaatsen
		mov		r7,a
		pop		acc
		mov		r6,a
		pop		acc
		mov		r5,a
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
		
		
		pop		psw
		pop		b
		pop		acc
		
		ret
