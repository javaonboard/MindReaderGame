
##### MIND READER, THE GAME THAT KNOWS YOUR THOUGHTS #####
# written by ... #
# see the user manual if you need help playing MIND READER #

.data
	# NUMERICAL VALUES
	
	# counter value of random section
	count_random: .word 0
	# program's guess
	guess_int: .word 0
	# card number
	card_int: .word 1
	# count variable to control the generate loop
	generate_count_int: .word 0
	# current index of the shown array
	shown_index: .word 0
	# current address offset(index) of the display array
	display_index: .word 0
	# card numbers that have already been displayed (5)
	shown_arr: .word 0, 0, 0, 0, 0, 0
	# values that exist on the card 'n' (33)
	display_arr: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	# the 'worth' of each card, 2^(card_int - 1)
	card_worth_arr: .word 1, 2, 4, 8, 16, 32
	# used for jumping between cards
	JumpTable: .word L0, L1, L2, L3, L4, L5
	
	# STRINGS
	
	prompt1: .asciiz "\nThink of a number between 1 and 63. Six cards will be displayed. After the last one, your number will be revealed. Enter 1 to start, or 0 to exit: "
	prompt2: .asciiz "Is your number on this card? Enter 1 for yes, or 0 for no: "
	prompt3: .asciiz "The number you were thinking of was: "
	card1header: .asciiz "\nCARD ONE \n"
	card2header: .asciiz "\nCARD TWO \n"
	card3header: .asciiz "\nCARD THREE \n"
	card4header: .asciiz "\nCARD FOUR \n"
	card5header: .asciiz "\nCARD FIVE \n"
	card6header: .asciiz "\nCARD SIX \n"
	cardOutline: .asciiz " ------------------------- \n"
	cardBorder: .asciiz "|"
	cardSpace: .asciiz " "
	newLine: .asciiz "\n"
	exception: .asciiz "\nThe input was wrong!"

.text
.globl MAIN

MAIN:
	     li $v0, 4				# get ready for print string
	     la $a0, prompt1			# print prompt1 in console
	     syscall
	     li $v0, 5				# get input from user
	     syscall
	     beq $v0, $zero, EXIT		# exit depends on user input; if 0, exit
	     addi $t0, $zero, 1			# add 1 to $t1
	     sw $zero, count_random		# make sure counter from random loop is 0
	     beq $v0, $t0, RANDOMIZE    	# if input is 1, start the program
	     # remainder of code for validity checking
	     li $v0, 4
	     la $a0, exception			# print exception message if input is wrong
	     syscall
	     j MAIN  				# keep repeating the main until user wants to exit

# randomly select a card 'n' without displaying the same card twice, utilizing card_int and shown_arr
RANDOMIZE:
		lw $t0, count_random            # load current count number
		beq $t0, 6, ANSWER	        # if all 6 cards were shown, branch to ANSWER
		li $a1, 6   		        # set the upper bound
		li $v0, 42  		        # generate random number
		syscall
		move $t1, $a0 		        # move from $a0 to $t1					
		sll $t2, $t1, 2	        	# get array index of genrated number	
		lw $t3, shown_arr($t2)          # load the number from array
		bne $t3, $zero, RANDOMIZE       # if already generated, try to generate new card number
		addi $t1, $t1, 1	        # increment the $t1 by one because we generate random number from 0-5
		sw $t1, card_int	        # store $t1 to card_int for next stage
		sw $t1, shown_arr($t2)	        # store the current card in array to avoid duplicate card number			
		addi $t0, $t0, 1	        # increment the counter	
		sw $t0, count_random	        # store the counter in count_random
		j GENERATE

# generates the values of card 'n'
GENERATE:
	lw $t0, generate_count_int		# load generate_count_int for loop control
	beq $t0, 64, CLEAR_GENERATE_DATA	# if display_arr is filled, exit loop
	
	lw $t1, card_int			# load card_int
	sub $t1, $t1, 1				# card_int - 1
	mul $t1, $t1, 4				# adjust for address offset 1
	la $t2, card_worth_arr			# load base address of card_worth_arr
	add $t2, $t1, $t2			# calculate address of 2^(card_int-1) value
	lw $t1, ($t2)				# load 2^(card_int-1) value
	
	and $t3, $t0, $t1			# generate_count_int AND 2^(card_int - 1) to determine if current value exists on current card
	add $a0, $t0, $zero			# pass generate_count_int to argument register $a0
	bne $t3, $zero, UPDATE_DISPLAY_ARR	# if result of AND operation is not zero, add generate_count_int to display_arr
	addi $t0, $t0, 1			# increment generate_count_int
	sw $t0, generate_count_int		# update generate_count_int in memory
	j GENERATE				# restart the loop

# stores the values of card 'n' into display_arr
UPDATE_DISPLAY_ARR:
	la $t0, display_arr			# load base address of display_arr into t0
	lw $t1, display_index			# load value of display_index into t1
	add $t0, $t0, $t1			# add base address and address offset to calculate address with offset
	lw $t2, ($t0)				# load value of the calculated address into t2
	bne $t2, 0, UPDATE_DISPLAY_INDEX	# if t2 is not zero, increment the display index
	sw $a0, ($t0)				# store value of generate_count_int into display_arr
	addi $a0, $a0, 1			# increment generate_count_int
	sw $a0, generate_count_int		# update generate_count_int in memory
	j GENERATE				# return to GENERATE loop

# increments display_index by 4
UPDATE_DISPLAY_INDEX:
	lw $t1, display_index			# load the current display_index
	addi $t1, $t1, 4			# increment display_index by 4
	sw $t1, display_index			# update display_index in memory
	j UPDATE_DISPLAY_ARR			# return to UPDATE_DISPLAY_ARR
	
# sets display_index and count_int back to 0
CLEAR_GENERATE_DATA:
	sw $zero, display_index
	sw $zero, generate_count_int
	j SHOW_CARD

# print display_arr
SHOW_CARD:
	la $t4, JumpTable			# t4 is the address of JumpTable array
	li $t3, 6 				# t3 is a constant (6)
	li $t2, 4				# t2 is a constant (4), to be used for subtraction
	lw $t1, card_int			# t1 is card_int
	
	beq $t1, $t3, L5    			# jump to L5 if card contains 6
	sll $t1, $t1, 2				# $t1 = index * 4 
	sub $t1, $t1, $t2			# $t1 is offset by 1, so need to shift down by 4 to compensate
	add $t1, $t1, $t4			# $t1 + $t4 gives actual address of jumpTable
	lw  $t0, 0($t1)				# load location of needed branch
	jr  $t0             			# jump to address in $t0
	
# CASES
# derived from JumpTable, depending on card number
	
L0:    	li $v0, 4     				# case 0 (card 1)
	la $a0, card1header			# print card1 header
	syscall 
	
     	j LOOP					# jump to loop
     	
L1:   	li $v0, 4  	 			# case 1 (card 2)
	la $a0, card2header			# print card2 header
	syscall 
	
      	j LOOP					# jump to loop
      	
L2:    	li $v0, 4  	   			# case 2 (card 3)
	la $a0, card3header			# print card3 header
	syscall 
	
      	j LOOP					# jump to loop
      	
L3:    	li $v0, 4     				# case 3 (card 4)
	la $a0, card4header			# print card1 header
	syscall 
	
     	j LOOP					# jump loop
     	
L4:   	li $v0, 4  	 			# case 4 (card 5)
	la $a0, card5header			# print card5 header
	syscall 
	
      	j LOOP					# jump loop
      	
L5:  	     					# default case (assumes card 6)
	li $v0, 4				# print card6 header
	la $a0, card6header
	syscall 
	
	addi $t0, $zero, 0 			# set loop iterator to 0
	j LOOP					# jump loop

LOOP:

	li $v0, 4				# print outline of card 
	la $a0, cardOutline
	syscall 
	
	addi $t0, $zero, 0  			# set counter t0 to 0 
	addi $t1, $zero, 32 			# set counter t1 to 28; index starts at 0, not 4, so it needs to be down 1 spot (4 bytes)
	
	
# row and column will be used to separate and reset the system
# t0 will hold the index value, t1 will hold the upperlimit, t2 is where the number will be stored
	
	# iterate through columns making line
	COLUMN:
		li $v0, 4
		la $a0, cardBorder		# print border
		syscall
		
		# go through and print out row using column 
		ROW:
			lw  $t2, display_arr($t0) 	# store loaded word into t2, offset by index counter, column spot
			addi $t0, $t0, 4		# update index of $t0
		
			li $v0, 4
			la $a0 cardSpace
			syscall 			# print out space
	
			bltu  $t2, 10 SPACEAGAIN	# if t2 (stored number) is less than 10, add another space
			j PRINTWORD			# jump to PRINTWORD
		
			# jump to this to add a second space if number has only one digit
			SPACEAGAIN:
			li $v0, 4
			la $a0 cardSpace		# print out space for next number
			syscall 
			j PRINTWORD			# jump to PRINTWORD
		
			# print the stored word at t2
			PRINTWORD:
			li $v0, 1			# load address for moving
			move $a0, $t2			# get ready to print stored number
			syscall
		
			bgt $t1, $t0, ROW		# if index(t0) reaches upperLimit(t1) jump to Row
			 
		# when here, done going through printing row and outside of the row loop
		add $t1, $t1, 32		# increase limit by 32, creating 8 new spots (bytes)
		
		li $v0, 4
		la $a0 cardSpace		# print out space for next border 
		syscall 
			
		la $a0, cardBorder		# print border
		syscall
		
		la $a0, newLine			# print newline
		syscall
		
		blt  $t1, 160, COLUMN		# if limit is now 156 this is fifth loop meaning it has gone through data, jump to update guess
		
		li $v0, 4
		la $a0, cardOutline		# print outline
		syscall
		
		J CLEAR_DISPLAY_ARR		# jump to UPDATE_GUESS
	
# prompt the user to determine if their number is on card 'n'. update guess value depending on confirmation
UPDATE_GUESS:
	li $v0, 4				# print prompt2
	la $a0, prompt2
	syscall
	li $v0, 5				# get user input
	syscall
	beq $v0, $zero, RANDOMIZE		# if input 0 go to randomize label if 1 continue
	li $t6, 1				# t6 will temporarily hold the constant 1
	bne $v0, $t6, ERROR			# if input isn't 1 throw exception
	# beyond this point assumes user input is 1
	lw $t0, card_int			# get current card number
	addi $t0, $t0, -1			# get current index
	sll $t0, $t0, 2				# calculate the memory address of value in array(multiply by 4)
	lw $t0, card_worth_arr($t0)		# load the value from array
	lw $t1, guess_int			# get current value of guess_int
	add $t0, $t0, $t1			# add up the guess value and current card value
	sw $t0, guess_int			# store result back to guess_int
	j RANDOMIZE
	
# clear the display array (which holds card numbers); get ready for next card	
CLEAR_DISPLAY_ARR:	
	la $t0, display_arr			# get display array address
	lw $t1, display_index			# load the index in t1
	add $t2, $t0, $t1			# addup the index and arra6y address
	
	li $t3, 32				# load 32 to t3
	sll $t3, $t3, 2				# shift t3 left 32

	beq $t1, $t3, CLEAR_INDEX		# if program has reached the end of the array, branch to CLEAR_INDEX
	li $t4, 0				# load 0 to t4
	sw $t4, 0($t2)				# store 0 to current item of array
	addi $t1, $t1, 4			# increment the current index by 4
	sw $t1, display_index			# store the current index
	
	j CLEAR_DISPLAY_ARR
	
# clear the generated card numbers index	
CLEAR_INDEX:
	li $t0, 0				# load 0 to t0 (clear t0)
	sw $t0, display_index			# set display_index to 0 (clear display_index)
	j UPDATE_GUESS				# jump to update guess
	
# print the program's final guess
ANSWER:
	li $v0, 4				# prepare to print string
	la $a0, prompt3				# print prompt3
	syscall
	lw $t0, guess_int			# load guess_int in t0
	li $v0, 1				# prepare to print int
	move $a0, $t0				# move t0 to a0
	syscall
	sw $zero, guess_int			# set the guess value to 0
	sw $zero, count_random			# set count_random to 0
	j CLEAR_SHOWN_ARRAY			
	
# clear the array used to generate random number	
CLEAR_SHOWN_ARRAY:
	lw $t0, count_random			# load count_random index
	beq $t0, 6, MAIN			# keep looping to reach 6 and then branch to MAIN
	sll $t1, $t0, 2				# shift left by 2 to get right index of array
	sw $zero, shown_arr($t1)		# set the current item in array to 0
	addi $t0, $t0, 1			# increment the loop counter by 1
	sw $t0, count_random			# store the loop counter in memeory
	j CLEAR_SHOWN_ARRAY
	
# exception for guess validity checking
ERROR:
	li $v0, 4
	la $a0, exception			# output exception (invalid input)
	syscall
	la $a0, newLine
	syscall
	j UPDATE_GUESS				# ask the user for a different number
	
#exit the program
EXIT:
	li $v0, 10
	syscall
