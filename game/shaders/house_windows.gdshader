shader_type canvas_item;
// Las ventanas de la casa (el celeste del sprite) se encienden con un color
// calido y saturado al maximo: el glow del entorno los toma por encima del umbral.

uniform vec3 window_color = vec3(0.588, 0.745, 0.824);
uniform vec3 lit_color : source_color = vec3(1.0, 0.78, 0.42);
uniform float lit_energy = 1.0;
uniform float flicker = 0.08;

varying float phase;

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	phase = world.x * 0.37 + world.y * 0.11;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (distance(c.rgb, window_color) < 0.05) {
		float f = 1.0 + flicker * sin(TIME * 7.0 + phase) * sin(TIME * 3.1 + phase * 2.0);
		c.rgb = lit_color * lit_energy * f;
	}
	COLOR = c * COLOR;
}
