;*********************************************************************************************
; Subroutine om de file-entry op te zoeken in FS
;
; Input: Te zoeken naam (op stackframe gepusht?) (filename 8(naam).3(extensie) bytes)
;
; Output: LBA van het begin van de cluster (in sector3 tot sector0)
;
;*********************************************************************************************

;OPM het huidige adres wordt ook opgeslagen in sector3 tem sector0


;NOG ZIEN WAAR DIT MOET
;testen of dit de laatste cluster is (end of chain marker bekijken in de FAT)



;pushen van standaardregisters (re-entrancy)
file_entry_search:
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
		mov			acc,r6
		push 		acc
		mov			acc,r7
		push 		acc

		;switch naar registerbank 1; deze extra registers zijn nodig
		setb			RS0

		mov 		acc,r0
		push 	acc
		mov 		acc,r1
		push 	acc
		mov 		acc,r2
		push 	acc
		mov 		acc,r3
		push 	acc
		mov 		acc,r4
		push 	acc
		mov 		acc,r5
		push 	acc
		mov		acc,r6
		push 	acc
		mov		acc,r7
		push 	acc

		;switch terug naar registerbank 0
		CLR			RS0


;pointers en tellers initialiseren
		mov 		a, sp	;zet stackpointer naar stackframe
		subb		a,#30	;ga terug op stack: 1 acc, 1 b, 1 psw, 	r0 r1 r2 r3 r4 r5 r6 r7 (8+8 van RegBank1) 11 bytes op stackframe(8.3 filenaam) totaal = 30
		;REGISTERS VOOR INGEGEVEN WAARDE OP STACKFRAME
		mov 		r0,a	;r0 houdt nu het begin van het stackframe bij met de opgegeven (te zoeken) filename
		mov			r1,a 	;r1:huidige stackframepointer bijhouden
		;REGISTERS ALS TELLERS
		mov 		r3,#0	;r3: de huidige counter instellen voor juiste aantal karakters bij te houden
		mov 		r4,#1	;r4: het aantal gepasseerde entries per sector bijhouden (Als we na 16 entries nog steeds niets gevonden hebben, moeten we het volgende deel van de cluster inlezen)
		mov 		r5,#1	;r5: het aantal gepasseerde sectoren per ingelezen cluster. (als we na secperclust aantal sectoren nog geen match hebben, moeten we een nieuwe cluster inlezen via de rootfolder)

;rootfolder inlezen (en ook opslaan in sectorgeheugenplaatsen voor eventueel later gebruik: nodig voor file_entry_search6)
		mov			a,root3
		mov			sector3,root3
		push		acc
		mov			a,root2
		mov			sector2,root2
		push		acc
		mov			a,root1
		mov			sector1,root1
		push		acc
		mov			a,root0
		mov			sector0,root0
		push		acc

		mov			a,#1 ;XRAM sector 1
		lcall			sd_read_block

;datapointer instellen
		mov			dph,#02h
		mov			dpl,#00h ;XRAM sector 1

;naam van een entry in een bestand staat op offset 1 en verder
;lezen van naam op adres 1????????????????????????????????????????????????????????????????????????????????????????????????????????????

file_entry_search0:
		movx		a,@DPTR
		mov			r2,a  	;r2: de huidige byte uit XRAM die moet vergeleken worden bijhouden
		mov			a,@r1	;haal de byte op van het stackframe die ingegeven is.
		clr			c	;geen carry voor vergelijking
		subb 		a,r2	;doe vergelijking
		cjne			a,#0h,file_entry_search3	;spring als ze niet gelijk zijn
;Het geteste karakter is gelijk
file_entry_search1:
		cjne			r3,#10,file_entry_search8		;testen of je moet stoppen

file_entry_search2:
		inc			r1	;incrementeer de huidige stackframepointer (input)
		inc 			DPTR	;incrementeer de datapointer (uit data table)
		inc 			r3	;incrementeer het aantal juiste karakters
		jmp			file_entry_search0;
;Het geteste karakter is niet gelijk
;zet sowieso de stackframe terug
file_entry_search3:
		mov			a,r0	;stackframepointer terug zetten naar begin entry
		mov 		r1,a	;zet r1 terug naar het begin van de filenaamoffset
		mov			r3,#00h ;zet r3 terug op nul (geen enkel juist getal meer)

;Hoe zetten we de DATAPTR?
;Zitten we in dezelfde sector?
;Zo niet, moeten we naar een volgende cluster gaan?
		cjne			r4,#16,file_entry_search7	;testen of je naar volgende sector moet
file_entry_search4:
		cjne			r5,#secperclust,file_entry_search6		;testen of je naar volgende cluster moet
file_entry_search5:
		;mov		errorbyte,#069h	;error gooien en dit nog niet doen :D
		jmp			file_entry_search9

;WE GAAN NAAR DE VOLGENDE SECTOR BINNEN DEZELFDE CLUSTER
file_entry_search6:
		;datapointer instellen (terug aan begin van de sector zetten)
		mov			dph,#02h
		mov			dpl,#00h ;XRAM sector 1

		;switch naar registerbank 1
		setb			RS0

		mov			r7,sector3
		mov			r6,sector2
		mov 		r5,sector1
		mov			r4,sector0
		mov			r3,#000h
		mov			r2,#000h
		mov 		r1,#000h
		mov			r0,#001h

		lcall			add32 ;ga een sector verder!

		mov			a,r3
		mov			sector3,r3
		push		acc
		mov			a,r2
		mov			sector2,r2
		push		acc
		mov			a,r1
		mov			sector1,r1
		push		acc
		mov			a,r0
		mov			sector0,r0
		push		acc
		mov			a,#1 ;XRAM sector 1
		lcall			sd_read_block


		clr			RS0
		;switch terug naar registerbank 0

		;pointers en tellers terug initialiseren
		;mov 		a, sp	                       |--> dit is niet nodig, deze waarde blijft immers altijd in r0 zitten
		;subb		a,#30	;(uitleg zie hierboven)|
		;REGISTERS VOOR INGEGEVEN WAARDE OP STACKFRAME
		mov			a,r0	;stackframepointer terug zetten naar begin entry
		mov			r1,a 	;
		;REGISTERS ALS TELLERS
		mov 		r3,#0	;r3: de huidige counter instellen voor juiste aantal bij te houden
		inc 			r4	;r4: het aantal gepasseerde entries per sector bijhouden (Als we na 16 entries nog steeds niets gevonden hebben, moeten we het volgende deel van de cluster inlezen)
					;r5 verandert niet


;WE GAAN NIET NAAR DE VOLGENDE SECTOR = gewoon datapointer optellen bij met 0x20
file_entry_search7:
		;even overgaan naar andere registerbank
		setb			RS0

		mov			r5,dph
		mov			r4,dpl
		mov 		r1,#000h
		mov			r0,#020h	; ga 0x20 verder
		lcall			add16		; deze kan normaal gezien niet overflowen, aangezien in de datapointer enkel waarden zullen zitten die wijzen naar file entries
		mov			dph,r1
		mov			dpl,r0		; datapointer is nu verdergegaagn

		clr			RS0		;terug naar registerbank 1 gaan

		jmp			file_entry_search0	;kijk verder na of de volgende file entries matchen






;ALLE GETESTE KARAKTERS ZIJN JUIST, WE HEBBEN DE ENTRY GEVONDEN
;vanaf hier worden registers r5,r4,r1,r0 overschreven en verliezen ze hun betekenis van hierboven
;We slaan het clusteradres op in de overblijvende registers:MSB[r7][r6][r3][r2]LSB
file_entry_search8:
		mov			r5,dph		; zet de datapointer op de clusternummers en haal deze op
		mov			r4,dpl
		mov 		r1,#000h
		mov			r0,#014h	; op offset 0x14 zitten de hoge twee bytes (little endian!) (dus op 0x15 zit de MSB )
		lcall			add16		; deze kan normaal gezien niet overflowen, aangezien in de datapointer enkel waarden zullen zitten die wijzen naar file entries

		mov			dph,r1
		mov			dpl,r0		;steek de berekende waarden in de datapointer

		movx		a,@DPTR		;lees byte uit
		mov			r6,a		;steek hem weg in r6
		inc			DPTR		;kijk een plaatsje verder, dit is de MSB van het clusteradres
		movx		a,@DPTR		;lees MSB uit
		mov			r7,a		;steek hem weg

		mov			r5,dph		; zet de datapointer op de clusternummers en haal deze op
		mov			r4,dpl
		mov 		r1,#000h
		mov			r0,#005h	; op offset 0x1A de lage twee bytes (dus op 0x1A zit de LSB) (+5h want 0x1A-(0x14+1))
		lcall			add16
		
		

		mov			dph,r1
		mov			dpl,r0		;steek de berekende waarden in de datapointer

		movx		a,@DPTR		;lees LSB uit
		mov			r2,a		;steek hem weg in r2
		inc			DPTR		;kijk een plaatsje verder
		movx		a,@DPTR		;lees byte uit
		mov			r3,a		;steek hem weg

		;uitlezen van filesize: 4 bytes
		inc			DPTR
		movx		a,@DPTR
		mov			filesize0,a
		inc			DPTR
		movx		a,@DPTR
		mov			filesize1,a
		inc			DPTR
		movx		a,@DPTR
		mov			filesize2,a
		inc			DPTR
		movx		a,@DPTR
		mov			filesize3,a
		

;Uitprinten uitgelezen clusteradres
;		mov			a,#040h
;		orl			a,#10000000b
;		lcall			outcharlcd
;		mov 		a,r7
;		lcall 			outbytelcd
;		mov	 		a,r6
;		lcall			outbytelcd
;		mov 		a,r3
;		lcall			outbytelcd
;		mov 		a,r2
;		lcall			outbytelcd

		;resultaat op stackframe plaatsen en omvormen tot sectoradres



		mov		a,r7
		mov		FATentry3,r7
		push		acc
		mov		a,r6
		mov		FATentry2,r6
		push		acc
		mov		a,r3
		mov		FATentry1,r3
		push		acc
		mov		a,r2
		mov		FATentry0,r2
		push		acc

		lcall		cluster_to_sector
		
		;sectoradres printen!		
;		mov		a,#000h
;		orl		a,#10000000b
;		lcall		outcharlcd
;		mov		a,sector3
;		lcall 		outbytelcd
;		mov		a,sector2
;		lcall		outbytelcd
;		mov		a,sector1
;		lcall		outbytelcd
;		mov		a,sector0
;		lcall		outbytelcd			;print om einde te tonen
		
		lcall		cluster_to_fatentry

		;input van de stack poppen
		pop		acc
		pop		acc
		pop		acc
		pop		acc



;alles terugzetten

		;registerbank 1

file_entry_search9:	SETB		RS0

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
