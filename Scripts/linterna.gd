extends Node3D

@onready var light: SpotLight3D = $Light
@onready var mesh: Node3D = $"Sketchfab_model/80726a169adf4a548c1ed385f0b522e1_obj_cleaner_materialmerger_gles/Object_2"
@onready var camera: Camera3D = get_parent()
@onready var audio_switch: AudioStreamPlayer3D = $AudioSwitch

var switch: bool = false

var current_quat: Quaternion
var target_quat: Quaternion

var follow_speed := 8.0

# SWAY (mouse)
var prev_cam_rot: Vector3
var sway := Vector3.ZERO
var sway_strength := 2.0
var sway_smooth := 8.0
var mouse_delta := Vector2.ZERO
# BOB (movimiento)
var bob_time := 0.0
var bob_speed := 10.0
var bob_amount := 0.10

func _ready():
	current_quat = light.global_transform.basis.get_rotation_quaternion()
	target_quat = current_quat
	
	prev_cam_rot = camera.rotation


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta = event.relative
	
	if event.is_action_pressed("light"):
		if GameManager.LinternInventory == true:
			audio_switch.play()
			switch = !switch
			light.visible = switch
			mesh.visible = switch
			
			if switch:
				target_quat = camera.global_transform.basis.get_rotation_quaternion()
				current_quat = target_quat
				light.global_transform.basis = Basis(current_quat)


func _process(delta: float) -> void:
	# =========================
	# LUZ (SIEMPRE PRECISA)
	# =========================
	target_quat = camera.global_transform.basis.get_rotation_quaternion()
	current_quat = current_quat.slerp(target_quat, follow_speed * delta)
	light.global_transform.basis = Basis(current_quat)
	
	
	# =========================
	# SWAY (MOUSE REAL)
	# =========================
	var target_sway = Vector3(
		0,
		mouse_delta.y * 0.002 * sway_strength, # 👈 usar Y en vez de X
		-mouse_delta.x * 0.002 * sway_strength
	)

	sway = sway.lerp(target_sway, sway_smooth * delta)

	# reset para el siguiente frame
	mouse_delta = Vector2.ZERO
	
	# =========================
	# BOB (MOVIMIENTO)
	# =========================
	var player = camera.get_parent()
	var speed := 0.0
	
	if player is CharacterBody3D:
		speed = player.velocity.length()
	
	var bob_offset = Vector3.ZERO
	
	if speed > 0.1:
		bob_time += delta * bob_speed
		bob_offset.z = abs(sin(bob_time)) * bob_amount
	else:
		bob_time = 0.0
		bob_offset.y = lerp(bob_offset.y, 0.0, 5 * delta)
	
	# =========================
	# APLICAR AL MESH
	# =========================
	mesh.rotation = sway
	mesh.position = bob_offset
