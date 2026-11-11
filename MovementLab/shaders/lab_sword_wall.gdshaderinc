uniform vec3 wall_left = vec3(-10000.0, 0.0, 0.0);
uniform vec3 wall_right = vec3(10000.0, 0.0, 0.0);
varying vec3 sword_world;

bool beyond_sword_wall() {
	bool left = sword_world.x < wall_left.x && sword_world.y >= wall_left.y && sword_world.y <= wall_left.z;
	bool right = sword_world.x > wall_right.x && sword_world.y >= wall_right.y && sword_world.y <= wall_right.z;
	return left || right;
}
