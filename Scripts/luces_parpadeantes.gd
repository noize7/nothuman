extends OmniLight3D

@export var min_energy := 0.0
@export var max_energy := 0.4
@export var flicker_speed := 0.3

func _ready():
	randomize()
	flicker()

func flicker():
	while true:
		var chance = randf()
		
		if chance < 0.2:
			# apagón total breve
			light_energy = 0.0
			await get_tree().create_timer(randf_range(0.1, 0.5)).timeout
		else:
			# parpadeo normal
			light_energy = randf_range(min_energy, max_energy)
			await get_tree().create_timer(flicker_speed).timeout
