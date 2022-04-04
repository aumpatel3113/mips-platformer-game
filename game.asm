##################################################################### 
# 
# CSCB58 Winter 2022 Assembly Final Project 
# University of Toronto, Scarborough 
# 
# Student: Aum Patel
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 4 (update this as needed)  
# - Unit height in pixels: 4 (update this as needed) 
# - Display width in pixels: 256 (update this as needed) 
# - Display height in pixels: 256 (update this as needed) 
# - Base Address for Display: 0x10008000 ($gp) 
# 
# Which milestones have been reached in this submission? 
# (See the assignment handout for descriptions of the milestones) 
# - Milestone 3 (choose the one the applies) 
# 
# Which approved features have been implemented for milestone 3? 
# (See the assignment handout for the list of additional features) 
# 1. (fill in the feature, if any) 
# 2. (fill in the feature, if any) 
# 3. (fill in the feature, if any) 
# ... (add more if necessary) 
# 
# Link to video demonstration for final submission: 
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it! 
# 
# Are you OK with us sharing the video with people outside course staff? 
# - yes / no / yes, and please share this project github link as well! 
# 
# Any additional information that the TA needs to know: 
# - w to jump
# - a to move left 
# - d to move right
# - p to reset game
# 
##################################################################### 

# FRAME BUFFER
.eqv	BASE_ADDRESS	0x10008000
.eqv	FRAME_BUFFER_W	64
.eqv	FRAME_BUFFER_H	64
.eqv 	FRAME_BUF_PIX_W	256
.eqv	FRAME_BUF_PIX_H	256

# TIME
.eqv	FRAME_PER_SEC	25
.eqv	SLEEP_TIME	40

.eqv	ENEMY_STUN	500
.eqv	MUSHROOM_STUN	350

# KEYBOARD
.eqv	KEY_STROKE_ADRS	0xffff0000
.eqv	w		119
.eqv	a		97
.eqv 	s		115
.eqv	d		100
.eqv 	p		112

# COLOURS
.eqv	BLACK	0x00000000
.eqv	WHITE	0x00ffffff
.eqv	RED	0x00ff0000
.eqv	DRK_GRN	0x00005505
.eqv	GREY	0x00636363
.eqv	PURPLE	0x00ae6bee
.eqv	TEAL	0x0000bf74
.eqv	BLUE	0x001234f5
.eqv	BROWN	0x00dcb845

# OBJECTS
.eqv	PLAYER_W	4
.eqv	PLAYER_H	5
.eqv	PLAYER_FLOOR_Y	57
.eqv	PLAYER_JUMP	-8

.eqv	ENEMY_W		5
.eqv	ENEMY_H		5
.eqv 	ENEMY_FLOOR_Y	57
.eqv	ENEMY_MAX_X	59
.eqv	ENEMY_SPEED 	-1

.eqv	MUSHROOM_W	3
.eqv	MUSHROOM_H	3
.eqv	MUSHROOM_FLR_Y	59
.eqv	MUSHROOM_SPWN_R	250
.eqv	MUSHROOM_SPWN_N	188
.eqv 	MUSHROOM_MAX_X	61

.eqv	PLATFORM_LEN	10
.eqv	PLATFORM_NUM	5

.eqv	GRAVITY_ACC	1

.data
MainPlayer:	.word	BLACK, WHITE, WHITE, WHITE, 
			GREY, WHITE, WHITE, BLACK,
			RED, WHITE, BLACK, WHITE,
			BLACK, WHITE, PURPLE, WHITE,
			BLACK, GREY, BLACK, GREY
			
EnemyCharacter:	.word	WHITE, DRK_GRN, DRK_GRN, DRK_GRN, WHITE,
			WHITE, WHITE, DRK_GRN, WHITE, WHITE,
			DRK_GRN, DRK_GRN, DRK_GRN, DRK_GRN, DRK_GRN,
			BLACK, DRK_GRN, WHITE, DRK_GRN, BLACK,
			TEAL, TEAL, BLACK, TEAL, TEAL
			
Mushroom:	.word	BLACK, BLUE, BLACK,
			BLUE, BLUE, BLUE,
			BLACK, BROWN, BLACK
			
PlayerX:	.word	0
PlayerY:	.word	PLAYER_FLOOR_Y
PlayerDX:	.word	0
PlayerDY:	.word	0

PlatformX:	.word	10, 30, 40, 50, 11
PlatformY:	.word	50, 45, 40, 45, 11

EnemyX:		.word	ENEMY_MAX_X
EnemyY:		.word 	ENEMY_FLOOR_Y
EnemyDX:	.word 	ENEMY_SPEED

MushroomX:	.word	32
MushroomY:	.word 	MUSHROOM_FLR_Y
SpawnMushroom:	.word	0
			

.text
.globl main

main:
init:	# State initialization 
	# Player State
	la $t0, PlayerX
	sw $zero, 0($t0)
	la $t0, PlayerY
	li $t1, PLAYER_FLOOR_Y
	sw $t1, 0($t0)
	la $t0, PlayerDX
	sw $zero, 0($t0)
	la $t0, PlayerDY
	sw $zero, 0($t0)
	
	# Enemy State
	la $t0, EnemyX
	li $t1, ENEMY_MAX_X
	sw $t1, 0($t0)
	la $t0, EnemyY
	li $t1, ENEMY_FLOOR_Y
	sw $t1, 0($t0)
	la $t0, EnemyDX
	li $t1, ENEMY_SPEED
	sw $t1, 0($t0)
	
	# Mushroom State
	la $t0, MushroomX
	li $t1, 32
	sw $t1, 0($t0)
	la $t0, MushroomY
	li $t1, MUSHROOM_FLR_Y
	sw $t1, 0($t0)
	la $t0, SpawnMushroom
	sw $zero, 0($t0)
	
	# Start Screen
		li $t0, BASE_ADDRESS
		addi $t1, $t0, 15872
initLoop:	beq $t0, $t1, initLoopEnd
		sw $zero, 0($t0)
		addi $t0, $t0, 4
		j initLoop
initLoopEnd:	addi $t1, $t1, 516
		li $t2, BROWN
floorLoop:	beq $t0, $t1, floorLoopEnd
		sw $t2, 0($t0)
		addi $t0, $t0, 4
		j floorLoop
floorLoopEnd:	

mainLoop:	jal DrawPlatforms
		# Figure out if the player character is standing on a platform
		jal HandleGravity
		
		# Check for keyboard input
		li $t0, KEY_STROKE_ADRS
		lw $t1, 0($t0)
		bne $t1, 1, skipInput
		jal HandleKey

skipInput:	# Erase objects from the old position on the screen
		# Erase Player
		la $t8, PlayerX
		la $t9, PlayerY
		lw $s0, 0($t8)
		lw $s1, 0($t9)
		add $a0, $s0, $zero
		add $a1, $s1, $zero
		jal EraseMainPlayer
		# Erase Enemy
		la $t8, EnemyX
		la $t9, EnemyY
		lw $s2, 0($t8)
		lw $s3, 0($t9)
		add $a0, $s2, $zero
		add $a1, $s3, $zero
		jal EraseEnemy
		
		# Update player location,
		add $a0, $s0, $zero
		add $a1, $s1, $zero
		jal GetValidPlayerDirection
		add $s0, $s0, $v0
		add $s1, $s1, $v1
		la $t8, PlayerX
		la $t9, PlayerY
		sw $s0, 0($t8)
		sw $s1, 0($t9)
		# Update enemy location,
		add $a0, $s2, $zero
		jal GetValidEnemyDirection
		la $t8, EnemyDX
		sw $v0, 0($t8)
		add $s2, $s2, $v0
		la $t8, EnemyX
		sw $s2, 0($t8)
		
		# Redraw objects in the new position on the screen
		# Draw main player
		la $t8, PlayerX
		la $t9, PlayerY
		lw $a0, 0($t8)
		lw $a1, 0($t9)
		jal DrawMainPlayer
		# Draw enemy 
		la $t8, EnemyX
		la $t9, EnemyY
		lw $a0, 0($t8)
		lw $a1, 0($t9)
		jal DrawEnemy
		
		# Check for various collisions
		add $a0, $s0, $zero
		add $a1, $s1, $zero
		add $a2, $s2, $zero
		add $a3, $s3, $zero
		jal TouchEnemy
		la $t8, MushroomX
		la $t9, MushroomY
		lw $s4, 0($t8)
		lw $s5, 0($t9)
		add $a0, $s0, $zero
		add $a1, $s1, $zero
		add $a2, $s4, $zero
		add $a3, $s5, $zero
		jal TouchMushroom
		
		# Update other game state and end of game
		# Check if we should use RNG to spawn mushroom if there is no mushroom spawned 
		la $t8, SpawnMushroom
		lw $s6, 0($t8)
		bnez $s6, skipMushroom
		# If no mushroom, spawn one in at random
		li $v0, 42 
		li $a0, 0 
		li $a1, MUSHROOM_SPWN_R
		syscall
		bne $a0, MUSHROOM_SPWN_N, skipMushroom
		# Here means we can spawn in mushroom
		la $t8, SpawnMushroom
		li $s6, 1
		sw $s6, 0($t8)
		# Draw mushroom at random x value
		li $v0, 42 
		li $a0, 0 
		li $a1, MUSHROOM_MAX_X
		syscall
		add $s4, $a0, $zero
		la $t8, MushroomX
		sw $s4, 0($t8)
		
		# Stop player from horizontally moving after it already moved for this frame
skipMushroom:	la $t8, PlayerDX
		sw $zero, 0($t8)
		# Draw mushroom only if it was spawned in 
		bne $s6, 1, noMushroom
		add $a0, $s4, $zero
		add $a1, $s5, $zero
		jal DrawMushroom
		
		# Sleep for a little before looping 
noMushroom:	li $v0, 32
		li $a0, SLEEP_TIME
		syscall 

		j mainLoop
mainLoopEnd:	li $v0, 10 # terminate the program gracefully 
 		syscall

# void TouchMushroom(px, py, mx, my)
TouchMushroom:
		# If there is no mushroom spawned in return from function
		la $t5, SpawnMushroom
		lw $t5, 0($t5)
		beqz $t5, noPMOverlap
		# Get player right and bottom values
		addi $t0, $a0, PLAYER_W
		addi $t0, $t0, -1
		addi $t1, $a1, PLAYER_H
		addi $t1, $t1, -1
		# Get enemy right and bottom values
		addi $t2, $a2, MUSHROOM_W
		addi $t2, $t2, -1
		addi $t3, $a3, MUSHROOM_H
		addi $t3, $t3, -1
		# Check for overlap
		bgt $a0, $t2, noPMOverlap
		blt $t0, $a2, noPMOverlap
		bgt $a1, $t3, noPMOverlap
		blt $t1, $a3, noPMOverlap
		# save $ra on stack
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		# Save Player X and Y ($a0, $a1)
		addi $sp, $sp, -8
		sw $a0, 4($sp)
		sw $a1, 0($sp)
		# Erase consumed mushroom
		move $a0, $a2
		move $a1, $a3
		jal EraseMushroom
		# Update state for mushroom spawn
		la $t5, SpawnMushroom
		sw $zero, 0($t5)
		# Restore $a0 and $a1 for Player X and Y
		lw $a1, 0($sp)
		lw $a0, 4($sp)
		addi $sp, $sp, 8
		li $a2, TEAL
		jal FillMainPlayer
		# restore $ra from stack
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		# Sleep for a little to show player was filled
		li $v0, 32
		li $a0, MUSHROOM_STUN
		syscall 
noPMOverlap:	jr $ra

# void TouchEnemy(px, py, ex, ey)
TouchEnemy:
		# Get player right and bottom values
		addi $t0, $a0, PLAYER_W
		addi $t0, $t0, -1
		addi $t1, $a1, PLAYER_H
		addi $t1, $t1, -1
		# Get enemy right and bottom values
		addi $t2, $a2, ENEMY_W
		addi $t2, $t2, -1
		addi $t3, $a3, ENEMY_H
		addi $t3, $t3, -1
		# Check for overlap
		bgt $a0, $t2, noPEOverlap
		blt $t0, $a2, noPEOverlap
		bgt $a1, $t3, noPEOverlap
		blt $t1, $a3, noPEOverlap
		# save $ra on stack
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		li $a2, RED
		jal FillMainPlayer
		# restore $ra from stack
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		# Sleep for a little to show player was filled
		li $v0, 32
		li $a0, ENEMY_STUN
		syscall 
noPEOverlap:	jr $ra
		

# Checks if the change in position of the enemy is valid
# (Can't go off left or right edges)
# Returns the change in valid position
# (int [dx]) GetValidEnemyDirection(x)
GetValidEnemyDirection:
		# If enemy X == 0 and dx < 0 or enemy X == ROW_WIDTH - ENEMY_W and dx > 0
 		# Then return dx = (-1 * original dx) else return dx = original dx 
		la $t9, EnemyDX
		lw $v0, 0($t9)
		bnez $a0, dxCheckGVED
		bgez $v0, dxCheckGVED
		mul $v0, $v0, -1
		jr $ra
dxCheckGVED:	bne $a0, ENEMY_MAX_X, retGVED
		blez $v0, retGVED
		mul $v0, $v0, -1
retGVED:	jr $ra

 
# Checks if the change in position of the player is valid
# (Can't go over upper, left, or right edges)
# Returns the change in position if valid and dx = 0 and dy = GRAVITY_ACC otherwise
# (int [dx], int [dy]) GetValidPlayerDirection(x, y)
GetValidPlayerDirection:
 		# If player X == 0 and dx < 0 or player X == ROW_WIDTH - PLAYER_W and dx > 0
 		# Then return dx = 0
 		# If player Y == 0 then return dy = GRAVITY_ACC
 		li $v1, GRAVITY_ACC
 		la $t8, PlayerDX
 		lw $v0, 0($t8)
 		li $t9, FRAME_BUFFER_W
 		subi $t9, $t9, PLAYER_W
 		bnez $a0, dxCheckGVPD
 		bgez $v0, dxCheckGVPD
 		move $v0, $zero
 		j dyCheckGVPD
dxCheckGVPD:	bne $a0, $t9, dyCheckGVPD
 		blez $v0, dyCheckGVPD
 		move $v0, $zero
dyCheckGVPD:	beqz $a1, retGVPD
 		la $t8, PlayerDY
 		lw $v1, 0($t8)
 		bne $a1, PLAYER_FLOOR_Y, retGVPD
 		blez $v1, retGVPD
 		move $v1, $zero
retGVPD:	jr $ra
 
 	
# void HandleGravity()
HandleGravity:	# Get Player X and Y coordinates
 		la $t0, PlayerX
 		la $t1, PlayerY
 		lw $t0, 0($t0)
 		lw $t1, 0($t1)
 		# If the colour of the pixel 5 rows down in frame buffer is brown
 		li $t2, BASE_ADDRESS
 		mul $t1, $t1, FRAME_BUFFER_W
 		add $t1, $t1, $t0
 		sll $t1, $t1, 2
 		add $t2, $t2, $t1
 		li $t3, FRAME_BUF_PIX_W
 		mul $t3, $t3, PLAYER_H
 		addi $t3, $t3, 4
 		add $t3, $t3, $t2 # $t3 is the pixel stood on 
 		# Then player is standing on platform and DY should be 0
 		# Else gravity should be on and DY > 0 
 		lw $t3, 0($t3)
 		la $t4, PlayerDY
 		beq $t3, BROWN, isOnPlatform
 		li $t5, GRAVITY_ACC
 		sw $t5, 0($t4)
 		jr $ra
isOnPlatform:	sw $zero, 0($t4)
 		jr $ra
 		
 
 # void HandleKey()	
HandleKey:	li $t0, KEY_STROKE_ADRS
 		addi $t0, $t0, 4
 		# get key that was pressed
 		lw $t1, 0($t0)
 		beq $t1, p, init
 		beq $t1, w, handleW
 		beq $t1, a, handleA
 		beq $t1, d, handleD
 		# Other key presses do not do anything
 		jr $ra
handleW:	li $t9, PLAYER_JUMP
 		la $t8, PlayerDY
 		lw $t7, 0($t8)
 		# Only be able to jump if not falling
 		bgez $t7, handleWJump
 		jr $ra
handleWJump:	sw $t9, 0($t8)
 		jr $ra
handleA:	li $t9, -1
 		la $t8, PlayerDX
 		sw $t9, 0($t8)
 		jr $ra
handleD:	li $t9, 1
 		la $t8, PlayerDX
 		sw $t9, 0($t8)
 		jr $ra
 		
# void DrawPlatforms()
DrawPlatforms:
		li $t8, 0
		li $t7, BROWN
drawPlatLoop:	beq $t8, PLATFORM_NUM, drawPlatLoopEnd
		la $t0, PlatformX
		la $t1, PlatformY
		sll $t2, $t8, 2
		add $t0, $t0, $t2
		add $t1, $t1, $t2
		lw $t3, 0($t0)	# Get X
		lw $t4, 0($t1)	# Get Y
		li $t9, BASE_ADDRESS
		mul $t4, $t4, FRAME_BUFFER_W
		add $t4, $t4, $t3
		sll $t4, $t4, 2
		add $t9, $t9, $t4
		# Paint platform
		sw $t7, 0($t9)
		sw $t7, 4($t9)
		sw $t7, 8($t9)
		sw $t7, 12($t9)
		sw $t7, 16($t9)
		sw $t7, 20($t9)
		sw $t7, 24($t9)
		sw $t7, 28($t9)
		sw $t7, 32($t9)
		sw $t7, 36($t9)
		addi $t8, $t8, 1
		j drawPlatLoop
drawPlatLoopEnd:
		jr $ra
		

# void DrawMainPlayer(x, y)
DrawMainPlayer:
	li $t0, BASE_ADDRESS
	li $t1, BLACK
	li $t2, WHITE
	li $t3, GREY
	li $t4, RED
	li $t5, PURPLE
	mul $a1, $a1, FRAME_BUFFER_W
	add $a1, $a1, $a0
	sll $a1, $a1, 2
	add $t0, $t0, $a1
	# ROW 1
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	# ROW 2
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t3, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t1, 12($t0)
	# ROW 3
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t4, 0($t0)
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	# ROW 4
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t5, 8($t0)
	sw $t2, 12($t0)
	# ROW 5
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t3, 4($t0)
	sw $t1, 8($t0)
	sw $t3, 12($t0)
	jr $ra
	
# void DrawEnemy(x, y)
DrawEnemy:
	li $t0, BASE_ADDRESS
	li $t1, BLACK
	li $t2, WHITE
	li $t3, DRK_GRN
	li $t4, TEAL
	mul $a1, $a1, FRAME_BUFFER_W
	add $a1, $a1, $a0
	sll $a1, $a1, 2
	add $t0, $t0, $a1
	# ROW 1
	sw $t2, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, 12($t0)
	sw $t2, 16($t0)
	# ROW 2
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t3, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	# ROW 3
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, 12($t0)
	sw $t3, 16($t0)
	# ROW 4
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t3, 4($t0)
	sw $t2, 8($t0)
	sw $t3, 12($t0)
	sw $t1, 16($t0)
	# ROW 5
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t4, 0($t0)
	sw $t4, 4($t0)
	sw $t1, 8($t0)
	sw $t4, 12($t0)
	sw $t4, 16($t0)
	jr $ra
	
# void DrawMushroom(x, y)
DrawMushroom:
	li $t0, BASE_ADDRESS
	li $t1, BLACK
	li $t2, BLUE
	li $t3, BROWN
	mul $a1, $a1, FRAME_BUFFER_W
	add $a1, $a1, $a0
	sll $a1, $a1, 2
	add $t0, $t0, $a1
	# ROW 1
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	# ROW 2
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	# ROW 3
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t3, 4($t0)
	sw $t1, 8($t0)
	jr $ra
	
# void EraseMainPlayer(x, y)
EraseMainPlayer:
	li $t0, BASE_ADDRESS
	li $t1, BLACK
	mul $a1, $a1, FRAME_BUFFER_W
	add $a1, $a1, $a0
	sll $a1, $a1, 2
	add $t0, $t0, $a1
	# ROW 1
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	# ROW 2
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	# ROW 3
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	# ROW 4
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	# ROW 5
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	jr $ra

# void EraseEnemy(x, y)
EraseEnemy:
	li $t0, BASE_ADDRESS
	li $t1, BLACK
	mul $a1, $a1, FRAME_BUFFER_W
	add $a1, $a1, $a0
	sll $a1, $a1, 2
	add $t0, $t0, $a1
	# ROW 1
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	# ROW 2
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	# ROW 3
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	# ROW 4
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	# ROW 5
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	jr $ra

# void EraseMushroom(x, y)
EraseMushroom:
	li $t0, BASE_ADDRESS
	li $t1, BLACK
	mul $a1, $a1, FRAME_BUFFER_W
	add $a1, $a1, $a0
	sll $a1, $a1, 2
	add $t0, $t0, $a1
	# ROW 1
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	# ROW 2
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	# ROW 3
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	jr $ra

# void FillMainPlayer(x, y, colour)
FillMainPlayer:
	li $t0, BASE_ADDRESS
	li $t1, BLACK
	mul $a1, $a1, FRAME_BUFFER_W
	add $a1, $a1, $a0
	sll $a1, $a1, 2
	add $t0, $t0, $a1
	# ROW 1
	sw $t1, 0($t0)
	sw $a2, 4($t0)
	sw $a2, 8($t0)
	sw $a2, 12($t0)
	# ROW 2
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $a2, 0($t0)
	sw $a2, 4($t0)
	sw $a2, 8($t0)
	sw $t1, 12($t0)
	# ROW 3
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $a2, 0($t0)
	sw $a2, 4($t0)
	sw $t1, 8($t0)
	sw $a2, 12($t0)
	# ROW 4
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $a2, 4($t0)
	sw $a2, 8($t0)
	sw $a2, 12($t0)
	# ROW 5
	addi $t0, $t0, FRAME_BUF_PIX_W
	sw $t1, 0($t0)
	sw $a2, 4($t0)
	sw $t1, 8($t0)
	sw $a2, 12($t0)
	jr $ra
