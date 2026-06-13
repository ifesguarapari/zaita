shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec2 focus_position = vec2(0.5, 0.5);
uniform vec2 focus_ellipse = vec2(1.58, 0.78);
uniform vec2 focus_drift = vec2(0.012, 0.006);
uniform float focus_drift_speed = 0.7;
uniform float focus_pulse_min = 1.0;
uniform float focus_pulse_max = 2.0;
uniform float focus_pulse_speed = 0.78;
uniform vec2 foot_ellipse = vec2(0.066, 0.02);
uniform vec2 foot_offset = vec2(0.0, -0.004);
uniform vec3 foot_shadow_color = vec3(0.18, 0.17, 0.16);
uniform float foot_shadow_strength = 0.0;
uniform float foot_shadow_core_strength = 0.0;
uniform float aspect_ratio = 1.777;
uniform float color_radius = 0.19;
uniform float fade_width = 0.12;
uniform float distant_saturation = 0.0;
uniform float distant_brightness = 1.0;
uniform float distant_gray_floor = 0.46;
uniform float distant_contrast = 0.58;
uniform float focus_brightness = 1.0;
uniform float vignette_strength = 0.0;

void fragment() {
	vec4 scene = texture(screen_texture, SCREEN_UV);
	vec2 animated_focus = focus_position + vec2(
		sin(TIME * focus_drift_speed) * focus_drift.x,
		cos(TIME * focus_drift_speed * 0.73) * focus_drift.y
	);
	float focus_pulse_phase = sin(TIME * focus_pulse_speed) * 0.5 + 0.5;
	float focus_pulse = mix(focus_pulse_min, focus_pulse_max, smoothstep(0.0, 1.0, focus_pulse_phase));
	vec2 focus_delta = SCREEN_UV - animated_focus;
	focus_delta.x *= aspect_ratio;
	focus_delta /= focus_ellipse * focus_pulse;
	float distance_from_focus = length(focus_delta);
	float animated_fade_width = fade_width * focus_pulse;
	float distant_mix = smoothstep(color_radius * 0.18, color_radius + animated_fade_width, distance_from_focus);
	float luminance = dot(scene.rgb, vec3(0.299, 0.587, 0.114));
	float lifted_luminance = clamp(
		distant_gray_floor + (luminance - 0.5) * distant_contrast,
		0.0,
		1.0
	);
	vec3 grayscale = vec3(lifted_luminance) * distant_brightness;
	vec3 distant_color = mix(grayscale, scene.rgb, distant_saturation);
	vec3 focus_color = scene.rgb * focus_brightness;
	vec3 filtered_color = mix(focus_color, distant_color, distant_mix);
	vec2 foot_delta = SCREEN_UV - (focus_position + foot_offset);
	foot_delta.x *= aspect_ratio;
	foot_delta /= foot_ellipse;
	float foot_distance = length(foot_delta);
	float foot_light = 1.0 - smoothstep(0.0, 0.72, foot_distance);
	float foot_core = 1.0 - smoothstep(0.0, 0.26, foot_distance);
	float foot_amount = clamp(
		foot_light * foot_shadow_strength + foot_core * foot_shadow_core_strength,
		0.0,
		1.0
	);
	filtered_color = mix(filtered_color, foot_shadow_color, foot_amount);

	vec2 vignette_delta = SCREEN_UV - vec2(0.5);
	vignette_delta.x *= aspect_ratio;
	float vignette = smoothstep(0.38, 0.92, length(vignette_delta));
	filtered_color *= 1.0 - vignette * vignette_strength;
	COLOR = vec4(filtered_color, scene.a);
}
