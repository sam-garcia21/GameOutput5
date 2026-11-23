extends Node3D

const RAY_LENGTH = 20
const COLLISION_LAYER_ID = pow(2, 13-1)
var check_hit = false
var origin
var cam_mouse_ray_project
@onready var _fire_point = $"../Body/GunArm/Muzzle"
@onready var _aim_cast = $"../AimTarget/AimCast"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func fire_shot(origin_in, cam_mouse_ray_project_in):
	print("fire_shot")
	origin = origin_in
	cam_mouse_ray_project = cam_mouse_ray_project_in
	check_hit = true

func _check_hit():
	print("_check_hit")
	
	var end = origin + cam_mouse_ray_project * RAY_LENGTH
	
	var query = PhysicsRayQueryParameters3D.create(origin, end, COLLISION_LAYER_ID, [$".."])
	query.exclude = [$".."]
	
	_aim_cast.global_position = origin
	_aim_cast.set_target_position(cam_mouse_ray_project * RAY_LENGTH)
	_aim_cast.force_raycast_update()
	
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	print("HIT")
	
	var collision_point = _aim_cast.get_collision_point()
	
	var fire_cast = $"../AimTarget/FireCast"
	fire_cast.global_position = _fire_point.global_transform.origin
	var local_collision_point = fire_cast.to_local(collision_point)
	
	fire_cast.set_target_position(local_collision_point)
	fire_cast.force_raycast_update()
	
	var from_gun_query = PhysicsRayQueryParameters3D.create(_fire_point.global_transform.origin, collision_point)
	from_gun_query.exclude = [$".."]
	
	var from_gun_result = get_world_3d().direct_space_state.intersect_ray(from_gun_query)
	
	result.clear()
	from_gun_result.clear()

func _physics_process(delta: float) -> void:
	if check_hit:
		check_hit = false
		print("check")
		_check_hit()
