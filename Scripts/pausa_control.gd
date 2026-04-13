extends Control

@onready var button_resume: Button = $VBoxContainer/ButtonResume
@onready var button_settings: Button = $VBoxContainer/ButtonSettings
@onready var button_quit: Button = $VBoxContainer/ButtonQuit
@onready var audio_paused: AudioStreamPlayer = $VBoxContainer/AudioPaused
@onready var pausa_canvas: CanvasLayer = $".."
@onready var air: ColorRect = $"../../Canvas/Air"
@onready var settings_control: Control = $SettingsControl
@onready var shader: ColorRect = $"../../Canvas/Shader"

#Signals Button Resume
func _on_button_resume_mouse_entered() -> void:
	button_resume.text = "> RESUME"
	audio_paused.play()
func _on_button_resume_mouse_exited() -> void:
	button_resume.text = "RESUME"
func _on_button_resume_pressed() -> void:
	pausa_canvas.visible = false
	get_tree().paused = false
	shader.material.set_shader_parameter("pixel_resolution", 300.0)
	air.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
#Signals Button Settings
func _on_button_settings_mouse_entered() -> void:
	button_settings.text = "> SETTINGS"
	audio_paused.play()
func _on_button_settings_mouse_exited() -> void:
	button_settings.text = "SETTINGS"
func _on_button_settings_pressed() -> void:
	settings_control.visible = true
	
#Signals Button Quit
func _on_button_quit_mouse_entered() -> void:
	button_quit.text = "> QUIT"
	audio_paused.play()
func _on_button_quit_mouse_exited() -> void:
	button_quit.text = "QUIT"
func _on_button_quit_pressed() -> void:
	get_tree().quit()

#Signals Settings
func _on_button_pressed() -> void:
	settings_control.visible = false
