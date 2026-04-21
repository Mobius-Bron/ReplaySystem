class_name ReplayEvent
extends Resource

enum EventType {
	BULLET_SPAWN,    # 子弹生成
	BULLET_DESPAWN   # 子弹消失
}

@export var event_type: EventType = EventType.BULLET_SPAWN
@export var timestamp: float = 0.0
@export var bullet_name: String = ""
@export var position: Vector3 = Vector3.ZERO
@export var direction: Vector3 = Vector3.RIGHT
@export var speed: float = 10.0
