  .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  
  .import exit_to_basic  
  
  .import dns_set_hostname
  .import dns_resolve
  .import dns_ip
  .import dns_status
  .import  __CODE_LOAD__
  .import  __CODE_SIZE__
  .import  __RODATA_SIZE__
  .import  __DATA_SIZE__
  

	.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

	.word basicstub		; load address

basicstub:
	.word @nextline
	.word 2003
	.byte $9e
	.byte <(((init / 1000) .mod 10) + $30)
	.byte <(((init / 100 ) .mod 10) + $30)
	.byte <(((init / 10  ) .mod 10) + $30)
	.byte <(((init       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0

.segment "EXEHDR"  ;this is what gets put an the start of the file on the Apple 2
        .addr           __CODE_LOAD__-$11                ; Start address
        .word           __CODE_SIZE__+__RODATA_SIZE__+__DATA_SIZE__+4	; Size
        jmp init

.code

init:
    
  jsr print_cr
  jsr print_ip_config
 
  init_ip_via_dhcp 
 
;  jsr overwrite_with_hardcoded_dns_server
  jsr print_ip_config
  
  ldax #hostname_1
  jsr do_dns_query  

  ldax #hostname_2
  jsr do_dns_query  

  ldax #hostname_3
  jsr do_dns_query  

  ldax #hostname_4
  jsr do_dns_query  

  ldax #hostname_5
  jsr do_dns_query  

  ldax #hostname_6
  jsr do_dns_query  

  jmp exit_to_basic


do_dns_query:
  pha
  jsr print
  lda #' '
  jsr print_a
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a
  pla
  jsr dns_set_hostname
  jsr dns_resolve
  bcc :+
  ldax #dns_lookup_failed_msg
  jsr print
  jmp @print_dns_status
:  
  ldax #dns_ip
  jsr print_dotted_quad
@print_dns_status:  
  jsr print_cr
  lda dns_status
  jsr print_hex
  lda dns_status+1
  jsr print_hex
  jsr print_cr
  rts

overwrite_with_hardcoded_dns_server:
  ldx #3
:
  lda hardcoded_dns_server,x
  sta cfg_dns,x
  dex
  bpl :-
  rts



	.rodata


buffer1: .res 256
hostname_1:
  .byte "SLASHDOT.ORG",0          ;this should be an A record

hostname_2:
  .byte "VICTA.JAMTRONIX.COM",0   ;this should be a CNAME

hostname_3:
  .byte "WWW.JAMTRONIX.COM",0     ;this should be another CNAME

hostname_4:
  .byte "FOO.BAR.BOGUS",0         ;this should fail

hostname_5:                       ;this should work (without hitting dns)
  .byte "111.22.3.4",0

hostname_6:                       ;make sure doesn't get treated as a number
  .byte "3COM.COM",0

hardcoded_dns_server:
;.byte 61,9,195,193 
;.byte 64,127,100,12
.byte 205,171,3,65
.byte 69,111,95,106 