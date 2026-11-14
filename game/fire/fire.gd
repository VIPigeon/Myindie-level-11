class_name Fire extends Node2D

const BASE_CELL_SIZE := Vector2i(128, 128)

@onready var flame: ColorRect = $Flame
@onready var light: PointLight2D = $Light
@onready var glow: Sprite2D = $Glow
@onready var embers: CPUParticles2D = $Embers
@onready var radius: float = Config.fire_radius

var stage_index: int = 0
var base_sprite := Sprite2D.new()
var ember_shader := preload("res://game/fire/ember.gdshader")
var surface_shader := preload("res://game/fire/surface.gdshader")
var camp_shader := preload("res://game/fire/fire.gdshader")
var bases_texture := preload("res://art/fire.png")

var highlighted := false
var contact_strength: float = 0.0
var contact_amount: float = 0.0
var contact_direction := Vector2.UP
var size_multiplier: float = 1.0
var elapsed: float = 0.0
var burst: float = 0.0
var last_feed_position := Vector2.ZERO
var target_scale: float = 1.0
var flame_material: ShaderMaterial
var feed_particles_scene := preload("res://game/fire/feed_particles.tscn")


func _ready() -> void:
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	base_sprite.material = unshaded
	base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(base_sprite)
	flame_material = flame.material.duplicate()
	flame.material = flame_material
	flame.z_index = Config.dragged_z_index + 1
	embers.amount = Config.ambient_ember_count
	embers.lifetime = Config.ambient_ember_lifetime
	embers.fixed_fps = 0
	set_fire_scale(Config.fire_scale)
	set_stage(0)


func _process(delta: float) -> void:
	if !is_equal_approx(size_multiplier, target_scale):
		apply_fire_scale(lerpf(size_multiplier, target_scale, 1.0 - exp(-Config.growth_response_speed * delta)))

	if stage_index == GlobalConfig.Stage.SURFACE:
		update_flame_geometry()

	elapsed += delta
	contact_amount = lerpf(contact_amount, contact_strength, 1.0 - exp(-Config.fire_contact_response * delta))
	flame_material.set_shader_parameter("contact_amount", contact_amount)
	flame_material.set_shader_parameter("contact_direction", contact_direction)
	burst = move_toward(burst, 0.0, Config.fire_burst_decay * delta)
	if stage_index == GlobalConfig.Stage.BLACK_HOLE:
		queue_redraw()

	flame_material.set_shader_parameter("clock", elapsed)
	flame_material.set_shader_parameter("burst", burst)

	var flicker := sin(elapsed * 9.3) * 0.5 + sin(elapsed * 17.7 + 1.2) * 0.3 + sin(elapsed * 4.1) * 0.2
	var energy: float = 1.0 + flicker * Config.fire_light_flicker + burst * 0.3
	if highlighted:
		energy += Config.fire_ready_light_boost

	light.energy = Config.fire_light_energy * energy
	glow.modulate.a = Config.fire_glow_opacity * energy


func grow_to(value: float) -> void:
	target_scale = maxf(value, 0.05)


func set_fire_scale(value: float) -> void:
	target_scale = maxf(value, 0.05)
	apply_fire_scale(target_scale)


func apply_fire_scale(value: float) -> void:
	size_multiplier = maxf(value, 0.05)
	radius = Config.fire_radius * size_multiplier

	update_flame_geometry()
	update_ember_geometry()
	light.texture_scale = Config.fire_light_radius * size_multiplier * 2.0 / light.texture.get_width()
	glow.scale = Vector2.ONE * light.texture_scale

	base_sprite.scale = Vector2.ONE * Config.world_pixel_size * size_multiplier
	var base_height := 0.12 if stage_index == GlobalConfig.Stage.EMBER else 0.51
	base_sprite.position = Vector2.DOWN * radius * Config.stage_flame_sizes[stage_index] * base_height
	queue_redraw()


func update_flame_geometry() -> void:
	if stage_index == GlobalConfig.Stage.SURFACE:
		var capture := surface_capture_rect()
		flame.scale = Vector2.ONE
		flame.position = capture.position - position
		flame.size = capture.size
		var viewport_size := get_viewport().get_visible_rect().size
		flame_material.set_shader_parameter("resolution", Vector2(viewport_size.x, viewport_size.y * Config.surface_band_height))
		return

	var visual_scale: float = Config.stage_flame_sizes[stage_index]
	flame.position = Vector2(-3.0, -Config.fire_canvas_top) * radius
	flame.size = Vector2(6.0, Config.fire_canvas_top + Config.fire_canvas_bottom) * radius

	flame_material.set_shader_parameter("canvas_size", flame.size / radius)
	flame_material.set_shader_parameter("canvas_origin", flame.position / radius)
	flame_material.set_shader_parameter("pixel_count", 6.0 * Config.fire_radius * visual_scale / Config.world_pixel_size)
	flame.scale = Vector2.ONE * visual_scale
	flame.position *= visual_scale


func update_ember_geometry() -> void:
	var visual_radius: float = radius * Config.stage_flame_sizes[stage_index]
	embers.position = Vector2.UP * visual_radius * 0.6
	embers.emission_rect_extents = Vector2(visual_radius * 0.5, visual_radius * 0.15)
	embers.initial_velocity_min = Config.ambient_ember_speed * size_multiplier * 0.4
	embers.initial_velocity_max = Config.ambient_ember_speed * size_multiplier
	embers.gravity = Vector2.DOWN * Config.ember_gravity * size_multiplier
	embers.scale_amount_min = Config.feed_particle_size * size_multiplier * 0.3
	embers.scale_amount_max = Config.feed_particle_size * size_multiplier * 0.65


func show_contact(position_: Vector2) -> void:
	var offset := position_ - position
	var reach: float = Config.fire_contact_radius * size_multiplier
	contact_strength = 1.0 - smoothstep(radius, reach, offset.length())
	if contact_strength <= 0.0:
		clear_contact()
		return

	if offset.length_squared() > 0.01:
		contact_direction = (offset - Vector2(0.0, Config.fire_contact_root_height) * radius).normalized()


func clear_contact() -> void:
	contact_strength = 0.0


func feed(origin := Vector2.INF) -> void:
	last_feed_position = position if origin == Vector2.INF else origin
	burst = 1.0
	var particles: FeedParticles = feed_particles_scene.instantiate()
	particles.particle_scale = size_multiplier * (0.55 if stage_index == GlobalConfig.Stage.EMBER else 1.0)
	particles.hot_color = flame_material.get_shader_parameter("hot_color")
	particles.edge_color = flame_material.get_shader_parameter("edge_color")
	var origin_height: float = 0.12 if stage_index == GlobalConfig.Stage.EMBER else Config.feed_particle_origin_height
	particles.position = last_feed_position + Vector2.UP * radius * origin_height
	particles.z_index = Config.dragged_z_index + 1
	get_parent().add_child(particles)


func contains_point(position_: Vector2) -> bool:
	if stage_index == GlobalConfig.Stage.SURFACE:
		return surface_capture_rect().has_point(position_)
	var capture_radius: float = Config.ember_capture_radius * size_multiplier if stage_index == GlobalConfig.Stage.EMBER else radius
	return position.distance_to(position_) <= capture_radius


func set_highlighted(value: bool) -> void:
	highlighted = value


func set_stage(stage: int) -> void:
	stage_index = stage
	configure_shader(stage)
	position = Vector2.ZERO
	if stage == GlobalConfig.Stage.SURFACE:
		var world_scale: float = pow(Config.stage_scale_factor, stage)
		position.y = Config.world_size.y * world_scale * Config.surface_height_ratio

	var has_flame := stage != GlobalConfig.Stage.BLACK_HOLE
	flame.visible = has_flame
	light.enabled = stage < GlobalConfig.Stage.SURFACE
	glow.visible = light.enabled
	embers.emitting = has_flame
	base_sprite.texture = null
	if stage < bases_texture.get_width() / BASE_CELL_SIZE.x:
		base_sprite.texture = ArtAtlas.frame(bases_texture, BASE_CELL_SIZE, stage)

	apply_fire_scale(size_multiplier)
	apply_palette(stage)


func apply_palette(stage: int) -> void:
	var edge: Color = Config.palette[Config.stage_edge_tones[stage]]
	var hot: Color = Config.palette[6]
	flame_material.set_shader_parameter("edge_color", edge)
	flame_material.set_shader_parameter("flame_color", Config.palette[Config.stage_flame_tones[stage]])
	flame_material.set_shader_parameter("hot_color", hot)
	flame_material.set_shader_parameter("core_color", Config.palette[7])
	light.color = hot
	glow.modulate = Color(hot, glow.modulate.a)

	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(hot, 0.0), hot, edge, Color(edge, 0.0)])
	embers.color_ramp = ramp


func extinguish() -> void:
	clear_contact()
	flame.hide()
	light.enabled = false
	glow.hide()
	embers.emitting = false
	set_process(false)


func reignite() -> void:
	flame.show()
	light.enabled = true
	glow.show()
	embers.emitting = true
	set_process(true)


func _draw() -> void:
	var palette := Config.palette
	if stage_index == GlobalConfig.Stage.PLANET:
		draw_circle(Vector2.ZERO, radius, palette[2])
		draw_circle(Vector2(-radius * 0.25, radius * 0.15), radius * 0.35, palette[4])
	elif stage_index == GlobalConfig.Stage.BLACK_HOLE:
		draw_arc(Vector2.ZERO, radius * 1.15, 0, TAU, 64, palette[3], radius * 0.25)
		draw_arc(Vector2.ZERO, radius * (1.3 + burst * Config.black_hole_feed_pulse), 0, TAU, 64, palette[6], radius * (0.06 + burst * 0.08))
		draw_circle(Vector2.ZERO, radius, palette[0])
	elif stage_index == GlobalConfig.Stage.SURFACE:
		draw_rect(Rect2(Vector2(-Config.world_size.x, 0) * size_multiplier, Vector2(Config.world_size.x * 2.0, Config.world_size.y) * size_multiplier), palette[1])


func configure_shader(stage: int) -> void:
	if stage == GlobalConfig.Stage.SURFACE:
		flame_material.shader = surface_shader
		return

	flame_material.shader = ember_shader if stage == GlobalConfig.Stage.EMBER else camp_shader
	var parameters := {"speed": Config.fire_speed}
	if stage == GlobalConfig.Stage.EMBER:
		parameters.merge({
			"flame_height": Config.ember_flame_height,
			"flame_width": Config.ember_flame_width,
			"feed_boost": Config.ember_feed_boost * Config.juice_strength,
		})
	else:
		parameters.merge({
			"contact_root_height": Config.fire_contact_root_height,
			"lean_strength": Config.fire_lean_strength,
			"animation_fps": Config.fire_animation_fps,
			"contact_length": Config.fire_contact_length,
			"contact_width": Config.fire_contact_width,
			"turbulence": Config.fire_turbulence,
		})

	for parameter in parameters:
		flame_material.set_shader_parameter(parameter, parameters[parameter])


func surface_capture_rect() -> Rect2:
	var viewport_rect := get_viewport().get_visible_rect()
	var visible_world: Rect2 = get_canvas_transform().affine_inverse() * viewport_rect
	var top := visible_world.end.y - visible_world.size.y * Config.surface_band_height
	return Rect2(
		Vector2(visible_world.position.x, top),
		Vector2(visible_world.size.x, maxf(0.0, visible_world.end.y - top)),
	)
