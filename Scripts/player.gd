extends CharacterBody3D

const SPEED = 5
const JUMP_VELOCITY = 4.5

# Sensaciones humanas
const LOOK_SMOOTH = 12.0
const BOB_FREQ = 6.0
const BOB_AMP = 0.015
const BREATH_FREQ = 1.5
const BREATH_AMP = 0.01

@onready var camera = $Camera3D

var rotation_x := 0.0
var target_rot_y := 0.0
var current_rot_y := 0.0

var bob_time := 0.0
var base_cam_y := 0.0

# =========================
# RAYCAST
# =========================
@onready var raycast = $Camera3D/RayCast
@onready var air: ColorRect = $Canvas/Air

var objeto_actual = null
var puede_reproducir_bebedero = true

# FIX PUERTAS
var ultimo_objeto = null
var tiempo_gracia := 0.2
var timer_gracia := 0.0

# =========================
# PAUSA
# =========================
@onready var pausa_canvas: CanvasLayer = $PausaCanvas
@onready var shader: ColorRect = $Canvas/Shader

# =========================
# ANIMACIÓN
# =========================
@onready var AnimationsPlayer : AnimationPlayer = $Police2_2/AnimationPlayer

# =========================
# SONIDOS DE CAMINAR
# =========================
@onready var ray_cast_walk: RayCast3D = $RayCastWalk
@onready var walk_1: AudioStreamPlayer3D = $Walk
@onready var walk_2: AudioStreamPlayer3D = $Walk2
@onready var walk_3: AudioStreamPlayer3D = $Walk3

enum estadoSonidoCaminar{
	walkInside,
	walkGrass,
	walkStone
}
@export_category("Sonidos al Caminar")
@export var estadoSonido: estadoSonidoCaminar = estadoSonidoCaminar.walkInside
var tiempo_paso = 0.0

# =========================
# FLASHLIGHT
# =========================
@onready var flashlight_icon: TextureRect = $Canvas/FlashlightIcon


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_cam_y = camera.position.y
	air.pivot_offset = air.size / 2


func _input(event):
	if event is InputEventMouseMotion:
		target_rot_y -= event.relative.x * Settings.mouse_sensitivity
		rotation_x -= event.relative.y * Settings.mouse_sensitivity
		rotation_x = clamp(rotation_x, deg_to_rad(-80), deg_to_rad(80))

	if event.is_action_pressed("cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		air.visible = false
		pausa_canvas.visible = true
		shader.material.set_shader_parameter("pixel_resolution", 512.0)
		get_tree().paused = true


func _physics_process(delta: float) -> void:
	# =========================
	# MOVIMIENTO
	# =========================
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		if AnimationsPlayer.current_animation != "walk":
			AnimationsPlayer.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		if AnimationsPlayer.current_animation != "idle":
			AnimationsPlayer.play("idle")

	move_and_slide()

	# =========================
	# ROTACIÓN SUAVE
	# =========================
	current_rot_y = lerp(current_rot_y, target_rot_y, delta * LOOK_SMOOTH)
	rotation.y = current_rot_y
	camera.rotation.x = lerp(camera.rotation.x, rotation_x, delta * LOOK_SMOOTH)

	# =========================
	# HEAD BOB + RESPIRACIÓN
	# =========================
	var speed := Vector2(velocity.x, velocity.z).length()

	var bob_offset := 0.0
	if speed > 0.1 and is_on_floor():
		bob_time += delta * BOB_FREQ
		bob_offset = sin(bob_time) * BOB_AMP
	else:
		bob_time = 0.0

	var breath = sin(Time.get_ticks_msec() * 0.001 * BREATH_FREQ) * BREATH_AMP
	camera.position.y = base_cam_y + bob_offset + breath

	# =========================
	# RAYCAST INTERACCIÓN
	# =========================
	var encontrado = null
	var bebedero_detectado = null
	var linterna_detectado = null
	if raycast.is_colliding():
		var obj = raycast.get_collider()
		while obj:
			if obj.is_in_group("puertas"):
				encontrado = obj
				ultimo_objeto = obj
				timer_gracia = tiempo_gracia
				break
			if obj.is_in_group("bebedero"):
				bebedero_detectado = obj
				break
			if obj.is_in_group("Linterna"):
				linterna_detectado = obj
				break
			obj = obj.get_parent()

	if encontrado:
		objeto_actual = encontrado
	else:
		if timer_gracia > 0:
			timer_gracia -= delta
			objeto_actual = ultimo_objeto
		else:
			objeto_actual = null
			
	# =========================
	# RAYCAST SONIDOS
	# =========================
	#TRABAJAR
	sonidos_caminar(delta)

	# =========================
	# UI
	# =========================
	var target_scale = Vector2.ONE
	var interactuable = objeto_actual or bebedero_detectado or linterna_detectado

	if interactuable:
		var pulse = sin(Time.get_ticks_msec() * 0.01) * 0.05
		target_scale = Vector2(1.5 + pulse, 1.5 + pulse)

	air.scale = air.scale.lerp(target_scale, delta * 8.0)

	if Input.is_action_just_pressed("interact"):
		if objeto_actual:
			abrir_puerta(objeto_actual)
		elif bebedero_detectado and puede_reproducir_bebedero:
			puede_reproducir_bebedero = false
			$Bebedero.play()
		elif linterna_detectado:
			linterna_detectado.get_node("AudioPickup").play()
			GameManager.LinternInventory = true
			flashlight_show_icon()

# =========================
# PUERTAS
# =========================
func abrir_puerta(puerta):
	

	if puerta.has_meta("moviendo") and puerta.get_meta("moviendo"):
		return

	if not puerta.has_meta("rotacion_inicial"):
		puerta.set_meta("rotacion_inicial", puerta.rotation_degrees.y)

	var rot_inicial = puerta.get_meta("rotacion_inicial")
	var abierta = puerta.get_meta("abierta") if puerta.has_meta("abierta") else false

	puerta.set_meta("moviendo", true)

	var audio_abrir = puerta.get_node_or_null("AudioAbrir")
	var audio_cerrar = puerta.get_node_or_null("AudioCerrar")

	var tween = create_tween()

	if abierta:
		if audio_abrir:
			audio_abrir.pitch_scale = randf_range(0.9, 1.1)
			audio_abrir.play()

		tween.tween_property(puerta, "rotation_degrees:y", rot_inicial, 0.4)
		puerta.set_meta("abierta", false)
	else:
		if audio_cerrar:
			audio_cerrar.pitch_scale = randf_range(0.9, 1.1)
			audio_cerrar.play()

		tween.tween_property(puerta, "rotation_degrees:y", rot_inicial + 90, 0.4)
		puerta.set_meta("abierta", true)

	tween.finished.connect(func():
		puerta.set_meta("moviendo", false)
	)

# =========================
# SONIDOS DE CAMINAR
# =========================
func sonidos_caminar(delta):
	var moviendose = is_on_floor() and Vector2(velocity.x, velocity.z).length() > 0.1
	
	var audio_actual: AudioStreamPlayer3D
	var intervalo: float

	match estadoSonido:
		estadoSonidoCaminar.walkInside:
			audio_actual = walk_1
			intervalo = 1.0
		estadoSonidoCaminar.walkGrass:
			audio_actual = walk_2
			intervalo = 0.6
		estadoSonidoCaminar.walkStone:
			audio_actual = walk_3
			intervalo = 0.4

	if moviendose:
		tiempo_paso -= delta
		
		if tiempo_paso <= 0:
			audio_actual.pitch_scale = randf_range(0.9, 1.1)
			audio_actual.play()
			tiempo_paso = intervalo
	else:
		if audio_actual and audio_actual.playing:
			audio_actual.stop()

func flashlight_show_icon():
	flashlight_icon.visible = true

func _on_h_slider_value_changed(value: float) -> void:
	Settings.mouse_sensitivity = value


func _on_bebedero_finished() -> void:
	puede_reproducir_bebedero = true
