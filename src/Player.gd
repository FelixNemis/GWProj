extends RigidBody3D

@onready var camera_pivot = find_child("CameraFocus")

@onready var seed_root = find_child("Seed")

var mouse_sensitivity = 0.5

var controller_look_sensitivity = 12

@export var movement_force: = .4

@export var vel_limit = 2.8

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
	if Input.is_action_just_pressed("Primary"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Input.is_action_just_pressed("Esc"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("Restart"):
		get_tree().reload_current_scene()
	
	
	
	var controller_h_look = Input.get_axis("controller_look_left", "controller_look_right")
	var controller_v_look = Input.get_axis("controller_look_up", "controller_look_down")
	if controller_h_look or controller_v_look:
		camera_look(Vector2(controller_h_look, controller_v_look), controller_look_sensitivity)
	

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_look(event.relative, mouse_sensitivity)

func camera_look(delta: Vector2, sensitivity) -> void:
	var arm = camera_pivot.get_child(0)
	arm.rotate_x(-delta.y * 0.01 * sensitivity)
	camera_pivot.rotate_y(-delta.x * 0.01 * sensitivity)
	arm.rotation.x = clamp(arm.rotation.x, -1.2, 1.2)
	

func _integrate_forces(state: PhysicsDirectBodyState3D):
#func _physics_process(delta):
	var forward_vec = -camera_pivot.transform.basis.z
	var left_vec = -camera_pivot.transform.basis.x
	
	var move_vec = Vector3.ZERO
	
	var actual_vel_limit = vel_limit
	
	var fb = Input.get_axis("backward", "forward")
	if fb != 0:
		var projected = state.linear_velocity.project(forward_vec * fb)
		var current_vel = projected.length() * sign(projected.dot(forward_vec * fb))
		
		var effective_force = movement_force
		if current_vel > actual_vel_limit:
			effective_force = 0
		if current_vel < 0:
			effective_force *= 2
		state.linear_velocity += forward_vec * fb * effective_force
		move_vec += forward_vec * fb
		
	
	var lr = Input.get_axis("right", "left")
	if lr != 0:
		var projected = state.linear_velocity.project(left_vec * lr)
		var current_vel = projected.length() * sign(projected.dot(left_vec * lr))
		
		var effective_force = movement_force
		if current_vel > actual_vel_limit:
			effective_force = 0
		if current_vel < 0:
			effective_force *= 2
		state.linear_velocity += left_vec * lr * effective_force
		move_vec += left_vec * lr
	
	# need to add drag for if the player is not inputting movement
	if abs(fb) < 0.1 and abs(lr) < 0.1:
		state.linear_velocity = state.linear_velocity.lerp(Vector3.ZERO, 0.1)
		
	
	global_rotation.y = camera_pivot.rotation.y
	$ChibiCharacterWithAnimsV17/AnimationTree.set("parameters/conditions/walk", move_vec != Vector3.ZERO)
	$ChibiCharacterWithAnimsV17/AnimationTree.set("parameters/conditions/idle", move_vec == Vector3.ZERO)
