#####################################################################
#
# Author: Jenny Ho
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
#
#  Features
# 1. More platform types, such as moving blocks, "spring" blocks (more bouncy), and "fragile" blocks (broken when jumped upon). 
#      Different types of platform blocks are distinguished by different colours.
# 2. Opponent that can move and hurt the Doodler.
# 3. Shooting: the Doodler can shoot (controlled by key f) and eliminate opponent.
# 4. Background music: add background music to the game. (sound effects only)
#
# Additional information 
# - Move left and right using "j" and "k"
# - To shoot a ball, press the key "f". The doodler can shoot up to 5 balls at a time. Those balls can harm and get rid of opponents.
# - If you bump into an opponent, you lose. If you jump on an opponent, you kill it.
# - There is a 33% chance for an opponent to appear on a normal or a bouncy blocks.
# - Green (normal block)
# - Blue (bouncy block)
# - Orange (fragile block)
# - Purple (moving block)
# - There is a 66.6% that the next block is a normal block, 12.5% for a bouncy block, 12.5% for a fragile block and 8.4% for a moving block
# - There are sound effects for when the doodler jumps on a block, shoots, kill an opponent, and when you lose.
#
#####################################################################

.data
	displayAddress:		.word	0x10008000
	lightBlue:			.word	0xd7f3f7
	darkBlue:			.word	0x001ae3
	lightGreen:			.word	0x78ff8a
	green:				.word	0x78ff8a
	black:				.word	0x000000
	red:					.word	0xff0000
	yellowGreen:			.word	0x5f7001
	darkRed:			.word	0x800909
	orange:				.word	0xff6a00			# Fragile block
	blue:				.word	0x00bfff				# Spring block
	purple:				.word	0x9500ff			# Moving block
	posX:				.word	0					# Position x of doodle (0, 4, 8, 12, 16, 20, ..., 124)
	posY:				.word	3840				# Position y of doodle (0, 128, 256, 384, ..., 3968)
	blockX:				.word	0, 0, 0				# numbered 0-31
	blockY:				.word	1152, 2560, 3968	# Position y (0, 128, 256, 384, ..., 3968)
	keystrokeAddress:	.word	0xffff0000 
	keyAddress:			.word	0xffff0004
	keyJ:				.word	'j'
	keyK:				.word	'k'
	keyF:				.word	'f'
	doodleVertical:		.word	1					# The next move of Doodle. 	1 if up, 0 if same, -1 if down
	jumpLevel:			.word	0					# range 0 to 120. If doodle is on bar, reset to 0
	ballX:				.space	20					# position x of balls
	ballY:				.space	20					# position y of balls
	ballIndex:			.word	0
	opp1X:				.word	0					# position x of opponent 1
	opp1Y:				.word	0					# position y of opponent 1
	opp1Show:			.word	0
	killed:				.word	1					# if killed = 0, game over
	onBouncy:			.word	0					# 1 if doodle has just jumped on a bouncy block
	blockType:			.word	0, 0, 0				# Type 0 (Normal), Type 1 (Bouncy), Type 2 (Fragile), Type 3 (Moving)
	blockStatus:			.word	0, 0, 0				# If block is fragile, 0 for no show and 1 for show. 
													# If block is moving, -1 for going left and 1 for going right
.text
	
#------------------------INITIALIZAITON---------------------------
main:
	# Set initial random position X for the 3 blocks
	la $t0, blockX
	jal randomNum
	move $t1, $v0
	sw $t1, 0($t0)
	jal randomNum
	move $t1, $v0
	sw $t1, 4($t0)
	jal randomNum
	move $t1, $v0
	sw $t1, 8($t0)
	
	#set position for doodle
	add $t1, $t1, $t1
	add $t1, $t1, $t1
	addi $t1, $t1, 12
	sw $t1, posX
	
	#draw initial display
	jal drawDisplay
	
	#initialize ball positions
	la $t0, ballX
	li $t1, -1
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	la $t0, ballY
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	
#--------------------------------MAIN LOOP-----------------------------

 loop:
 	jal jump
 	jal keyInput
 	jal updateNextMove
 	jal drawDisplay
 	jal drawBall
 	li $a0, 50
 	jal wait
 	
	lw $t0, posY 
 	beq $t0, 3968, lose
 	lw $t0, killed 
 	beqz $t0, lose
 	j loop 
 
 #--------------------------------------WAIT------------------------------------
 wait:
 	li $v0, 32
	syscall
	jr $ra
 
 #-------------------------------------JUMP---------------------------------------
jump:	
	la $t1, blockType	
	li $t2, 3								# Move block if there is a moving block
	lw $t3, 0($t1)
	bne $t2, $t3, secondBlockMoving
firstBlockMoving:
	lw $t4, blockStatus
	lw $t5, blockX
	add $t5, $t5, $t4
	sw $t5, blockX 
	blez $t5, firstBlockGoRight
	bge $t5, 23, firstBlockGoLeft
	j secondBlockMoving
firstBlockGoRight:
	li $t6, 1
	sw $t6, blockStatus
	j secondBlockMoving
firstBlockGoLeft:
	li $t6, -1
	sw $t6, blockStatus
secondBlockMoving:
	lw $t3, 4($t1)
	bne $t2, $t3, thirdBlockMoving
	lw $t4, blockStatus+4
	lw $t5, blockX+4
	add $t5, $t5, $t4
	sw $t5, blockX+4
	blez $t5, secondBlockGoRight
	bge $t5, 23, secondBlockGoLeft
	j thirdBlockMoving
secondBlockGoRight:
	li $t6, 1
	sw $t6, blockStatus+4
	j thirdBlockMoving
secondBlockGoLeft:
	li $t6, -1
	sw $t6, blockStatus+4
thirdBlockMoving:
	lw $t3, 8($t1)
	bne $t2, $t3, after
	lw $t4, blockStatus+8
	lw $t5, blockX+8
	add $t5, $t5, $t4
	sw $t5, blockX+8 
	blez $t5, thirdBlockGoRight
	bge $t5, 23, thirdBlockGoLeft
	j after
thirdBlockGoRight:
	li $t6, 1
	sw $t6, blockStatus+8
	j after
thirdBlockGoLeft:
	li $t6, -1
	sw $t6, blockStatus+8
	j after
after:
	lw $t1, doodleVertical
	bgtz $t1, moveUp                  		# move doodle one pixel up
	beqz $t1, moveBlock	          		# move block down while doodle stays at same level
	bltz $t1, moveDown             		# move doodle one pixel down
	
#---------------------------KEYBOARD INPUT-------------------------------

keyInput:
	lw $t1, 0xffff0000
	bnez $t1, keyPressed
	jr $ra
keyPressed:
	lbu $t2, 0xffff0004
	lbu $t3, keyJ
	beq $t2, $t3, moveLeft
	lbu $t3, keyK
	beq $t2, $t3, moveRight
	lbu $t3, keyF
	beq $t2, $t3, shoot
	jr $ra

#---------------------DOODLE MOVE LEFT ------------------------------
moveLeft: 
	lw $t4, posX
	beqz $t4, moveLeftZero
	addi $t4, $t4, -4
	sw $t4, posX
	jr $ra
moveLeftZero:
	addi $t4, $t4, 124
	sw $t4, posX
	jr $ra

#---------------------DOODLE MOVE RIGHT ------------------------------
moveRight: 
	lw $t4, posX
	beq $t4, 124, moveRight124
	addi $t4, $t4, 4
	sw $t4, posX
	jr $ra
moveRight124:
	sw $zero, posX
	jr $ra
	
#-------------------------------DOODLE SHOOT---------------------------------
shoot:
	li $a0, 66
	li $a1, 400
	li $a2, 127
	li $a3, 60
 	li $v0, 31
	syscall
	lw $t1, posX
	lw $t2, posY
	addi $t1, $t1, 4
	bne $t1, 128, elseShoot
	addi $t1, $t1, -128
elseShoot: 
	addi $t2, $t2, -384
	lw $t3, ballIndex
	la $t4, ballX
	add $t4, $t4, $t3
	sw $t1, 0($t4)
	la $t4, ballY
	add $t4, $t4, $t3
	sw $t2, 0($t4)
	addi $t3, $t3, 4
	bne $t3, 20, elseShoot2
	move $t3, $zero
elseShoot2:
	sw $t3, ballIndex
	jr $ra

#---------------------DOODLE MOVE UP FUNCTION------------------------------
moveUp: 
	lw $t1, posY
	addi $t1, $t1, -128
	sw $t1, posY
	jr $ra
	
#---------------------DOODLE MOVE DOWN FUNCTION------------------------------
moveDown: 
	lw $t1, posY
	addi $t1, $t1, 128
	sw $t1, posY
	jr $ra

#------------------------------ MOVE BLOCK FUNCTION------------------------------
moveBlock:
	lw $t0, opp1Show
	beqz $t0, skipOppUpdate
	lw $t2, opp1Y
	addi $t2, $t2, 128
	sw $t2, opp1Y
	ble $t2, 4224, skipOppUpdate
	sw $zero, opp1Show 
skipOppUpdate:
	li $t0, 0
moveBlockLoop: 
	la $t1, blockY
	add $t1, $t1, $t0
	lw $t2, 0($t1)
	addi $t2, $t2, 128
	sw $t2, 0($t1)
	bne $t2, 4096, skipBlock                 	# block passed. create new block
	li $t2,  -128						# create random position for new block
	sw $t2, 0($t1)
	addi $sp, $sp, -4                               
	sw $ra, ($sp)
	jal randomNum
	move $t4, $v0
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	la $t3, blockX
	add $t3, $t3, $t0
	sw $t4, 0($t3)
	la $t7, blockType
	add $t7, $t7, $t0
	addi $sp, $sp, -4                                	# decide type of block
	sw $ra, ($sp)
	jal randomNum      				
	move $t3, $v0					
	lw $ra, ($sp)						
	addi $sp, $sp, 4					
	bge $t3, 22, movingBlockSet		#if number is 22-23, block is moving.
	bge $t3, 19, bouncyBlockSet		# if number is 19-21, block is fragile.
	bge $t3, 16, fragileBlockSet		#if number is 16-18, block is bouncy.
	sw $zero, 0($t7)
	j createOpp
movingBlockSet:
	li $t5, 3
	sw $t5, 0($t7)
	la $t6, blockStatus
	add $t6, $t6, $t0
	li $t5, 1
	sw $t5, 0($t6)
	la $t3, blockX
	add $t3, $t3, $t0
	lw $t3, 0($t3)
	blt $t3, 23, skipBlock
	li $t5, -1
	sw $t5, 0($t6)
	j skipBlock
bouncyBlockSet:
	li $t5, 1
	sw $t5, 0($t7)
	j createOpp
fragileBlockSet:
	li $t5, 2
	sw $t5, 0($t7)
	la $t6, blockStatus
	add $t6, $t6, $t0
	li $t5, 1
	sw $t5, 0($t6)
	j skipBlock
	
createOpp:							# 33% chance of creating opponent
	lw $t1, opp1Show
	beq $t1, 1, skipBlock
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal randomNum
	move $t1, $v0
	lw $ra, ($sp)
	addi $sp, $sp, 4
	bge $t1, 8, skipBlock
	add $t4, $t4, $t4
	add $t4, $t4, $t4
	add $t4, $t4, 8
	add $t2, $t2, -128
	sw $t4, opp1X
	sw $t2, opp1Y
	li $t1, 1
	sw $t1, opp1Show
	
skipBlock:
	addi $t0, $t0, 4
	bne $t0, 12, moveBlockLoop
	jr $ra
	
#---------------------------------UPDATE NEXT MOVE-------------------------------
updateNextMove:
	lw $t1, jumpLevel
	lw $t2, doodleVertical
	lw $t3, posY
	bgtz $t2, up                       		# doodle moved up
	beqz $t2, stay                   		# doodle stayed
	bltz $t2, down                   		# doodle moved down
up:
	addi $t1, $t1, 1
	sw $t1, jumpLevel
	lw $t2, onBouncy
	bnez $t2, upBouncy
	beq $t1, 19, goingDown
	beq $t3, 1408, goingStay
	jr $ra
upBouncy:
	beq $t1, 30, goingDown
	beq $t3, 1408, goingStay
	jr $ra
stay:
	addi $t1, $t1, 1
	sw $t1, jumpLevel
	lw $t2, onBouncy
	bnez $t2, stayBouncy
	beq $t1, 19, goingDown
	jr $ra
stayBouncy:
	beq $t1, 30, goingDown
	jr $ra
down:
	addi $t1, $t1, -1
	sw $t1, jumpLevel
	lw $t0, displayAddress
	lw $t4, posX
	add $t0, $t0, $t3
	add $t0, $t0, $t4
	addi $t0, $t0, 128
	lw $t5, 0($t0)
	lw $t2, lightGreen
	beq $t2, $t5, hitNormalBlock
	lw $t2, blue
	beq $t2, $t5, hitBouncyBlock
	lw $t2, orange
	beq $t2, $t5, hitFragileBlock
	lw $t2, purple
	beq $t2, $t5, hitMovingBlock
	lw $t6, darkRed
	lw $t7, yellowGreen
	beq $t5, $t6, hitOppTopRed
	beq $t5, $t7, hitOppTopGreen
	addi $t0, $t0, 8
	bge, $t4, 120, modify
	j else
modify:
	addi $t0, $t0, -120
else:
	lw $t5, 0($t0)
	lw $t2, lightGreen
	beq $t2, $t5, hitNormalBlock
	lw $t2, blue
	beq $t2, $t5, hitBouncyBlock
	lw $t2, orange
	beq $t2, $t5, hitFragileBlock
	lw $t2, purple
	beq $t2, $t5, hitMovingBlock
	beq $t5, $t6, hitOppTopRed
	beq $t5, $t7, hitOppTopGreen
	jr $ra
	
hitNormalBlock:      
	li $a0, 40 						#hit block SOUND EFFECT
	li $a1, 400
	li $a2, 13
	li $a3, 60
 	li $v0, 31
	syscall
	sw $zero, jumpLevel
	sw $zero, onBouncy 
	j goingUp          
	
hitBouncyBlock:        
	li $a0, 48						#hit block SOUND EFFECT
	li $a1, 800
	li $a2, 45
	li $a3, 60
 	li $v0, 31
	syscall 
	sw $zero, jumpLevel
	li $t1, 1
	sw $t1, onBouncy 
	j goingUp     
	
hitFragileBlock:
	li $a0, 60						#hit block SOUND EFFECT
	li $a1, 800
	li $a2, 47
	li $a3, 60
 	li $v0, 31
	syscall
	sw $zero, jumpLevel
	sw $zero, onBouncy 
	la $t1, blockStatus
	lw $t2, blockY
	lw $t3, posY
	add $t3, $t3, 128
	beq $t3, $t2, firstBlock
	lw $t2, blockY+4
	beq $t3, $t2, secondBlock
	lw $t2, blockY+8
	beq $t3, $t2, thirdBlock
	j goingUp   
firstBlock:
	sw $zero, 0($t1)
	j goingUp   
secondBlock:
	sw $zero, 4($t1)
	j goingUp   
thirdBlock:
	sw $zero, 8($t1)
	j goingUp   
	
hitMovingBlock:
	li $a0, 40 						#hit block SOUND EFFECT
	li $a1, 400
	li $a2, 13
	li $a3, 60
 	li $v0, 31
	syscall
	sw $zero, onBouncy 
	sw $zero, jumpLevel
	j goingUp   
	
hitOppTopRed:
	li $a0, 40 						#sound
	li $a1, 400
	li $a2, 127
	li $a3, 60
 	li $v0, 31
	syscall
	li $t2, 2
	sw $t2, jumpLevel
	sw $zero, onBouncy 
	sw $zero, opp1Show
	j goingUp     
	
hitOppTopGreen:
	li $a0, 40						#sound
	li $a1, 400
	li $a2, 127
	li $a3, 60
 	li $v0, 31
	syscall
	li $t2, 3
	sw $t2, jumpLevel
	sw $zero, onBouncy 
	sw $zero, opp1Show
	
goingUp:                                     			#next move is set to going up
	li $t1, 1         
	sw $t1, doodleVertical          
	jr $ra
	
goingStay:                                   			#next move is set to stay
	sw $zero, doodleVertical          
	jr $ra
	
goingDown:                                  		#next move is set to going down
	li $t1, -1
	sw $t1, doodleVertical          
	jr $ra
	
#------------------ RANDOM NUMBER FROM 0 TO 23 FUNCTION ---------------------	
randomNum:
	li $v0, 42
	li $a0, 1
	li $a1,  24
	syscall
	move $v0, $a0
	jr $ra
			
#--------------------------DRAW BALL FUNCTION---------------------------
drawBall:
	li $t3, 0
drawBallLoop:
	la $t4, ballY
	add $t4, $t4, $t3
	lw $t2, 0($t4)
	bltz $t2, skipDrawBall
	lw $t0, displayAddress
	la $t5, ballX
	add $t5, $t5, $t3
	lw $t1, 0($t5)
	add $t0, $t0, $t1
	add $t0, $t0, $t2
	lw $t6, darkRed                       		# Check if ball hit opponent
	lw $t7, yellowGreen
	lw $t8, 0($t0)
	beq $t6, $t8, hitOpp
	beq $t7, $t8, hitOpp
	j missOpp
hitOpp:
	li $a0, 40						#sound
	li $a1, 400
	li $a2, 127
	li $a3, 100
 	li $v0, 31
	syscall
	sw $zero, opp1Show
	j drawDisplay
missOpp:
	lw $t6, black
	sw $t6, 0($t0)
	addi $t2, $t2, -128
	addi $t2, $t2, -128
	sw $t2, 0($t4)
	
skipDrawBall:
	addi $t3, $t3, 4
	bne $t3, 20, drawBallLoop
	jr $ra

#-------------------- DRAW ENTIRE DISPLAY FUNCTION-----------------
drawDisplay:
	lw $t0, displayAddress
	lw $t1, lightBlue
	li $t2, 0
background:
	sw $t1, 0($t0)
	addi $t0, $t0, 4
	addi $t2, $t2, 1
	bne $t2, 1024, background

	li $t2, 0							#Paint the blocks
block:
	lw $t0, displayAddress
	la $t3, blockX
	add $t3, $t3, $t2
	lw $t3, 0($t3)
	la $t4, blockY
	add $t4, $t4, $t2
	lw $t4, 0($t4)
	bltz $t4, skipDrawBlock
	add $t3, $t3, $t3
	add $t3, $t3, $t3
	add $t0, $t0, $t3
	add $t0, $t0, $t4	
	la $t1, blockType
	add $t1, $t1, $t2
	lw $t1, 0($t1)
	beq $t1, 1, drawBouncyBlock
	beq $t1, 2, drawFragileBlock
	beq $t1, 3, drawMovingBlock
drawNormalBlock:
	lw $t1, lightGreen
	j startDrawBlock
drawBouncyBlock:
	lw $t1, blue
	j startDrawBlock
drawFragileBlock:
	la $t1, blockStatus
	add $t1, $t1, $t2
	lw $t1, 0($t1)
	beqz $t1, skipDrawBlock
	lw $t1, orange
	j startDrawBlock
drawMovingBlock:
	lw $t1, purple
	j startDrawBlock
	
startDrawBlock:	
	li $t5, 0
blockLoop:
	sw $t1, 0($t0)
	addi $t0, $t0, 4
	addi $t5, $t5, 1
	bne $t5, 9, blockLoop
skipDrawBlock:
	addi $t2, $t2, 4
	bne $t2, 16, block

	lw $t1, opp1Show						#draw opponent 1
	beqz $t1, skipDrawOpp1
	lw $t1, darkRed
	lw $t2, yellowGreen
	lw $t3, opp1X
	lw $t4, opp1Y
	lw $t0, displayAddress
	add $t0, $t0, $t3
	add $t0, $t0, $t4
	bgt $t4, 3968, cont1
	bltz $t4, cont1
	sw $t1, 0($t0)
	sw $t1, 8($t0)
	sw $t1, 16($t0)
cont1:
	addi $t0, $t0, -128
	bgt $t4, 4096, cont2
	blez $t4, cont2
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
cont2:
	addi $t0, $t0, -124
	bgt $t4, 4224, skipDrawOpp1
	ble $t4, 128,  skipDrawOpp1
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)

skipDrawOpp1:
	lw $t6, darkRed  
	lw $t0, displayAddress					#draw doodle
	lw $t1, darkBlue
	lw $t2, posX
	lw $t3, posY
	beq $t2, 120, split1
	beq $t2, 124, split2
	add $t0, $t0, $t2
	add $t0, $t0, $t3
	sw $t1, 0($t0)    
	sw $t1, 8($t0)
	addi $t0, $t0, -128
	lw $t8, 0($t0)							# Check if doodle head hit opponent
	beq $t6, $t8, doodleHitOpp0
	beq $t7, $t8, doodleHitOpp0
	j doodleMissOpp0
doodleHitOpp0:
	sw $zero, killed
doodleMissOpp0:                                                 
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	lw $t8, 8($t0)							# Check if doodle head hit opponent
	beq $t6, $t8, doodleHitOpp1
	beq $t7, $t8, doodleHitOpp1
	j doodleMissOpp1
doodleHitOpp1:
	sw $zero, killed
doodleMissOpp1:                                                
	sw $t1, 8($t0)
	addi $t0, $t0, -124
	lw $t8, 0($t0)							# Check if doodle head hit opponent
	beq $t6, $t8, doodleHitOpp2
	beq $t7, $t8, doodleHitOpp2
	j doodleMissOpp2
doodleHitOpp2:
	sw $zero, killed
doodleMissOpp2:                                      
	sw $t1, 0($t0)
	jr $ra
	
split1:
	lw $t0, displayAddress
	add $t0, $t0, $t2
	add $t0, $t0, $t3
	sw $t1, 0($t0)
	addi $t0, $t0, -120
	sw $t1, 0($t0)
	addi $t0, $t0, -128
	sw $t1, 0($t0)
	sw $t1, 120($t0)
	sw $t1, 124($t0)
	addi $t0, $t0, -4
	lw $t6, darkRed                                           		# Check if doodle head hit opponent
	lw $t8, 0($t0)
	beq $t6, $t8, doodleHitOpp3
	beq $t7, $t8, doodleHitOpp3
	j doodleMissOpp3
doodleHitOpp3:
	sw $zero, killed
doodleMissOpp3:
	sw $t1, 0($t0)
	jr $ra

split2:
	lw $t0, displayAddress
	add $t0, $t0, $t2
	add $t0, $t0, $t3
	sw $t1, 0($t0)
	addi $t0, $t0, -120
	sw $t1, 0($t0)
	addi $t0, $t0, -132
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 124($t0)
	addi $t0, $t0, -128
	lw $t6, darkRed                                            	# Check if doodle head hit opponent
	lw $t8, 0($t0)
	beq $t6, $t8, doodleHitOpp4
	beq $t7, $t8, doodleHitOpp4
	j doodleMissOpp4
doodleHitOpp4:
	sw $zero, killed
doodleMissOpp4:
	sw $t1, 0($t0)
	jr $ra
	
# ------------------------------- GAME OVER DISPLAY ----------------------------
lose:
	lw $t0, displayAddress
	addi $t0, $t0, 896
	lw $t1, black
	li $t2, 0
loseBackground:
	sw $t1, 0($t0)
	addi $t0, $t0, 4
	addi $t2, $t2, 1
	bne $t2, 576, loseBackground
		
	lw $t0, displayAddress
	lw $t1, red
	# first row
	sw $t1, 1176($t0)
	sw $t1, 1180($t0)
	sw $t1, 1184($t0)
	sw $t1, 1188($t0)
	sw $t1, 1196($t0)
	sw $t1, 1200($t0)
	sw $t1, 1204($t0)
	sw $t1, 1208($t0)
	sw $t1, 1216($t0)
	sw $t1, 1232($t0)
	sw $t1, 1240($t0)
	sw $t1, 1244($t0)
	sw $t1, 1248($t0)
	sw $t1, 1252($t0)
	# second row
	sw $t1, 1304($t0)
	sw $t1, 1324($t0)
	sw $t1, 1336($t0)
	sw $t1, 1344($t0)
	sw $t1, 1348($t0)
	sw $t1, 1356($t0)
	sw $t1, 1360($t0)
	sw $t1, 1368($t0)
	# third row
	sw $t1, 1432($t0)
	sw $t1, 1440($t0)
	sw $t1, 1444($t0)
	sw $t1, 1452($t0)
	sw $t1, 1456($t0)
	sw $t1, 1460($t0)
	sw $t1, 1464($t0)
	sw $t1, 1472($t0)
	sw $t1, 1480($t0)
	sw $t1, 1488($t0)
	sw $t1, 1496($t0)
	sw $t1, 1500($t0)
	sw $t1, 1504($t0)
	# fourth row
	sw $t1, 1560($t0)
	sw $t1, 1572($t0)
	sw $t1, 1580($t0)
	sw $t1, 1592($t0)
	sw $t1, 1600($t0)
	sw $t1, 1616($t0)
	sw $t1, 1624($t0)
	# fifth row
	sw $t1, 1688($t0)
	sw $t1, 1692($t0)
	sw $t1, 1696($t0)
	sw $t1, 1700($t0)
	sw $t1, 1708($t0)
	sw $t1, 1720($t0)
	sw $t1, 1728($t0)
	sw $t1, 1744($t0)
	sw $t1, 1752($t0)
	sw $t1, 1756($t0)
	sw $t1, 1760($t0)
	sw $t1, 1764($t0)
	# sixth row
	sw $t1, 2324($t0)
	sw $t1, 2328($t0)
	sw $t1, 2332($t0)
	sw $t1, 2336($t0)
	sw $t1, 2344($t0)
	sw $t1, 2360($t0)
	sw $t1, 2368($t0)
	sw $t1, 2372($t0)
	sw $t1, 2376($t0)
	sw $t1, 2380($t0)
	sw $t1, 2388($t0)
	sw $t1, 2392($t0)
	sw $t1, 2396($t0)
	sw $t1, 2408($t0)
	# seventh row
	sw $t1, 2452($t0)
	sw $t1, 2464($t0)
	sw $t1, 2472($t0)
	sw $t1, 2488($t0)
	sw $t1, 2496($t0)
	sw $t1, 2516($t0)
	sw $t1, 2524($t0)
	sw $t1, 2536($t0)
	# eight row
	sw $t1, 2580($t0)
	sw $t1, 2592($t0)
	sw $t1, 2604($t0)
	sw $t1, 2612($t0)
	sw $t1, 2624($t0)
	sw $t1, 2628($t0)
	sw $t1, 2632($t0)
	sw $t1, 2644($t0)
	sw $t1, 2648($t0)
	sw $t1, 2652($t0)
	sw $t1, 2664($t0)
	# ninth row
	sw $t1, 2708($t0)
	sw $t1, 2720($t0)
	sw $t1, 2732($t0)
	sw $t1, 2740($t0)
	sw $t1, 2752($t0)
	sw $t1, 2772($t0)
	sw $t1, 2780($t0)
	# tenth row
	sw $t1, 2836($t0)
	sw $t1, 2840($t0)
	sw $t1, 2844($t0)
	sw $t1, 2848($t0)
	sw $t1, 2864($t0)
	sw $t1, 2880($t0)
	sw $t1, 2884($t0)
	sw $t1, 2888($t0)
	sw $t1, 2892($t0)
	sw $t1, 2900($t0)
	sw $t1, 2912($t0)
	sw $t1, 2920($t0)
	
	li $a0, 62
	li $a1, 500
	li $a2, 63
	li $a3, 60
 	li $v0, 31
	syscalL
	li $a0, 50
	li $a1, 500
	li $a2, 63
	li $a3, 60
 	li $v0, 31
	syscall
	
 	li $a0, 400
 	li $v0, 32
	syscall
	
	li $a0, 61
	li $a1, 500
	li $a2, 63
	li $a3, 60
 	li $v0, 31
	syscall
	li $a0, 49
	li $a1, 500
	li $a2, 63
	li $a3, 60
 	li $v0, 31
	syscall

	li $a0, 400
 	li $v0, 32
	syscall
	
	li $a0, 60
	li $a1, 500
	li $a2, 63
	li $a3, 60
 	li $v0, 31
	syscall
	li $a0, 48
	li $a1, 500
	li $a2, 63
	li $a3, 60
 	li $v0, 31
	syscall
	
	li $a0, 400
 	li $v0, 32
	syscall
	
	li $a0, 59
	li $a1, 1800
	li $a2, 63
	li $a3, 60
 	li $v0, 31
	syscall
	li $a0, 47
	li $a1, 1800
	li $a2, 63
	li $a3, 60
 	li $v0, 31
	syscall
	
#-------------------------TERMINATE PROGRAM--------------------------------
Exit:
	li $v0, 10
	syscall
	
