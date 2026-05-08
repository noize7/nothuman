shader_type canvas_item;

uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float border_size = 4.0;
uniform float radius = 20.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

float rounded_box(vec2 p, vec2 size, float r) {
	vec2 d = abs(p) - size + r;
	return length(max(d, 0.0)) - r;
}

void fragment() {
	vec2 rect_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 pos = UV * rect_size;

	vec2 center = rect_size * 0.5;
	vec2 half_size = rect_size * 0.5;

	float outer = rounded_box(pos - center, half_size, radius);

	float inner = rounded_box(
		pos - center,
		half_size - border_size,
		radius
	);

	if (outer <= 0.0 && inner > 0.0) {
		COLOR = vec4(border_color.rgb, border_color.a * alpha);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}