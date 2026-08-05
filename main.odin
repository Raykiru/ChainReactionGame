package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

window_width: i32 = 1280
window_height: i32 = 720

VIRTUAL_WIDTH :: 600
VIRTUAL_HEIGHT :: 600
TS_GRAY :: [4]u8{18, 18, 18, 255}

GRID_ARR_SIZE :: GAME_GRID_SIZE.x * GAME_GRID_SIZE.y

gamestate: struct {
	delta:       f32,
	game_time:   f64,
	turn_player: rl.Color,
	won:         bool,
	grid:        [GRID_ARR_SIZE]struct {
		cap:   i32,
		owner: rl.Color,
	},
	limit:       [GRID_ARR_SIZE]i32,
	react_queue: [dynamic]i32,
	react_done:  int,
}

main :: proc() {

	rl.InitWindow(window_width, window_height, "Chain Reaction")
	rl.SetWindowState({.WINDOW_RESIZABLE})

	rl.SetTargetFPS(60)


	virtual_screen_init(VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

	// initialisation
	for cell, i in gamestate.limit {
		i := i32(i)
		if left_i := i + 1;
		   (left_i) / GAME_GRID_SIZE.x == (i) / GAME_GRID_SIZE.x &&
		   i < len(gamestate.grid) {gamestate.limit[i] += 1}
		if right_i := i - 1;
		   right_i / GAME_GRID_SIZE.x == (i) / GAME_GRID_SIZE.x && i > 0 {gamestate.limit[i] += 1}
		if down_i := i + GAME_GRID_SIZE.x; down_i < len(gamestate.grid) {gamestate.limit[i] += 1}
		if up_i := i - GAME_GRID_SIZE.x; up_i >= 0 {gamestate.limit[i] += 1}
	}
	gamestate.turn_player = rl.RED
	gamestate.won = false


	for !rl.WindowShouldClose() {
		gamestate.delta = rl.GetFrameTime()
		gamestate.game_time = rl.GetTime()

		mouse_pos := cast([2]i32)[2]f32{virtual_screen_mouse_pos()}
		left_click := rl.IsMouseButtonPressed(.LEFT)
		if left_click do fmt.println("clicked")
		reload := rl.IsKeyPressed(.R)


		// game state

		if reload {
			// reset turn count
			curr_turn := persist_add(0)
			persist_add(-curr_turn)

			// reset board
			gamestate.grid = {}

			// undo win
			gamestate.won = false

			// reset to default first player
			gamestate.turn_player = rl.RED
		}


		// game logic
		if !gamestate.won {
			// overflowing


			red_count, blue_count: int
			if len(gamestate.react_queue) == 0 do for cell, i in gamestate.grid {
				i := i32(i)
				if cell.cap >= gamestate.limit[i] {append(&gamestate.react_queue, i)}
				if cell.owner == rl.RED {red_count += 1}
				if cell.owner == rl.BLUE {blue_count += 1}
			}
			if persist_add(0) > 1 {
				if red_count * blue_count == 0 {
					if red_count == 0 do gamestate.turn_player = rl.BLUE
					if blue_count == 0 do gamestate.turn_player = rl.RED
					gamestate.won = true
				}
			}

			for i in gamestate.react_queue {
				if gamestate.grid[i].cap < gamestate.limit[i] {panic("found the bug")}
				gamestate.grid[i].cap -= gamestate.limit[i]
				gamestate.react_done += 1

				// grid spreading pattern:
				//   |i-y|
				//i-1| i |i+1
				//   |i+y|
				{
					new_reaction := false
					// if not spreading outside the bounds to the right

					if left_i := i + 1;
					   (left_i) / GAME_GRID_SIZE.x == (i) / GAME_GRID_SIZE.x &&
					   i < len(gamestate.grid) {
						gamestate.grid[left_i].cap += 1
						gamestate.grid[left_i].owner = gamestate.grid[i].owner

						this_reacted := gamestate.grid[left_i].cap >= gamestate.limit[left_i]
						if new_reaction {
							new_reaction = true
							append(&gamestate.react_queue, left_i)
						}

					}

					if right_i := (i - 1);
					   right_i / GAME_GRID_SIZE.x == (i) / GAME_GRID_SIZE.x && i > 0 {
						gamestate.grid[right_i].cap += 1
						gamestate.grid[right_i].owner = gamestate.grid[i].owner

						this_reacted := gamestate.grid[right_i].cap >= gamestate.limit[right_i]
						if new_reaction {
							new_reaction = true
							append(&gamestate.react_queue, right_i)
						}
					}

					if down_i := (i + GAME_GRID_SIZE.x); down_i < len(gamestate.grid) {
						gamestate.grid[down_i].cap += 1
						gamestate.grid[down_i].owner = gamestate.grid[i].owner

						this_reacted := gamestate.grid[down_i].cap >= gamestate.limit[down_i]
						if new_reaction {
							new_reaction = true
							append(&gamestate.react_queue, down_i)
						}
					}

					if up_i := (i - GAME_GRID_SIZE.x); up_i >= 0 {
						gamestate.grid[up_i].cap += 1
						gamestate.grid[up_i].owner = gamestate.grid[i].owner

						this_reacted := gamestate.grid[up_i].cap >= gamestate.limit[up_i]
						if new_reaction {
							new_reaction = true
							append(&gamestate.react_queue, up_i)
						}
					}

					if new_reaction {break}
				}
			}

			if len(gamestate.react_queue) == gamestate.react_done &&
			   len(gamestate.react_queue) > 0 {
				clear(&gamestate.react_queue)
				gamestate.react_done = 0
			} else if left_click {
				// clicking
				grid_pos := (mouse_pos - GAME_BOARD_OFFSET) / CELL_SIZE
				arr_pos := grid_pos.x + grid_pos.y * GAME_GRID_SIZE.x

				if mouse_pos.x >= GAME_BOARD_OFFSET.x &&
				   mouse_pos.y >= GAME_BOARD_OFFSET.y &&
				   mouse_pos.x <= (GAME_BOARD_OFFSET + GAME_BOARD_SIZE).x &&
				   mouse_pos.y <= (GAME_BOARD_OFFSET + GAME_BOARD_SIZE).y {

					// validate legal click
					if gamestate.grid[arr_pos].cap == 0 ||
					   gamestate.grid[arr_pos].owner == gamestate.turn_player {
						gamestate.grid[arr_pos].cap += 1
						gamestate.grid[arr_pos].owner = gamestate.turn_player
						gamestate.turn_player =
							rl.RED if gamestate.turn_player == rl.BLUE else rl.BLUE
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

					if size == gamestate.limit[pos] - 1 {
						color = rl.ColorContrast(color, 1)
						wobble := oscilate(
							gamestate.game_time,
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

				for piece, pos in gamestate.grid {
					pos := i32(pos)
					if piece.cap != 0 {
						draw_piece(pos, piece.cap, piece.owner)
					}
				}


				rl.DrawText("Turn player", 0, 0, 40, gamestate.turn_player)
				if gamestate.won do rl.DrawText("Won", 0, 100, 40, gamestate.turn_player)
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
