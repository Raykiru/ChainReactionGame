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
		left_click := rl.IsMouseButtonPressed(.LEFT)


		// game logic
		@(static) grid: [GAME_GRID_SIZE.x * GAME_GRID_SIZE.y]i32
		{


			// overflowing

			@(static) react_queue: [dynamic]i32
			@(static) react_done: int = 0
			for cell, i in grid {i := i32(i)

				if cell >= 4 {append(&react_queue, i)}
			}

			for i in react_queue {
				grid[i] -= 4
				react_done += 1

				// grid spreading pattern:
				//   |i-y|
				//i-1| i |i+1
				//   |i+y|
				{
					// if not spreading outside the bounds to the right
					if (i + 1) / GAME_GRID_SIZE.x == (i) / GAME_GRID_SIZE.x && i < len(grid) {
						grid[i + 1] += 1
					}

					if (i - 1) / GAME_GRID_SIZE.x == (i) / GAME_GRID_SIZE.x && i > 0 {
						grid[i - 1] += 1
					}

					if (i + GAME_GRID_SIZE.x) < len(grid) {
						grid[i + GAME_GRID_SIZE.x] += 1
					}

					if (i - GAME_GRID_SIZE.x) >= 0 {
						grid[i - GAME_GRID_SIZE.x] += 1
					}
				}
			}

			if len(react_queue) == react_done && len(react_queue) > 0 {
				clear(&react_queue)
				react_done = 0
			} else if left_click {
				// clicking
				grid_pos := (mouse_pos - GAME_BOARD_OFFSET) / CELL_SIZE
				arr_pos := grid_pos.x + grid_pos.y * GAME_GRID_SIZE.y
				grid[arr_pos] += 1
			}

		}

		// virtual drawing
		if (virtual_screen_draw()) {
			// draw board
			{
				xoff := GAME_BOARD_OFFSET.x
				yoff := GAME_BOARD_OFFSET.y
				rl.DrawRectangle(xoff, yoff, **GAME_BOARD_SIZE, rl.GRAY / 2 + rl.BLUE / 2)
				// draw grid
				{

					// horizontal
					for x in 1 ..< GAME_GRID_SIZE.x {
						rl.DrawLine(
							xoff + CELL_SIZE * x,
							yoff,
							xoff + CELL_SIZE * x,
							yoff + GAME_BOARD_SIZE.x,
							rl.WHITE,
						)

					}
					for y in 1 ..< GAME_GRID_SIZE.y {
						rl.DrawLine(
							xoff,
							yoff + CELL_SIZE * y,
							xoff + GAME_BOARD_SIZE.y,
							yoff + CELL_SIZE * y,
							rl.WHITE,
						)
					}
				}

				// draw pieces
				draw_piece :: proc(grid_pos: [2]i32, size: i32, color: rl.Color) {
					square_pos := grid_pos * CELL_SIZE + GAME_BOARD_OFFSET
					rl.DrawRectangle(**square_pos, CELL_SIZE, CELL_SIZE, color)
					rl.DrawText(fmt.caprint(size), **(square_pos + CELL_SIZE / 2), 24, rl.BLACK)
				}

				for piece, pos in grid {
					pos := i32(pos)
					if piece != 0 {
						piece_pos := [2]i32{pos % GAME_GRID_SIZE.x, pos / GAME_GRID_SIZE.y}
						draw_piece(piece_pos, piece, rl.RED)
					}
				}
			}


		}


		virtual_screen_render()
	}
}

GAME_GRID_SIZE :: [2]i32{5, 5}
CELL_SIZE :: 80
GAME_BOARD_SIZE :: [2]i32{GAME_GRID_SIZE.x * CELL_SIZE, GAME_GRID_SIZE.y * CELL_SIZE}
GAME_BOARD_OFFSET :: [2]i32 {
	(VIRTUAL_WIDTH - GAME_BOARD_SIZE.x) / 2,
	(VIRTUAL_HEIGHT - GAME_BOARD_SIZE.y) / 2,
}
#assert(GAME_BOARD_SIZE.x <= VIRTUAL_WIDTH)
#assert(GAME_BOARD_SIZE.y <= VIRTUAL_HEIGHT)
