shader_type canvas_item;

uniform bool space_background = false;
uniform vec2 world_size = vec2(960.0, 540.0);
uniform vec4 dark_color : source_color;
uniform vec4 light_color : source_color;
uniform float pixel_size = 4.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = (UV - 0.5) * world_size;
	vec2 cell = floor(p / pixel_size);
	float grain = hash(cell);
	vec3 earth = mix(dark_color.rgb, light_color.rgb, step(0.7, grain));
	float ash = 1.0 - smoothstep(65.0, 135.0, length(p * vec2(1.0, 1.4)));
	earth = mix(earth, dark_color.rgb, step(0.5, ash));
	COLOR = vec4(space_background ? dark_color.rgb : earth, 1.0);
}
