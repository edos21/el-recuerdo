shader_type canvas_item;
// Contorno de un texel alrededor del sprite: separa a los personajes del
// fondo sin cambiarles el color. Las sombras llevan un borde frio y claro
// (se recortan contra la penumbra); el protagonista, uno oscuro (se lee aun
// junto al brillo de un recuerdo).

uniform vec4 outline_color : source_color = vec4(0.05, 0.04, 0.08, 1.0);
uniform float alpha_cut = 0.1;

varying vec4 modulate_color;

void vertex() {
	modulate_color = COLOR;
}

void fragment() {
	if (COLOR.a < alpha_cut) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float near = max(
			max(texture(TEXTURE, UV + vec2(px.x, 0.0)).a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a),
			max(texture(TEXTURE, UV + vec2(0.0, px.y)).a, texture(TEXTURE, UV - vec2(0.0, px.y)).a));
		// Hereda la transparencia del personaje (fundidos, parpadeos).
		COLOR = vec4(outline_color.rgb, outline_color.a * step(alpha_cut, near) * modulate_color.a);
	}
}
