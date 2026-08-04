package main

import "core:fmt"
import "core:math"
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
		@(static) delta: f32
		@(static) game_time: f64
		@(static) turn_player := rl.RED
		@(static) won := false
		delta = rl.GetFrameTime()
		game_time = rl.GetTime()

		mouse_pos := cast([2]i32)[2]f32{virtual_screen_mouse_pos()}
		left_click := rl.IsMouseButtonPressed(.LEFT)
		reload := rl.IsKeyPressed(.R)


		// game state
		@(static) grid: [GAME_GRID_SIZE.x * GAME_GRID_SIZE.y]struct {
			cap:   i32,
			owner: rl.Color,
		}
		@(static) limit: [GAME_GRID_SIZE.x * GAME_GRID_SIZE.y]i32

		if reload {
			// reset turn count
			curr_turn := persist_add(0)
			persist_add(-curr_turn)

			// reset board
			grid = {}

			// undo win
			won = false

			// reset to default first player
			turn_player = rl.RED
		}


		@(static) once := true
		if once do for cell, i in limit {
			i := i32(i)
			if left_i := i + 1; (left_i) / GAME_GRID_SIZE.x == (i) / GAME_GRID_SIZE.x && i < len(grid) {limit[i] += 1}
			if right_i := i - 1; right_i / GAME_GRID_SIZE.x == (i) / GAME_GRID_SIZE.x && i > 0 {limit[i] += 1}
			if down_i := i + GAME_GRID_SIZE.x; down_i < len(grid) {limit[i] += 1}
			if up_i := i - GAME_GRID_SIZE.x; up_i >= 0 {limit[i] += 1}
		}
		once = false

		// game logic
		if !won {
			// overflowing

			@(static) react_queue: [dynamic]i32
			@(static) react_done: int = 0

			red_count, blue_count: int
			if len(react_queue) == 0 do for cell, i in grid {
				i := i32(i)
				if cell.cap >= limit[i] {append(&react_queue, i)}
				if cell.owner == rl.RED {red_count += 1}
				if cell.owner == rl.BLUE {blue_count += 1}
			}
			if persist_add(0) > 1 {
				if red_count * blue_count == 0 {
					if red_count == 0 do turn_player = rl.BLUE
					if blue_count == 0 do turn_player = rl.RED
					won = true
				}
			}

			for i in react_queue {
				grid[i].cap -= limit[i]
				react_done += 1

				// grid spreading pattern:
				//   |i-y|
				//i-1| i |i+1
				//   |i+y|
				{
					new_reaction := false
					// if not spreading outside the bounds to the right

					if left_i := i + 1;
					   (left_i) / GAME_GRID_SIZE.x == (i) / GAME_GRID_SIZE.x && i < len(grid) {
						grid[left_i].cap += 1
						grid[left_i].owner = grid[i].owner

						this_reacted := grid[left_i].cap >= limit[left_i]
						if new_reaction {
							new_reaction = true
							append(&react_queue, left_i)
						}

					}

					if right_i := (i - 1);
					   right_i / GAME_GRID_SIZE.x == (i) / GAME_GRID_SIZE.x && i > 0 {
						grid[right_i].cap += 1
						grid[right_i].owner = grid[i].owner

						this_reacted := grid[right_i].cap >= limit[right_i]
						if new_reaction {
							new_reaction = true
							append(&react_queue, right_i)
						}
					}

					if down_i := (i + GAME_GRID_SIZE.x); down_i < len(grid) {
						grid[down_i].cap += 1
						grid[down_i].owner = grid[i].owner

						this_reacted := grid[down_i].cap >= limit[down_i]
						if new_reaction {
							new_reaction = true
							append(&react_queue, down_i)
						}
					}

					if up_i := (i - GAME_GRID_SIZE.x); up_i >= 0 {
						grid[up_i].cap += 1
						grid[up_i].owner = grid[i].owner

						this_reacted := grid[up_i].cap >= limit[up_i]
						if new_reaction {
							new_reaction = true
							append(&react_queue, up_i)
						}
					}

					if new_reaction {break}
				}
			}

			if len(react_queue) == react_done && len(react_queue) > 0 {
				clear(&react_queue)
				react_done = 0
			} else if left_click {
				// clicking
				grid_pos := (mouse_pos - GAME_BOARD_OFFSET) / CELL_SIZE
				arr_pos := grid_pos.x + grid_pos.y * GAME_GRID_SIZE.x

				if mouse_pos.x >= GAME_BOARD_OFFSET.x &&
				   mouse_pos.y >= GAME_BOARD_OFFSET.y &&
				   mouse_pos.x <= (GAME_BOARD_OFFSET + GAME_BOARD_SIZE).x &&
				   mouse_pos.y <= (GAME_BOARD_OFFSET + GAME_BOARD_SIZE).y {

					// validate legal click
					if grid[arr_pos].cap == 0 || grid[arr_pos].owner == turn_player {
						grid[arr_pos].cap += 1
						grid[arr_pos].owner = turn_player
						turn_player = rl.RED if turn_player == rl.BLUE else rl.BLUE
						turn := persist_add(1)
					} else {
						// ilegal click
						fmt.println("illegal clock")
					}

				} else {
					fmt.println("Mouse outside board")
				}
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
							yoff + GAME_BOARD_SIZE.y,
							rl.WHITE,
						)

					}
					for y in 1 ..< GAME_GRID_SIZE.y {
						rl.DrawLine(
							xoff,
							yoff + CELL_SIZE * y,
							xoff + GAME_BOARD_SIZE.x,
							yoff + CELL_SIZE * y,
							rl.WHITE,
						)
					}
				}

				// x : time in seconds
				// period: duration of a full oscilation
				// shift: offset of the oscilation in seconds
				// amp: amplitude of a full oscilation
				oscilate :: #force_inline proc(x, period, shift, amp: f64) -> f64 {
					return math.sin_f64((x + shift) * 2.0 * math.PI / period) * amp
				}

				// draw pieces
				draw_piece :: proc(pos: i32, size: i32, color: rl.Color) {
					grid_pos := [2]i32{pos % GAME_GRID_SIZE.x, pos / GAME_GRID_SIZE.x}
					color := color
					square_pos := grid_pos * CELL_SIZE + GAME_BOARD_OFFSET

					if size == limit[pos] - 1 {
						color = rl.ColorContrast(color, 1)
						wobble := oscilate(
							game_time,
							0.5,
							f64(grid_pos.x + grid_pos.y * 2) / 10,
							2,
						)

						square_pos.x += cast(i32)wobble
					}
					center := cast([2]f32)square_pos + CELL_SIZE / 2
					layer_height: f32 : CELL_SIZE / 8
					piece_height := layer_height * f32(size)
					base_y := center.y + piece_height / 2


					for i in 0 ..< size {
						brightness := (f32(i) - f32(size - 1) / 2) * 0.1
						layer_color := rl.ColorBrightness(color, brightness)

						draw_cylinder_piece(
							center.x,
							base_y - f32(i) * layer_height,
							CELL_SIZE / 2,
							CELL_SIZE / 4,
							layer_height,
							layer_color,
						)
					}
				}

				for piece, pos in grid {
					pos := i32(pos)
					if piece.cap != 0 {
						draw_piece(pos, piece.cap, piece.owner)
					}
				}


				rl.DrawText("Turn player", 0, 0, 40, turn_player)
				if won do rl.DrawText("Won", 0, 100, 40, turn_player)
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
