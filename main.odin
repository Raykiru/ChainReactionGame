package main

import "core:fmt"
import rl "vendor:raylib"

window_width: i32 = 1280
window_height: i32 = 720

VIRTUAL_WIDTH :: 600
VIRTUAL_HEIGHT :: 600
TS_GRAY :: [4]u8{18, 18, 18, 255}

main :: proc() {

	rl.InitWindow(window_width, window_height, "Chain Reaction")
	rl.SetWindowState({.WINDOW_RESIZABLE})

	rl.SetTargetFPS(60)


	virtual_screen_init(VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

	for !rl.WindowShouldClose() {
		delta := rl.GetFrameTime()

		mouse_pos := cast([2]i32)[2]f32{virtual_screen_mouse_pos()}

		// virtual drawing
		if virtual_screen_draw() {

		}


		virtual_screen_render()
	}

}

draw :: proc() {}
