extends Node3D

@export var speed: float = 50.0
@export var damage: int = 10

@onready var area: Area3D = $"Area3D"

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += -global_transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()
	queue_free()
