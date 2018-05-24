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



SD_append:

;print stackpointer
;			mov		a,#000h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,sp
;			lcall		outbytelcd

			push 		acc
			push 		b
			push		psw

			clr		nieuweclusternodig

;******************naam naar stack pushen*******************
SD_append0:
			mov		r0,#11 		;(tel af voor 11 8.3 filenaam)
			mov		r1,#0		;(tel op voor dptr te verzetten)


SD_append1:
			djnz		r0,SD_append2	;doe verder tot alle letters gepusht zijn
			jmp		SD_append3	;stop met pushen indien alle letters gepusht zijn

SD_append2:
			mov		a,r1
			inc 		r1
			movc		a,@a+dptr
			push		acc
			jmp 		SD_append1


SD_append3:
;***************einde naam naar stack****************************
			lcall		file_entry_search	;zoekt naar naam,
								;geeft filelengte terug in filesize3 tem filesize0
;kijken hoeveel sectoren de filelengte overspant
;dit doen door te delen door 512 (shift over 9 bits)
;restwaarde berekenen door r1 en r0 al eerst te shiften over 9 bits
;dit zijn de hoeveelheid bytes in de laatste (niet volgeschreven) sector

			mov		r1,filesize1
			mov		r0,filesize0

;filesize printen
;			mov		a,#000h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,filesize3
;			lcall 		outbytelcd
;			mov		a,filesize2
;			lcall		outbytelcd
;			mov		a,filesize1
;			lcall 		outbytelcd
;			mov		a,filesize0
;			lcall		outbytelcd

			mov		a,r1
			anl		a,#00000001b;r7 & r6 bevatten nu de rest van de deling
			mov		r7,a
			mov		a,r0
			mov		r6,a
;nadat de rest is uitgerekend, kunnen we het totaal aantal sectoren uitrekenen
			mov		r3,filesize3
			mov		r2,filesize2
			mov		r1,filesize1
			mov		r0,filesize0

			mov		r4,#9		;logical shift over 9 bits
			lcall		shiftright32
;r3 tot r0 bevatten nu de hoeveelheid sectoren
			mov		filesize3,r3
			mov		filesize2,r2
			mov		filesize1,r1
			mov		filesize0,r0

;aantal sectoren printen + restwaarde
;			mov		a,#000h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,r3
;			lcall 		outbytelcd
;			mov		a,r2
;			lcall		outbytelcd
;			mov		a,r1
;			lcall		outbytelcd
;			mov		a,r0
;			lcall		outbytelcd
;			mov		a,r7
;			lcall		outbytelcd
;			mov		a,r6
;			lcall		outbytelcd



;kijken hoeveel clusters we hebben (in registerbank 1)
;(aantal sectoren delen door secperclust)
;de restwaarde is hier in de hoeveelste sector van de laatste cluster we moeten schrijven
;kan tussen 0 en secperclust-1 liggen
;hier moeten we zelf een masker aanmaken voor de restwaarde, want het masker is afhankelijk van secperclust
			setb		rs0
			clr		rs1

			mov		r4,#01h		;waarde om na te kijken met secperclust
			mov		r5,#00h		;teller
			mov		r6,#000h	;r6 gaat maskerwaarde bijhouden, kan maximaal 255 zijn
;we gaan r4 telkens vermenigvuldigen met 2 (shift naar links) totdat het gelijk is aan secperclust
;en tegelijkertijd maken we ons masker door met de carry te shiften naar links (zodat er altijd een 1 verschijnt rechts)

SD_append4:
			mov		a,r4
			cjne		a,secperclust,SD_append5
			jmp		SD_append6

SD_append5:
			mov		a,r4
			rl		a
			mov		r4,a
			inc		r5
			setb		c
			mov		a,r6
			rlc		a			;1tjes in masker rotaten (carry telkens 1)
			mov		r6,a

;luswaarde uitprinten + masker + teller + secperclust
;			mov		a,#000h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,r4
;			lcall		outbytelcd
;			mov		a,r5
;			lcall		outbytelcd
;			mov		a,r6
;			lcall		outbytelcd
;			mov		a,secperclust
;			lcall		outbytelcd

			jmp		SD_append4


SD_append6:
;nu weten we hoeveel we moeten opschuiven, en kunnen we het masker toepassen om de restwaarde van clusters
;te bekomen

			mov		r3,filesize3
			mov		r2,filesize2
			mov		r1,filesize1
			mov		r0,filesize0

			mov		a,r0
			anl		a,r6		;masker toepassen
			mov		r6,a		;r6 bevat nu de restwaarde



;op voorhand uitrekenen of er een nieuwe cluster zou nodig zijn bij overflow van sector
;maw: nakijken of secperclust - 1 gelijk is aan de restwaarde (in r6)
			mov		a,secperclust
			subb		a,#01h			;nakijken of het nodig is om een nieuwe cluster aan te maken
			subb		a,r6			;bij overflow in sector bij het wegschrijven van data
			cjne		a,#00h,SD_append7
			setb		nieuweclusternodig	;bit om nieuwe cluster nodig aan te duiden of niet
SD_append7:

			;vervolgens r0 tem r3 delen door secperclust (= shiften over tellerwaarde van eerder)
			mov		a,r5
			mov		r4,a
			lcall		shiftright32 	;r0 tem r3 bevat nu hoeveel clusters we nodig hebben, r6 bevat restwaarde

			mov		filesize3,r3
			mov		filesize2,r2
			mov		filesize1,r1
			mov		filesize0,r0	;filesize bevat nu het aantal clusters


			mov		a,FAT3
			push		acc
			mov		a,FAT2
			push		acc
			mov		a,FAT1
			push		acc
			mov		a,FAT0
			push		acc
			mov		a,#0

			lcall		SD_read_block

;de volgende stap is om het aantal keer dat er clusters zijn, de FAT daisy chain te volgen om zo
;op de laatste cluster uit te komen. Hier moeten we vervolgens appenden.
			setb		RS1
			setb		RS0		;registerbank 4

			mov		r3,filesize3
			mov		r2,filesize2
			mov		r1,filesize1
			mov		r0,filesize0
			mov		r7,#00h
			mov		r6,#00h
			mov		r5,#00h
			mov		r4,#01h		;registers klaarmaken, we gaan iedere lus r7 tem r4 aftrekken van r3 tem r0

;clusterwaarde uitprinten + restwaarde (klopt)
;			mov		a,#000h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,sector3
;			lcall		outbytelcd
;			mov		a,sector2
;			lcall		outbytelcd
;			mov		a,sector1
;			lcall		outbytelcd
;			mov		a,sector0
;			lcall		outbytelcd
;			mov		a,r6

SD_append8:
;SD_append4 of er uberhaupt wel daisychain nodig is, zo niet skip naar sector inladen
;maw: is r3 tem r0 == nul?
			mov		r4,#00h	;nu bevat register4 tem register7 volledig nul
			lcall		cmp32
			jb		F0,SD_append11  ;als f0 staat, dan zijn de twee gelijk


;r3 tem r0 != nul:
;volgen gelinkte lijst van clusters tot we aan de laatste cluster belanden
;door telkens r3 tot r0 te decrementeren (adhv sub32)
SD_append9:
			mov		r4,#00h	;nu bevat register4 tem register7 volledig nul
			lcall		cmp32
			jb		F0,SD_append10	;als f0 staat, dan zijn de twee gelijk

;testprint
;			mov		a,#040h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,sector3


			mov		a,#000h

			mov		dph,fatentry1
			mov		dpl,fatentry0

			movx		a,@DPTR			;fatentry inlezen
			mov		fatentry3,a
			mov		sector3,a
			inc		DPTR
			movx		a,@DPTR
			mov		fatentry2,a
			mov		sector2,a
			inc		DPTR
			movx		a,@DPTR
			mov		fatentry1,a
			mov		sector1,a
			inc		DPTR
			movx		a,@DPTR
			mov		fatentry0,a
			mov		sector0,a

			lcall		cluster_to_fatentry



			mov		r4,#01h	;nu bevat register4 tem register7 1
			lcall		sub32
			jmp		SD_append9


			;laatste cluster gevonden, joepie
SD_append10:




;weer in registerbank 1, waar r6 het aantal sectoren in de laatste cluster bevat

;sectoradres van de cluster uitreken adhv cluster_to_sector
			mov		a,sector3
			push		acc
			mov		a,sector2
			push		acc
			mov		a,sector1
			push		acc
			mov		a,sector0
			push		acc

			lcall		cluster_to_sector	;sector3 tem sector0 bevat nu het sectoradres van de cluster die we zoeken
			pop		acc
			pop		acc
			pop		acc
			pop		acc

			;sectoradres printen!
;			mov		a,#040h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,sector3
;			lcall 		outbytelcd
;			mov		a,sector2
;			lcall		outbytelcd
;			mov		a,sector1
;			lcall		outbytelcd
;			mov		a,sector0
;			lcall		outbytelcd			;print om einde te tonen

SD_append11:	setb		rs0
			clr		rs1

;aantal restsectoren printen
;			mov		a,#000h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,r6
;			lcall 		outbytelcd

;vervolgens het aantal sectoren dat we al in de cluster zitten (register6) erbij optellen
			mov		a,r6
			mov		r4,a
			mov		r7,#00h
			mov		r6,#00h
			mov		r5,#00h

			mov		r3,sector3
			mov		r2,sector2
			mov		r1,sector1
			mov		r0,sector0

			lcall		add32	;r3 tem r0 bevat nu het sectoradres waarin we moeten schrijven

			mov		sector3,r3
			mov		sector2,r2
			mov		sector1,r1
			mov		sector0,r0


;sectoradres printen!
;			mov		a,#000h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,sector3
;			lcall 		outbytelcd
;			mov		a,sector2
;			lcall		outbytelcd
;			mov		a,sector1
;			lcall		outbytelcd
;			mov		a,sector0
;			lcall		outbytelcd

;sectoradres van te beginnen sector is gevonden, inladen in xram ( in xram4)
;register 1 & 0 worden hier gebruikt als stockage van DPTR
;register3 wordt gebruikt als teller
			clr		rs0
			clr		rs1		;r6 & r7 bevatten hier de restwaarde (byte offset voor in geheugen)
			clr		f0		;f0 clearen voor later te gebruiken
			mov		a,sector3
			push		acc
			mov		a,sector2
			push		acc
			mov		a,sector1
			push		acc
			mov		a,sector0
			push		acc
			mov		a,#3
			lcall		SD_read_block	;xram 4 bevat nu laatste sector vd te appenden file

;uitrekenen waar we moeten schrijven om te appenden
;r6 & r7 bevatten hier de offset, hierbij tellen we nog eens 600h op omdat we in xram4 werken
			mov		a,r6
			mov		r0,a
			mov		a,r7
			mov		r1,a
			mov		r5,#06h
			mov		r4,#00h
			lcall		add16	;r0 en r1 bevatten nu de eerste plek waar naar geschreven moet worden in xram
;waarden terug in r6 & r7 steken = schrijfDPTR
			mov		a,r1
			mov		r7,a
			mov		a,r0
			mov		r6,a		;r6 & r7 bevatten nu de eerste plek
			mov		r0,#00h		;r0 gaat gebruikt worden als tellerwaarde

			mov		r5,#04h		;leesDPTR klaarzetten
			mov		r4,#00h



SD_append12:
;SD_append12 gaat byte-per-byte van xram3 naar xram4 schrijven
;de DPTR voor xram4 wordt opgeslagen in r7&r6 (schrijfDPTR),
;de DPTR voor xram3 wordt opgeslagen in r5&r4 (leesDPTR)
;SD_append12 kent 2 stopcondities:
;	*er is geen data meer om weg te schrijven (leesDPTR wijst naar 00h)
;	*het volledige xram3 is weggeschreven (teller r0 == 512, en overflowbit F0 == 1)
;
;indien er over xram4 geschreven wordt (schrijfDPTR == 512) dan wordt bekeken of er een nieuwe cluster moet
;aangemaakt worden (SD_append17) of enkel een nieuwe sector nodig is (SD_append22)

;de twee datapointers afdrukken
;			mov		a,#000h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,r7
;			lcall 		outbytelcd
;			mov		a,r6
;			lcall		outbytelcd
;			mov		a,r5
;			lcall		outbytelcd
;			mov		a,r4
;			lcall		outbytelcd
;			mov		a,r0
;			lcall		outbytelcd

 			mov		dph,r5	;leesDPTR inladen
			mov		dpl,r4
			movx		a,@DPTR	;a bevat nu wat geschreven moet worden
			inc		DPTR	;leesDPTR al eentje verder zetten
			mov		r5,dph
			mov		r4,dpl	;leesDPTR opslagen

;meteen nakijken of de waarde niet 00h is - maw of er nog data is dat geschreven moet worden
			cjne		a,#00h,SD_append13
			jmp		SD_append16

SD_append13:
;indien niet 00h, schrijven naar schrijfDPTR
			inc		r0	;teller incrementeren
			mov		dph,r7	;schrijfDPTR inladen
			mov		dpl,r6
			movx		@DPTR,a	;ingelezen waarde wegschrijven naar schrijfDPTR
			inc		DPTR	;schrijfDPTR al incrementeren
			mov		r7,dph
			mov		r6,dpl	;schrijfDPTR opslaan

;nakijken of hele xram blok is weggeschreven
;dit gebeurt door bij de eerste keer dat r0 gelijk is aan FFh een bit F0 te raisen
;indien zowel de bit staat, alsdat r0 gelijk is aan FFh, dan is de volledige blok weggeschreven (512 bytes)
			mov		a,r0
			cjne		a,#0FFh,SD_append14
			jb		f0,SD_append16
			mov		r0,#00h
			setb		f0

;nakijken of er een nieuwe cluster/sector nodig is door r6&r7 te vergelijken met 07FFh
;en vervolgens te kijken of de nieuweclusternodig vlag staat
SD_append14:
			mov		a,r6
			cjne		a,#00h,SD_append15	;nakijken of we niet over sector-/clustergrens hebben geschreven
			mov		a,r7
			cjne		a,#008h,SD_append15

			jb		nieuweclusternodig,SD_append17
			ljmp		SD_append22

SD_append15:		jmp		SD_append12
;einde SD_append12


;tussensprong om limitaties smalljump te overkomen
SD_append16:			jmp		SD_append27

SD_append17:
;gaat nieuwe cluster maken, door te zoeken naar de eerstvolgende lege FAT entry (00h)
;en hiervan het clusteradres te berekenen
			mov		a,#00Dh
			orl		a,#10000000b
			lcall		outcharlcd
			mov		a,#96h
			lcall		outbytelcd

;leesDPTR & teller opslaan (schrijfDPTR wordt gereset op 600h)
			mov		a,r5
			push		acc
			mov		a,r4
			push		acc
			mov		a,r0
			push		acc

;huidige sector wegschrijven
			mov		a,r0		;tellerwaarde overzetten naar r7
			mov		r7,a
			mov		a,sector3
			push		acc
			mov		a,sector2
			push		acc
			mov		a,sector1
			push		acc
			mov		a,sector0
			push		acc
			mov		a,#3
			lcall		SD_write_block	;block terug weggeschreven

;zoeken naar nieuwe FAT entry
			mov		a,FAT3
			push		acc
			mov		a,FAT2
			push		acc
			mov		a,FAT1
			push		acc
			mov		a,FAT0
			push		acc
			mov		a,#00h	;FAT opnieuw inladen
			lcall		SD_read_block


			mov		dph,#00h
			mov		dpl,#07h	;DPTR op 7 plaatsen,
							;eerste twee entries zijn gereserveerd

;magische methode - niet in verder kijken
;enorm vage manier om een lege sector te vinden, maar werkt wel (denk ik)

SD_append18:		inc		DPTR
SD_append19:		inc		DPTR
SD_append20:		inc		DPTR
SD_append21:		inc		DPTR

			movx		a,@DPTR
			cjne		a,#00h,SD_append18
			inc		DPTR
			movx		a,@DPTR
			cjne		a,#00h,SD_append19
			inc		DPTR
			movx		a,@DPTR
			cjne		a,#00h,SD_append20
			inc		DPTR
			movx		a,@DPTR
			cjne		a,#00h,SD_append21

;keigoed, er is een lege plek hey
;clusternummer uitrekenen
			mov		r1,dph	;DPTR delen door 4 om clusternummer te verkrijgen
			mov		r0,dpl
			mov		r5,#00h
			mov		r4,#04h
			lcall		div16	;nu weten we ons clusternummer

;vervolgens moeten we de FAT entry van onze vorige cluster aanpassen zodat deze wijst naar de nieuwe
;cluster, en moeten de FAT entry van onze nieuwe cluster aanpassen zodat hij wijst naar FFFFFFFFh

			mov		a,fatentry1
			push		acc
			mov		a,fatentry0
			push		acc
			mov		a,#00h
			push		acc
			mov		a,#00h
			push		acc
			mov		a,r1
			push		acc
			mov		a,r0
			push		acc
			lcall		edit_FAT
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc
			pop		acc

			mov		fatentry3,#00h
			mov		fatentry2,#00h
			mov		fatentry1,r1		;fatentryoffset van nieuwe cluster uitrekenen
			mov		fatentry0,r0
			lcall		cluster_to_fatentry

			mov		a,fatentry1
			push		acc
			mov		a,fatentry0
			push		acc
			mov		a,#0ffh
			push		acc
			mov		a,#0ffh
			push		acc
			mov		a,#0ffh
			push		acc
			mov		a,#0ffh
			push		acc
			lcall		edit_fat	;fat aanpassen


;sectoradres van de nieuwe cluster uitrekenen
			mov		a,#00h
			push		acc
			mov		a,#00h
			push		acc
			mov		a,r1
			push		acc
			mov		a,r0
			push		acc
			lcall		cluster_to_sector;nu zit in sector0 tem sector3 de juiste waarde
			pop		acc
			pop		acc
			pop		acc
			pop		acc

			mov		a,#3
			lcall		xram_nul_maken	;beginnen met een schone block in het xram
			mov		a,r7
			mov		r0,a
			mov		r7,#06h	;schrijfDPTR resetten
			mov		r6,#00h

			pop		acc	;teller inladen
			mov		r0,a
			pop		acc	;leesDPTR terug inladen
			mov		r4,a
			pop		acc
			mov		r5,a
			jmp		SD_append12

SD_append22:
;nieuwe sector starten
			mov		a,#00Dh
			orl		a,#10000000b
			lcall		outcharlcd
			mov		a,#69h
			lcall		outbytelcd

;leesDPTR opslaan (schrijfDPTR wordt gereset op 600h)
			mov		a,r0
			push		acc
			mov		a,r4
			push		acc
			mov		a,r5
			push		acc

;huidige sector wegschrijven
			mov		a,sector3
			push		acc
			mov		a,sector2
			push		acc
			mov		a,sector1
			push		acc
			mov		a,sector0
			push		acc
			mov		a,#03h
			lcall		SD_write_block

;xram clearen
			mov		a,#03h
			lcall		xram_nul_maken
			mov		r7,#06h
			mov		r6,#00h	;resetten schrijfpointer

;sectorwaarde incrementeren op pittig vage manier
			mov		a,sector0
			cjne		a,#0ffh,SD_append26	;indien sector0 niet ffh is, gewoon incrementeren
			mov		a,sector1
			cjne		a,#0ffh,SD_append25	;indien het vorige getal ffh, maar sector1 != ffh
							;sector1 & sector0 incrementeren
			mov		a,sector2
			cjne		a,#0ffh,SD_append24	;indien de vorige ffh, maar sector2 niet
							;alle drie incrementeren

SD_append23:			inc		sector3		;indien alle sector2 tem sector0 == ffh: alles incrementeren!
SD_append24:			inc		sector2
SD_append25:			inc		sector1
SD_append26:			inc		sector0

			mov		r7,#06h		;schrijfDPTR resetten
			mov		r6,#00h

			pop		acc		;teller inladen
			mov		r5,a
			pop		acc		;leesDPTR weer terugzetten
			mov		r4,a
			pop		acc
			mov		r0,a
			jmp		SD_append12		;verder lussen


;het einde!
SD_append27:

;sector weer wegschrijven naar de SD kaart
			mov		a,sector3
			push		acc
			mov		a,sector2
			push		acc
			mov		a,sector1
			push		acc
			mov		a,sector0
			push		acc
			mov		a,#03
			lcall		SD_write_block

;afprinten sectoradres
			mov		a,#040h
			orl		a,#10000000b
			lcall		outcharlcd
			mov		a,sector3
			lcall 		outbytelcd
			mov		a,sector2
			lcall		outbytelcd
			mov		a,sector1
			lcall		outbytelcd
			mov		a,sector0
			lcall		outbytelcd

;de filesize nog eens opzoeken adhv file_entry_search
			lcall		file_entry_search

;nieuwe filesize uitrekenen
			mov		r7,filesize3
			mov		r6,filesize2
			mov		r5,filesize1
			mov		r4,filesize0
			mov		r3,#00h
			mov		r2,#00h
			mov		r1,#00h
			jnb		f0,SD_append28	;afhankelijk van f0 r1 op 1 zetten
			mov		r1,#01h
SD_append28:
			lcall		add32	;nieuwe filesize in r3 tem r0

			mov		a,r3
			push		acc
			mov		a,r2
			push		acc
			mov		a,r1
			push		acc
			mov		a,r0
			push		acc
			lcall		edit_size	;size aanpassen

;filenaam van de stack poppen
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
			pop		acc




			pop 		acc
			pop		b
			pop		psw

;print stackpointer
;			mov		a,#001h
;			orl		a,#10000000b
;			lcall		outcharlcd
;			mov		a,sp
;			lcall		outbytelcd

			ret
