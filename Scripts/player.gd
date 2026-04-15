extends CharacterBody3D

const SPEED = 2.5
const JUMP_VELOCITY = 4.5
#const MOUSE_SENSITIVITY = 0.002

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

# Linterna Variables
@onready var spot_light_3d: SpotLight3D = $Camera3D/SpotLight3D
const FLASHLIGHT_LAG = 10.0
const FLASHLIGHT_SWAY = 0.02
var toggleLight = false
var flashlight_rot := Vector2.ZERO
var flashlight_target := Vector2.ZERO

# Ray Cast
@onready var raycast = $Camera3D/RayCast
@onready var air: ColorRect = $Canvas/Air

var objeto_actual = null
var puede_reproducir_bebedero = true
# 🔥 FIX PUERTAS
var ultimo_objeto = null
var tiempo_gracia := 0.2
var timer_gracia := 0.0

# Variables Pausa
@onready var pausa_canvas: CanvasLayer = $PausaCanvas
@onready var shader: ColorRect = $Canvas/Shader

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_cam_y = camera.position.y
	air.pivot_offset = air.size / 2


func _input(event):
	if event is InputEventMouseMotion:
		target_rot_y -= event.relative.x * Settings.mouse_sensitivity
		rotation_x -= event.relative.y * Settings.mouse_sensitivity
		rotation_x = clamp(rotation_x, deg_to_rad(-80), deg_to_rad(80))

		# Linterna
		flashlight_target.x = -event.relative.x * FLASHLIGHT_SWAY
		flashlight_target.y = -event.relative.y * FLASHLIGHT_SWAY

	if event.is_action_pressed("cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		air.visible = false
		pausa_canvas.visible = true
		shader.material.set_shader_parameter("pixel_resolution", 512.0)
		get_tree().paused = true

	#Funcion de Linterna
	if event.is_action_pressed("light"):
		funLintern()


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
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# =========================
	# ROTACIÓN SUAVE
	# =========================

	current_rot_y = lerp(current_rot_y, target_rot_y, delta * LOOK_SMOOTH)
	rotation.y = current_rot_y
	camera.rotation.x = lerp(camera.rotation.x, rotation_x, delta * LOOK_SMOOTH)

	# =========================
	# MOVIMIENTO NATURAL
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
	# LINTERNa
	# =========================

	flashlight_rot = flashlight_rot.lerp(flashlight_target, delta * FLASHLIGHT_LAG)

	spot_light_3d.rotation.x = camera.rotation.x + flashlight_rot.y
	spot_light_3d.rotation.y = flashlight_rot.x

	flashlight_target = flashlight_target.lerp(Vector2.ZERO, delta * 5.0)

	var noise = sin(Time.get_ticks_msec() * 0.01) * 0.003
	spot_light_3d.rotation.x += noise
	spot_light_3d.rotation.y += noise * 0.5
	spot_light_3d.light_energy = 0.5 + randf_range(0.4, 0.5)
	# =========================
	# RAYCAST INTERACCIÓN (FIX)
	# =========================

	var encontrado = null

	var bebedero_detectado = null
	
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
			obj = obj.get_parent()
			

	# 🔥 FIX: mantener objeto aunque se pierda por rotación
	if encontrado:
		objeto_actual = encontrado
	else:
		if timer_gracia > 0:
			timer_gracia -= delta
			objeto_actual = ultimo_objeto
		else:
			objeto_actual = null

	# =========================
	# UI
	# =========================

	var target_scale = Vector2.ONE
	var interactuable = objeto_actual or bebedero_detectado
	if interactuable:
		var pulse = sin(Time.get_ticks_msec() * 0.01) * 0.05
		target_scale = Vector2(1.3 + pulse, 1.3 + pulse)

	air.scale = air.scale.lerp(target_scale, delta * 8.0)
	if Input.is_action_just_pressed("interact"):
		# 🚪 puertas
		if objeto_actual:
			abrir_puerta(objeto_actual)
		# 🚰 bebedero
		elif bebedero_detectado and puede_reproducir_bebedero:
			puede_reproducir_bebedero = false
			$Bebedero.play()

# =========================
# 🚪 PUERTAS (FIX COMPLETO)
# =========================

func abrir_puerta(puerta):
	
	# Evitar spam
	if puerta.has_meta("moviendo") and puerta.get_meta("moviendo"):
		return

	# Guardar rotación inicial
	if not puerta.has_meta("rotacion_inicial"):
		puerta.set_meta("rotacion_inicial", puerta.rotation_degrees.y)

	var rot_inicial = puerta.get_meta("rotacion_inicial")

	var abierta = false
	if puerta.has_meta("abierta"):
		abierta = puerta.get_meta("abierta")

	puerta.set_meta("moviendo", true)

	# 🔊 Obtener audio
	var audio_abrir = puerta.get_node_or_null("AudioAbrir")
	var audio_cerrar = puerta.get_node_or_null("AudioCerrar")
	var tween = create_tween()

	if abierta:
		# 🔊 SONIDO CERRAR
		if audio_abrir:
			audio_abrir.pitch_scale = randf_range(0.9, 1.1)
			audio_abrir.play()

		tween.tween_property(puerta, "rotation_degrees:y", rot_inicial, 0.4)
		puerta.set_meta("abierta", false)
	else:
		# 🔊 SONIDO ABRIR
		if audio_cerrar:
			audio_cerrar.pitch_scale = randf_range(0.9, 1.1)
			audio_cerrar.play()

		tween.tween_property(puerta, "rotation_degrees:y", rot_inicial + 90, 0.4)
		puerta.set_meta("abierta", true)

	tween.finished.connect(func():
		puerta.set_meta("moviendo", false)
	)

func funLintern():
	toggleLight = !toggleLight
	spot_light_3d.visible = toggleLight


func _on_h_slider_value_changed(value: float) -> void:
	Settings.mouse_sensitivity = value

# 🚰 bebedero
func _on_bebedero_finished() -> void:
	puede_reproducir_bebedero = true
