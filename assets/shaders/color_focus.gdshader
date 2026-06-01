shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec2 focus_position = vec2(0.5, 0.5);
uniform float aspect_ratio = 1.777;
uniform float color_radius = 0.14;
uniform float fade_width = 0.42;
uniform float distant_saturation = 0.08;
uniform float distant_brightness = 0.58;
uniform float vignette_strength = 0.28;

void fragment() {
	vec4 scene = texture(screen_texture, SCREEN_UV);
	vec2 focus_delta = SCREEN_UV - focus_position;
	focus_delta.x *= aspect_ratio;
	float distance_from_focus = length(focus_delta);
	float distant_mix = smoothstep(color_radius, color_radius + fade_width, distance_from_focus);
	float luminance = dot(scene.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grayscale = mix(vec3(luminance), scene.rgb, distant_saturation) * distant_brightness;
	vec3 filtered_color = mix(scene.rgb, grayscale, distant_mix);

	vec2 vignette_delta = SCREEN_UV - vec2(0.5);
	vignette_delta.x *= aspect_ratio;
	float vignette = smoothstep(0.38, 0.92, length(vignette_delta));
	filtered_color *= 1.0 - vignette * vignette_strength;
	COLOR = vec4(filtered_color, scene.a);
}
