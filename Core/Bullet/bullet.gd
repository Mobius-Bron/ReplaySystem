class_name Bullet
extends Node3D

@export var speed: float = 10.0  # 飞行速度
@export var direction: Vector3 = Vector3.RIGHT  # 飞行方向（默认X轴正方向）
@export var lifetime: float = 5.0  # 子弹生命周期（秒）

var current_lifetime: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 向指定方向移动
	global_position += direction * speed * delta
	
	# 生命周期管理
	current_lifetime += delta
	if current_lifetime >= lifetime:
		queue_free()  # 自动删除子弹
