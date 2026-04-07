extends CharacterBody3D

const SPEED = 2.5
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

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
#Linterna Variables
@onready var spot_light_3d: SpotLight3D = $Camera3D/SpotLight3D
const FLASHLIGHT_LAG = 10.0
const FLASHLIGHT_SWAY = 0.02

var flashlight_rot := Vector2.ZERO
var flashlight_target := Vector2.ZERO

# Ray Cast
@onready var raycast = $Camera3D/RayCast
@onready var air: ColorRect = $Canvas/Air
var objeto_actual = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_cam_y = camera.position.y  # 👈 guardamos altura original
	air.pivot_offset = air.size / 2

func _input(event):
	if event is InputEventMouseMotion:
		# Guardamos rotación objetivo (no aplicamos directo)
		target_rot_y -= event.relative.x * MOUSE_SENSITIVITY
		rotation_x -= event.relative.y * MOUSE_SENSITIVITY
		rotation_x = clamp(rotation_x, deg_to_rad(-80), deg_to_rad(80))
		#Linterna
		# Movimiento objetivo de la linterna (retraso)
		flashlight_target.x = -event.relative.x * FLASHLIGHT_SWAY
		flashlight_target.y = -event.relative.y * FLASHLIGHT_SWAY
	if event.is_action_pressed("cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	#Interactua con objetos
	if event.is_action_pressed("interact") and objeto_actual:
		abrir_puerta(objeto_actual)


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
	# 🎥 ROTACIÓN SUAVE (peso humano)
	# =========================

	current_rot_y = lerp(current_rot_y, target_rot_y, delta * LOOK_SMOOTH)
	rotation.y = current_rot_y
	camera.rotation.x = lerp(camera.rotation.x, rotation_x, delta * LOOK_SMOOTH)

	# =========================
	# 🎥 MOVIMIENTO NATURAL (SIN BAJAR CÁMARA)
	# =========================

	var speed := Vector2(velocity.x, velocity.z).length()

	# Head bob MUY sutil
	var bob_offset := 0.0
	if speed > 0.1 and is_on_floor():
		bob_time += delta * BOB_FREQ
		bob_offset = sin(bob_time) * BOB_AMP
	else:
		bob_time = 0.0

	# Respiración (siempre activa)
	var breath = sin(Time.get_ticks_msec() * 0.001 * BREATH_FREQ) * BREATH_AMP

	# Aplicamos SOLO en Y (altura), sin desplazar X/Z
	camera.position.y = base_cam_y + bob_offset + breath
	
	
	# Linterna
	# =========================
	# 🔦 LINERNA CON INERCIA
	# =========================

	# Suavizado (retraso)
	flashlight_rot = flashlight_rot.lerp(flashlight_target, delta * FLASHLIGHT_LAG)

	# Aplicar rotación con retraso
	spot_light_3d.rotation.x = camera.rotation.x + flashlight_rot.y
	spot_light_3d.rotation.y = flashlight_rot.x

	# Reset suave (evita acumulación)
	flashlight_target = flashlight_target.lerp(Vector2.ZERO, delta * 5.0)
	# Micro temblor (mano humana)
	var noise = sin(Time.get_ticks_msec() * 0.01) * 0.003
	spot_light_3d.rotation.x += noise
	spot_light_3d.rotation.y += noise * 0.5
	
	
	# =========================
	# RAYCAST INTERACCIÓN
	# =========================

	var encontrado = null

	if raycast.is_colliding():
		var obj = raycast.get_collider()

		while obj:
			if obj.is_in_group("puertas"):
				encontrado = obj
				break
			obj = obj.get_parent()

	# Guardamos resultado final
	objeto_actual = encontrado

	# UI
	var target_scale = Vector2.ONE

	if objeto_actual:
		var pulse = sin(Time.get_ticks_msec() * 0.01) * 0.05
		target_scale = Vector2(1.3 + pulse, 1.3 + pulse)

	# Suavizado
	air.scale = air.scale.lerp(target_scale, delta * 8.0)
func abrir_puerta(puerta):
	var abierta = false

	if puerta.has_meta("abierta"):
		abierta = puerta.get_meta("abierta")

	var tween = create_tween()

	if abierta:
		# CERRAR
		tween.tween_property(puerta, "rotation_degrees:y", 0, 0.4)
		puerta.set_meta("abierta", false)
	else:
		# ABRIR
		tween.tween_property(puerta, "rotation_degrees:y", 90, 0.4)
		puerta.set_meta("abierta", true)
