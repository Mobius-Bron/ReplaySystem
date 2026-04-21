class_name ReplayData
extends Resource

@export var frames: Array[ReplayFrame] = []
@export var events: Array[ReplayEvent] = []
@export var total_duration: float = 0.0

# 场景对象信息 - 使用平行数组存储以避免GDScript类型系统问题
@export var scene_object_types: Array[String] = []
@export var scene_object_paths: Array[String] = []
@export var scene_object_positions: Array[Vector3] = []
@export var scene_object_rotations: Array[Vector3] = []
@export var scene_object_scales: Array[Vector3] = []

func clear():
	frames.clear()
	events.clear()
	scene_object_types.clear()
	scene_object_paths.clear()
	scene_object_positions.clear()
	scene_object_rotations.clear()
	scene_object_scales.clear()
	total_duration = 0.0
