shader_type canvas_item;
render_mode unshaded;

uniform vec2 canvas_size = vec2(6.0, 7.5);
uniform vec2 canvas_origin = vec2(-3.0, -4.5);
uniform float pixel_count = 228.0;
uniform float clock = 0.0;
uniform float speed = 1.0;
uniform float burst = 0.0;
uniform float feed_boost = 1.1;
uniform float flame_height = 0.42;
uniform float flame_width = 0.14;
uniform float contact_amount = 0.0;
uniform vec2 contact_direction = vec2(0.0, -1.0);
uniform vec4 edge_color : source_color;
uniform vec4 flame_color : source_color;
uniform vec4 hot_color : source_color;
uniform vec4 core_color : source_color;

void fragment() {
	float pixel = 6.0 / pixel_count;
	vec2 p = (floor((UV * canvas_size + canvas_origin) / pixel) + 0.5) * pixel;
	float t = clock * speed;
	float height = flame_height * (1.0 + 0.1 * sin(t * 5.0) + burst * feed_boost + contact_amount * 0.28);
	float up = (0.12 - p.y) / height;
	float bend = sin(t * 3.8 + up * 3.0) * 0.035 * up;
	bend += contact_direction.x * contact_amount * 0.035 * up;
	float width = flame_width * (1.0 + burst * 0.55 + contact_amount * 0.15) * pow(max(1.0 - up, 0.0), 0.75);
	width *= 1.0 + 0.12 * sin(t * 7.0 + up * 5.0);
	float edge = width - abs(p.x - bend);
	float inside = step(0.0, up) * step(up, 1.0) * step(0.0, edge);
	float heat = edge / max(width, pixel) - up * 0.35;
	vec3 color = edge_color.rgb;
	color = mix(color, flame_color.rgb, step(0.2, heat));
	color = mix(color, hot_color.rgb, step(0.45, heat));
	color = mix(color, core_color.rgb, step(0.75, heat));
	COLOR = vec4(color, inside);
}
