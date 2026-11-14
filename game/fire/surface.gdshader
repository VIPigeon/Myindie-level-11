shader_type canvas_item;
render_mode unshaded;

uniform float clock = 0.0;
uniform float burst = 0.0;
uniform vec2 resolution = vec2(400.0, 126.0);
uniform vec4 edge_color : source_color;
uniform vec4 flame_color : source_color;
uniform vec4 hot_color : source_color;
uniform vec4 core_color : source_color;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = smoothstep(vec2(0.0), vec2(1.0), fract(p));
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}

void fragment() {
	vec2 uv = (floor(UV * resolution) + 0.5) / resolution;
	float t = clock;
	float rise = 1.0 - uv.y;
	float curl = noise(vec2(uv.x * 9.0, rise * 3.0 - t * 1.6));
	float detail = noise(vec2(uv.x * 27.0 + curl, rise * 7.0 - t * 3.0));
	float height = 0.48 + curl * 0.42 + detail * 0.12 + burst * 0.18;
	float field = height - rise;
	float inside = step(0.0, field);
	float heat = field + detail * 0.1;
	vec3 color = edge_color.rgb;
	color = mix(color, flame_color.rgb, step(0.08, heat));
	color = mix(color, hot_color.rgb, step(0.22, heat));
	color = mix(color, core_color.rgb, step(0.48, heat));
	COLOR = vec4(color, inside);
}
