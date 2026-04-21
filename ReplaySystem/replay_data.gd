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

# 灯光信息
@export var light_types: Array[String] = []
@export var light_positions: Array[Vector3] = []
@export var light_rotations: Array[Vector3] = []
@export var light_energy: Array[float] = []
@export var light_color: Array[Color] = []
@export var light_range: Array[float] = []

func clear():
	frames.clear()
	events.clear()
	scene_object_types.clear()
	scene_object_paths.clear()
	scene_object_positions.clear()
	scene_object_rotations.clear()
	scene_object_scales.clear()
	light_types.clear()
	light_positions.clear()
	light_rotations.clear()
	light_energy.clear()
	light_color.clear()
	light_range.clear()
	total_duration = 0.0
