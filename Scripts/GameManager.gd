extends Node

var volume_value : float = 50

func set_volume(new_value: float):
	volume_value = clamp(new_value, 0, 100)

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(volume_value / 100.0)
	)
