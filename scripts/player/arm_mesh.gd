extends MeshInstance3D

@onready var _fire_cast: RayCast3D = $"../../../AimTarget/FireCast"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var target_point
	if _fire_cast.is_colliding():
		target_point = _fire_cast.get_collision_point()
	else:
		# Convert AimCast's local end point into global 3D space
		target_point = _fire_cast.to_global(_fire_cast.target_position)
	look_at(target_point)
