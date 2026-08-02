package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

// Draw a 3D-looking cylinder piece on a 2D board.
// x, y: center of the base (bottom ellipse) on the board.
// radius_x, radius_y: horizontal/vertical radius of the ellipses.
//   To look correct, radius_y should be about 0.3–0.5 * radius_x.
// height: vertical distance between the centers of the two ellipses.
// color: base color of the piece.

import rlgl "vendor:raylib/rlgl"

draw_cylinder_piece :: proc(x, y: f32, radius_x, radius_y, height: f32, color: rl.Color) {
	side_color := rl.ColorBrightness(color, -0.3)

	// side wall
	rl.DrawRectangleV({x - radius_x, y - height}, {radius_x * 2, height}, side_color)
	rl.DrawEllipse(i32(x), i32(y - height), radius_x, radius_y, side_color)
	rl.DrawEllipse(i32(x), i32(y), radius_x, radius_y, side_color)

	// top cap
	rl.DrawEllipse(i32(x), i32(y - height), radius_x, radius_y, color)
}
