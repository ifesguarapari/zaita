shader_type canvas_item;

uniform vec4 clay_tint : source_color = vec4(0.59, 0.43, 0.30, 1.0);
uniform vec2 sample_origin = vec2(0.19, 0.32);
uniform vec2 sample_size = vec2(0.62, 0.34);
uniform float texture_repeat = 5.6;
uniform float texture_strength = 0.18;
uniform float contrast = 0.28;
uniform float brightness = 1.08;

void fragment() {
	vec2 repeated_uv = UV * texture_repeat;
	vec2 mirrored_uv = abs(fract(repeated_uv) * 2.0 - 1.0);
	vec4 source = texture(TEXTURE, sample_origin + mirrored_uv * sample_size);
	vec3 sampled_color = mix(clay_tint.rgb, source.rgb, source.a);
	float luminance = dot(sampled_color, vec3(0.299, 0.587, 0.114));
	float softened_luminance = clamp(0.5 + (luminance - 0.5) * contrast, 0.0, 1.0);
	vec3 clay_detail = clay_tint.rgb * (0.78 + softened_luminance * 0.48);
	vec3 color = mix(clay_detail, sampled_color, texture_strength * source.a);
	COLOR = vec4(clamp(color * brightness, 0.0, 1.0), 1.0);
}
