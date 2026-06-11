package main

import "core:fmt"
import sdl "vendor:sdl3"

PLAYER_SIZE_WIDTH :: 30.0
PLAYER_SIZE_HEIGHT :: 50.0
SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 1024

Game_State :: struct {
	window:  ^sdl.Window,
	render:  ^sdl.Renderer,
	running: bool,
	player:  Player,
	world:   World,
}

World :: struct {
	break_velocity: [2]f32,
}

Player :: struct {
	coord:           [2]f32,
	velocity:        [2]f32,
	max_speed:       f32,
	increment_speed: f32,
	life:            int,
	max_life:        int,
	shield:          int,
	alive:           bool,
}

main :: proc() {
	if !sdl.Init({.VIDEO}) {
		fmt.println("SDL Init failed")
		return
	}
	defer sdl.Quit()

	game_state := Game_State{}
	game_state.running = true
	game_state.player = Player {
		coord           = {500.0, 500.0},
		velocity        = {0.0, 0.0},
		max_speed       = 600.0,
		increment_speed = 200.0,
		life            = 10,
		max_life        = 10,
		shield          = 1,
		alive           = true,
	}

	game_state.world = World {
		break_velocity = {5.0, 5.0},
	}

	game_state.window = sdl.CreateWindow("Odin Space Shooter", SCREEN_WIDTH, SCREEN_HEIGHT, {})

	if game_state.window == nil {
		fmt.println("Failed to create window", sdl.GetError())
		return
	}
	defer sdl.DestroyWindow(game_state.window)

	sdl.SetHint(sdl.HINT_RENDER_VSYNC, "1")
	game_state.render = sdl.CreateRenderer(game_state.window, nil)

	if game_state.render == nil {
		fmt.println("SDL render failed", sdl.GetError())
		return
	}
	defer sdl.DestroyRenderer(game_state.render)

	last_time := sdl.GetTicks()

	for game_state.running {
		current_time := sdl.GetTicks()
		dt := f32(current_time - last_time) / 1000.0
		last_time = current_time
		handle_events(&game_state)
		update(&game_state, dt)
		render(&game_state)
	}
}

update :: proc(state: ^Game_State, dt: f32) {
	if state.player.velocity[0] > state.player.max_speed do state.player.velocity[0] = state.player.max_speed
	else if state.player.velocity[0] < -state.player.max_speed do state.player.velocity[0] = -state.player.max_speed

	if state.player.velocity[1] > state.player.max_speed do state.player.velocity[1] = state.player.max_speed
	else if state.player.velocity[1] < -state.player.max_speed do state.player.velocity[1] = -state.player.max_speed

	state.player.coord[0] += state.player.velocity[0] * dt
	state.player.coord[1] += state.player.velocity[1] * dt

	player_in_screen: bool = true
	if state.player.coord[0] < 0.0 {
		player_in_screen = false
		if state.player.velocity[0] < 0.0 do state.player.velocity[0] += 2 * state.player.increment_speed
	} else if state.player.coord[0] > f32(SCREEN_WIDTH) - PLAYER_SIZE_WIDTH {
		player_in_screen = false
		state.player.coord[0] = f32(SCREEN_WIDTH) - PLAYER_SIZE_WIDTH
		if state.player.velocity[0] > 0.0 do state.player.velocity[0] -= 2 * state.player.increment_speed
	}

	if state.player.coord[1] < 0.0 {
		player_in_screen = false
		if state.player.velocity[1] < 0.0 do state.player.velocity[1] += 2 * state.player.increment_speed
	} else if state.player.coord[1] > f32(SCREEN_HEIGHT) - PLAYER_SIZE_HEIGHT {
		player_in_screen = false
		state.player.coord[1] = f32(SCREEN_HEIGHT) - PLAYER_SIZE_HEIGHT
		if state.player.velocity[1] > 0.0 do state.player.velocity[1] -= 2 * state.player.increment_speed
	}

	if player_in_screen {
		if state.player.velocity[0] > 0.0 do state.player.velocity[0] -= state.world.break_velocity[0]
		else if state.player.velocity[0] < 0.0 do state.player.velocity[0] += state.world.break_velocity[0]

		if state.player.velocity[1] > 0.0 do state.player.velocity[1] -= state.world.break_velocity[1]
		else if state.player.velocity[1] < 0.0 do state.player.velocity[1] += state.world.break_velocity[1]
	}
}

handle_events :: proc(state: ^Game_State) {
	event: sdl.Event
	for sdl.PollEvent(&event) {
		#partial switch event.type {
		case .QUIT:
			state.running = false
		case .KEY_DOWN:
			if event.key.scancode == .ESCAPE {
				state.running = false
			}
			if event.key.scancode == .UP {
				state.player.velocity[1] -= state.player.increment_speed
			}
			if event.key.scancode == .DOWN {
				state.player.velocity[1] += state.player.increment_speed
			}
			if event.key.scancode == .RIGHT {
				state.player.velocity[0] += state.player.increment_speed
			}
			if event.key.scancode == .LEFT {
				state.player.velocity[0] -= state.player.increment_speed
			}
		}
	}
}

render :: proc(state: ^Game_State) {
	sdl.SetRenderDrawColorFloat(state.render, 0.05, 0.05, 0.08, 1.0)
	sdl.RenderClear(state.render)

	if state.player.alive {
		player_rect := sdl.FRect {
			x = state.player.coord[0],
			y = state.player.coord[1],
			w = PLAYER_SIZE_WIDTH,
			h = PLAYER_SIZE_HEIGHT,
		}

		sdl.SetRenderDrawColorFloat(state.render, 0.0, 0.8, 1.0, 1.0)
		sdl.RenderFillRect(state.render, &player_rect)
	}

	sdl.RenderPresent(state.render)
}
