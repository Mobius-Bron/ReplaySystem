class_name FireBox
extends Node3D

const BULLET = preload("uid://nqj72jsxrdrk")

var is_in_replay_mode: bool = false

func _ready() -> void:
	add_to_group("fire_boxes")

func _on_fire_box_area_area_entered(area: Area3D) -> void:
	# 重播模式下不执行任何逻辑
	if is_in_replay_mode:
		return
	
	if area.name == "CharacterArea":
		print("[FireBox] 检测到玩家，生成子弹")
		
		var new_bullet: Bullet = BULLET.instantiate()
		new_bullet.name = "Bullet_" + str(Time.get_ticks_msec())
		
		get_tree().root.add_child(new_bullet)
		new_bullet.speed = randf_range(5.0, 15.0)
		new_bullet.global_position = self.global_position + Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1))
		
		print("  → 子弹已创建: ", new_bullet.name, " 位置: ", new_bullet.global_position)
		
		# 记录子弹生成事件
		if ReplaySystem.Instance and ReplaySystem.Instance.mode_type == ReplaySystem.SystemMode.RECORDING:
			var event = ReplayEvent.new()
			event.event_type = ReplayEvent.EventType.BULLET_SPAWN
			event.timestamp = ReplaySystem.Instance.current_time
			event.bullet_name = new_bullet.name
			event.position = new_bullet.global_position
			event.direction = new_bullet.direction
			event.speed = new_bullet.speed
			ReplaySystem.Instance.replay_data.events.append(event)
			print("[FireBox] ✓ 子弹生成事件已记录")

# 重播模式下生成子弹（由ReplaySystem调用）
func replay_spawn_bullet(pos: Vector3, dir: Vector3, spd: float, bname: String) -> Bullet:
	print("[FireBox] 重播模式生成子弹: ", bname)
	
	var new_bullet: Bullet = BULLET.instantiate()
	new_bullet.name = bname
	new_bullet.is_in_replay_mode = true
	new_bullet.global_position = pos
	new_bullet.direction = dir
	new_bullet.speed = spd
	
	get_tree().root.add_child(new_bullet)
	print("  ✓ 重播子弹已创建: ", bname, " 位置: ", pos)
	return new_bullet
