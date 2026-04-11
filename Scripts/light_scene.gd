extends OmniLight3D

@export_category("Debug")
@export var encendido_luz: bool

func _ready() -> void:
	self.visible = encendido_luz
