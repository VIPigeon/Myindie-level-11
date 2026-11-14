class_name Main extends Node

@onready var game_viewport: SubViewport = $GameViewport
@onready var game_image: TextureRect = $GameImage
@onready var world_node: Node2D = $GameViewport/World
@onready var gui_node: Control = $UI/GUI
@onready var camera: Camera2D = $GameViewport/World/Camera2D

var gameplay: Gameplay
var view_scale: float = 1.0


func _ready() -> void:
	game_image.texture = game_viewport.get_texture()
	setup_ground()
	gameplay = Gameplay.new(world_node, gui_node)
	gameplay.create_game()
	get_window().focus_exited.connect(gameplay.drag_controller.cancel_drag)
	get_window().mouse_exited.connect(gameplay.drag_controller.cancel_drag)
	get_viewport().size_changed.connect(update_camera)
	update_camera()


func update_camera() -> void:
	gameplay.drag_controller.cancel_drag()
	apply_camera()


func apply_camera() -> void:
	var viewport_size := Vector2(game_viewport.size)
	var camera_scale := minf(
		viewport_size.x / (Config.world_size.x * view_scale),
		viewport_size.y / (Config.world_size.y * view_scale)
	)

	camera.zoom = Vector2.ONE * camera_scale
	camera.position = Vector2.ZERO
	camera.force_update_scroll()
	var ground: ColorRect = $GameViewport/World/Ground
	ground.size = viewport_size / camera.zoom
	ground.position = -ground.size * 0.5
	ground.material.set_shader_parameter("world_size", ground.size)
	ground.material.set_shader_parameter("pixel_size", Config.world_pixel_size * view_scale)
	ground.material.set_shader_parameter("space_background", gameplay.stage_controller.stage >= GlobalConfig.Stage.SURFACE)


func _input(event: InputEvent) -> void:
	if gameplay == null:
		return

	if event is InputEventMouse:
		var local_position: Vector2 = game_image.get_global_transform_with_canvas().affine_inverse() * event.position
		var mapped: InputEventMouse = event.duplicate()
		mapped.position = local_position * Vector2(game_viewport.size) / game_image.size
		gameplay.drag_controller.handle_input(mapped)
	else:
		gameplay.drag_controller.handle_input(event)


func setup_ground() -> void:
	$GameViewport/World/Ambient.color = Config.ambient_color
	var ground: ColorRect = $GameViewport/World/Ground
	ground.position = -Config.world_size * 0.5
	ground.size = Config.world_size
	var ground_material := ShaderMaterial.new()
	ground_material.shader = preload("res://game/fire/ground.gdshader")
	ground_material.set_shader_parameter("world_size", Config.world_size)
	ground_material.set_shader_parameter("pixel_size", Config.world_pixel_size)
	ground_material.set_shader_parameter("dark_color", Config.palette[0])
	ground_material.set_shader_parameter("light_color", Config.palette[1])
	ground.material = ground_material


func _process(delta: float) -> void:
	if gameplay == null:
		return

	gameplay.tick(delta)
	$GameViewport/World/Road.visible = gameplay.stage_controller.stage == GlobalConfig.Stage.HOUSE
	$GameViewport/World/Road.scale = Vector2.ONE * gameplay.stage_controller.stage_scale
	var desired := gameplay.stage_controller.view_scale
	if is_equal_approx(view_scale, desired):
		return

	view_scale = lerpf(view_scale, desired, 1.0 - exp(-Config.camera_response_speed * delta))
	apply_camera()
