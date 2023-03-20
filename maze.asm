.globl main
.data
	file: .asciiz "input"	# locatie file, langste rij mag niet langer als 32 letters zijn en niet meer als 32 rijen
	buffer: .space 2048
	w: .word 119
	p: .word 112
	s: .word 115
	u: .word 117
	nl: .word 10
	e: .word 101
	c: .word 99
	z: .word 122
	q: .word 113
	d: .word 100
	x: .word 120
	blue: .word 0x0000ff
	black: .word 0x000000
	yellow: .word 0xffff00
	green: .word 0x00ff00
	red: .word 0xff0000
	white: .word 0xffffff
	victory_message: .asciiz "You won, thank you for playing!\n"
.text
#main
main:
	jal	read_inputfile		# functie om input file in te lezen
					# maakt gebruik van t0-t4 maar we hoeven ze hier niet op te slaan
	
	move $a1, $v0	# player x	# return player x en y in v0 en v1
	move $a2, $v1	# player y
	
	gameloop:
		li $a0, 60	# delay van 60ms
		li $v0, 32
		syscall
		
		lw $t0, 0xffff0000	# laad de nieuwe input flag
		beq $t0, 0, gameloop 	# geen nieuwe input
		
		li $t3, 0xffff0004	# laad adres van input in t3
		lw $a0, ($t3)		# haal input waarde uit de adres en zet in arg0
		
		# a0 = input, a1 = player x, a2 = player y
		jal parse_input		# parseinput return (nieuwe) positie player
					# gebruikt t0-t4 maar we hoeven ze hier niet op te slaan
		
		move $a1, $v0		# positie opnieuw als argument voor volgende iteratie
		move $a2, $v1		
		
	j gameloop
	
	victory:
	la $a0, victory_message		# laad en print victory message
	li $v0, 4
	syscall
	
	gameloop_end:			# einde
	li $v0, 10
	syscall
	
parse_input:
	# a0 = input, a1 = player x, a2 = player y
	# gebruikt t0-t4, dus best opslaan als je ze achteraf nodig hebt
	# return (nieuwe) positie player in v0-v1
	
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 28	# allocate 28 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s0, -8($fp)	# saved registers
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw	$s3, -20($fp)
	sw	$s4, -24($fp)
	
	lw $t0, z	# laad char codes voor inputs
	lw $t1, s
	lw $t2, q
	lw $t3, d
	lw $t4, x
	
	j input_branch
	
		move_left:
			move $a0, $a1	# a0 = huidige x
			move $a1, $a2	# a1 = huidige y
			
			move $a2, $a0		# a2 = nieuwe x = x
			subi $a3, $a1, 1	# a3 = nieuwe y = y - 1
		j move_player
		
		move_right:
			move $a0, $a1 	# a0 = huidige x
			move $a1, $a2	# a1 = huidige y
			
			move $a2, $a0		# a2 = nieuwe x = x
			addi $a3, $a1, 1	# a3 = nieuwe y = y + 1
		j move_player
		
		move_up:
			move $a0, $a1	# a0 = huidige x
			move $a1, $a2	# a1 = huidige y
			
			subi $a2, $a0, 1	# a2 = nieuwe x = x - 1
			move $a3, $a1		# a3 = nieuwe y = y
		j move_player
		
		move_down:
			move $a0, $a1	# a0 = huidige x
			move $a1, $a2	# a1 = huidige y
			
			addi $a2, $a0, 1	# a2 = nieuwe x = x + 1
			move $a3, $a1		# a3 = nieuwe y = y
		j move_player
		
	
	input_branch:
	beq $a0, $t4, gameloop_end
	beq $a0, $t2, move_left
	beq $a0, $t3, move_right
	beq $a0, $t0, move_up
	beq $a0, $t1, move_down
	
	# invalid key, return huidige locatie
	move $v0, $a1	
	move $v1, $a2
	j parsei_end
	
	move_player:
	
	# a0 = curr_x, a1 = curr_y, a2 = new_x, a3 = new_y
	jal update_position	# return (nieuwe) player position in v0 en v1
	
	move $s0, $v0		# save nieuwe player pos
	move $s1, $v1
	
	move $a2, $a0		# originele adres als argument voor coord_to_adress
	move $a3, $a1
	
	jal coord_to_adress
	
	lw $t1, black		# laad black in t1
	
	sw $t1, ($v0)		# kleur originele positie zwart

	move $a2, $s0		# nieuwe positie als argument voor coord_to_adress
	move $a3, $s1
	
	jal coord_to_adress	
	
	lw $t1, yellow		# laad yellow in t1
	
	sw $t1, ($v0)		# kleur nieuwe positie yellow
	
	move $v0, $s0		# return nieuwe positie
	move $v1, $s1
	
	parsei_end:
	lw	$s4, -24($fp)	# saved registers restore
	lw	$s3, -20($fp)
	lw	$s2, -16($fp)
	lw	$s1, -12($fp)
	lw	$s0, -8($fp)
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra

update_position:
	# a0 = curr_x, a1 = curr_y, a2 = new_x, a3 = new_y
	# gebruikt t1-t4, slaag op indien je achteraf nodig hebt
	# return (nieuwe) positie in v0-v1
	
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 24	# allocate 24 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw 	$s1, -8($fp)
	sw	$s2, -12($fp)
	sw	$s3, -16($fp)
	sw	$s4, -20($fp)
	
	# a2 = x, a3 = y
	# gebruikt t1-t2, maar we hoeven ze niet op te slaan hier
	jal coord_to_adress	# return adres in $v0
	
	lw $t1, blue		# laad kleuren
	lw $t2, red
	lw $t3, green
	
	lw $t4, ($v0)		# haal kleur uit memory adres van huidige pixel
	
	j updatep_branch
	
		invalid_move:
			move $v0, $a0	# invalid move dus return huidige positie
			move $v1, $a1	
		j updatep_end
	
	updatep_branch:
	beq $t4, $t1, invalid_move	# collision met blue
	beq $t4, $t2, invalid_move	# collision met red
	beq $t4, $t3, victory		# collision met green -> victory
	
	move $v0, $a2			# geen collision dus return nieuwe positie
	move $v1, $a3
	
	updatep_end:
	lw	$s4, -20($fp)
	lw	$s3, -16($fp)
	lw	$s2, -12($fp)
	lw	$s1, -8($fp)	# reset saved register $s0
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra

coord_to_adress:
	# a2 = x
	# a3 = y
	# gebruikt t1-t2, slaag op indien nodig achteraf
	# return memory adres in v0
	
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 16	# allocate 16 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s1, -8($fp)
	sw	$s2, -12($fp)
	
	# offset in memory berekenen
	mul $t1, $a2, 32	# t1 = x * 32
	add $t2, $a3, $t1 	# t2 = y + x*32
	mul $t2, $t2, 4		# t2 = 4(y + x*32) = offset in memory
		
	la $v0, ($gp)		# gp in v0
	add $v0, $v0, $t2	# return gp + offset in v0
	
	
	lw	$s2, -12($fp)
	lw	$s1, -8($fp)
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra

read_inputfile:
	# geen arguments
	# functie gebruikt t0-t4, dus best in s0-s4 opslaan als je ze achteraf nodig hebt
	# return positie player in v0-v1
	
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 28	# allocate 28 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s0, -8($fp)	# save saved registers
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw	$s3, -20($fp)
	sw	$s4, -24($fp)
	
		li $v0, 13	# syscal code laad file descriptor
		la $a0, file	# file naam
		li $a1, 0 	# read flag
		li $a2, 0	# mode genegeerd
		syscall
		
		move $t0, $v0	# file descriptor opslaan
		la $t1, buffer  # buffer location opslaan
		
		li $v0, 14	# syscal code file lezen
		move $a0, $t0	# file descriptor
		move $a1, $t1	# buffer waarin opslaan
		li $a2, 2048	# max groote te lezen
		syscall
		
		li $v0, 0 # x init
		li $v1, 0 # y init
		# loop over elke char
		charloop:
			lb $t2, ($t1) # get char uit huidige buffer offset
		
			beqz $t2, end_charloop # einde van input file
			
			move $s0, $t0	# parse char gebruikt t0-t2 en t5-t9 maar we hebben enkel t0-t2 nodig
			move $s1, $t1
			move $s2, $t2
			
			move $a0, $t2	# parse char functie, return in v0 en v1 huidige x en y coord dat getekend wordt
			move $a1, $t1	# en in t3 en t4 de x en y van de player wanneer we die tegenkomen
			jal parse_char	
			
			move $t0, $s0	# registers terughalen
			move $t1, $s1
			move $t2, $s2
			
			addi $t1, $t1, 1 # update buffer offset
			j charloop
		
		end_charloop:
		li $v0, 16 	# file sluiten
		move $a0, $t0	# file descriptor
		syscall
		
		move $v0, $t3
		move $v1, $t4
	
	lw	$s4, -24($fp)	# restore saved registers
	lw	$s3, -20($fp)
	lw	$s2, -16($fp)
	lw	$s1, -12($fp)
	lw	$s0, -8($fp)	
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra
	
	
parse_char:
	# a0 = huidige char, a1 = locatie van char in memory
	# gebruikt t0-t9 waarbij t3-t4 als return registers dienen, dus best t0-t9 opslaan als je ze nog nodig hebt achteraf
	# return positie player in t3-t4 en positie volgende pixel in v0-v1
	
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 40	# allocate 40 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s0, -8($fp)	# save locally used registers
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw 	$s3, -20($fp)
	sw	$s4, -24($fp)
	sw	$s5, -28($fp)
	sw	$s6, -32($fp)
	sw	$s7, -36($fp)
	
	lw $t0, nl	# laad char codes
	lw $t1, w
	lw $t2, p
	lw $s2, s	# t3 en t4 worden gebruikt voor return
	lw $s3, u	# 
	lw $t5, e
	lw $t6, c
	
	j parsec_branch
	
		newline_char:
			subi $v1, $v1, 1	# y-1 want buiten de grid
			lb $t7, 1($a1)		# volgende char inladen en zien of niet einde van input is
			beqz $t7, parsec_end	# indien einde van input dan zijn we klaar
	
			addi $v0, $v0, 1	# anders rij++ en y = 0
			li $v1, 0
	
		j parsec_end
	
		w_char:
			lw $s0, blue		# kleur blue
		j parsec_branch_end
	
		p_char:
			lw $s0, black		# kleur black
		j parsec_branch_end
	
		s_char:	
			move $t3, $v0		# huidige positie returnen als player positie
			move $t4, $v1
			lw $s0, yellow		# kleur yellow
		j parsec_branch_end
	
		u_char:
			lw $s0, green		# kleur green
		j parsec_branch_end
	
		e_char:
			lw $s0, red		# kleur red
		j parsec_branch_end
	
		c_char:
			lw $s0, white		# kleur white
		j parsec_branch_end
	
	parsec_branch:
	
	beq $a0, $t1, w_char
	beq $a0, $t2, p_char
	beq $a0, $s2, s_char
	beq $a0, $s3, u_char
	beq $a0, $t5, e_char
	beq $a0, $t6, c_char
	
	parsec_branch_end:	
	move $s1, $v0				# save v0 en a0
	move $s2, $a0
	
	move $a2, $v0				# huidige positie naar memory adres in bitmap omzetten
	move $a3, $v1
	
	jal coord_to_adress
	
	move $t8, $v0				# memory adres in t8 opslaan
	
	move $v0, $s1				# v0 en a0 restoren
	move $a0, $s2
	
	sw $s0, ($t8)				# kleur van huidige pixel opslaan in de bitmap
	
	beq $a0, $t0, newline_char		# newline check
	
	addi $v1, $v1, 1			# else y++
	
	parsec_end:
	lw	$s7, -36($fp)	# retrieve saved registers
	lw	$s6, -32($fp)
	lw	$s5, -28($fp)
	lw	$s4, -24($fp)
	lw	$s3, -20($fp)
	lw	$s2, -16($fp)
	lw	$s1, -12($fp)	
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra
