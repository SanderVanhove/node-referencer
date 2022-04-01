extends Node2D

### Automatic References Start ###
onready var _animated_sprite: AnimatedSprite = $Node2D/AnimatedSprite
onready var _kinematic_body_2d: KinematicBody2D = $Node2D/KinematicBody2D
onready var _node_2d: Node2D = $Node2D
onready var _tool_custome_class_script: CustomeClass = $ToolCustomeClassScript
onready var _tool_script: Node2D = $ToolScript
onready var _with_space: Node2D = $"With Space"
### Automatic References Stop ###


const A_CONSTANT: int = 4

func _ready() -> void:
	pass
