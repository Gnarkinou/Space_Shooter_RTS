package main

import "core:fmt"
import "core:math"
import sdl "vendor:sdl3"

list_projectiles: [dynamic]^Projectile
list_ennemy_ships: [dynamic]^Ennemy_ship

World :: struct {
	break_velocity: [2]f32,
}

Player :: struct {
	coord:                                                [2]f32,
	size:                                                 [2]f32,
	velocity:                                             [2]f32,
	max_speed:                                            f32,
	increment_speed:                                      f32,
	life, max_life:                                       int,
	shield, max_shield, reload_shield, max_reload_shield: int,
	alive:                                                bool,
	primary_weapon, secondary_weapon:                     Weapon,
}

Weapon :: struct {
	name:                                 string,
	speed:                                f32,
	max_speed:                            f32,
	acceleration:                         f32,
	alive:                                bool,
	life:                                 int,
	dmg_type:                             string,
	dmg:                                  int,
	fire_rate, waiting_time, number_ammo: int,
	target_follow_delta:                  int,
	size_projectiles:                     [2]f32,
	follow_target:                        bool,
	firing:                               bool,
}

Projectile :: struct {
	name:                string,
	velocity:            [2]f32,
	speed:               int,
	acceleration:        f32,
	max_speed:           f32,
	alive:               bool,
	life:                int,
	dmg:                 ^int,
	dmg_type:            ^string,
	size:                [2]f32,
	coordinates:         [2]f32,
	target:              ^[2]f32,
	target_alive:        ^bool,
	target_follow_delta: ^int,
	follow_target:       bool,
	player_friendly:     bool,
}

Ennemy_ship :: struct {
	name:                             string,
	coordinates:                      [2]f32,
	velocity:                         [2]int,
	max_speed:                        int,
	acceleration:                     int,
	life:                             int,
	max_life:                         int,
	shield:                           int,
	pattern:                          string,
	alive:                            bool,
	primary_weapon, secondary_weapon: Weapon,
	size:                             [2]int,
}

/*
BLOCS FONCTIONS -- gestion de la physique pour touts niveaux
   */

render_projectiles :: proc(state: ^Game_State) {
	sdl.SetRenderDrawColorFloat(state.render, 1.0, 1.0, 0.0, 1.0)
	for proj in list_projectiles {
		if proj.alive {
			proj_rect := sdl.FRect {
				x = proj.coordinates[0],
				y = proj.coordinates[1],
				w = proj.size[0],
				h = proj.size[1],
			}
			sdl.RenderFillRect(state.render, &proj_rect)
		}
	}
}

render_player :: proc(state: ^Game_State) {
	if state.player.alive {
		player_rect := sdl.FRect {
			x = state.player.coord[0],
			y = state.player.coord[1],
			w = state.player.size[0],
			h = state.player.size[1],
		}
		sdl.SetRenderDrawColorFloat(state.render, 0.0, 0.8, 1.0, 1.0)
		sdl.RenderFillRect(state.render, &player_rect)
	}
}

render_ennemy_ships :: proc(state: ^Game_State, dt: f32) {
	for ennemy in list_ennemy_ships {
		if ennemy.alive {
			ennemy_rect := sdl.FRect {
				x = ennemy.coordinates[0],
				y = ennemy.coordinates[1],
				h = f32(ennemy.size[1]),
				w = f32(ennemy.size[0]),
			}
			sdl.SetRenderDrawColorFloat(state.render, 0.0, 0.8, 1.0, 1.0)
			sdl.RenderFillRect(state.render, &ennemy_rect)
		}
	}
}

update_level :: proc(state: ^Game_State, dt: f32) {
	for i := 0; i < len(list_ennemy_ships); {
		ennemy := list_ennemy_ships[i]
		if ennemy.life <= 0 do ennemy.alive = false
		if state.player.life <= 0 do state.player.alive = false

		if !ennemy.alive || ennemy.coordinates[1] > SCREEN_HEIGHT + 100 {
			fmt.println("Ennemy", ennemy.name, "destroyed !!!")
			free(ennemy)
			unordered_remove(&list_ennemy_ships, i)
			continue
		}

		switch ennemy.pattern {
		case "swipe":
			if ennemy.coordinates[0] <= 0 ||
			   ennemy.coordinates[0] + f32(ennemy.size[0]) >= SCREEN_WIDTH {
				ennemy.velocity[0] = -ennemy.velocity[0]
			}
		}

		if ennemy.primary_weapon.firing &&
		   ennemy.primary_weapon.waiting_time <= 0 &&
		   ennemy.coordinates[1] >= 0 {
			p := new(Projectile)
			p.name = ennemy.primary_weapon.name
			p.speed = int(ennemy.primary_weapon.speed)
			p.velocity[0] = ennemy.primary_weapon.speed
			p.velocity[1] = ennemy.primary_weapon.speed
			p.speed = int(ennemy.primary_weapon.speed)
			p.acceleration = ennemy.primary_weapon.acceleration
			p.alive = true
			p.life = 1
			p.dmg = &ennemy.primary_weapon.dmg
			p.size = ennemy.primary_weapon.size_projectiles
			p.follow_target = ennemy.primary_weapon.follow_target
			p.player_friendly = false
			p.coordinates = {
				ennemy.coordinates[0] + f32(ennemy.size[0]) / 2,
				ennemy.coordinates[1] + f32(ennemy.size[1]),
			}
			ennemy.primary_weapon.waiting_time = ennemy.primary_weapon.fire_rate
			append(&list_projectiles, p)
		}

		ennemy.coordinates[0] += f32(ennemy.velocity[0]) * dt
		ennemy.coordinates[1] += f32(ennemy.velocity[1]) * dt
		ennemy.primary_weapon.waiting_time -= 1
		i += 1
	}
	update_level1(state)
}

update_player_status :: proc(state: ^Game_State, dt: f32) {
	if state.player.shield < state.player.max_shield && state.player.reload_shield <= 0 {
		state.player.shield += 1
		state.player.reload_shield = state.player.max_reload_shield
		fmt.println("Shield regenerated to:", state.player.shield)
	} else if state.player.reload_shield > 0 do state.player.reload_shield -= 1
}

update_projectiles :: proc(state: ^Game_State, dt: f32) {
	for i := 0; i < len(list_projectiles); {
		projectile := list_projectiles[i]
		if projectile.life <= 0 do projectile.alive = false
		if !projectile.alive {
			free(projectile)
			unordered_remove(&list_projectiles, i)
			continue
		}

		if projectile.follow_target {
			if !projectile.target_alive^ &&
			   len(list_ennemy_ships) > 0 &&
			   projectile.player_friendly {
				aim_shortest_target(projectile)
				projectile_deplacements(projectile, state)
			} else if !projectile.target_alive^ {
				if projectile.velocity[1] == 0 do projectile.velocity[1] -= f32(projectile.speed)

			} else {
				projectile_deplacements(projectile, state)
			}
		} else if projectile.player_friendly {
			projectile.velocity[0] = f32(projectile.speed)
			projectile.velocity[1] = -f32(projectile.speed)
		} else {
			projectile.velocity[0] = f32(projectile.speed)
			projectile.velocity[1] = f32(projectile.speed)
		}
		projectile.coordinates[0] += projectile.velocity[0] * dt
		projectile.coordinates[1] += projectile.velocity[1] * dt

		if projectile.velocity[0] > 0 {
			projectile.velocity[0] -= state.world.break_velocity[0]
		} else if projectile.velocity[0] < 0 {
			projectile.velocity[0] += state.world.break_velocity[0]
		}

		if projectile.velocity[1] > 0 {
			projectile.velocity[1] -= state.world.break_velocity[1]
		} else if projectile.velocity[1] < 0 {
			projectile.velocity[1] += state.world.break_velocity[1]
		}

		for other_projectile in list_projectiles {
			if other_projectile.player_friendly == projectile.player_friendly do continue
			if !other_projectile.alive || other_projectile.life <= 0 do continue
			x_overlap :=
				other_projectile.coordinates[0] < projectile.coordinates[0] + projectile.size[0] &&
				other_projectile.coordinates[0] + other_projectile.size[0] >
					projectile.coordinates[0]
			y_overlap :=
				other_projectile.coordinates[1] < projectile.coordinates[1] + projectile.size[1] &&
				other_projectile.coordinates[1] + other_projectile.size[1] >
					projectile.coordinates[1]
			if x_overlap && y_overlap {
				projectile.life -= other_projectile.dmg^
				other_projectile.life -= projectile.dmg^
				fmt.println("projectile-projectile collision detected !!!")
			}
			x_overlap =
				other_projectile.coordinates[0] < state.player.coord[0] + state.player.size[0] &&
				other_projectile.coordinates[0] + other_projectile.size[0] > state.player.coord[0]
			y_overlap =
				other_projectile.coordinates[1] < state.player.coord[1] + state.player.size[1] &&
				other_projectile.coordinates[1] + other_projectile.size[1] > state.player.coord[1]
			if x_overlap && y_overlap {
				if state.player.shield <= 0 do state.player.life -= other_projectile.dmg^
				else do state.player.shield -= other_projectile.dmg^
				other_projectile.life = 0
				fmt.println("enemy_projectile-player collision detected !!!")
				fmt.println("player life:", state.player.life)
				fmt.println("Shield strengh:", state.player.shield)
			}
		}

		for enemy_ship in list_ennemy_ships {
			if !enemy_ship.alive || enemy_ship.life <= 0 do continue
			x_overlap :=
				enemy_ship.coordinates[0] < projectile.coordinates[0] + projectile.size[0] &&
				enemy_ship.coordinates[0] + f32(enemy_ship.size[0]) > projectile.coordinates[0]
			y_overlap :=
				enemy_ship.coordinates[1] < projectile.coordinates[1] + projectile.size[1] &&
				enemy_ship.coordinates[1] + f32(enemy_ship.size[1]) > projectile.coordinates[1]
			if x_overlap && y_overlap {
				projectile.life = 0
				enemy_ship.life -= projectile.dmg^
				fmt.println("projectile-ennemy ship collision detected !!!")
			}
			x_overlap =
				enemy_ship.coordinates[0] < state.player.coord[0] + state.player.size[0] &&
				enemy_ship.coordinates[0] + f32(enemy_ship.size[0]) > state.player.coord[0]
			y_overlap =
				enemy_ship.coordinates[1] < state.player.coord[1] + state.player.size[1] &&
				enemy_ship.coordinates[1] + f32(enemy_ship.size[1]) > state.player.coord[1]
			if x_overlap && y_overlap {
				enemy_ship.life = 0
				if state.player.shield >= 0 do state.player.shield -= 1
				else do state.player.life -= 1
				fmt.println("ship-ennemy ship collision detected !!!")
			}
		}

		if projectile.coordinates[1] < -100 || projectile.coordinates[1] > SCREEN_HEIGHT + 100 {
			free(projectile)
			unordered_remove(&list_projectiles, i)
		} else if projectile.coordinates[0] > SCREEN_WIDTH + 50 ||
		   projectile.coordinates[0] < -50 {
			free(projectile)
			unordered_remove(&list_projectiles, i)
		} else {
			i += 1
		}
	}
	if state.player.primary_weapon.waiting_time > 0 do state.player.primary_weapon.waiting_time -= 1
	else do state.player.primary_weapon.waiting_time = 0

	if state.player.alive &&
	   state.player.primary_weapon.firing &&
	   state.player.primary_weapon.waiting_time <= 0 {
		p := new(Projectile)
		p.name = state.player.primary_weapon.name
		p.velocity[1] = state.player.primary_weapon.speed
		p.velocity[0] = state.player.primary_weapon.speed
		p.speed = int(state.player.primary_weapon.speed)
		p.acceleration = state.player.primary_weapon.acceleration
		p.alive = true
		p.life = state.player.primary_weapon.life
		p.dmg = &state.player.primary_weapon.dmg
		p.size = state.player.primary_weapon.size_projectiles
		p.follow_target = state.player.primary_weapon.follow_target
		p.player_friendly = true
		p.coordinates = {state.player.coord[0] + state.player.size[0] / 2, state.player.coord[1]}
		append(&list_projectiles, p)
		state.player.primary_weapon.waiting_time = state.player.primary_weapon.fire_rate
	}
	if state.player.secondary_weapon.waiting_time > 0 do state.player.secondary_weapon.waiting_time -= 1
	else do state.player.secondary_weapon.waiting_time = 0

	if state.player.alive &&
	   state.player.secondary_weapon.firing &&
	   state.player.secondary_weapon.waiting_time <= 0 &&
	   state.player.secondary_weapon.number_ammo > 0 {
		p := new(Projectile)
		p.name = state.player.secondary_weapon.name
		p.velocity[0] = state.player.secondary_weapon.speed
		p.velocity[1] = -state.player.secondary_weapon.speed
		p.speed = int(state.player.secondary_weapon.speed)
		p.acceleration = state.player.secondary_weapon.acceleration
		p.alive = true
		p.life = state.player.secondary_weapon.life
		p.dmg = &state.player.secondary_weapon.dmg
		p.size = state.player.secondary_weapon.size_projectiles
		p.player_friendly = true
		p.coordinates = {state.player.coord[0] + state.player.size[0] / 2, state.player.coord[1]}
		p.follow_target = state.player.secondary_weapon.follow_target
		if p.follow_target {
			aim_shortest_target(p)
		}
		append(&list_projectiles, p)
		state.player.secondary_weapon.waiting_time = state.player.secondary_weapon.fire_rate
		state.player.secondary_weapon.number_ammo -= 1
	}
	if state.player.secondary_weapon.firing do state.player.secondary_weapon.firing = false
}

aim_shortest_target :: proc(p: ^Projectile) {
	dist, dist_min: f32
	dist_min = 0
	for enemy in list_ennemy_ships {
		dx := enemy.coordinates[0] - p.coordinates[0]
		dy := enemy.coordinates[1] - p.coordinates[1]
		dist = math.sqrt(dx * dx + dy * dy)
		if dist_min == 0 || dist < dist_min {
			dist_min = dist
			p.target = &enemy.coordinates
			p.target_alive = &enemy.alive
		}
	}
}

projectile_deplacements :: proc(p: ^Projectile, state: ^Game_State) {
	if p.player_friendly {
		if p.coordinates[0] > p.target[0] && p.velocity[0] < -p.max_speed {
			p.velocity[0] -= f32(p.target_follow_delta^)
		} else if p.coordinates[0] < p.target[0] && p.velocity[0] < p.max_speed {
			p.velocity[0] += f32(p.target_follow_delta^)
		}

		if p.coordinates[1] < p.target[1] && p.velocity[1] < p.max_speed {
			p.velocity[1] += f32(p.target_follow_delta^)
		} else if p.coordinates[1] > p.target[1] && p.velocity[1] < -p.max_speed {
			p.velocity[1] -= f32(p.target_follow_delta^)
		}
		return
	}
	if p.coordinates[0] > state.player.coord[0] && p.velocity[0] < -p.max_speed {
		p.velocity[0] -= f32(p.target_follow_delta^)
	} else if p.coordinates[0] < state.player.coord[0] && p.velocity[1] < p.max_speed {
		p.velocity[0] += f32(p.target_follow_delta^)
	}
	if p.coordinates[1] < state.player.coord[1] && p.velocity[1] < p.max_speed {
		p.velocity[1] += f32(p.target_follow_delta^)
	} else if p.coordinates[1] > state.player.coord[1] && p.velocity[1] < -p.max_speed {
		p.velocity[1] -= f32(p.target_follow_delta^)
	}
}
