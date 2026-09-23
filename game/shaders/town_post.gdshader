shader_type canvas_item;
render_mode unshaded;
// Post-proceso del pueblo: foco tipo tilt-shift (lo lejano se desenfoca, como
// un recuerdo que todavia no termina de volver), sombras de nubes y rayos de
// sol anclados al mundo, gradacion calida/fria y una aberracion suave en los
// bordes. `instability` (1 - Estabilidad) empuja el desenfoque y la
// aberracion: cuanto menos estable, menos nitido se ve el mundo.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D cloud_noise : repeat_enable, filter_linear;

uniform vec2 view_origin = vec2(0.0);
uniform vec2 view_size = vec2(1066.0, 600.0);
uniform float instability : hint_range(0.0, 1.0) = 0.5;

uniform float focus_center = 0.56;
uniform float focus_band = 0.26;
uniform float focus_soft = 0.32;
uniform float blur_lod_min = 0.6;
uniform float blur_lod_max = 2.4;

uniform float cloud_scale = 1100.0;
uniform vec2 cloud_wind = vec2(14.0, 6.0);
uniform float cloud_strength = 0.75;

uniform float ray_strength = 0.07;
uniform float vignette = 0.26;
uniform float aberration_px = 2.5;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 from_center = uv - vec2(0.5);

	float lod = mix(blur_lod_min, blur_lod_max, instability);
	float blur = smoothstep(focus_band, focus_band + focus_soft, abs(uv.y - focus_center)) * lod;

	vec2 shift = from_center * length(from_center) * 2.0 * aberration_px * (0.4 + instability) * SCREEN_PIXEL_SIZE;
	vec3 col;
	col.r = textureLod(screen_tex, uv + shift, blur).r;
	col.g = textureLod(screen_tex, uv, blur).g;
	col.b = textureLod(screen_tex, uv - shift, blur).b;

	vec2 world = view_origin + uv * view_size;

	// Dos octavas de ruido a distinta velocidad: las nubes cambian de forma
	// mientras avanzan, en vez de ser una textura que se desliza.
	vec2 drift = TIME * cloud_wind;
	float n = texture(cloud_noise, (world + drift) / cloud_scale).r * 0.65
			+ texture(cloud_noise, (world - drift * 0.6) / (cloud_scale * 0.45)).r * 0.35;
	float cloud = smoothstep(0.48, 0.70, n);
	col *= mix(vec3(1.0), vec3(0.62, 0.68, 0.85), cloud * cloud_strength);

	float ray = sin((world.x + world.y * 0.55) * 0.010 + TIME * 0.25) * 0.5 + 0.5;
	ray *= sin((world.x + world.y * 0.55) * 0.023 - TIME * 0.4) * 0.5 + 0.5;
	col += vec3(1.0, 0.82, 0.55) * pow(ray, 4.0) * ray_strength * (1.0 - cloud);

	// Luces calidas, sombras frias: el "golden hour" de los pixel art modernos.
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, col * vec3(0.88, 0.95, 1.10), (1.0 - luma) * 0.45);
	col = mix(col, col * vec3(1.08, 1.00, 0.86), luma * 0.35);
	col = mix(vec3(luma), col, 1.12);
	col = mix(col, col * col * (3.0 - 2.0 * col), 0.25);

	float v = smoothstep(0.35, 0.95, length(from_center * vec2(1.0, 1.25)) * 1.2);
	col *= 1.0 - v * vignette;

	COLOR = vec4(col, 1.0);
}
