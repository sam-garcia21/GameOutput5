class_name Enemy

extends CharacterBody3D

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
## High so movement responds quickly without sliding around.
@export var acceleration: float = 40.0
@export var air_acceleration: float = 12.0
@export var jump_velocity: float = 4.5
@export var health: int = 3

@onready var body: Node3D = $Body
@onready var head: Node3D = $Body/Head
@onready var timer: Timer = $Timer
@onready var move_timer: Timer = $MoveTimer
@onready var particles: GPUParticles3D = $Particles

var move_direction: Vector3
var is_moving: bool = false
var is_alive: bool = true

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var time = randf_range(0, 5)
	timer.wait_time = time
	timer.start()
	
func _on_timer_timeout() -> void:
	var angle = randf_range(0, TAU)
	var time = randf_range(0, 5)
	move_timer.wait_time = time
	rotate_y(angle)
	is_moving = true
	move_direction = _get_move_direction()
	move_timer.start()
	
func _on_move_timer_timeout() -> void:
	is_moving = false
	var time = randf_range(0, 2)
	timer.wait_time = time
	timer.start()

func _physics_process(delta: float) -> void:
	if is_moving and is_alive:
		# Gravity
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Camera-relative horizontal movement
		var direction := move_direction
		var speed := walk_speed
		var target := direction * speed
		var accel := acceleration if is_on_floor() else air_acceleration

		var horizontal := Vector2(velocity.x, velocity.z)
		horizontal = horizontal.move_toward(Vector2(target.x, target.z), accel * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.y

		move_and_slide()

func _get_move_direction() -> Vector3:
	var forward := -global_basis.z
	forward.y = 0.0
	# input.y is negative for "forward" (Godot's get_vector convention).
	return forward.normalized()

func _take_damage() -> void:
	health -= 1

	if health <= 0:
		_die()
		
func _die() -> void:
	is_alive = false
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", Vector3(0,0,90), 0.8) # Fades out over 0.5s
	particles.visible = true
	particles.emitting = true
	await tween.finished
	queue_free()
