class_name ReplaySystem
extends Node3D

static var Instance: ReplaySystem = null

enum SystemMode { RECORDING, PLAYBACK, OFF }

@onready var free_camera: Camera3D = $FreeCamera

@export var mode_type: SystemMode = SystemMode.OFF
@export var record_file_path: String = "res://replaysystem/data/ReplayData.res"
@export_range(0.0, 30.0) var MoveSpeed: float = 10.0
@export_range(0.0, 3.0) var RotationSpeed: float = 1.0
@export var sample_rate: float = 0.1

var Pitch: float = 0.0
var Yaw: float = 0.0

var replay_data: ReplayData = null
var current_time: float = 0.0
var last_sample_time: float = 0.0

var is_paused: bool = false
var use_free_camera: bool = false
var spawned_bullets: Dictionary = {}  # bullet_name -> Bullet

func _init():
	Instance = self

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	match mode_type:
		SystemMode.OFF:
			set_process(false)
		
		SystemMode.RECORDING:
			_start_recording()
		
		SystemMode.PLAYBACK:
			_start_playback()

func _process(delta: float) -> void:
	match mode_type:
		SystemMode.OFF:
			return
		
		SystemMode.RECORDING:
			_tick_recording(delta)
		
		SystemMode.PLAYBACK:
			if not is_paused:
				_tick_playback(delta)
			_handle_playback_input()

func _exit_tree() -> void:
	stop_and_save_recording()

func _start_recording() -> void:
	print("========================================")
	print("[ReplaySystem] 开始录制...")
	print("========================================")
	
	replay_data = ReplayData.new()
	current_time = 0.0
	last_sample_time = 0.0
	
	var root = get_tree().current_scene
	print("[ReplaySystem] 当前场景: ", root.name)
	print("[ReplaySystem] 场景子节点数: ", root.get_child_count())
	
	# 记录场景中所有对象的信息
	_record_scene_objects()
	
	if free_camera:
		free_camera.current = false
		print("[ReplaySystem] 自由相机已禁用")
	
	print("[ReplaySystem] 录制系统就绪!")
	print("  - 记录的场景对象数: ", replay_data.scene_object_types.size())
	print("========================================")

func _record_scene_objects() -> void:
	print("[ReplaySystem] 正在扫描场景对象...")
	var root = get_tree().current_scene
	
	if not root:
		push_error("[ReplaySystem] 无法获取当前场景根节点!")
		return
	
	var player_count = 0
	var firebox_count = 0
	var hitbox_count = 0
	var ground_count = 0
	var light_count = 0
	
	print("[ReplaySystem] 遍历场景中的 ", root.get_child_count(), " 个对象...")
	
	for child in root.get_children():
		print("  检查对象: ", child.name, " (类型: ", child.get_class(), ")")
		
		# 玩家角色
		if child is CharacterBody3D:
			replay_data.scene_object_types.append("Player")
			replay_data.scene_object_paths.append("res://Core/Character/character_base.tscn")
			replay_data.scene_object_positions.append(child.global_position)
			replay_data.scene_object_rotations.append(child.rotation)
			replay_data.scene_object_scales.append(child.scale)
			player_count += 1
			print("    ✓ 识别为玩家，位置: ", child.global_position)
		
		# FireBox
		elif "firebox" in child.name.to_lower():
			replay_data.scene_object_types.append("FireBox")
			replay_data.scene_object_paths.append("res://Core/Box/fire_box.tscn")
			replay_data.scene_object_positions.append(child.global_position)
			replay_data.scene_object_rotations.append(child.rotation)
			replay_data.scene_object_scales.append(child.scale)
			firebox_count += 1
			print("    ✓ 识别为FireBox，位置: ", child.global_position)
		
		# HitBox
		elif "hitbox" in child.name.to_lower():
			replay_data.scene_object_types.append("HitBox")
			replay_data.scene_object_paths.append("res://Core/Box/hit_box.tscn")
			replay_data.scene_object_positions.append(child.global_position)
			replay_data.scene_object_rotations.append(child.rotation)
			replay_data.scene_object_scales.append(child.scale)
			hitbox_count += 1
			print("    ✓ 识别为HitBox，位置: ", child.global_position)
		
		# 地面（MeshInstance3D）
		elif child is MeshInstance3D and ("ground" in child.name.to_lower() or "floor" in child.name.to_lower()):
			replay_data.scene_object_types.append("Ground")
			replay_data.scene_object_paths.append("")  # 地面不需要预制体
			replay_data.scene_object_positions.append(child.global_position)
			replay_data.scene_object_rotations.append(child.rotation)
			replay_data.scene_object_scales.append(child.scale)
			ground_count += 1
			print("    ✓ 识别为地面，位置: ", child.global_position)
		
		# 光源
		elif child is Light3D:
			var light_type = "DirectionalLight3D" if child is DirectionalLight3D else "OmniLight3D"
			replay_data.light_types.append(light_type)
			replay_data.light_positions.append(child.global_position)
			replay_data.light_rotations.append(child.rotation)
			
			# 记录光源属性
			if child is DirectionalLight3D:
				replay_data.light_energy.append(child.light_energy)
				replay_data.light_color.append(child.light_color)
				replay_data.light_range.append(0.0)  # DirectionalLight没有range
			elif child is OmniLight3D:
				replay_data.light_energy.append(child.omni_range)
				replay_data.light_color.append(child.color)
				replay_data.light_range.append(child.omni_range)
			
			light_count += 1
			print("    ✓ 识别为光源(", light_type, ")，能量: ", child.light_energy, " 颜色: ", child.light_color)
		
		else:
			print("    - 跳过此对象")
	
	print("[ReplaySystem] 场景扫描完成:")
	print("  - 玩家数量: ", player_count)
	print("  - FireBox数量: ", firebox_count)
	print("  - HitBox数量: ", hitbox_count)
	print("  - 地面数量: ", ground_count)
	print("  - 光源数量: ", light_count)
	print("  - 总对象数: ", replay_data.scene_object_types.size())

func _tick_recording(delta: float) -> void:
	current_time += delta
	if current_time - last_sample_time >= sample_rate:
		_sample_frame()
		last_sample_time = current_time

func _sample_frame() -> void:
	var frame = ReplayFrame.new()
	frame.timestamp = current_time
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		frame.player_position = player.global_position
	
	var main_camera = get_viewport().get_camera_3d()
	if main_camera:
		frame.camera_position = main_camera.global_position
		frame.camera_rotation = main_camera.rotation
	
	for bullet in get_tree().get_nodes_in_group("bullets"):
		if bullet is Bullet:
			frame.bullet_positions.append(bullet.global_position)
			frame.bullet_names.append(bullet.name)
	
	replay_data.frames.append(frame)
	
	if replay_data.frames.size() % 10 == 0:
		print("[ReplaySystem] 已录制帧数: ", replay_data.frames.size(), " 当前时间: ", current_time)

func _start_playback() -> void:
	print("========================================")
	print("[ReplaySystem] 开始重播...")
	print("========================================")
	
	if not ResourceLoader.exists(record_file_path):
		push_error("录制文件不存在: " + record_file_path)
		mode_type = SystemMode.OFF
		return
	
	print("[ReplaySystem] 加载录制文件: ", record_file_path)
	replay_data = ResourceLoader.load(record_file_path) as ReplayData
	
	if not replay_data:
		push_error("加载录制数据失败")
		mode_type = SystemMode.OFF
		return
	
	print("[ReplaySystem] 数据加载成功!")
	print("  - 总帧数: ", replay_data.frames.size())
	print("  - 场景对象数: ", replay_data.scene_object_types.size())
	print("  - 总时长: ", replay_data.total_duration)
	
	current_time = 0.0
	is_paused = false
	use_free_camera = false
	spawned_bullets.clear()
	
	# 清空当前场景并重建
	print("[ReplaySystem] 正在重建场景...")
	await _clear_and_rebuild_scene()
	
	# 应用第一帧
	if replay_data.frames.size() > 0:
		print("[ReplaySystem] 应用初始帧状态...")
		_apply_frame(replay_data.frames[0])
	
	_setup_playback_camera()
	
	print("[ReplaySystem] 重播系统就绪!")
	print("========================================")

func _clear_and_rebuild_scene() -> void:
	var root = get_tree().current_scene
	
	print("[ReplaySystem] 清空现有场景对象...")
	var deleted_count = 0
	for child in root.get_children():
		if child != self and not (child is Camera3D):
			child.queue_free()
			deleted_count += 1
	print("  - 删除了 ", deleted_count, " 个对象")
	
	# 等待删除完成
	await get_tree().process_frame
	print("[ReplaySystem] 场景已清空")
	
	# 根据录制数据重建场景
	print("[ReplaySystem] 开始实例化场景对象...")
	var instantiated_count = 0
	
	# 1. 先实例化地面
	for i in range(replay_data.scene_object_types.size()):
		if replay_data.scene_object_types[i] == "Ground":
			var position = replay_data.scene_object_positions[i]
			var rotation = replay_data.scene_object_rotations[i]
			var scale = replay_data.scene_object_scales[i]
			
			print("  → 创建地面...")
			
			# 创建简单的地面对象
			var ground = MeshInstance3D.new()
			root.add_child(ground)
			
			ground.name = "Ground"
			ground.mesh = PlaneMesh.new()
			ground.mesh.size = Vector2(50, 50)
			ground.global_position = position
			ground.rotation = rotation
			ground.scale = scale
			
			# 添加材质
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.3, 0.3, 0.3, 1)
			ground.material_override = material
			
			instantiated_count += 1
			print("    ✓ 地面创建成功，位置: ", position)
	
	# 2. 实例化游戏对象（Player、FireBox、HitBox）
	for i in range(replay_data.scene_object_types.size()):
		var obj_type = replay_data.scene_object_types[i]
		
		if obj_type == "Ground":
			continue  # 地面已经创建过了
		
		var scene_path = replay_data.scene_object_paths[i]
		var position = replay_data.scene_object_positions[i]
		var rotation = replay_data.scene_object_rotations[i]
		var scale = replay_data.scene_object_scales[i]
		
		print("  → 实例化: ", obj_type, " 路径: ", scene_path)
		
		if scene_path.is_empty():
			push_error("对象类型 ", obj_type, " 没有预制体路径")
			continue
		
		if not ResourceLoader.exists(scene_path):
			push_error("预制体不存在: " + scene_path)
			continue
		
		var scene = load(scene_path) as PackedScene
		if scene:
			var instance = scene.instantiate()
			instance.global_position = position
			instance.rotation = rotation
			instance.scale = scale
			instance.is_in_replay_mode = true
			
			root.add_child(instance)
			instantiated_count += 1
			print("    ✓ 成功创建: ", obj_type, " 位置: ", instance.global_position)
		else:
			push_error("加载预制体失败: " + scene_path)
	
	# 3. 实例化光源
	for i in range(replay_data.light_types.size()):
		var light_type = replay_data.light_types[i]
		var position = replay_data.light_positions[i]
		var rotation = replay_data.light_rotations[i]
		var energy = replay_data.light_energy[i]
		var color = replay_data.light_color[i]
		var range_val = replay_data.light_range[i]
		
		print("  → 创建光源: ", light_type)
		
		var light: Light3D
		if light_type == "DirectionalLight3D":
			light = DirectionalLight3D.new()
			light.light_energy = energy
			light.light_color = color
		elif light_type == "OmniLight3D":
			light = OmniLight3D.new()
			light.omni_range = range_val
			light.color = color
		
		if light:
			light.global_position = position
			light.rotation = rotation
			root.add_child(light)
			instantiated_count += 1
			print("    ✓ 光源创建成功，能量: ", energy, " 颜色: ", color)
	
	print("[ReplaySystem] 场景重建完成，共创建 ", instantiated_count, " 个对象")
	
	# 再等待一帧确保实例化完成
	await get_tree().process_frame
	print("[ReplaySystem] 所有对象初始化完毕!")

func _setup_playback_camera() -> void:
	if free_camera:
		free_camera.current = false
	use_free_camera = false

func _tick_playback(delta: float) -> void:
	# 暂停时不更新
	if is_paused:
		return
	
	current_time += delta
	
	if current_time >= replay_data.total_duration and replay_data.total_duration > 0:
		print("[ReplaySystem] 重播完成")
		is_paused = true
		return
	
	var target_frame = _find_frame_at_time(current_time)
	if target_frame:
		_apply_frame(target_frame)
	
	# 移除事件处理，子弹完全由帧数据驱动

func _find_frame_at_time(time: float) -> ReplayFrame:
	if not replay_data or replay_data.frames.size() == 0:
		return null
	
	var closest_frame: ReplayFrame = null
	var min_diff = INF
	
	for frame in replay_data.frames:
		var diff = abs(frame.timestamp - time)
		if diff < min_diff:
			min_diff = diff
			closest_frame = frame
	
	return closest_frame

func _apply_frame(frame: ReplayFrame) -> void:
	if not frame:
		return
	
	# 同步玩家位置
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = frame.player_position
	
	# 同步子弹状态 - 纯视觉代理方式
	var active_bullets: Dictionary = {}
	for i in range(frame.bullet_names.size()):
		var name = frame.bullet_names[i]
		active_bullets[name] = frame.bullet_positions[i]
	
	# 销毁不在当前帧中的子弹
	for name in spawned_bullets.keys():
		if not active_bullets.has(name):
			var bullet = spawned_bullets[name]
			if bullet:
				bullet.queue_free()
			spawned_bullets.erase(name)
	
	# 更新或创建子弹代理
	for name in active_bullets.keys():
		var pos = active_bullets[name]
		if spawned_bullets.has(name):
			# 更新现有子弹位置
			var bullet = spawned_bullets[name]
			if bullet:
				bullet.global_position = pos
		else:
			# 创建简单的视觉代理（绿色球体）
			var proxy = MeshInstance3D.new()
			proxy.mesh = SphereMesh.new()
			proxy.mesh.radius = 0.1
			proxy.mesh.height = 0.2
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0, 1, 0, 1)  # 绿色
			proxy.material_override = material
			
			proxy.global_position = pos
			proxy.name = name
			proxy.set_process_mode(Node.PROCESS_MODE_ALWAYS)  # 确保不受暂停影响
			
			get_tree().current_scene.add_child(proxy)
			spawned_bullets[name] = proxy
			print("[ReplaySystem] 创建子弹代理: ", name, " 位置: ", pos)

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_F1):
		is_paused = not is_paused
		print("[ReplaySystem] 暂停状态: ", is_paused)
	
	if Input.is_key_pressed(KEY_F2):
		use_free_camera = not use_free_camera
		if free_camera:
			free_camera.current = use_free_camera
		print("[ReplaySystem] 自由相机: ", use_free_camera)
	
func _handle_playback_input() -> void:
	if use_free_camera and free_camera:
		var input_dir: Vector3 = Vector3.ZERO
		
		if Input.is_key_pressed(KEY_W):
			input_dir.z -= 1
		if Input.is_key_pressed(KEY_S):
			input_dir.z += 1
		if Input.is_key_pressed(KEY_A):
			input_dir.x -= 1
		if Input.is_key_pressed(KEY_D):
			input_dir.x += 1
		if Input.is_key_pressed(KEY_Q):
			input_dir.y += 1
		if Input.is_key_pressed(KEY_E):
			input_dir.y -= 1
		
		free_camera.global_position += input_dir.normalized() * MoveSpeed * get_process_delta_time()

func stop_and_save_recording() -> void:
	if mode_type != SystemMode.RECORDING:
		return
	
	print("========================================")
	print("[ReplaySystem] 停止录制并保存...")
	print("========================================")
	
	if replay_data.frames.size() > 0:
		replay_data.total_duration = replay_data.frames[-1].timestamp
	
	print("[ReplaySystem] 录制统计:")
	print("  - 总帧数: ", replay_data.frames.size())
	print("  - 总时长: ", replay_data.total_duration, " 秒")
	
	# 确保目录存在
	var dir = DirAccess.open("res://replaysystem")
	if not dir:
		DirAccess.make_dir_recursive_absolute("res://replaysystem/data")
		print("[ReplaySystem] 创建数据目录: res://replaysystem/data")
	
	# 使用正确的路径
	var save_path = "res://replaysystem/data/ReplayData.res"
	var save_error = ResourceSaver.save(replay_data, save_path)
	
	if save_error == OK:
		print("[ReplaySystem] ✓ 录制已保存到: ", save_path)
	else:
		push_error("[ReplaySystem] ✗ 保存失败: " + str(save_error))
	
	mode_type = SystemMode.OFF
	set_process(false)
	print("========================================")
