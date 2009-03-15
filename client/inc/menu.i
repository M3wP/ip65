
OPTIONS_PER_PAGE = $10
.bss

number_of_options: .res 2
current_option: .res 2
temp_option_counter: .res 2

first_option_this_page: .res 2
options_shown_this_page: .res 1
options_table_pointer: .res 2
jump_to_prefix: .res 1
last_page_flag: .res 1

get_current_byte: .res 4
  

.code


;on entry, AX should point to the list of null terminated option strings to be selected from
;on exit, AX points to the selected string
select_option_from_menu:

  stax options_table_pointer
  stax get_current_byte+1
;set the 'LDA' and RTS' opcodes for the 'get current byte' subroutine, which is self-modified-code, hence must be located in RAM not ROM
  lda #$ad  ;opcode for LDA absolute
  sta get_current_byte
  lda #$60  ;opcode for RTS
  sta get_current_byte+3  

  lda #0
  sta current_option
  sta current_option+1
  sta number_of_options
  sta number_of_options+1


;count the number of options. this is done by scanning till we find a double zero, incrementing the count on each single zero
@count_strings:
  jsr @skip_past_next_null_byte
  inc number_of_options
  bne :+
  inc number_of_options+1
:
  jsr get_current_byte
  bne @count_strings 

 jmp @display_first_page_of_options

@skip_past_next_null_byte:
  jsr @move_to_next_byte
  jsr get_current_byte
  bne @skip_past_next_null_byte  
  jsr @move_to_next_byte
  rts
  

@move_to_next_byte:
  inc get_current_byte+1
  bne :+
  inc get_current_byte+2
:  
  rts

;move the ptr along till it's pointing at the whatever is the value of current_option
@move_to_current_option:
  ldax  options_table_pointer
  stax get_current_byte+1
  lda #0
  sta temp_option_counter
  sta temp_option_counter+1

@skip_over_strings:
  lda temp_option_counter
  cmp current_option
  bne  @not_at_current_option
  lda temp_option_counter+1
  cmp current_option+1
  bne @not_at_current_option
  rts
@not_at_current_option:    
  jsr @skip_past_next_null_byte

  inc temp_option_counter
  bne :+
  inc temp_option_counter+1
:    
  jmp @skip_over_strings  




  
@display_first_page_of_options:
  lda   #0
  sta   first_option_this_page
  sta   first_option_this_page+1
  

@print_current_page:
  lda   first_option_this_page  
  sta   current_option
  lda   first_option_this_page+1
  sta   current_option+1
  lda   #0
  sta   last_page_flag
  
  jsr   @move_to_current_option
  
  
  jsr   cls
  
  ldax  #select_from_following_options
  jsr   print
  

;  lda   #'('
;  jsr   print_a
;  lda   #'$'
;  jsr   print_a
;  lda   first_option_this_page+1
;  jsr   print_hex
;  lda   first_option_this_page
;  jsr   print_hex
;  lda   #'/'
;  jsr   print_a
;  lda   #'$'
;  jsr   print_a
;  lda   number_of_options+1
;  jsr   print_hex
;  lda   number_of_options
;  jsr   print_hex
;  lda   #')'
;  jsr   print_a
;  jsr   print_cr
  
  
  jsr   print_cr
  lda   #0
  sta   options_shown_this_page

@print_loop:
  
  lda   options_shown_this_page 
  clc
  adc   #'A'
  jsr print_a
  
  lda  #')'
  jsr print_a

  lda  #' '
  jsr print_a

;  lda get_current_byte+2
;  jsr print_hex
;  lda get_current_byte+1
;  jsr print_hex
 
  lda get_current_byte+1
  ldx get_current_byte+2
 
  jsr print
  jsr print_cr
  jsr @skip_past_next_null_byte
  inc current_option
  bne :+
  inc current_option+1
:  
  lda current_option
  cmp number_of_options
  bne :+
  lda current_option+1
  cmp number_of_options+1
  bne :+
  inc last_page_flag
  jmp @print_instructions_and_get_keypress
:  
  inc options_shown_this_page
  lda options_shown_this_page
  cmp #OPTIONS_PER_PAGE
  beq @print_instructions_and_get_keypress
  jmp @print_loop

@jump_to:
  jsr print_cr
  ldax #jump_to_prompt
  jsr print
  lda #'?'
  
  jsr get_key
  ora #$80      ;set the high bit
  
  
  sta jump_to_prefix
  ldax  options_table_pointer
  stax get_current_byte+1
  lda #0
  sta current_option
  sta current_option+1
  
@check_if_at_jump_to_prefix:  
  jsr get_current_byte
  ora #$80      ;set high bit
  cmp jump_to_prefix
  beq @at_prefix
  jsr @skip_past_next_null_byte
  inc  current_option
  bne :+
  inc  current_option+1
:  
  jsr get_current_byte
  bne @check_if_at_jump_to_prefix
  jsr beep  ;if we got to the end of the options table without finding the char we want, then sound a beep
  jmp @jump_to_finished
@at_prefix:
  lda current_option
  sta first_option_this_page
  lda current_option+1
  sta first_option_this_page+1
@jump_to_finished:  
   jmp  @print_current_page  


@print_instructions_and_get_keypress:
  lda   number_of_options+1
  bne   @navigation_instructions
  lda   number_of_options
  cmp   #OPTIONS_PER_PAGE
  bcc   :+
@navigation_instructions:  
  ldax  #navigation_instructions
  jsr   print  
:  
@get_keypress:
  lda #'?'

  jsr get_key

 jsr print_hex
;  @fixme:
;    jmp @fixme

  cmp #'/'+$80
  beq @jump_to
  cmp #$95
  beq @forward_one_page
  cmp #$8a
  beq @forward_one_page
  cmp #$8b
  beq @back_one_page
  cmp #$88
  beq @back_one_page
  
  ora #$e0      ;make it a lower case letter with high bit set
  sec
  sbc #$e1
  bcc @get_keypress ;if we have underflowed, it wasn't a valid option
  cmp #OPTIONS_PER_PAGE-1
  beq @got_valid_option
  bpl @get_keypress ;if we have underflowed, it wasn't a valid option


@got_valid_option:
  clc
  adc first_option_this_page
  sta  current_option
  lda #0
  adc first_option_this_page+1

  sta  current_option+1

  jsr  @move_to_current_option
  ldax get_current_byte+1
  
  rts


@forward_one_page:  
  clc
  lda last_page_flag
  beq :+
@back_to_first_page:  
  jmp @display_first_page_of_options
:  
  lda first_option_this_page
  adc #OPTIONS_PER_PAGE
  sta first_option_this_page
  bcc :+
  inc first_option_this_page+1
:

  jmp @print_current_page

@back_one_page:  
  sec
  lda first_option_this_page
  sbc #OPTIONS_PER_PAGE
  sta first_option_this_page
  lda first_option_this_page+1
  sbc #0
  sta first_option_this_page+1    
  bmi @show_last_page_of_options
  
  jmp @print_current_page
@show_last_page_of_options:
  sec
  lda number_of_options  
  sbc #OPTIONS_PER_PAGE
  sta first_option_this_page
  lda number_of_options+1
  sbc #0
  sta first_option_this_page+1
  bmi @back_to_first_page
  jmp @print_current_page

.rodata
select_from_following_options: .byte "SELECT ONE OF THE FOLLOWING OPTIONS:",13,0
navigation_instructions: .byte 13,"ARROW KEYS NAVIGATE BETWEEN MENU PAGES",13
.byte "/ TO JUMP ",13
.byte 0
jump_to_prompt: .byte "JUMP TO:",0