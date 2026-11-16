uniform vec3 cutaway_entry = vec3(0.0);
uniform vec3 cutaway_exit = vec3(0.0);
uniform vec3 cutaway_branch = vec3(0.0);

// X is the cut face, Y is the deck and Z points down the tunnel.
bool behind_passage(vec3 point, vec3 portal) {
	return (point.x - portal.x) * portal.z > .035
		&& point.y >= portal.y - .12 && point.y < portal.y + 2.5;
}

bool behind_cutaway_wall(vec3 point) {
	return behind_passage(point, cutaway_entry) || behind_passage(point, cutaway_exit)
		|| behind_passage(point, cutaway_branch);
}
