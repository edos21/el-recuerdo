shader_type canvas_item;
// Las ventanas de la casa (la mascara house_x_windows.png que escribe el generador) se encienden con un color
// calido y saturado al maximo: el glow del entorno los toma por encima del umbral.

uniform sampler2D window_mask : hint_default_black, filter_nearest;
uniform vec3 lit_color : source_color = vec3(1.0, 0.78, 0.42);
uniform float flicker = 0.08;

varying float phase;

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	phase = world.x * 0.37 + world.y * 0.11;
}

// COLOR ya llega multiplicado por la textura: solo se reemplaza donde la mascara es blanca.
void fragment() {
	if (texture(window_mask, UV).r > 0.5) {
		float f = 1.0 + flicker * sin(TIME * 7.0 + phase) * sin(TIME * 3.1 + phase * 2.0);
		COLOR.rgb = lit_color * f;
	}
}
