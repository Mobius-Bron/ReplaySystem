class_name FireBox
extends Node3D

const BULLET = preload("uid://nqj72jsxrdrk")

func _on_fire_box_area_area_entered(area: Area3D) -> void:
	if area.name == "CharacterArea":
		var new_bullet: Bullet = BULLET.instantiate()
		
		get_tree().root.add_child(new_bullet)
		new_bullet.global_position = self.global_position + Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1))
