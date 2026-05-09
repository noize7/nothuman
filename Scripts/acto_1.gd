extends Control


var switch : bool = false

# Tab
@onready var home_button: Button = $Tab/HomeButton
@onready var back_audio: ColorRect = $Tab/AudioButton/BackAudio
@onready var label_value: Label = $Tab/AudioButton/BackAudio/LabelValue
@onready var audio: HScrollBar = $Tab/AudioButton/BackAudio/Audio

# Menu Home
@onready var background_menu_home: ColorRect = $BackgroundMenuHome
@onready var settings_icon_2: Button = $BackgroundMenuHome/SettingsIcon2
@onready var trash_button: TextureButton = $TrashButton
@onready var folder_button: TextureButton = $FolderButton






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
	trash_button.disabled = switch
	folder_button.disabled = switch

# - Cambio de Valor de audio
func _on_audio_value_changed(value: float) -> void:
	GameManager.set_volume(value)
	label_value.text = str(int(GameManager.volume_value))
