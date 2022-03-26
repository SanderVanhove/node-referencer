extends Node2D

### Automatic References Start ###
onready var _collision_shape_2d: CollisionShape2D = $Node2D/KinematicBody2D/CollisionShape2D
onready var _ray_cast_2d: RayCast2D = $Node2D/AnimatedSprite/RayCast2D
### Automatic References Stop ###

const A_CONSTANT: int = 4

func _ready() -> void:
	_ray_cast_2d
