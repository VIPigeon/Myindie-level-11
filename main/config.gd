class_name GlobalConfig extends Node

enum Stage { EMBER, CAMP, HOUSE, SURFACE, PLANET, BLACK_HOLE }

@export var starting_items: int = 12
@export var starting_score: int = 0
@export var spawn_attempts: int = 100
@export var world_size := Vector2(960.0, 720.0)
@export var spawn_padding: float = 60.0
@export var fire_clearance: float = 70.0
@export var fuel_spacing: float = 90.0

@export_group("Топливо")
@export var fuel_size := Vector2(72.0, 48.0)
@export var fuel_points: Array[int] = [1, 2, 3, 2, 1, 8, 2, 3, 2, 3, 4, 2, 500, 3]
@export var dragged_z_index: int = 1

@export_group("Огонь")
@export var fire_radius: float = 76.0
@export var fire_scale: float = 1.0
@export var world_pixel_size: float = 2.0
@export var ember_capture_radius: float = 24.0
@export var ember_flame_height: float = 0.42
@export var ember_flame_width: float = 0.14
@export var fire_animation_fps: float = 24.0
@export var fire_speed: float = 1.0
@export var fire_turbulence: float = 0.65
@export var fire_contact_radius: float = 150.0
@export var fire_contact_length: float = 1.1
@export var fire_contact_width: float = 0.18
@export var fire_contact_root_height: float = -0.5
@export var fire_lean_strength: float = 0.08
@export var fire_contact_response: float = 12.0
@export var fire_burst_decay: float = 2.5
@export var fire_canvas_bottom: float = 3.0
@export var fire_canvas_top: float = 4.5

@export_group("Освещение")
@export var fire_light_radius: float = 340.0
@export var fire_light_energy: float = 1.45
@export var fire_light_flicker: float = 0.13
@export var fire_ready_light_boost: float = 0.15
@export var fire_glow_opacity: float = 0.20
@export var ambient_color := Color("798392")

@export_group("Рост и этапы")
@export var stage_upgrade_costs: Array[int] = [40, 160, 400, 800, 1000, 1600]
@export var stage_reward_multipliers: Array[int] = [1, 5, 15, 40, 1, 100]
@export var stage_scale_factor: float = 2.0
@export var growth_response_speed: float = 4.0
@export var camera_response_speed: float = 3.0

@export_group("Искры при кормлении")
@export var feed_particle_count: int = 34
@export var feed_particle_lifetime: float = 1.15
@export var feed_particle_speed: float = 400.0
@export var feed_particle_gravity: float = 150.0
@export var feed_particle_size: float = 6.0

@export_group("Помощники")
@export var helper_speed: float = 160.0
@export var helper_pickup_distance: float = 12.0
@export var helper_animation_fps: float = 10.0
@export var helper_fuel_ratio: float = 0.5

@export_group("Машины")
@export var car_count: int = 1
@export var car_speed: float = 200.0
@export var car_points: int = 45
@export var car_size := Vector2(84.0, 40.0)
@export var road_top_ratio: float = 0.32
@export var road_lane_ratio: float = 0.41
@export var car_spacing: float = 160.0

@export_group("Палитра")
@export var palette: PackedColorArray = PackedColorArray([
	Color("0d2b45"), Color("203c56"), Color("544e68"), Color("8d697a"),
	Color("d08159"), Color("ffaa5e"), Color("ffd4a3"), Color("ffecd6"),
])

@export var stage_flame_tones: Array[int] = [5, 5, 5, 5, 5, 3]
@export var stage_edge_tones: Array[int] = [4, 3, 2, 1, 4, 1]

@export_group("Частицы Godot")
@export var feed_particle_spread: float = 80.0
@export var feed_particle_emission_radius: float = 18.0
@export var feed_ember_count: int = 12
@export var feed_ember_lifetime: float = 1.6
@export var feed_ember_speed: float = 100.0
@export var ember_gravity: float = -16.0
@export var ambient_ember_count: int = 14
@export var ambient_ember_lifetime: float = 2.2
@export var ambient_ember_speed: float = 95.0

@export var feed_particle_origin_height: float = 0.6

@export_group("Дрейн прогресса")
@export var stage_progress_drain: Array[float] = [1.0, 7.0, 60.0, 130.0, 250.0, 160.0]
@export var stage_drain_delay: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

@export_group("Первые этапы")
@export var camp_initial_packs: int = 0
@export var fuel_placeholder_size := Vector2(64.0, 88.0)
@export var fuel_hit_padding: float = 10.0
@export var pack_size := Vector2(40.0, 56.0)
@export var stage_flame_sizes: Array[float] = [1.0, 0.8, 1.0, 1.0, 1.0, 1.0]

@export_group("Поздние этапы")
@export var flying_speed: float = 70.0
@export var surface_height_ratio: float = 0.38
@export var surface_band_height: float = 0.42
@export var planet_starting_fuel: float = 300.0

@export_group("Сгорание предметов")
@export var fuel_burn_duration: float = 0.85
@export var fuel_burn_border: float = 0.12
@export var fuel_burn_noise: float = 0.24

@export_group("Наборы топлива")
@export var stage_fuel_kinds: Array[PackedInt32Array] = [
	PackedInt32Array([3, 4]),
	PackedInt32Array([0, 3]),
	PackedInt32Array([6, 7]),
	PackedInt32Array([8, 9, 10, 11]),
	PackedInt32Array([12]),
	PackedInt32Array([13]),
]

@export_group("Фидбек")
@export var juice_strength: float = 1.0
@export var fuel_hover_lift: float = 5.0
@export var fuel_drop_height: float = 8.0
@export var fuel_drop_duration: float = 0.22
@export var feed_feedback_duration: float = 0.65
@export var feedback_reward_size: int = 32
@export var feedback_reward_rise: float = 70.0
@export var feedback_volume_db: float = -16.0
@export var ember_feed_boost: float = 1.1
@export var black_hole_feed_pulse: float = 0.2
