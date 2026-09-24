shader_type canvas_item;
render_mode unshaded;
// Variante sin desenfoque: una lectura de pantalla sin mipmaps.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

#include "res://shaders/world_post.gdshaderinc"
