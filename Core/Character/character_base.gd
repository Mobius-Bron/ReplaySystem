class_name CharacterBase
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var is_in_replay_mode: bool = false

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if is_in_replay_mode:
		return
	
	var input_dir := Input.get_vector("player_left", "player_right", "player_fwd", "player_bwd")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
