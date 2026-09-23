shader_type canvas_item;
// Balanceo de la copa: solo se mueven los vertices de arriba del sprite, los
// pies quedan fijos (y con ellos el orden por Y y la colision). La fase sale
// de la posicion en el mundo para que los arboles no se muevan al unisono.

uniform float strength = 1.6;
uniform float speed = 1.1;

void vertex() {
	float top = 1.0 - UV.y;
	vec2 world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	float phase = world.x * 0.013 + world.y * 0.007;
	float gust = sin(TIME * speed + phase) + 0.35 * sin(TIME * speed * 2.7 + phase * 1.7);
	VERTEX.x += gust * strength * top * top;
}
