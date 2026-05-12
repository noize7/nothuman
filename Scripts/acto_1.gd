extends Control


var switch : bool = false
var switch_archivos : bool = false
# Tab
@onready var home_button: Button = $Tab/HomeButton
@onready var back_audio: ColorRect = $Tab/AudioButton/BackAudio
@onready var label_value: Label = $Tab/AudioButton/BackAudio/LabelValue
@onready var audio: HScrollBar = $Tab/AudioButton/BackAudio/Audio

# Menu Home
@onready var background_menu_home: ColorRect = $BackgroundMenuHome
@onready var trash_button: TextureButton = $TrashButton

# Sounds
@onready var click: AudioStreamPlayer = $Click

#OpenWindows
@onready var background_archivos: ColorRect = $BackgroundArchivos

#Icons
@onready var exit_icon: Button = $BackgroundArchivos/Bar/Exit
@onready var adm_archivos: Button = $BackgroundMenuHome/MenuHome/AdmArchivos

#ButtonsArchives
@onready var documents: Control = $BackgroundArchivos/Documents
@onready var images: Control = $BackgroundArchivos/Images

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("light"):
		click.play()


# Boton Menu Home
func _on_home_button_pressed() -> void:
	background_menu_home.visible = !background_menu_home.visible

# Boton Salir de Juego
func _on_exit_icon_pressed() -> void:
	get_tree().quit()

# Boton Start De Menu Home
	
#Tabs Botones
# - AudioBoton

func _on_audio_button_pressed() -> void:
	switch = !switch
	back_audio.visible = switch
	trash_button.disabled = switch

# - Cambio de Valor de audio
func _on_audio_value_changed(value: float) -> void:
	GameManager.set_volume(value)
	label_value.text = str(int(GameManager.volume_value))

# Icons Signals
func _on_exit_pressed() -> void:
	switch_archivos = !switch_archivos
	background_archivos.visible = switch_archivos


func _on_adm_archivos_pressed() -> void:
	switch_archivos = !switch_archivos
	background_archivos.visible = switch_archivos
	background_menu_home.visible = false


func _on_documents_pressed() -> void:
	documents.visible = true
	images.visible = false


func _on_images_pressed() -> void:
	documents.visible = false
	images.visible = true
