;*********************************************************************************************
; Subroutine om een gegeven aantal bytes (max 512) uit te lezen in het XRAM
;
; Input: filename in DPTR
;
;
; Output: De te lezen file in XRAM 3
;
;*********************************************************************************************

SD_read:

;code om stackpointer te tonen
;			mov		a,#0Ah
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		 a,sp
;			lcall 		outbytelcd

			push 	acc
			push	b
			push	psw

			mov		a,r0
			push	acc
			mov		a,r1
			push	acc

;******************naam naar stack pushen*******************
SD_read0:			
			mov		r0,#11 		;(tel af voor 11 8.3 filenaam)
			mov		r1,#0		;(tel op voor dptr te verzetten)


SD_read1:
			djnz		r0,SD_read2	;doe verder tot alle letters gepusht zijn
			jmp		SD_read3	;stop met pushen indien alle letters gepusht zijn

SD_read2:
			mov		a,r1
			inc 		r1
			movc		a,@a+dptr
			push		acc
			jmp 		SD_read1


SD_read3:
;***************einde naam naar stack****************************
			lcall		file_entry_search	;zoekt naar naam,
			;geeft sectoradres terug van eerste sector file



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


;			mov		a,#000h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov	 	a,sector3
;			lcall 		outbytelcd
;			mov		a,sector2
;			lcall		outbytelcd
;			mov		a,sector1
;			lcall		outbytelcd
;			mov 		a,sector0
;			lcall		outbytelcd			;print om einde te tonen

			mov		a,sector3
			push		acc
			mov		a,sector2
			push		acc
			mov		a,sector1
			push		acc
			mov		a,sector0
			push		acc
			mov		a,#00h		;
			lcall		sd_read_block	;sector van file inladen in 3de block XRAM
							;MAAR: werkt om een of andere reden enkel in XRAM 0?

;code om de eerste 4 bytes van de net gelezen file te tonen op LCD
;			mov		dph,06h
;			mov		dpl,00h
;			mov		a,#004h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			movx	 	a,@dptr
;			inc		dptr
;			lcall 		outbytelcd
;			movx		a,@dptr
;			inc 		dptr
;			lcall		outbytelcd
;			movx 		a,@dptr
;			inc		dptr
;			lcall		outbytelcd
;			movx 		a,@dptr
;			lcall		outbytelcd			;print om einde te tonen

			;that's it! ezpz
			pop		acc
			mov		r1,a
			pop		acc
			mov		r0,a
			pop		psw
			pop		b
			pop		acc

;code om stackpointer te tonen
;			mov		a,#0Ch
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		 a,sp
;			lcall 		outbytelcd


			ret
