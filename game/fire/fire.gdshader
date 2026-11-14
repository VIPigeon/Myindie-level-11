shader_type canvas_item;
render_mode unshaded;

uniform vec2 canvas_size = vec2(6.0, 7.5);
uniform vec2 canvas_origin = vec2(-3.0, -4.5);
uniform float clock = 0.0;
uniform float pixel_count = 112.0;
uniform float animation_fps = 24.0;
uniform float speed = 1.0;
uniform float turbulence = 0.65;
uniform float burst = 0.0;
uniform float contact_amount = 0.0;
uniform vec2 contact_direction = vec2(0.0, -1.0);
uniform float contact_length = 1.1;
uniform float contact_width = 0.18;
uniform float contact_root_height = -0.5;
uniform float lean_strength = 0.08;
uniform vec4 edge_color : source_color = vec4(0.81568627, 0.50588235, 0.34901961, 1.0);
uniform vec4 flame_color : source_color = vec4(1.0, 0.66666667, 0.36862745, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.83137255, 0.63921569, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.9254902, 0.83921569, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), u.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.57 + noise(p * 2.07 + 13.1) * 0.28 + noise(p * 4.13 + 7.7) * 0.15;
}

void fragment() {
	float pixel = 6.0 / pixel_count;
	vec2 p = (floor((UV * canvas_size + canvas_origin) / pixel) + 0.5) * pixel;
	float t = floor(clock * animation_fps) / animation_fps * speed;
	vec2 q = p;
	float lean_height = clamp((0.48 - p.y) / 2.25, 0.0, 1.0);
	q.x -= contact_direction.x * contact_amount * lean_strength * lean_height * lean_height;
	float height = (0.48 - q.y) / (2.25 + burst * 0.35);
	float n = fbm(vec2(q.x * 3.0, q.y * 2.0 + t * 2.8));
	float curl = (fbm(vec2(q.y * 2.1 - t, t * 0.65)) - 0.5);
	float x = q.x + curl * height * turbulence;
	float width = 0.40 * pow(max(0.0, 1.0 - height), 0.70);
	float left_height = height / (0.68 + 0.09 * sin(t * 1.7));
	float right_height = height / (0.77 + 0.08 * sin(t * 2.1 + 2.0));
	float left = 0.42 * pow(max(0.0, 1.0 - left_height), 0.8) - abs(x + (0.48 - height * 0.12));
	float right = 0.40 * pow(max(0.0, 1.0 - right_height), 0.8) - abs(x - (0.48 - height * 0.10));
	float field = max(width - abs(x), max(left, right)) + (n - 0.48) * turbulence * (0.35 + height);
	float tip_erosion = pow(max(height - 0.9, 0.0), 2.0) * 4.0;
	float inside = step(0.0, field - tip_erosion) * step(0.0, height);
	float heat = field / max(width, 0.1) - height * 0.40 + (n - 0.5) * 0.18;
	vec3 fire = edge_color.rgb;
	fire = mix(fire, flame_color.rgb, step(0.13, heat));
	fire = mix(fire, hot_color.rgb, step(0.36, heat));
	fire = mix(fire, core_color.rgb, step(0.69, heat));

	vec3 result = fire;
	float alpha = inside;

	vec2 direction = contact_direction;
	vec2 root = vec2(direction.x * contact_width, contact_root_height);
	float reach = contact_length * contact_amount;
	vec2 relative = p - root;
	float along = dot(relative, direction) / max(reach, 0.001);
	float u = clamp(along, 0.0, 1.0);
	vec2 normal = vec2(-direction.y, direction.x);
	float curl_offset = sin(u * 5.0 - t * 8.0) * sin(u * 3.14159) * 0.06;
	float width_contact = contact_width * pow(1.0 - u, 0.65);
	float side = abs(dot(relative, normal) - curl_offset);
	float tongue = step(side, width_contact) * step(0.0, along) * step(along, 1.0) * step(0.02, contact_amount);
	float tongue_heat = 1.0 - side / max(width_contact, 0.001) - u * 0.55;
	vec3 tongue_color = mix(flame_color.rgb, hot_color.rgb, step(0.3, tongue_heat));
	tongue_color = mix(tongue_color, core_color.rgb, step(0.75, tongue_heat));
	result = mix(result, tongue_color, tongue * (1.0 - inside));
	alpha = max(alpha, tongue);
	COLOR = vec4(result, alpha);
}
