class_name Crate

extends StaticBody3D

@export var health: int = 3
@onready var mesh: MeshInstance3D = $Mesh
@onready var particles: GPUParticles3D = $Particles

func _take_damage() -> void:
	health -= 1

	if health <= 0:
		_break()
		
func _break() -> void:
	mesh.visiible = false
	particles.visible = true
	particles.emitting = true
	await particles.finished
	queue_free()
