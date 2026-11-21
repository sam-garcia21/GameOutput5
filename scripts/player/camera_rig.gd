class_name CameraRig
extends Node3D
## Over-the-shoulder camera rig. Attached to Player/CameraPivot.
##
##   CameraPivot (this)   : at shoulder/head height, handles PITCH only.
##   └ SpringArm3D        : offset sideways to a shoulder, extends backwards.
##                          Pulls the camera in front of walls (terrain collision).
##     └ Camera3D
##
## The rig is parented to the player and has no follow-smoothing, so the camera
## stays at a fixed spot relative to the actor. The only interpolated motion is
## the optional shoulder switch, which the spec requires to be a smooth
## transition instead of instant.

@export var min_pitch_deg: float = -70.0
@export var max_pitch_deg: float = 60.0

@export_group("Shoulder")
## Sideways distance of the camera from the actor's centre line.
@export var shoulder_offset: float = 0.6
## Higher means a faster (but still smooth) shoulder switch.
@export var switch_speed: float = 10.0

@onready var spring_arm: SpringArm3D = $SpringArm3D

## 1 = right shoulder, -1 = left shoulder.
var _shoulder_side: float = 1.0


func _ready() -> void:
	# Don't let the camera collide with its own player's capsule.
	var player := get_parent() as CollisionObject3D
	if player:
		spring_arm.add_excluded_object(player.get_rid())
	spring_arm.position.x = shoulder_offset * _shoulder_side


## Called by the player on vertical mouse movement (radians).
func add_pitch(amount: float) -> void:
	rotation.x = clampf(rotation.x + amount,
			deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))


func switch_shoulder() -> void:
	_shoulder_side = -_shoulder_side


func is_right_shoulder() -> bool:
	return _shoulder_side > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_shoulder"):
		switch_shoulder()


func _process(delta: float) -> void:
	# Frame-rate independent exponential ease toward the target shoulder.
	var target_x := shoulder_offset * _shoulder_side
	spring_arm.position.x = lerpf(spring_arm.position.x, target_x,
			1.0 - exp(-switch_speed * delta))
