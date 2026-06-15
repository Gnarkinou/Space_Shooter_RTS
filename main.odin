package main

import "core:fmt"
import sdl "vendor:sdl3"

PLAYER_SIZE_WIDTH :: 30.0
PLAYER_SIZE_HEIGHT :: 50.0
SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 1024

Game_State :: struct {
	window:    ^sdl.Window,
	render:    ^sdl.Renderer,
	running:   bool,
	map_level: int,
	player:    Player,
	world:     World,
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
	}

	game_state.player = Player {
		coord           = {500.0, 500.0},
		velocity        = {0.0, 0.0},
		max_speed       = 700.0,
		increment_speed = 250.0,
		life            = 10,
		max_life        = 10,
		shield          = 1,
		alive           = true,
	}

	game_state.player.primary_weapon = Weapon {
		name             = "small_laser",
		speed            = 400,
		acceleration     = 1.0,
		alive            = true,
		dmg_type         = "laser",
		dmg              = 10,
		fire_rate        = 50,
		size             = {10, 20},
		size_projectiles = {5, 10},
		waiting_time     = 0,
		//auto_fire        = true, //Yeah I could remove this one and play only with the firing
		firing           = true,
		coordinates      = &game_state.player.coord,
		//target           = &game_state.player.coord,
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
		update_level1(&game_state, dt)
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

	for ennemy in list_ennemy_ships {
		ennemy.coordinates[1] += f32(ennemy.velocity[1]) * dt
		ennemy.coordinates[0] += f32(ennemy.velocity[0]) * dt
	}

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

	for i := 0; i < len(list_player_projectiles);  /**/{
		projectile := list_player_projectiles[i]
		if !projectile.alive {
			free(projectile)
			unordered_remove(&list_player_projectiles, i)
			continue
		}
		if !projectile.follow_target do projectile.coordinates[0] += 0
		else {
			// Logic à implémenter pour le suivit de la cible
			// Peut etre intéresant d'avoir la target comme un pointer
			// On récupère ses coordonnées à chaque frame et on se déplace d'un delta en sa direction sur l'axe x
			// Qque chose comme ça:
			//projectile.coordinates[0]=(projectile.coordinates[0] - projectile.target[0]) * delta_déplacement
		}
		projectile.coordinates[1] -= projectile.speed * dt
		projectile.speed = projectile.speed * projectile.acceleration
		if projectile.coordinates[1] < -100 {
			//projectile.alive = false // probable not necessary
			free(projectile)
			unordered_remove(&list_player_projectiles, i)
		} else {
			i += 1
		}
	}

	state.player.primary_weapon.waiting_time -= 1

	if state.player.primary_weapon.firing && state.player.primary_weapon.waiting_time <= 0 {
		p := new(Projectile)
		p.name = state.player.primary_weapon.name
		p.speed = state.player.primary_weapon.speed
		p.acceleration = state.player.primary_weapon.acceleration
		p.alive = true
		p.life = 10
		p.dmg = 20
		p.size = state.player.primary_weapon.size_projectiles
		p.follow_target = state.player.primary_weapon.follow_target
		p.player_friendly = true
		if p.follow_target do p.target = state.player.primary_weapon.target^
		else do p.target = state.player.coord[0] + PLAYER_SIZE_WIDTH / 2
		p.coordinates = {
			state.player.primary_weapon.coordinates[0] + PLAYER_SIZE_WIDTH / 2,
			state.player.primary_weapon.coordinates[1],
		}
		append(&list_player_projectiles, p)
		state.player.primary_weapon.waiting_time = state.player.primary_weapon.fire_rate
	}
	update_level1(state, dt)
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

	sdl.SetRenderDrawColorFloat(state.render, 1.0, 1.0, 0.0, 1.0)
	for projectile in list_player_projectiles {
		if projectile.alive {
			projectile_rect := sdl.FRect {
				x = projectile.coordinates[0],
				y = projectile.coordinates[1],
				w = projectile.size[0],
				h = projectile.size[1],
			}
			sdl.RenderFillRect(state.render, &projectile_rect)
		}
	}

	sdl.SetRenderDrawColorFloat(state.render, 1.0, 0.8, 1.0, 1.0)
	for ennemy in list_ennemy_ships {
		if ennemy.alive {
			ennemy_rect := sdl.FRect {
				x = ennemy.coordinates[0],
				y = ennemy.coordinates[1],
				h = f32(ennemy.height),
				w = f32(ennemy.width),
			}
			fmt.println(ennemy_rect.h)
			sdl.SetRenderDrawColorFloat(state.render, 0.0, 0.8, 1.0, 1.0)
			sdl.RenderFillRect(state.render, &ennemy_rect)
		}
	}
	sdl.RenderPresent(state.render)
}
