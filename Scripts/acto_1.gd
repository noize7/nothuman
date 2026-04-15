extends Control

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
func _on_settings_icon_2_mouse_entered() -> void:
	settings_icon_2.text = "> START"
func _on_settings_icon_2_mouse_exited() -> void:
	settings_icon_2.text = "START"
