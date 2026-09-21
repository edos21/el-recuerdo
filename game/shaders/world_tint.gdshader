shader_type canvas_item;
// Progresion de color del Nivel 1 (seccion 27 del documento base): el mundo
// arranca casi en blanco y negro y va recuperando saturacion con cada
// recuerdo. `focus_*` es el "parche" de color alrededor del jugador de las
// etapas intermedias; `vignette` es el efecto corporal de la Estabilidad.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float saturation : hint_range(0.0, 1.0) = 0.12;
uniform float focus_saturation : hint_range(0.0, 1.0) = 0.75;
uniform vec2 focus_center = vec2(-10000.0, -10000.0);
uniform float focus_radius = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.0;
uniform float cold_tint : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 c = texture(screen_tex, SCREEN_UV);
	float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float s = saturation;
	if (focus_radius > 0.0) {
		float d = distance(FRAGCOORD.xy, focus_center);
		float t = 1.0 - smoothstep(focus_radius * 0.55, focus_radius, d);
		s = max(s, mix(saturation, focus_saturation, t));
	}
	vec3 col = mix(vec3(gray), c.rgb, s);
	// Lo desaturado tira un poco a frio y oscuro: misterio, no alegria.
	vec3 cold = col * vec3(0.86, 0.90, 1.02) * 0.92;
	col = mix(col, cold, (1.0 - s) * cold_tint);
	vec2 uv = SCREEN_UV - vec2(0.5);
	float v = smoothstep(0.30, 0.85, length(uv) * 1.25);
	col = mix(col, col * 0.12, v * vignette);
	COLOR = vec4(col, 1.0);
}
