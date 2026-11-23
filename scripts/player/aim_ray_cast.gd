extends Node3D

const RAY_LENGTH = 20
const COLLISION_LAYER_ID = pow(2, 13-1)
var check_hit = false
var origin
var collision_point
@export var bullet_scene: PackedScene 
@onready var _fire_point = $"../Body/GunArm/Muzzle"
@onready var _aim_cast = $"../AimTarget/AimCast"
@onready var player = $".."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if bullet_scene:
		var camera = get_viewport().get_camera_3d()
		var warmup_bullet = bullet_scene.instantiate()
		add_child(warmup_bullet)
		
		# Place directly in front of the camera so the GPU is forced to render & compile it
		if camera:
			warmup_bullet.global_position = camera.global_position + (-camera.global_transform.basis.z * 2.0)
		warmup_bullet.scale = Vector3(0.001, 0.001, 0.001) # Invisible to player
		
		await get_tree().process_frame
		await get_tree().process_frame
		warmup_bullet.queue_free()

func fire_shot(origin_in, cam_mouse_ray_project_in):
	print("fire_shot")
	origin = origin_in
	check_hit = true
	
func _update_hit():
	print("_check_hit")
	
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
		
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var origin = camera.project_ray_origin(screen_center)
	var direction = camera.project_ray_normal(screen_center)
	var end = origin + direction * RAY_LENGTH
	
	var query = PhysicsRayQueryParameters3D.create(origin, end, COLLISION_LAYER_ID, [$".."])
	query.exclude = [$".."]
	
	_aim_cast.global_position = origin
	_aim_cast.target_position = _aim_cast.to_local(end) #
	_aim_cast.force_raycast_update()
	
	if _aim_cast.is_colliding():
		print("HIT")
		collision_point = _aim_cast.get_collision_point()
	else:
		print("NO TARGET")
		var player_forward = -player.global_transform.basis.z
		collision_point = _fire_point.global_position + (player_forward * RAY_LENGTH)
	
	var fire_cast = $"../AimTarget/FireCast"
	fire_cast.global_position = _fire_point.global_transform.origin
	var local_collision_point = fire_cast.to_local(collision_point)
	
	fire_cast.set_target_position(local_collision_point)
	fire_cast.force_raycast_update()

func _check_hit():
	spawn_bullet(collision_point)
	
	var from_gun_query = PhysicsRayQueryParameters3D.create(_fire_point.global_transform.origin, collision_point)
	from_gun_query.exclude = [$".."]
	
	var from_gun_result = get_world_3d().direct_space_state.intersect_ray(from_gun_query)
	from_gun_result.clear()
	
func spawn_bullet(target_point: Vector3) -> void:
	if not bullet_scene:
		return
		
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# Place at muzzle and rotate its -Z axis straight toward the target point
	bullet.global_position = _fire_point.global_position
	if not bullet.global_position.is_equal_approx(target_point):
		bullet.look_at(target_point, Vector3.UP)

func _physics_process(delta: float) -> void:
	_update_hit()
	if check_hit:
		check_hit = false
		print("check")
		_check_hit()
