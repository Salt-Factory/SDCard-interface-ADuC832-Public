;*********************************************************************************************
; Subroutine om de FAT-partitite op een SD-kaart te initialiseren
;
; Input: geen
;
; Output: LBA FAT partitie
;	 LBA rootfolder
;
;*********************************************************************************************

nieuweclusternodig	bit	00h

FAT0		equ		33h
FAT1		equ		34h
FAT2		equ		35h
FAT3		equ		36h

root0		equ		37h
root1		equ		38h
root2		equ		39h
root3		equ		40h

sector0		equ		41h
sector1		equ		42h
sector2		equ		43h
sector3		equ		44h

secperclust	equ		45h

FATentry0	equ		46h
FATentry1	equ		47h
FATentry2	equ		48h
FATentry3	equ		49h

filesize0		equ		50h
filesize1		equ		51h
filesize2		equ		52h
filesize3		equ		53h

FAT_init:
			push	acc
			push	b
			push	psw

			mov		a,r0
			push	acc
			mov		a,r1
			push	acc
			mov		a,r2
			push	acc
			mov		a,r3
			push	acc
			mov		a,r4
			push	acc
			mov		a,r5
			push	acc
			mov		a,r6
			push	acc
			mov		a,r7
			push 	acc

;adres van nulde sector op stack plaatsen
			mov		a,#00h
			push	acc
			mov		a,#00h
			push	acc
			mov		a,#00h
			push 	acc
			mov		a,#00h
			push	acc


;sector in XRAM0 inlezen
			mov		a,#0000h
			lcall		sd_read_block

;			pop		acc
;			pop		acc
;			pop		acc
;			pop		acc



;Uitlezen LBA part1, nagaan of de eerste sector het MBR is; of meteen al FAT32 partitie
;bytes 0x1C6 t.e.m. 0x1C9 met 0x1C6 LSB
;datapointer op positie eerste byte van LBA partitie 1 zetten
			mov		dph,#01h
			mov 	dpl,#0C6h

;8 bits lezen op adres in datapointer en wegschrijven
			movx	a,@DPTR
			mov		FAT0,a			;FAT0 bevat de laagste byte van het sectornumer van de 1ste partitie
			inc		DPTR

			movx	a,@DPTR
			mov		FAT1,a			;FAT1 bevat de laagste byte van het sectornumer van de 1ste partitie
			inc		DPTR

			movx	a,@DPTR
			mov		FAT2,a			;FAT2 bevat de laagste byte van het sectornumer van de 1ste partitie
			inc		DPTR

			movx	a,@DPTR
			mov		FAT3,a			;FAT3 bevat de laagste byte van het sectornumer van de 1ste partitie
			inc		DPTR



;****Code om LBA te printen*******
;			mov		a,#001h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,FAT3
;			lcall		outbytelcd
;
;			mov		a,#003h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,FAT2
;			lcall		outbytelcd
;
;			mov		a,#005h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,FAT1
;			lcall		outbytelcd
;
;			mov		a,#007h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,FAT0
;			lcall		outbytelcd



;****Ophalen volumeID FAT32 partitie******;
			mov		a,FAT3
			push	acc
			mov		a,FAT2
			push	acc
			mov		a,FAT1
			push	acc
			mov		a,FAT0
			push	acc
			mov		a,#0

			lcall 		sd_read_block




			;TODO: WAARDEN NAKIJKEN! ->errors gooien indien nodig!;

			mov		DPH,#0h
			mov		DPL,#0Dh	;adres van secperclust
			movx	a,@DPTR
			mov		secperclust,a


;uitlezen aantal gereserveerde sectors, optellen bij eerdere LBA om zo de FAT uit te komen!
;gebruik van add32-routine: p47 documentatie
			mov		r7,FAT3	;laden ACC1 met LBA
			mov		r6,FAT2
			mov		r5,FAT1
			mov		r4,FAT0

			mov		r3,#0h	;gereserveerde sectors is maar 2 bytes lang
			mov		r2,#0h

			mov		dph,#0h	;Eerste byte ophalen, door endianness is dit de laagste byte
			mov		dpl,#0Eh
			movx	a,@DPTR
			mov		r0,a
			inc		DPTR	;Tweede byte ophalen, door endianness is dit de hoogste byte
			movx	a,@DPTR
			mov		r1,a

			lcall		add32	;oproepen van optelsubroutine, resultaat zit in r0 t.e.m r3

			mov		FAT3,r3	;FAT3 t.e.m. FAT0 bevat nu sectornummer van FAT! Yay!
			mov		FAT2,r2	;sectornummer FAT is gekend, volume ID nog in XRAM 0
			mov		FAT1,r1
			mov		FAT0,r0



;****Code om LBA te printen*******
;			mov		a,#001h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,FAT3
;			lcall		outbytelcd
;
;			mov		a,#003h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,FAT2
;			lcall		outbytelcd
;
;			mov		a,#005h
;			orl		a,#10000000b
;;			lcall		outcharlcd
;			mov		a,FAT1
;			lcall		outbytelcd
;
;			mov		a,#007h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,FAT0
;			lcall		outbytelcd
;

;****Berekenen sectornummer rootfolder*****
; = FAT + 2*sector/FAT, oftewel FAT + sector/FAT + sector/FAT
;sector/FAT is 4 bytes, van 0x24 tot 0x27, met 0x24 LSB

			mov		dph,#0h
			mov		dpl,#24h
			movx	a,@DPTR
			mov		r4,a
			inc		DPTR
			movx	a,@DPTR
			mov		r5,a
			inc 		DPTR
			movx	a,@DPTR
			mov		r6,a
			inc 		DPTR
			movx	a,@DPTR
			mov 	r7,a




			lcall		add32	;FAT zit reeds nog in r0 tem r3

			mov		dph,#0h
			mov		dpl,#24h
			movx	a,@DPTR
			mov		r4,a
			inc		DPTR
			movx	a,@DPTR
			mov		r5,a
			inc 		DPTR
			movx	a,@DPTR
			mov		r6,a
			inc 		DPTR
			movx	a,@DPTR
			mov 	r7,a

			lcall		add32	;twee keer uitvoeren, voor de zekerheid data opnieuw inladen

			mov		root3,r3
			mov		root2,r2
			mov		root1,r1
			mov		root0,r0

			mov		a,root3
			push	acc
			mov		a,root2
			push	acc
			mov		a,root1
			push	acc
			mov		a,root0
			push	acc
			mov		a,#1

			lcall		sd_read_block	;rootfolder bevindt zich nu XRAM1



			mov		a,FAT3
			push 	acc
			mov		a,FAT2
			push 	acc
			mov		a,FAT1
			push 	acc
			mov		a,FAT0
			push 	acc
			mov		a,#0
			lcall		sd_read_block


;****Code om LBA te printen*******
;			mov		a,#041h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,root3
;			lcall		outbytelcd
;
;			mov		a,#043h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,root2
;			lcall		outbytelcd
;
;			mov		a,#045h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,root1
;			lcall		outbytelcd
;
;			mov		a,#047h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,root0
;			lcall		outbytelcd

			pop		acc
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

			pop		acc
			pop		b
			pop		psw

			ret
