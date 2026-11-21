shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 0.5) = 0.08;

void fragment() {
	vec2 uv = UV;
	vec2 centered = uv - 0.5;
	vec2 half_size = vec2(0.5);
	float r = clamp(corner_radius, 0.0, 0.5);

	vec2 q = abs(centered) - (half_size - vec2(r));
	float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;

	vec4 tex_color = texture(TEXTURE, uv);
	float alpha = 1.0 - smoothstep(-0.005, 0.005, dist);

	COLOR = vec4(tex_color.rgb, tex_color.a * alpha);
}