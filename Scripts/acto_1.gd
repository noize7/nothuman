extends Control


var switch : bool = false

# Tab
@onready var home_button: Button = $Tab/HomeButton
@onready var back_audio: ColorRect = $Tab/AudioButton/BackAudio


# Menu Home
@onready var background_menu_home: ColorRect = $BackgroundMenuHome
@onready var settings_icon_2: Button = $BackgroundMenuHome/SettingsIcon2


# Boton Menu Home
func _on_home_button_pressed() -> void:
	background_menu_home.visible = !background_menu_home.visible

# Boton Salir de Juego
func _on_exit_icon_pressed() -> void:
	get_tree().quit()

# Boton Start De Menu Home
# - Entrada de Mouse al Boton
func _on_settings_icon_2_mouse_entered() -> void:
	settings_icon_2.text = "> START"
# - Salida de Mouse al Boton
func _on_settings_icon_2_mouse_exited() -> void:
	settings_icon_2.text = "START"
# - Presion en el Boton
func _on_settings_icon_2_pressed() -> void:
	background_menu_home.visible = false
	home_button.disabled = true
	get_tree().change_scene_to_file("res://Escenas/mapa_pruebas.tscn")
	
	
	
#Tabs Botones
# - AudioBoton

func _on_audio_button_pressed() -> void:
	switch = !switch
	back_audio.visible = switch


func _on_audio_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
