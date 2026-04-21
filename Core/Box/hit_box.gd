class_name HitBox
extends Node3D

func _on_hit_box_area_area_entered(area: Area3D) -> void:
	if area.name == "BulletArea":
		var bullet = area.get_parent()
		bullet.queue_free()
