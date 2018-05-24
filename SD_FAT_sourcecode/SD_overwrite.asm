;*********************************************************************************************
; Subroutine om op de SD kaart te overschrijven
;
; Input: Filenaam op stack gepusht
;		data om te schrijven in xram3
;
; Output: niks
;
;
;*********************************************************************************************

SD_overwrite:



			push 	acc
			push 	b
			push	psw


;******************naam naar stack pushen*******************
SD_overwrite0:
			mov		r0,#11 		;(tel af voor 11 8.3 filenaam)
			mov		r1,#0		;(tel op voor dptr te verzetten)


SD_overwrite1:
			djnz		r0,SD_overwrite2	;doe verder tot alle letters gepusht zijn
			jmp		SD_overwrite3	;stop met pushen indien alle letters gepusht zijn

SD_overwrite2:
			mov		a,r1
			inc 		r1
			movc	a,@a+dptr
			push	acc
			jmp 		SD_overwrite1


SD_overwrite3:
;***************einde naam naar stack****************************
			lcall		file_entry_search	;zoekt naar naam,
								;geeft sectoradres terug van eerste sector file
								;en geeft ook FATentry-nummer van die eerste sector

			mov		a,sector3
			push	acc
			mov		a,sector2
			push	acc
			mov		a,sector1
			push	acc
			mov		a,sector0
			push	acc
			mov		a,#03h

			lcall		sd_write_block	;het eigenlijke overschrijven

;*****************FAT AANPASSEN****************************
;Zit de FAT entry in deze sector? of niet?

			mov		a,#00h
SD_overwrite4:


			mov 	R3,FATentry3
			mov 	R2,FATentry2
			mov 	R1,FATentry1
			mov 	R0,FATentry0
			mov 	R7,#00h
			mov 	R6,#00h
			mov 	R5,#02h
			mov 	R4,#00h
			lcall		cmp32
			jc		SD_overwrite6 ;indien carry gezet is, is  fatentry kleiner dan 512
			sjmp	SD_overwrite5

;als we nog niet juist zitten moeten we 512 aftrekken tot we juist zitten
SD_overwrite5:
			lcall	 	sub32
			inc		a

SD_overwrite6:

			mov		dph,r1
			mov		dpl,r0

			mov		r7,#00h
			mov		r6,#00h
			mov		r5,#00h
			mov		r4,a	;;accumulator houdt 1 byte bij TODO: uitbreiden naar 2 bytes via registerbank ofzoiets
			mov		r3,FAT3
			mov		r2,FAT2
			mov		r1,FAT1
			mov		r0,FAT0
			lcall		add32
			mov		a,r3
			push	acc
			mov		a,r2
			push	acc
			mov		a,r1
			push	acc
			mov		a,r0
			push	acc
			mov		a,#00h

			lcall		sd_read_block

			mov		a,#0ffh
			movx	@DPTR,a
			inc		dptr
			movx	@DPTR,a
			inc		dptr
			movx	@DPTR,a
			inc		dptr
			movx	@DPTR,a

			mov		a,r3
			push	acc
			mov		a,r2
			push	acc
			mov		a,r1
			push	acc
			mov		a,r0
			push	acc
			mov		a,#00h

			lcall		sd_write_block

;***********aanpassen filesize**************************
;nu de data weggeschreven is, moet de filesize nog aangepast worden.
;allereerst moeten we dus de lengte van de nieuwe data bepalen

			mov		dph,#05h
			mov		dpl,#0FFh	;we moeten in XRAM 3 de lengte bepalen, maar omdat we beginnen met "inc dptr"
								;zetten we DPTR op 600h-1h

SD_overwrite7:
			inc		DPTR
			movx	a,@dptr
			cjne		a,#00h,SD_overwrite7		;indien '00h' niet gevonden is, zoek verder

			;00h is gevonden
			mov		r0,dpl
			mov		r1,dph
			mov		r4,#00h
			mov		r5,#06h
			lcall		sub16	;aantal bytes berekenen,r0 & r1 bevatten nu respectievelijk
							;de LSB en de MSB

			mov		a,#00h
			push	acc
			mov		a,#00h
			push	acc
			mov		a,r1
			push	acc
			mov		a,r0
			push	acc
			lcall		edit_size

			pop		acc	;filenaam van stack poppen
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc


			pop 		acc
			pop		b
			pop		psw
			ret
