class_name HitBox
extends Node3D

var is_in_replay_mode: bool = false

func _ready() -> void:
	add_to_group("hit_boxes")

func _on_hit_box_area_area_entered(area: Area3D) -> void:
	# 重播模式下不执行任何逻辑
	if is_in_replay_mode:
		return
	
	if area.name == "BulletArea":
		var bullet = area.get_parent()
		# print("[HitBox] 检测到子弹: ", bullet.name)
		
		# 记录子弹销毁事件
		if ReplaySystem.Instance and ReplaySystem.Instance.mode_type == ReplaySystem.SystemMode.RECORDING:
			var event = ReplayEvent.new()
			event.event_type = ReplayEvent.EventType.BULLET_DESPAWN
			event.timestamp = ReplaySystem.Instance.current_time
			event.bullet_name = bullet.name
			ReplaySystem.Instance.replay_data.events.append(event)
			# print("[HitBox] ✓ 子弹销毁事件已记录")
		
		bullet.queue_free()
		# print("  → 子弹已销毁: ", bullet.name)
