
  
.data
	count_random: .word 0
	guess_int: .word 0 #accumulator variable that stores the guess
	
	card_int: .word 1 #stores the card number
	
	generate_count_int: .word 0 #count variable to control generate loop
	
	shown_index: .word 0 #stores the current index of the shown array
	
	display_index: .word 0 #stores the current address offset(index) of the display array
	
	shown_arr: .word 0, 0, 0, 0, 0, 0 #stores the card numbers that have already been displayed
	
	display_arr: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 #stores the values that exist on the card 'n'
	
	card_worth_arr: .word 1, 2, 4, 8, 16, 32 #stores the 'worth' of each card, 2^(card_int - 1)
	
	JumpTable: .word L0, L1, L2, L3, L4, L5
	
	prompt1: .asciiz "\nThink of a number between 1 and 63. Six cards will be displayed. After the last one, your number will be revealed. Enter 1 to start, or 0 to exit: "
	
	prompt2: .asciiz "Is your number on this card? Enter 1 for yes, or 0 for no: "
	
	prompt3: .asciiz "The number you were thinking of was: "
	
	card1header: .asciiz "\nCARD ONE \n"
	
	card2header: .asciiz "\nCARD TWO \n"
	
	card3header: .asciiz "\nCARD THREE \n"
	
	card4header: .asciiz "\nCARD FOUR \n"
	
	card5header: .asciiz "\nCARD FIVE \n"
	
	card6header: .asciiz "\nCARD SIX \n"
	
	cardOutline: .asciiz "---------------------------\n"
	
	cardBorder: .asciiz "|"
	
	cardSpace: .asciiz " "
		
	newLine: .asciiz "\n"
	
	exception: .asciiz "\nThe input was wrong!"

.text
.globl MAIN

MAIN:
	     li $v0, 4
	     la $a0, prompt1
	     syscall
	     li $v0, 5
	     syscall
	     beq $v0, $zero, EXIT
	     addi $t0, $zero, 1
	     sw $zero, count_random
	     beq $v0, $t0, RANDOMIZE
	     li $v0, 4
	     la $a0, exception
	     syscall
	     j MAIN

#Randomly select a card 'n' without displaying the same card twice, utilizing card_int and shown_arr
RANDOMIZE:
		lw $t0, count_random
		beq $t0, 6, ANSWER
		li $a1, 6   # set the upper bound
		li $v0, 42  #geenrate random number
		syscall
		move $t1, $a0 #move from $a0 to $t1
		#add $t2, $zero, $t1 #hold genrated number in $t2 temporary
		sll  $t2, $t1, 2	#get array index of genrated number	
		lw $t3, shown_arr($t2)  #check if the random card number already generated
		bne $t3, $zero, RANDOMIZE  #if generated try to generate new card number
		addi $t1, $t1, 1
		sw $t1, card_int
		sw $t1, shown_arr($t2)
		addi $t0, $t0, 1
		sw $t0, count_random
		j GENERATE

#Generates the values of card 'n'
GENERATE:
	lw $t0, generate_count_int		#load generate_count_int for loop control
	beq $t0, 64, CLEAR_GENERATE_DATA	#if display_arr is filled, exit loop
	
	lw $t1, card_int			#load card_int
	sub $t1, $t1, 1				#card_int - 1
	mul $t1, $t1, 4				#address offset1
	la $t2, card_worth_arr			#load base address of card_worth_arr
	add $t2, $t1, $t2			#calculate address of 2^(card_int-1) value
	lw $t1, ($t2)				#load 2^(card_int-1) value
	
	and $t3, $t0, $t1			#generate_count_int AND 2^(card_int - 1) to determine if current value exists on current card
	add $a0, $t0, $zero			#pass generate_count_int to argument register $a0
	bne $t3, $zero, UPDATE_DISPLAY_ARR	#if result of AND operation is not zero, add generate_count_int to display_arr
	addi $t0, $t0, 1			#increment generate_count_int
	sw $t0, generate_count_int		#update generate_count_int in memory
	j GENERATE				#restart the loop

#Stores the values of card 'n' into display_arr
UPDATE_DISPLAY_ARR:
	la $t0, display_arr			#load base address of display_arr
	lw $t1, display_index			#load value of display_index
	add $t0, $t0, $t1			#add base address and address offset
	lw $t2, ($t0)				#load value at the calculated address
	bne $t2, 0, UPDATE_DISPLAY_INDEX	#if this value is not zero, increment the display index
	sw $a0, ($t0)				#store value of generate_count_int into display_arr
	addi $a0, $a0, 1			#increment generate_count_int
	sw $a0, generate_count_int		#update generate_count_int in memory
	j GENERATE				#return to GENERATE loop

#Increments display_index by 4
UPDATE_DISPLAY_INDEX:
	lw $t1, display_index			#load the current display_index
	addi $t1, $t1, 4			#increment display_index by 4
	sw $t1, display_index			#update display_index in memory
	j UPDATE_DISPLAY_ARR			#return to UPDATE_DISPLAY_ARR
	
#Sets display_index and count_int back to 0
CLEAR_GENERATE_DATA:
	sw $zero, display_index
	sw $zero, generate_count_int
	j SHOW_CARD

#Print display_arr
SHOW_CARD:
	
	la $t4, JumpTable			#t4 is address of JumpTable;
	li $t3, 6 				#t4 is a constant 6
	li $t2, 4				#t2 is a constant 4 for subtraction
	lw $t1, card_int			#t1 is card_int
	
	beq $t1, $t3, L5    			#test to see if card_int contains 6, jump if true.
	sll $t1, $t1, 2				#$t0 = index * 4 
	sub $t1, $t1, $t2			#$t1 is offset by 1 so need to shift down by 4
	add  $t1, $t1, $t4			#$t1 + $t4 gives actual address of jumpTable
	lw  $t0, 0($t1)				#Load location of needed branch
	jr  $t0             			#jump to address in $t0
	
#cases In Jump table depending on card number	
L0:    	li $v0, 4     				#case 0
	la $a0, card1header			#print card1 header
	syscall 
	
     	j LOOP					#jump loop
     	
L1:   	li $v0, 4  	 			#case 1
	la $a0, card2header			#print card2 header
	syscall 
	
      	j LOOP					#jump loop
      	
L2:    	li $v0, 4  	   			#case 2
	la $a0, card3header			#print card3 header
	syscall 
	
      	j LOOP					#jump loop
      	
L3:    	li $v0, 4     				#case 0
	la $a0, card4header			#print card1 header
	syscall 
	
     	j LOOP					#jump loop
     	
L4:   	li $v0, 4  	 			#case 1
	la $a0, card5header			#print card5 header
	syscall 
	
      	j LOOP					#jump loop
      	
L5:  	     					#default case
	li $v0, 4				#print card6 header
	la $a0, card6header
	syscall 
	
	addi $t0, $zero, 0 			#set loop iterator to 0
	j LOOP					#jump loop

LOOP:

	li $v0, 4				#print outline 
	la $a0, cardOutline
	syscall 
	
	addi $t0, $zero, 0  			# set counter t0 to 0 
	addi $t1, $zero, 32 			# set counter t1 to 28, index starts at 0 and not 4 so thats why its down 1 spot(4 bytes)
	
	
#Row and column will be used to seperate and reset the system. 
#t0 will hold the index value, t1 will hold the upperlimit, t2 is where the number will be stored
	
	#iterate through columns making line
	COLUMN:
		li $v0, 4
		la $a0, cardBorder		#print border
		syscall
		
		#Go through and print out row using column 
		ROW:
			lw  $t2, display_arr($t0) 	#store loaded word into t2, offset by index counter, column spot
			addi $t0, $t0, 4		#update index of $t0
		
			li $v0, 4
			la $a0 cardSpace
			syscall 			#print out space
	
			bltu  $t2, 10 SPACEAGAIN	#if t2(stored number) is less than 10 add another space
			j PRINTWORD			#jump to PRINTWORD
		
			#Jump to this to add a second space if number is less than 10
			SPACEAGAIN:
			li $v0, 4
			la $a0 cardSpace		#pint out space for next number
			syscall 
			j PRINTWORD			#jump to PRINTWORD
		
			#PRINT the stored word at t2
			PRINTWORD:
			li $v0, 1			#load address for moving
			move $a0, $t2			#get ready to print stored number
			syscall
		
			bgt $t1, $t0, ROW		#if index(t0) reaches upperLimit(t1) jump to Row
			 
		#when here done going through printing row and outside of the row loop
		add $t1, $t1, 32		#up limit by 32, creating 8 new spots
		
		li $v0, 4
		la $a0 cardSpace		#pint out space for next border 
		syscall 
			
		la $a0, cardBorder		#print border
		syscall
		
		la $a0, newLine			#print newline
		syscall
		
		blt  $t1, 160, COLUMN		#If limit is now 156 this is fifth loop meaning it has gone through data, jump to update guess
		
		li $v0, 4
		la $a0, cardOutline		#print outline
		syscall
		
		J UPDATE_GUESS			#Jump UPDATE_GUESS
	
#Prompt the user to determine if their number is on card 'n'. Update guess value
UPDATE_GUESS:
	li $v0, 4				#print prompt2
	la $a0, prompt2
	syscall
	li $v0, 5				#get user input
	syscall
	beq $v0, $zero, RANDOMIZE		#if input 0 go to randomize label if 1 continue
	lw $t0, card_int			#get curent card number
	addi $t0, $t0, -1			#get current index
	sll $t0, $t0, 2				#calculate the memory address of value in array(multiply by 4)
	lw $t0, card_worth_arr($t0)		#load the value from array
	lw $t1, guess_int			#get current value of guess_int
	add $t0, $t0, $t1			#add up the guess value and current card value
	sw $t0, guess_int			#store result back to guess_int
	j RANDOMIZE				#jump back to RANDOMIZE label
	
ANSWER:
	li $v0, 4
	la $a0, prompt3
	syscall
	lw $t0, guess_int
	li $v0, 1
	move $a0, $t0
	syscall
	sw $zero, guess_int
	sw $zero, count_random
	j CLEAR_SHOWN_ARRAY
CLEAR_SHOWN_ARRAY:
	lw $t0, count_random
	beq $t0, 6, MAIN
	sll $t1, $t0, 2
	sw $zero, shown_arr($t1)
	addi $t0, $t0, 1
	sw $t0, count_random
	j CLEAR_SHOWN_ARRAY

EXIT:

li $v0, 10
syscall

