class_name FeedParticles extends Node2D

@onready var sparks: CPUParticles2D = $Sparks
@onready var embers: CPUParticles2D = $Embers

var hot_color: Color
var edge_color: Color
var particle_scale: float = 1.0
var finished_emitters: int = 0


func _ready() -> void:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.18, 0.65, 1.0])
	ramp.colors = PackedColorArray([Config.palette[7], hot_color, edge_color, Color(edge_color, 0.0)])
	for emitter in [sparks, embers]:
		emitter.color_ramp = ramp
		emitter.local_coords = false
		emitter.fixed_fps = 0
		emitter.emission_sphere_radius = Config.feed_particle_emission_radius * particle_scale
		emitter.scale_amount_min = Config.feed_particle_size * particle_scale * 0.5
		emitter.scale_amount_max = Config.feed_particle_size * particle_scale
		emitter.finished.connect(on_emitter_finished)

	sparks.amount = Config.feed_particle_count
	sparks.lifetime = Config.feed_particle_lifetime
	sparks.spread = Config.feed_particle_spread
	sparks.initial_velocity_min = Config.feed_particle_speed * particle_scale * 0.45
	sparks.initial_velocity_max = Config.feed_particle_speed * particle_scale
	sparks.gravity = Vector2.DOWN * Config.feed_particle_gravity * particle_scale
	embers.position = Vector2.UP * Config.fire_radius * particle_scale * Config.feed_particle_origin_height
	embers.amount = Config.feed_ember_count
	embers.lifetime = Config.feed_ember_lifetime
	embers.initial_velocity_min = Config.feed_ember_speed * particle_scale * 0.4
	embers.initial_velocity_max = Config.feed_ember_speed * particle_scale
	embers.gravity = Vector2.DOWN * Config.ember_gravity * particle_scale
	sparks.emitting = true
	embers.emitting = true


func on_emitter_finished() -> void:
	finished_emitters += 1
	if finished_emitters == 2:
		queue_free()
