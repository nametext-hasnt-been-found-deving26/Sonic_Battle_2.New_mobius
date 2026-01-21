shader_type canvas_item;

void vertex() {
	UV.y -= 0.125 * TIME;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
