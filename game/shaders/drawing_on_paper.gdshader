shader_type canvas_item;
render_mode blend_mul;
// Hace que una lámina escaneada parezca dibujada en la página del libro: se
// multiplica por el papel de abajo (el blanco de la hoja no tapa nada y los
// lápices toman su tono), se amarillea un poco para igualarlo, lleva el grano del
// papel y el borde se recorta a mano, irregular y con fundido, en vez de cortarse
// recto. Con multiplicar, blanco = no hacer nada, así que fundir es ir a blanco.

uniform vec3 paper_tint = vec3(1.0, 0.95, 0.84);
// Multiplicar contra un papel que ya es beige oscurece todo: se compensa antes.
uniform float exposure = 1.18;
uniform float grain_strength = 0.06;
uniform float grain_size = 1.6;
// Cuánto se corre el borde recortado (fracción del lado corto) y qué tan ancho es el fundido.
uniform float edge_roughness = 0.10;
uniform float edge_inset = 0.015;
uniform float edge_fade = 0.05;
uniform float edge_noise_scale = 7.0;
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), u.x),
			mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec4 art = texture(TEXTURE, UV);
	vec2 size_px = 1.0 / TEXTURE_PIXEL_SIZE;
	float short_side = min(size_px.x, size_px.y);
	vec2 to_edge = min(UV, 1.0 - UV) * size_px / short_side;
	float dist = min(to_edge.x, to_edge.y);
	vec2 p = UV * size_px / short_side * edge_noise_scale + seed * 17.0;
	float wobble = value_noise(p) * 0.65 + value_noise(p * 2.7) * 0.35 - 0.5;
	float mask = smoothstep(0.0, edge_fade, dist - edge_inset + wobble * edge_roughness);
	vec3 color = clamp(art.rgb * exposure, 0.0, 1.0) * paper_tint;
	color *= 1.0 + (hash(floor(FRAGCOORD.xy / grain_size)) - 0.5) * grain_strength;
	// Lo transparente no dibuja nada (multiplicar por negro lo taparía).
	COLOR = vec4(mix(vec3(1.0), color, mask * art.a), 1.0);
}
