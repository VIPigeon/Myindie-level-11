class_name Fuel extends Node2D

enum Kind {
	BRANCH,
	PAPER,
	TRASH,
	LEAF,
	BUTT,
	PACK,
	TREE,
	BIN,
	SATELLITE,
	SHIP,
	UFO,
	METEOR,
	MOON,
	STAR,
}

const NAME_KEYS: Array[String] = [
	"FUEL_BRANCH", "FUEL_PAPER", "FUEL_TRASH", "FUEL_LEAF", "FUEL_BUTT", "FUEL_PACK",
	"FUEL_TREE", "FUEL_BIN", "FUEL_SATELLITE", "FUEL_SHIP", "FUEL_UFO", "FUEL_METEOR",
	"FUEL_MOON", "FUEL_STAR",
]
const ART: Dictionary = {
	Kind.LEAF: {"texture": preload("res://art/leaves.png"), "cell": Vector2i(32, 32)},
	Kind.BUTT: {"texture": preload("res://art/butts.png"), "cell": Vector2i(32, 32)},
	Kind.BRANCH: {"texture": preload("res://art/sticks.png"), "cell": Vector2i(64, 128)},
}

@onready var label: Label = get_node_or_null("Label")

var stage: int = 0
var kind: Kind
var point_value: int
var dragged := false
var reserved_by: Node2D
var bounds: Rect2
var hovered := false
var heat: float = 0.0
var heat_target: float = 0.0
var feedback_time: float = 0.0
var pickup_age: float = 10.0
var landing_tween: Tween
var landing_offset: float = 0.0
var visual_offset := Vector2.ZERO
var visual_angle: float = 0.0
var visual_scale: float = 1.0
var hover_material: ShaderMaterial
var burning := false
var burn_elapsed: float = 0.0
var flight_direction: float = 1.0
var burn_shader := preload("res://game/fuel/burn.gdshader")
var art_texture: AtlasTexture
var art_bounds: Rect2


func _ready() -> void:
	bounds = Rect2(-Config.fuel_size * 0.5, Config.fuel_size)
	label.position = bounds.position
	label.size = bounds.size
	point_value = Config.fuel_points[kind] * Config.stage_reward_multipliers[stage]
	setup_art()
	setup_feedback()
	update_text()


func update_text() -> void:
	var key := NAME_KEYS[kind]
	if stage > GlobalConfig.Stage.CAMP and kind <= Kind.TRASH:
		key = "FUEL_STAGE_%d_%d" % [stage, kind]

	label.text = tr("FUEL_VALUE") % [tr(key), point_value]


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and label != null:
		update_text()


func setup_art() -> void:
	if stage > GlobalConfig.Stage.CAMP or self is Car:
		if kind >= Kind.TREE:
			bounds = Rect2(-Config.fuel_placeholder_size * 0.5, Config.fuel_placeholder_size)
			label.hide()
		return

	if ART.has(kind):
		var art: Dictionary = ART[kind]
		var texture: Texture2D = art.texture
		var cell: Vector2i = art.cell
		var frame_count := texture.get_width() / cell.x
		art_texture = ArtAtlas.frame(texture, cell, randi_range(0, frame_count - 1))

	label.hide()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var size := Config.pack_size
	if art_texture != null:
		var source_size := art_texture.get_size()
		size = source_size * Config.world_pixel_size
	art_bounds = Rect2(-size * 0.5, size)
	bounds = art_bounds.grow(Config.fuel_hit_padding)


func _draw() -> void:
	draw_set_transform(visual_offset + Vector2(0, landing_offset), visual_angle, Vector2.ONE * visual_scale)
	if art_texture != null:
		draw_texture_rect(art_texture, art_bounds, false, Color.WHITE)
		return
	if kind >= Kind.TREE:
		draw_placeholder()
		return
	if kind == Kind.PACK:
		draw_rect(art_bounds, Config.palette[7])
		draw_rect(Rect2(art_bounds.position, Vector2(art_bounds.size.x, art_bounds.size.y * 0.35)), Config.palette[4])
		draw_rect(art_bounds.grow(-8.0), Config.palette[2], false, 3.0)
		return

	draw_rect(bounds, Config.palette[4])


func contains_point(position_: Vector2) -> bool:
	return bounds.has_point((position_ - position) / scale)


func set_dragged(value: bool) -> void:
	dragged = value
	if value:
		stop_landing()
		pickup_age = 0.0
	else:
		heat_target = 0.0
	queue_redraw()


func land() -> void:
	stop_landing()
	visual_offset = Vector2.ZERO
	visual_angle = 0.0
	visual_scale = 1.0
	pickup_age = 10.0
	heat = 0.0
	landing_tween = create_tween()
	landing_tween.tween_method(set_landing_offset, -Config.fuel_drop_height, 0.0, Config.fuel_drop_duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func set_landing_offset(value: float) -> void:
	landing_offset = value
	queue_redraw()


func stop_landing() -> void:
	if landing_tween != null:
		landing_tween.kill()
	landing_offset = 0.0


func is_flying() -> bool:
	return kind in [Kind.SATELLITE, Kind.SHIP, Kind.UFO, Kind.METEOR]


func tick_flight(delta: float) -> void:
	if !is_flying() or dragged or burning:
		return

	position.x += Config.flying_speed * scale.x * flight_direction * delta
	var edge := Config.world_size.x * scale.x * 0.5 + bounds.size.x * scale.x
	if absf(position.x) > edge:
		position.x = -signf(position.x) * edge


func burn(origin: Vector2) -> void:
	stop_landing()
	burning = true
	visual_offset = Vector2.ZERO
	visual_angle = 0.0
	visual_scale = 1.0
	set_process(false)
	reserved_by = null
	dragged = false
	if label != null:
		label.hide()
	var shader_material := ShaderMaterial.new()
	shader_material.shader = burn_shader
	shader_material.set_shader_parameter("item_rect", Vector4(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y))
	shader_material.set_shader_parameter("burn_origin", ((origin - position) / scale - bounds.position) / bounds.size)
	shader_material.set_shader_parameter("pixel_size", Config.world_pixel_size)
	shader_material.set_shader_parameter("border_width", Config.fuel_burn_border)
	shader_material.set_shader_parameter("noise_amount", Config.fuel_burn_noise)
	shader_material.set_shader_parameter("palette", Config.palette)
	material = shader_material
	queue_redraw()


func tick_burn(delta: float) -> bool:
	burn_elapsed += delta
	material.set_shader_parameter("progress", minf(burn_elapsed / Config.fuel_burn_duration, 1.0))
	return burn_elapsed >= Config.fuel_burn_duration


func draw_placeholder() -> void:
	var palette := Config.palette
	match kind:
		Kind.TREE:
			draw_rect(Rect2(-5, 0, 10, 28), palette[4])
			draw_colored_polygon(PackedVector2Array([Vector2(0, -40), Vector2(-30, 12), Vector2(30, 12)]), palette[3])
		Kind.BIN:
			draw_rect(Rect2(-22, -23, 44, 48), palette[2])
			draw_rect(Rect2(-26, -28, 52, 7), palette[3])
			for x in [-12, 0, 12]:
				draw_line(Vector2(x, -14), Vector2(x, 18), palette[1], 3)
		Kind.SATELLITE:
			draw_rect(Rect2(-34, -15, 22, 30), palette[2])
			draw_rect(Rect2(12, -15, 22, 30), palette[2])
			draw_rect(Rect2(-10, -9, 20, 18), palette[6])
			draw_line(Vector2(-30, 0), Vector2(30, 0), palette[4], 3)
		Kind.SHIP:
			draw_colored_polygon(PackedVector2Array([Vector2(34, 0), Vector2(-25, -23), Vector2(-14, 0), Vector2(-25, 23)]), palette[6])
			draw_rect(Rect2(-32, -5, 15, 10), palette[5])
		Kind.UFO:
			draw_circle(Vector2(0, -7), 16, palette[3])
			draw_rect(Rect2(-32, -2, 64, 12), palette[6])
		Kind.METEOR:
			draw_colored_polygon(PackedVector2Array([Vector2(-35, -18), Vector2(20, -12), Vector2(28, 12), Vector2(0, 22)]), palette[4])
			draw_circle(Vector2(12, 5), 16, palette[2])
		Kind.MOON:
			draw_circle(Vector2.ZERO, 26, palette[6])
			draw_circle(Vector2(-9, -6), 7, palette[3])
			draw_circle(Vector2(10, 10), 5, palette[4])
		Kind.STAR:
			draw_colored_polygon(PackedVector2Array([Vector2(0, -28), Vector2(8, -8), Vector2(28, 0), Vector2(8, 8), Vector2(0, 28), Vector2(-8, 8), Vector2(-28, 0), Vector2(-8, -8)]), palette[6])


func setup_feedback() -> void:
	set_process(true)

	hover_material = ShaderMaterial.new()
	hover_material.shader = preload("res://game/fuel/hover.gdshader")
	hover_material.set_shader_parameter("outline_color", Config.palette[6])
	hover_material.set_shader_parameter("has_sprite", art_texture != null)
	hover_material.set_shader_parameter("hot_color", Config.palette[7])
	material = hover_material


func set_hovered(value: bool) -> void:
	hovered = value
	if hover_material != null:
		hover_material.set_shader_parameter("highlighted", hovered or dragged)


func set_heat(value: bool) -> void:
	heat_target = 1.0 if value else 0.0


func _process(delta: float) -> void:
	if burning:
		return

	feedback_time += delta
	pickup_age += delta
	heat = move_toward(heat, heat_target, delta * 8.0)
	var lift: float = Config.fuel_hover_lift if hovered or dragged else 0.0
	var target_offset := Vector2(0.0, -lift)
	if dragged:
		target_offset += Vector2(sin(feedback_time * 43.0), cos(feedback_time * 37.0)) * heat * 3.0

	visual_offset = visual_offset.lerp(target_offset * Config.juice_strength, 1.0 - exp(-delta * 20.0))
	visual_angle = sin(feedback_time * 31.0) * heat * 0.07 * Config.juice_strength
	visual_scale = 1.0 + sin(pickup_age * 24.0) * exp(-pickup_age * 9.0) * 0.15 * Config.juice_strength
	if hover_material != null:
		hover_material.set_shader_parameter("highlighted", hovered or dragged)
		hover_material.set_shader_parameter("heat", heat)
	queue_redraw()
