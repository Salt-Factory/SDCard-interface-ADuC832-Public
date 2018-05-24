;*********************************************************************************************
; !!!        De routine initlcd van aduc800_mide.inc moet eerst worden uitgevoerd        !!!!
;
; Errorhandle
; Print af op het scherm wat er in de errorbyte zit
; 	Input: 	errorcode op geheugenplaats 032h
; 	Output: op scherm: +----------------+
;											 |FAT Error: 0xXX |
;											 |SD  Error: 0xXX |
;											 +----------------+
;
;		Deze routine zet de cursor af, om terug aan te zetten moet outchar gebeuren van 011h of 012h
;**********************************************************************************************
; SD_error	 equ 		031h -- gedefined in SD_RAW
; errorcode	 equ		032h -- gedefined in ander???
;**********************************************************************************************
;	sd_error:			 0x00 = geen fout
;								 0x01 = kaart niet beschikbaar
;								 0x02 =  kaart reageert niet
;								 0x03 = check pattern of incompatibel spanningsbereik
;								 0x04 = kaart reageert niet op 'SEND OPERATING CONDITIONS'
;								 0x05 = kaart reageert niet op 'READ OCR'
;								 0x06 = kaart reageert niet op 'SET BLOCK LENGHT'
;
; FAT error

Errorhandle:	push dph
							push dpl
							push a

							mov dptr,Errorhandle0
							lcall outmsgalcd ;druk string af
							mov a,errorcode
							lcall outbytelcd
							mov dptr,Errorhandle1
							lcall outmsgalcd ;druk string af
							mov a,sd_error
							lcall outbytelcd

							pop a
							pop dpl
							pop dph

							ret

Errorhandle0: db 13h,10000000b 	;cursor af en naar eerste cursorpositie
							db 'FAT Error:  0x'
							db 10001110b			;cursor sowieso naar 15de hokje zetten <-- is dit overbodig?
							db 0							;einde string
Errorhandle1:	db 11000000b		 	;cursor naar cursor positie 2 de lijn
							db 'SD  Error:  0x'
							db 11001110b			;cursor sowieso naar 15de hokje zetten <-- is dit overbodig?
							db 0							;einde string
