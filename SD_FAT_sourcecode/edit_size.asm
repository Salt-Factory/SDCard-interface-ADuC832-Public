;*********************************************************************************************
; Subroutine om de grootte van een file aan te passen in de FAT.
;
; Input: Te zoeken naam (op stackframe) (filename 8(naam).3(extensie) bytes)
;					nieuwe filesize (op stackframe)
;
; Output: LBA van het begin van de cluster (in sector3 tot sector0)
;
;*********************************************************************************************

;OPM het huidige adres wordt ook opgeslagen in sector3 tem sector0


;NOG ZIEN WAAR DIT MOET
;testen of dit de laatste cluster is (end of chain marker bekijken in de FAT)



;pushen van standaardregisters (re-entrancy)
edit_size:
		push 		acc
		push 		b
		push 		psw

		mov 		acc,r0
		push 		acc
		mov 		acc,r1
		push 		acc
		mov 		acc,r2
		push 		acc
		mov 		acc,r3
		push 		acc
		mov 		acc,r4
		push 		acc
		mov 		acc,r5
		push 		acc
		mov		acc,r6
		push 		acc
		mov		acc,r7
		push 		acc

		;switch naar registerbank 1; deze extra registers zijn nodig
		setb		RS0

		mov 		acc,r0
		push 		acc
		mov 		acc,r1
		push 		acc
		mov 		acc,r2
		push 		acc
		mov 		acc,r3
		push 		acc
		mov 		acc,r4
		push 		acc
		mov 		acc,r5
		push 		acc
		mov		acc,r6
		push 		acc
		mov		acc,r7
		push 		acc

		;switch terug naar registerbank 0
		CLR		RS0

;pointers en tellers initialiseren
		mov 		a, sp	;zet stackpointer naar stackframe
		subb		a,#34	;ga terug op stack: 1 acc, 1 b, 1 psw, 	r0 r1 r2 r3 r4 r5 r6 r7 (8+8 van RegBank1) 11 bytes op stackframe(8.3 filenaam), nieuwe filesize 4 bytes totaal = 34
		;REGISTERS VOOR INGEGEVEN WAARDE OP STACKFRAME
		mov 		r0,a	;r0 houdt nu het begin van het stackframe bij met de opgegeven (te zoeken) filename
		mov		r1,a 	;r1:huidige stackframepointer bijhouden
		;REGISTERS ALS TELLERS
		mov 		r3,#0	;r3: de huidige counter instellen voor juiste aantal karakters bij te houden
		mov 		r4,#1	;r4: het aantal gepasseerde entries per sector bijhouden (Als we na 16 entries nog steeds niets gevonden hebben, moeten we het volgende deel van de cluster inlezen)
		mov 		r5,#1	;r5: het aantal gepasseerde sectoren per ingelezen cluster. (als we na secperclust aantal sectoren nog geen match hebben, moeten we een nieuwe cluster inlezen via de rootfolder)

;rootfolder inlezen (en ook opslaan in sectorgeheugenplaatsen voor eventueel later gebruik: nodig voor edit_size6)
		mov		a,root3
		mov		sector3,root3
		push		acc
		mov		a,root2
		mov		sector2,root2
		push		acc
		mov		a,root1
		mov		sector1,root1
		push		acc
		mov		a,root0
		mov		sector0,root0
		push		acc

		mov		a,#1 ;XRAM sector 1
		lcall		sd_read_block

;datapointer instellen
		mov		dph,#02h
		mov		dpl,#00h ;XRAM sector 1

;naam van een entry in een bestand staat op offset 1 en verder
;lezen van naam op adres 1

edit_size0:	movx		a,@DPTR
		mov		r2,a  	;r2: de huidige byte uit XRAM die moet vergeleken worden bijhouden
		mov		a,@r1	;haal de byte op van het stackframe die ingegeven is.
		clr		c	;geen carry voor vergelijking
		subb 		a,r2	;doe vergelijking
		cjne		a,#0h,edit_size3	;spring als ze niet gelijk zijn
;Het geteste karakter is gelijk
edit_size1:	cjne		r3,#10,edit_size8		;testen of je moet stoppen
edit_size2:
		inc		r1	;incrementeer de huidige stackframepointer (input)
		inc 		DPTR	;incrementeer de datapointer (uit data table)
		inc 		r3	;incrementeer het aantal juiste karakters
		jmp		edit_size0;
;Het geteste karakter is niet gelijk
;zet sowieso de stackframe terug
edit_size3:	mov		a,r0	;stackframepointer terug zetten naar begin entry
		mov 		r1,a	;zet r1 terug naar het begin van de filenaamoffset
		mov		r3,#00h ;zet r3 terug op nul (geen enkel juist getal meer)

;Hoe zetten we de DATAPTR?
;Zitten we in dezelfde sector?
;Zo niet, moeten we naar een volgende cluster gaan?
		cjne		r4,#16,edit_size7	;testen of je naar volgende sector moet
edit_size4:
		cjne		r5,#secperclust,edit_size6		;testen of je naar volgende cluster moet
edit_size5:
		;mov		errorbyte,#069h	;error gooien en dit nog niet doen :D
		jmp		edit_size9

;WE GAAN NAAR DE VOLGENDE SECTOR BINNEN DEZELFDE CLUSTER
edit_size6:
		;datapointer instellen (terug aan begin van de sector zetten)
		mov		dph,#02h
		mov		dpl,#00h ;XRAM sector 1

		;switch naar registerbank 1
		setb		RS0

		mov		r7,sector3
		mov		r6,sector2
		mov 		r5,sector1
		mov		r4,sector0
		mov		r3,#000h
		mov		r2,#000h
		mov 		r1,#000h
		mov		r0,#001h

		lcall		add32 ;ga een sector verder!

		mov		a,r3
		mov		sector3,r3
		push		acc
		mov		a,r2
		mov		sector2,r2
		push		acc
		mov		a,r1
		mov		sector1,r1
		push		acc
		mov		a,r0
		mov		sector0,r0
		push		acc
		mov		a,#1 ;XRAM sector 1
		lcall		sd_read_block


		clr		RS0
		;switch terug naar registerbank 0

		;pointers en tellers terug initialiseren
		;mov 		a, sp	                       |--> dit is niet nodig, deze waarde blijft immers altijd in r0 zitten
		;subb		a,#30	;(uitleg zie hierboven)|
		;REGISTERS VOOR INGEGEVEN WAARDE OP STACKFRAME
		mov		a,r0	;stackframepointer terug zetten naar begin entry
		mov		r1,a 	;
		;REGISTERS ALS TELLERS
		mov 		r3,#0	;r3: de huidige counter instellen voor juiste aantal bij te houden
		inc 		r4	;r4: het aantal gepasseerde entries per sector bijhouden (Als we na 16 entries nog steeds niets gevonden hebben, moeten we het volgende deel van de cluster inlezen)
					;r5 verandert niet


;WE GAAN NIET NAAR DE VOLGENDE SECTOR = gewoon datapointer optellen bij met 0x20
edit_size7:
		;even overgaan naar andere registerbank
		setb		RS0

		mov		r5,dph
		mov		r4,dpl
		mov 		r1,#000h
		mov		r0,#020h	; ga 0x20 verder
		lcall		add16		; deze kan normaal gezien niet overflowen, aangezien in de datapointer enkel waarden zullen zitten die wijzen naar file entries
		mov		dph,r1
		mov		dpl,r0		; datapointer is nu verdergegaagn

		clr		RS0		;terug naar registerbank 1 gaan

		jmp		edit_size0	;kijk verder na of de volgende file entries matchen






;ALLE GETESTE KARAKTERS ZIJN JUIST, WE HEBBEN DE ENTRY GEVONDEN
;vanaf hier worden registers r5,r4,r1,r0 overschreven en verliezen ze hun betekenis van hierboven
;We slaan het clusteradres op in de overblijvende registers:MSB[r7][r6][r3][r2]LSB
edit_size8:
		mov		r5,dph		; zet de datapointer op de entrynummers en haal deze op
		mov		r4,dpl
		mov 		r1,#000h
		mov		r0,#01Ch	
		lcall		add16		; deze kan normaal gezien niet overflowen, aangezien in de datapointer enkel waarden zullen zitten die wijzen naar file entries

		mov		dph,r1
		mov		dpl,r0

		mov		a,sp
		clr		c
		subb	a,#21
		mov		r0,a
		mov		a,@r0
		movx	@DPTR,a
		inc		DPTR
		dec		r0
		mov		a,@r0
		movx	@DPTR,a
		inc		DPTR
		dec		r0
		mov		a,@r0
		movx	@DPTR,a
		inc		DPTR
		dec		r0
		mov		a,@r0
		movx	@DPTR,a

		mov		a,sector3
		push	acc
		mov		a,sector2
		push	acc
		mov		a,sector1
		push	acc
		mov		a,sector0
		push	acc
		mov		a,#01h

		lcall		sd_write_block



;alles terugzetten

		;registerbank 1

edit_size9:	SETB		RS0

		pop acc
		mov r7,acc
		pop acc
		mov r6,acc
		pop acc
		mov r5,a
		pop acc
		mov r4,a
		pop acc
		mov r3,acc
		pop acc
		mov r2,acc
		pop acc
		mov r1,a
		pop acc
		mov r0,a

		CLR		RS0

		;registerbank 0

		pop acc
		mov r7,acc
		pop acc
		mov r6,acc
		pop acc
		mov r5,a
		pop acc
		mov r4,a
		pop acc
		mov r3,acc
		pop acc
		mov r2,acc
		pop acc
		mov r1,a
		pop acc
		mov r0,a

		pop psw
		pop b
		pop acc

		ret
