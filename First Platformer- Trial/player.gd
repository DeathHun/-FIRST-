extends CharacterBody2D

@export var movement_data : PlayerMovementData

var air_jump = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var coyote_jump_timer = $Coyote_Jump_Timer
@onready var starting_position = global_position

func _physics_process(delta):
	handle_gravity(delta)
	var input_axis = Input.get_axis("move_left", "move_right")
	handle_acceleration(input_axis, delta)
	update_animations(input_axis)
	handle_jump()
	handle_wall_jump()
	
	#Part A Coyote Jump
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	#Part B Coyote Jump
	var just_left_ledge = was_on_floor and not is_on_floor() and velocity.y >= 0
	if just_left_ledge:
		coyote_jump_timer.start()
	
func update_animations(input_axis):
	if not is_on_floor():
		animated_sprite_2d.play("Jump")
		animated_sprite_2d.flip_h = (input_axis > 0)
	elif input_axis != 0:
		animated_sprite_2d.flip_h = (input_axis > 0)
		animated_sprite_2d.play("Run")
	else:
		animated_sprite_2d.play("Idle")

func handle_jump():
	if is_on_floor(): air_jump = true
	
	if is_on_floor() or coyote_jump_timer.time_left>0.0:
		if Input.is_action_just_pressed("jump"):
			velocity.y = movement_data.jump_velocity

	elif not is_on_floor():
		if Input.is_action_just_released("jump") and velocity.y < movement_data.jump_velocity / 2.0:
			velocity.y = movement_data.jump_velocity / 2.0
		
		if Input.is_action_just_pressed("jump") and air_jump==true :
			velocity.y = movement_data.jump_velocity * 0.8
			air_jump = false

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * movement_data.gravity_scale * delta

func handle_wall_jump():
	if not is_on_wall(): return
	var wall_normal = get_wall_normal()
	if Input.is_action_just_pressed("move_left") and wall_normal == Vector2.LEFT and is_on_wall_only():
		velocity.x = wall_normal.x * movement_data.speed
		velocity.y = movement_data.jump_velocity
	if Input.is_action_just_pressed("move_right") and wall_normal == Vector2.RIGHT and is_on_wall_only():
		velocity.x = wall_normal.x * movement_data.speed
		velocity.y = movement_data.jump_velocity

func handle_acceleration(input_axis, delta):
	if input_axis != 0:
		velocity.x = move_toward(velocity.x, movement_data.speed*input_axis, movement_data.acceleration * delta)
	if input_axis == 0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)
	if input_axis == 0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistence * delta)

func handle_player_movement():
	if Input.is_action_just_pressed("jump"):
		movement_data =  load("res://FasterMovementData.tres")

func _on_hazard_detector_area_entered(area):
	global_position = starting_position
	#if the player needs to die then queue_free()
