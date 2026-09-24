// Unico post-proceso del mundo (lo instancia Core, debajo del HUD). Cada
// escena lo configura con un WorldLook; los valores por defecto no hacen nada,
// para que una escena nueva arranque neutra.
//
// - Progresion de color (seccion 15 del documento base): el recuerdo arranca
//   casi en blanco y negro; `focus_*` es el parche de color alrededor del
//   jugador de las etapas intermedias.
// - `instability` (1 - Estabilidad) empuja el desenfoque y la aberracion:
//   cuanto menos estable, menos nitido se ve el mundo.
// - Nubes y rayos van anclados al mundo, no a la pantalla.
//
// Cada variante (world_post*.gdshader) declara `screen_tex` antes de incluir
// esto: el desenfoque necesita mipmaps de la pantalla y generarlos cuesta en
// cada frame, asi que solo los pide la variante que desenfoca.

uniform sampler2D cloud_noise : repeat_enable, filter_linear;

uniform vec2 view_origin = vec2(0.0);
uniform vec2 view_size = vec2(1000.0, 562.0);
uniform float instability : hint_range(0.0, 1.0) = 0.0;

uniform float saturation : hint_range(0.0, 1.0) = 1.0;
uniform float focus_saturation : hint_range(0.0, 1.0) = 0.75;
uniform vec2 focus_center = vec2(-10000.0, -10000.0);
uniform float focus_radius = 0.0;
uniform float cold_tint : hint_range(0.0, 1.0) = 0.0;

uniform float tilt_center = 0.56;
uniform float tilt_band = 0.32;
uniform float tilt_soft = 0.32;
uniform float blur_lod_min = 0.0;
uniform float blur_lod_max = 0.0;
uniform float aberration_px = 0.0;

uniform float cloud_scale = 1100.0;
uniform vec2 cloud_wind = vec2(14.0, 6.0);
uniform float cloud_strength = 0.0;
uniform float ray_strength = 0.0;

uniform float grade_strength : hint_range(0.0, 1.0) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 from_center = uv - vec2(0.5);

	float lod = mix(blur_lod_min, blur_lod_max, instability);
	float blur = smoothstep(tilt_band, tilt_band + tilt_soft, abs(uv.y - tilt_center)) * lod;
	vec3 col = textureLod(screen_tex, uv, blur).rgb;
	if (aberration_px > 0.0) {
		vec2 shift = from_center * length(from_center) * 2.0 * aberration_px * (0.4 + instability) * SCREEN_PIXEL_SIZE;
		col.r = textureLod(screen_tex, uv + shift, blur).r;
		col.b = textureLod(screen_tex, uv - shift, blur).b;
	}

	float gray = dot(col, vec3(0.299, 0.587, 0.114));
	float s = saturation;
	if (focus_radius > 0.0) {
		float d = distance(FRAGCOORD.xy, focus_center);
		float t = 1.0 - smoothstep(focus_radius * 0.55, focus_radius, d);
		s = max(s, mix(saturation, focus_saturation, t));
	}
	col = mix(vec3(gray), col, s);
	// Lo desaturado tira un poco a frio y oscuro: misterio, no alegria.
	vec3 cold = col * vec3(0.86, 0.90, 1.02) * 0.92;
	col = mix(col, cold, (1.0 - s) * cold_tint);

	// Ramas uniformes: todos los pixeles toman el mismo camino, asi que una
	// escena sin cielo (el Nivel 1) no paga el ruido ni los senos.
	if (cloud_strength > 0.0 || ray_strength > 0.0) {
		vec2 world = view_origin + uv * view_size;
		// Dos octavas de ruido a distinta velocidad: las nubes cambian de forma
		// mientras avanzan, en vez de ser una textura que se desliza.
		vec2 drift = TIME * cloud_wind;
		float n = texture(cloud_noise, (world + drift) / cloud_scale).r * 0.65
				+ texture(cloud_noise, (world - drift * 0.6) / (cloud_scale * 0.45)).r * 0.35;
		float cloud = smoothstep(0.48, 0.70, n) * cloud_strength;
		col *= mix(vec3(1.0), vec3(0.62, 0.68, 0.85), cloud);

		float ray = sin((world.x + world.y * 0.55) * 0.010 + TIME * 0.25) * 0.5 + 0.5;
		ray *= sin((world.x + world.y * 0.55) * 0.023 - TIME * 0.4) * 0.5 + 0.5;
		col += vec3(1.0, 0.82, 0.55) * pow(ray, 4.0) * ray_strength * (1.0 - cloud);
	}

	// Luces calidas, sombras frias. La saturacion extra se escala con `s`
	// para que la gradacion no le devuelva color a un recuerdo todavia gris.
	if (grade_strength > 0.0) {
		float luma = dot(col, vec3(0.299, 0.587, 0.114));
		vec3 graded = mix(col, col * vec3(0.88, 0.95, 1.10), (1.0 - luma) * 0.45);
		graded = mix(graded, graded * vec3(1.08, 1.00, 0.86), luma * 0.35);
		graded = mix(vec3(luma), graded, 1.0 + 0.12 * s);
		graded = mix(graded, graded * graded * (3.0 - 2.0 * graded), 0.25);
		col = mix(col, graded, grade_strength);
	}

	float v = smoothstep(0.30, 0.85, length(from_center) * 1.25);
	col = mix(col, col * 0.12, v * vignette);

	COLOR = vec4(col, 1.0);
}
