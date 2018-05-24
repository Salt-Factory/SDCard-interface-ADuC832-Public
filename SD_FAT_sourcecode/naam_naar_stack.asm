;********************************************************************************************************************
; Subroutine
; 
; Input:in de DPTR het startadres van de te pushen string.
; 
; Output: niets, de filenaam wordt op de stack gepusht
;
; OPM: 	!!!!	deze routine werkt enkel met 8.3 (short_filenames)	!!!!
;	
;	- 	Indien de bestandsnaam korter is dan 8 karakters,dient deze achteraan
;		bijgevuld te worden met spaties
;	-	Indien de bestandsnaam langer is dan 8 karakters wordt er met VFAT
;		extended filenames gewerkt, deze moet dan omgevormd worden tot een 8.3 filenaam
;		deze kan gevonden worden in Command prompt met het commando "dir /x" in de map
;		waar het bestand staat. (commando werkt niet in powershell, en bij NTFS kan het afgezet worden)
;	-	Mapnamen hebben geen extensie. In dit geval dienen deze ook aangevuld te worden door spaties.
;	-	Voorbeelden
;		*	de map 		Documenten 			->	'DOCUME~1   '
;		*	het bestand 	InstalledSoftwareList.txt	->	'INSTAL~1TXT'
;		*	de map		Sony Xperia			->	'SONYXP~1   '
;		*	de map		Sony Xperia 2 in zelfde map	->	'SONYXP~2   '	(later aangemaakt)
;		*	het bestand	ziever.txt			->	'ZIEVER  TXT'
;		*	het bestand	volledig.asm			->	'VOLLEDIGASM'
;
; OPM:	!!!!		DEZE ROUTINE VERNIETIGT ACC, R0 EN R1		!!!!
;
; Gebruik:
;		mov 	DPTR,#tekst
;		lcall 	naam_naar_stack
;	----------------------------------
;	tekst:	db	'ZIEVER  TXT'		(Dit wordt meestal op het einde van het programma gezet)
;
;********************************************************************************************************************

naam_naar_stack:
		pop acc
		mov	r2,a
		pop	acc
		mov	r3,a
		mov	r0,#11 		;(tel af voor 11 8.3 filenaam)
		mov	r1,#0		;(tel op voor dptr te verzetten)

	
naam_naar_stack_1:
		djnz	r0,naam_naar_stack_2	;doe verder tot alle letters gepusht zijn
		jmp	naam_naar_stack_3	;stop met pushen indien alle letters gepusht zijn

naam_naar_stack_2:
		mov	a,r1
		inc 	r1
		movc	a,@a+dptr
		push	acc
		jmp 	naam_naar_stack_1
		

naam_naar_stack_3:
		mov	a,r3
		push acc
		mov	a,r2
		push acc
		push	acc
		ret				;keer terug indien gedaan
		
		