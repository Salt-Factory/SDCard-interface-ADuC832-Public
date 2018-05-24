$nolist	
$nomod51
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\mide\reg832.pdf)
$list

stack_init	equ	07fh
			org	0000h
			ljmp	start

start:		
		mov		sp,#stack_init

		lcall 		initlcd
		lcall 		lcdlighton
		lcall		sd_init
		lcall 		FAT_init
		
;xram clearen
		mov		a,#3h
		lcall		xram_nul_maken
		
		mov		a,#2h
		lcall		xram_nul_maken
		
;wat brol wegschrijven in xram als test		
		mov		DPTR,#josse
		mov		r0,#00h
		mov		r1,#250
		mov		r2,#04h
		mov		r3,#00h

noeens:	
		mov		DPTR,#josse
		mov		a,r0
		movc		a,@a+dptr
		dec		r1
		inc		r0
		
		mov		dph,r2
		mov		dpl,r3
		movx		@DPTR,a
		inc		DPTR
		mov		r2,dph
		mov		r3,dpl
		
		cjne		r1,#00h,noeens
		
		mov		DPTR,#filenaam
		lcall		SD_append

		mov		a,#04Dh
		orl		a,#10000000b
		lcall		outcharlcd
		mov	 	a,#69h
		lcall		outbytelcd
		jmp		einde
	
	
einde:		jmp einde
		
filenaam:	db	"BROLDINGTXT"
josse:		db	"0123456789111315161719212325272931333537394143454749012345678911131516171921232527293133353739414345474901234567891"
		db	"1131516171921232527293133353739414345474901234567891113151617192123252729313335373941434547490123456789111315161719212325272931333537394143454749"

$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\mide\aduc800_mideA.inc)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\RAW\SD_CARD_RAW.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\FAT_init.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\sector_nullen_maken.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\edit_FAT.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\cluster_to_sector.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\cluster_to_fatentry.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\edit_size.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\file_entry_search.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\SD_read.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\SD_overwrite.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\SD_append.asm)
$include (Z:\home\saltfactory\Documents\Projectjes\BachProef\SDCard-Aduc832\Library\xram_nul_maken.asm)



end


