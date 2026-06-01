shader_type canvas_item;

uniform float base_brightness = 0.68;
uniform float texture_contrast = 0.34;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float light_gray = clamp(base_brightness + (luminance - 0.42) * texture_contrast, 0.54, 0.86);
	COLOR = vec4(vec3(light_gray), 1.0);
}
