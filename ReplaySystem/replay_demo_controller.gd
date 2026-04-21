class_name ReplayDemoController
extends Node3D

# 这个脚本展示如何手动控制ReplaySystem
# 可以将此脚本添加到场景中的任意节点上

@export var auto_stop_time: float = 25.0  # 自动停止录制的时间（秒）
var elapsed_time: float = 0.0

func _ready() -> void:
	# 等待ReplaySystem初始化
	await get_tree().process_frame
	
	if ReplaySystem.Instance:
		print("[ReplayDemo] ReplaySystem已就绪")
		print("[ReplayDemo] 当前模式: ", ReplaySystem.Instance.mode_type)
	else:
		push_warning("[ReplayDemo] 未找到ReplaySystem实例")

func _process(delta: float) -> void:
	elapsed_time += delta
	
	# 示例：在录制模式下，25秒后自动停止并保存
	if ReplaySystem.Instance and ReplaySystem.Instance.mode_type == ReplaySystem.SystemMode.RECORDING:
		if elapsed_time >= auto_stop_time:
			print("[ReplayDemo] 达到自动停止时间，保存录制...")
			ReplaySystem.Instance.stop_and_save_recording()
			
			# 可以在这里切换到重播模式或其他操作
			print("[ReplayDemo] 录制完成！可以切换到PLAYBACK模式查看重播")
