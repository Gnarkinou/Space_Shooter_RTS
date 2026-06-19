package main

import "core:fmt"
import sdl "vendor:sdl3"

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 1024

Game_State :: struct {
	window:         ^sdl.Window,
	render:         ^sdl.Renderer,
	running, pause: bool,
	map_level:      int,
	player:         Player,
	world:          World,
}

main :: proc() {
	if !sdl.Init({.VIDEO}) {
		fmt.println("SDL Init failed")
		return
	}
	defer sdl.Quit()

	game_state := Game_State {
		map_level = 1,
		running   = true,
		pause     = false,
	}

	game_state.player = Player {
		coord           = {500.0, 500.0},
		size            = {30.0, 50.0},
		velocity        = {0.0, 0.0},
		max_speed       = 700.0,
		increment_speed = 250.0,
		life            = 10,
		max_life        = 10,
		shield          = 1,
		max_shield      = 1,
		reload_shield   = 20,
		alive           = true,
	}

	game_state.player.primary_weapon = Weapon {
		name             = "small_laser",
		speed            = 400,
		acceleration     = 1.0,
		alive            = true,
		dmg_type         = "laser",
		dmg              = 1,
		fire_rate        = 50,
		//size             = {10, 20},
		size_projectiles = {5, 10},
		waiting_time     = 0,
		firing           = true,
		coordinates      = &game_state.player.coord,
		follow_target    = false,
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
	init_level1(&game_state)

	for game_state.running {
		current_time := sdl.GetTicks()
		dt := f32(current_time - last_time) / 1000.0
		last_time = current_time
		handle_events(&game_state)
		update(&game_state, dt)
		render(&game_state, dt)
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
	} else if state.player.coord[0] > f32(SCREEN_WIDTH) - state.player.size[0] {
		player_in_screen = false
		state.player.coord[0] = f32(SCREEN_WIDTH) - state.player.size[0]
		if state.player.velocity[0] > 0.0 do state.player.velocity[0] -= 2 * state.player.increment_speed
	}

	if state.player.coord[1] < 0.0 {
		player_in_screen = false
		if state.player.velocity[1] < 0.0 do state.player.velocity[1] += 2 * state.player.increment_speed
	} else if state.player.coord[1] > f32(SCREEN_HEIGHT) - state.player.size[1] {
		player_in_screen = false
		state.player.coord[1] = f32(SCREEN_HEIGHT) - state.player.size[1]
		if state.player.velocity[1] > 0.0 do state.player.velocity[1] -= 2 * state.player.increment_speed
	}

	if player_in_screen {
		if state.player.velocity[0] > 0.0 do state.player.velocity[0] -= state.world.break_velocity[0]
		else if state.player.velocity[0] < 0.0 do state.player.velocity[0] += state.world.break_velocity[0]

		if state.player.velocity[1] > 0.0 do state.player.velocity[1] -= state.world.break_velocity[1]
		else if state.player.velocity[1] < 0.0 do state.player.velocity[1] += state.world.break_velocity[1]
	}
	if !state.pause && sdl.GetTicks() % 1000 < 16 do update_player_status(state, dt)
	update_player_projectiles(state, dt)
	update_level(state, dt)
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

render :: proc(state: ^Game_State, dt: f32) {
	sdl.SetRenderDrawColorFloat(state.render, 0.05, 0.05, 0.08, 1.0)
	sdl.RenderClear(state.render)
	render_player(state)
	sdl.SetRenderDrawColorFloat(state.render, 1.0, 1.0, 0.0, 1.0)
	render_player_projectiles(state)
	sdl.SetRenderDrawColorFloat(state.render, 1.0, 0.8, 1.0, 1.0)
	render_ennemy_ships(state, dt)
	render_level(state)
	sdl.RenderPresent(state.render)
}
