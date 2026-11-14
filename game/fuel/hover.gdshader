shader_type canvas_item;
render_mode unshaded;
uniform bool has_sprite = true;
uniform bool highlighted = false;
uniform float heat = 0.0;
uniform vec4 outline_color : source_color;
uniform vec4 hot_color : source_color;

void fragment() {
	vec4 source = COLOR;
	vec2 pixel = TEXTURE_PIXEL_SIZE;
	float border = max(max(texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a,
		texture(TEXTURE, UV - vec2(pixel.x, 0.0)).a),
		max(texture(TEXTURE, UV + vec2(0.0, pixel.y)).a, texture(TEXTURE, UV - vec2(0.0, pixel.y)).a));
	if (highlighted && source.a < 0.01 && border > 0.5) {
		source = outline_color;
	}
	if (highlighted && !has_sprite && source.a > 0.5) {
		source.rgb = outline_color.rgb;
	}
	if (heat > 0.5 && source.a > 0.5 && sin(TIME * 18.0 + UV.x * 25.0 + UV.y * 17.0) > 0.85) {
		source.rgb = hot_color.rgb;
	}
	COLOR = source;
}
