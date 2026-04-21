class_name ReplayFrame
extends Resource

@export var timestamp: float = 0.0
@export var player_position: Vector3 = Vector3.ZERO
@export var camera_position: Vector3 = Vector3.ZERO
@export var camera_rotation: Vector3 = Vector3.ZERO
@export var bullet_positions: Array[Vector3] = []
@export var bullet_names: Array[String] = []

class BulletState:
	var bullet_id: int
	var position: Vector3
	var direction: Vector3
	var speed: float
	
	func _init(id: int = -1, pos: Vector3 = Vector3.ZERO, dir: Vector3 = Vector3.RIGHT, spd: float = 10.0):
		bullet_id = id
		position = pos
		direction = dir
		speed = spd
