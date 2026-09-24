shader_type canvas_item;
render_mode unshaded;
// Variante con desenfoque (tilt-shift): pide mipmaps de la pantalla.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

#include "res://shaders/world_post.gdshaderinc"
