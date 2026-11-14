shader_type canvas_item;
render_mode unshaded;
uniform vec4 item_rect;
uniform vec2 burn_origin = vec2(0.5);
uniform float progress = 0.0;
uniform float pixel_size = 4.0;
uniform float border_width = 0.12;
uniform float noise_amount = 0.24;
uniform vec4 palette[8] : source_color;
varying vec2 item_position;

void vertex() {
	item_position = VERTEX;
}

void fragment() {
	vec4 source = COLOR;
	vec2 snapped = floor((item_position - item_rect.xy) / pixel_size) * pixel_size;
	vec2 uv = snapped / item_rect.zw;
	vec2 origin = clamp(burn_origin, vec2(0.0), vec2(1.0));
	float noise = fract(sin(dot(floor(snapped / pixel_size), vec2(127.1, 311.7))) * 43758.5453);
	float distance_to_fire = length(uv - origin) + noise * noise_amount;
	float radius = progress * (1.415 + noise_amount + border_width) - border_width;
	float heat = clamp(1.0 - (distance_to_fire - radius) / border_width, 0.0, 1.0);
	if (heat > 0.0) {
		int band = clamp(int(floor(heat * 8.0)), 0, 7);
		source.rgb = palette[band].rgb;
	}
	source.a *= step(radius, distance_to_fire) * (1.0 - step(1.0, progress));
	COLOR = source;
}
