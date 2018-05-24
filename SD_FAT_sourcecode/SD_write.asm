;*********************************************************************************************
; Subroutine om op de SD kaart te schrijven
;
; Input: Filenaam op stack gepusht
;		data om te schrijven in xram4
;
; Output: niks 
;
;
;*********************************************************************************************

			push 	acc
			push 	b
			push	psw
		
		
;******************naam naar stack pushen*******************
naam_naar_stack:			
			mov		r0,#11 		;(tel af voor 11 8.3 filenaam)
			mov		r1,#0		;(tel op voor dptr te verzetten)

	
naam_naar_stack_1:
			djnz		r0,naam_naar_stack_2	;doe verder tot alle letters gepusht zijn
			jmp		naam_naar_stack_3	;stop met pushen indien alle letters gepusht zijn

naam_naar_stack_2:
			mov		a,r1
			inc 		r1
			movc	a,@a+dptr
			push	acc
			jmp 		naam_naar_stack_1
		

naam_naar_stack_3:
;***************einde naam naar stack****************************
			lcall		file_entry_search	;zoekt naar naam,
									;geeft sectoradres terug van eerste sector file
							
		
		
		
		
			pop 		acc
			pop		b
			pop		psw