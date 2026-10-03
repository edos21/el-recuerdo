shader_type canvas_item;
// Papel viejo para las paginas del cuaderno: grano fino de fibra, manchas
// grandes y suaves de envejecimiento, y bordes mas oscuros. Solo toca lo que
// dibuja la pagina (papel y lo impreso); el texto a mano son nodos hijos y no
// pasa por aca, para que el grano no ensucie la lectura.

uniform vec2 page_size = vec2(740.0, 800.0);
uniform float grain_strength = 0.045;
uniform float grain_scale = 1.6;
uniform float stain_strength = 0.06;
uniform float stain_scale = 140.0;
uniform float edge_darkening = 0.16;
uniform float edge_width = 0.22;
uniform float seed = 0.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 p = local_position + seed * 97.0;
	float grain = hash(floor(p / grain_scale)) - 0.5;
	float stain = value_noise(p / stain_scale) * 0.65 + value_noise(p / (stain_scale * 0.35)) * 0.35;
	vec2 uv = local_position / page_size;
	vec2 to_edge = min(uv, 1.0 - uv);
	float edge = 1.0 - smoothstep(0.0, edge_width, min(to_edge.x, to_edge.y * 1.3));
	float shade = 1.0 + grain * grain_strength - stain * stain_strength - edge * edge * edge_darkening;
	COLOR.rgb *= shade;
}
