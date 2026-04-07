shader_type canvas_item;

uniform float direction = 1;
uniform float speed = 1.0;
uniform float y_frequency = 1.0;
uniform float y_amplitude = 0.005;
varying vec4 modulate; // ensures the modulate functions still work

void vertex() {
	modulate = COLOR;
}

void fragment() {
	float move_x = direction * speed * TIME;
	float move_y = sin(TIME * y_frequency) * y_amplitude;
	vec2 move = vec2(move_x, move_y);
	COLOR = texture(TEXTURE, UV + move) * modulate;
}

