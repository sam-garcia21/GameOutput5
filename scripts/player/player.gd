class_name Player
extends CharacterBody3D
## Over-the-shoulder player: movement + yaw (looking left/right).
##
## How the camera follows the actor:
##   - Mouse X rotates THIS node (the whole actor) around Y. The camera rig is a
##     child, so the camera and the actor's main body ALWAYS face the same
##     horizontal direction, and the camera never drifts or lags.
##   - Mouse Y is passed to CameraPivot (camera_rig.gd), which only pitches the
##     camera. The body stays upright.
##   - Mouse look only changes rotation, never position or velocity, so looking
##     around never moves the actor.
##
## Movement is computed from the CAMERA's orientation (see _get_move_direction).

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
## High so movement responds quickly without sliding around.
@export var acceleration: float = 40.0
@export var air_acceleration: float = 12.0
@export var jump_velocity: float = 4.5

@export_group("Mouse Look")
@export var mouse_sensitivity: float = 0.0025 ## radians per pixel

@onready var camera_pivot: CameraRig = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var body: Node3D = $Body
@onready var head: Node3D = $Body/Head
@onready var gun_arm: Node3D = $Body/GunArm
@onready var muzzle: Marker3D = $Body/GunArm/Muzzle


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE and Input.is_action_just_pressed("shoot"):
		print("shoot")
		var cam = $CameraPivot/SpringArm3D/Camera3D
		var origin = cam.project_ray_origin(event.position)
		var cam_mouse_ray_project = cam.project_ray_normal(event.position)
		
		$AimRayCast.fire_shot(origin, cam_mouse_ray_project)

func _unhandled_input(event: InputEvent) -> void:
	# Esc frees the mouse; clicking the window captures it again.
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw: rotate the whole actor, so the body and camera turn together.
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Pitch: only the camera pivot tilts.
		camera_pivot.add_pitch(-event.relative.y * mouse_sensitivity)


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Camera-relative horizontal movement
	var direction := _get_move_direction()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target := direction * speed
	var accel := acceleration if is_on_floor() else air_acceleration

	var horizontal := Vector2(velocity.x, velocity.z)
	horizontal = horizontal.move_toward(Vector2(target.x, target.z), accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y

	move_and_slide()


## Returns a world-space direction on the XZ plane built from the camera's
## facing. W always moves toward the screen's forward and A/D strafe along the
## screen's left/right. The body never turns toward the movement direction, so
## it keeps facing the same way as the camera (strafing/backpedalling).
func _get_move_direction() -> Vector3:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input == Vector2.ZERO:
		return Vector3.ZERO

	var cam_basis := camera.global_basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	# input.y is negative for "forward" (Godot's get_vector convention).
	return (right * input.x + forward * -input.y).normalized()


# --- API for teammates (aiming / shooting) -----------------------------------

func get_camera() -> Camera3D:
	return camera


func get_head() -> Node3D:
	return head


func get_gun_arm() -> Node3D:
	return gun_arm


func get_muzzle() -> Marker3D:
	return muzzle
