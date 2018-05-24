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

		mov		DPTR,#filenaam
		lcall		SD_read
		
		mov		dph,#00h	;klaarzetten datapointer
		mov		dpl,#00h	;

		mov		a,#000h	
		orl		a,#10000000b
		lcall		outcharlcd
		movx	 	a,@dptr
		lcall		outbytelcd
		inc		dptr
		movx	 	a,@dptr
		lcall		outbytelcd
		inc		dptr
		movx	 	a,@dptr
		lcall		outbytelcd
		inc		dptr
		movx	 	a,@dptr
		lcall		outbytelcd	;eerste 4 bytes van file tonen op LCD
	


		jmp		einde
	
	
einde:		jmp einde
		
filenaam:	db	"BROLDINGTXT"

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


