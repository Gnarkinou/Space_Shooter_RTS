package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import sdl "vendor:sdl3"

list_projectiles: [dynamic]^Projectile
list_ennemy_ships: [dynamic]^Ennemy_ship

World :: struct {
	break_velocity: f32,
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
	life:                                 int,
	dmg_type:                             string,
	dmg:                                  int,
	number_canons:                        int,
	fire_rate, waiting_time, number_ammo: int,
	target_follow_delta:                  int,
	size_projectiles:                     [2]f32,
	follow_target:                        bool,
	firing:                               bool,
}

Projectile :: struct {
	name:                       string,
	velocity:                   [2]f32,
	speed:                      int,
	acceleration:               f32,
	max_speed:                  f32,
	alive:                      bool,
	life:                       int,
	dmg:                        ^int,
	dmg_type:                   ^string,
	size:                       [2]f32,
	coordinates:                [2]f32,
	target_ship_id:             int,
	target_follow_delta:        ^int,
	follow_target, target_lost: bool,
	player_friendly:            bool,
}

Ennemy_ship :: struct {
	id:                                                   int,
	name:                                                 string,
	coordinates:                                          [2]f32,
	velocity:                                             [2]int,
	max_speed:                                            [2]int, // This is necessary for the special moves
	acceleration:                                         int,
	life:                                                 int,
	max_life:                                             int,
	shield, max_shield, reload_shield, max_reload_shield: int,
	pattern:                                              string,
	alive:                                                bool,
	primary_weapon, secondary_weapon:                     Weapon,
	size:                                                 [2]int,
}

/*
BLOCS FONCTIONS -- gestion de la physique pour touts niveaux
   */

render_projectiles :: proc(state: ^Game_State) {
	for proj in list_projectiles {
		if !proj.alive do continue
		proj_rect := sdl.FRect {
			x = proj.coordinates[0] - (proj.size[0] / 2.0),
			y = proj.coordinates[1] - (proj.size[1] / 2.0),
			w = proj.size[0],
			h = proj.size[1],
		}

		if !proj.follow_target {
			sdl.SetRenderDrawColorFloat(state.render, 1.0, 1.0, 0.0, 1.0)
			sdl.RenderFillRect(state.render, &proj_rect)
		} else {
			angle_radians := math.atan2(proj.velocity[1], proj.velocity[0])
			angle_radians += (math.PI / 2.0)
			cos_a := math.cos(angle_radians)
			sin_a := math.sin(angle_radians)
			half_w := proj.size[0] / 2.0
			half_h := proj.size[1] / 2.0

			local_vertices := [4][2]f32 {
				{-half_w, -half_h}, // Top-Left
				{half_w, -half_h}, // Top-Right
				{half_w, half_h}, // Bottom-Right
				{-half_w, half_h}, // Bottom-Left
			}
			vertices := [4]sdl.Vertex{}
			color := sdl.FColor{1.0, 0.0, 0.0, 1.0}

			for i in 0 ..< 4 {
				lx := local_vertices[i][0]
				ly := local_vertices[i][1]
				rx := lx * cos_a - ly * sin_a
				ry := lx * sin_a + ly * cos_a
				v := sdl.Vertex{}
				v.color = color
				v.position.x = proj.coordinates[0] + rx
				v.position.y = proj.coordinates[1] + ry
				vertices[i] = v
			}
			indices := [6]i32{0, 1, 2, 0, 2, 3}
			sdl.RenderGeometry(state.render, nil, &vertices[0], 4, &indices[0], 6)
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
	cleanup_list()
	for ennemy in list_ennemy_ships {
		if ennemy.life <= 0 do ennemy.alive = false
		if state.player.life <= 0 do state.player.alive = false
		if !state.pause && sdl.GetTicks() % 1000 < 16 do update_enemy_status(ennemy)
		switch ennemy.pattern {
		case "swipe":
			if ennemy.coordinates[0] <= 0 ||
			   ennemy.coordinates[0] + f32(ennemy.size[0]) >= SCREEN_WIDTH {
				ennemy.velocity[0] = -ennemy.velocity[0]
			}
		case "dance":
			if ennemy.coordinates[0] <= 6 * f32(ennemy.size[0]) {
				ennemy.velocity[0] += ennemy.max_speed[0] / 8
				ennemy.velocity[1] += ennemy.max_speed[1] / 2
			} else if ennemy.coordinates[0] >= SCREEN_WIDTH - f32(ennemy.size[0]) {
				ennemy.velocity[0] -= ennemy.max_speed[0] / 8
				ennemy.velocity[1] += ennemy.max_speed[1] / 2
			} else if ennemy.velocity[1] <= 0 {
				ennemy.velocity[1] = 0
			} else {
				ennemy.velocity[1] -= ennemy.max_speed[1] / 100
			}
			if ennemy.velocity[0] >= ennemy.max_speed[0] do ennemy.velocity[0] = ennemy.max_speed[0]
			if ennemy.velocity[0] <= -ennemy.max_speed[0] do ennemy.velocity[0] = -ennemy.max_speed[0]
			if ennemy.velocity[1] >= ennemy.max_speed[1] do ennemy.velocity[1] = ennemy.max_speed[1]
			if ennemy.velocity[1] <= -ennemy.max_speed[1] do ennemy.velocity[1] = -ennemy.max_speed[1]
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
			p.life = ennemy.primary_weapon.life
			p.dmg = &ennemy.primary_weapon.dmg
			p.size = ennemy.primary_weapon.size_projectiles
			p.follow_target = ennemy.primary_weapon.follow_target
			p.player_friendly = false
			p.coordinates = {
				ennemy.coordinates[0] +
				f32(ennemy.size[0]) / f32(ennemy.primary_weapon.number_canons + 1),
				ennemy.coordinates[1] + f32(ennemy.size[1]),
			}
			ennemy.primary_weapon.waiting_time = ennemy.primary_weapon.fire_rate
			append(&list_projectiles, p)
		}

		ennemy.coordinates[0] += f32(ennemy.velocity[0]) * dt
		ennemy.coordinates[1] += f32(ennemy.velocity[1]) * dt
		ennemy.primary_weapon.waiting_time -= 1
	}
	update_level1(state)
}

update_player_status :: proc(state: ^Game_State) {
	if state.player.max_shield == 0 do return
	if state.player.shield < state.player.max_shield && state.player.reload_shield <= 0 {
		state.player.shield += 1
		state.player.reload_shield = state.player.max_reload_shield
		fmt.println("Shield regenerated to:", state.player.shield)
	} else if state.player.reload_shield > 0 do state.player.reload_shield -= 1
}

update_enemy_status :: proc(enemy: ^Ennemy_ship) {
	if enemy.max_shield == 0 do return
	if enemy.shield < enemy.max_shield && enemy.reload_shield <= 0 {
		enemy.shield += 1
		enemy.reload_shield = enemy.max_reload_shield
		fmt.println("Enemy shield reloaded to: ", enemy.shield)
	} else if enemy.reload_shield > 0 do enemy.reload_shield -= 1
}

update_projectiles :: proc(state: ^Game_State, dt: f32) {
	for i := 0; i < len(list_projectiles); i += 1 {
		projectile := list_projectiles[i]
		if projectile.coordinates[1] < -100 || projectile.coordinates[1] > SCREEN_HEIGHT + 100 {
			projectile.life = 0
			projectile.alive = false
		} else if projectile.coordinates[0] > SCREEN_WIDTH + 50 ||
		   projectile.coordinates[0] < -50 {
			projectile.life = 0
			projectile.alive = false
		}

		if projectile.life <= 0 do projectile.alive = false
		if projectile.follow_target {
			if projectile.target_lost && len(list_ennemy_ships) > 0 && projectile.player_friendly {
				fmt.println("Finding new target")
				aim_shortest_target(projectile)
				projectile_deplacements(projectile, state)
			} else if projectile.target_lost {
				if projectile.velocity[1] == 0 do projectile.velocity[1] -= f32(projectile.speed)

			} else {
				projectile_deplacements(projectile, state)
			}
		} else if projectile.player_friendly {
			projectile.velocity[0] = 0
			projectile.velocity[1] = -f32(projectile.speed)
		} else {
			projectile.velocity[0] = 0
			projectile.velocity[1] = f32(projectile.speed)
		}
		projectile.coordinates += projectile.velocity * dt
		projectile.velocity *= state.world.break_velocity * dt

		if !projectile.player_friendly && projectile.alive && projectile.life > 0 {
			x_overlap :=
				projectile.coordinates[0] < state.player.coord[0] + state.player.size[0] &&
				projectile.coordinates[0] + projectile.size[0] > state.player.coord[0]
			y_overlap :=
				projectile.coordinates[1] < state.player.coord[1] + state.player.size[1] &&
				projectile.coordinates[1] + projectile.size[1] > state.player.coord[1]
			if x_overlap && y_overlap {
				if state.player.shield <= 0 do state.player.life -= projectile.dmg^
				else do state.player.shield -= projectile.dmg^
				projectile.life = 0
				fmt.println("enemy_projectile-player collision detected !!!")
			}
		}

		for j := i + 1; j < len(list_projectiles); j += 1 {
			other_projectile := list_projectiles[j]
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
		}

		for enemy_ship in list_ennemy_ships {
			if !enemy_ship.alive || enemy_ship.life <= 0 do continue
			if projectile.player_friendly {
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
			}
			x_overlap :=
				enemy_ship.coordinates[0] < state.player.coord[0] + state.player.size[0] &&
				enemy_ship.coordinates[0] + f32(enemy_ship.size[0]) > state.player.coord[0]
			y_overlap :=
				enemy_ship.coordinates[1] < state.player.coord[1] + state.player.size[1] &&
				enemy_ship.coordinates[1] + f32(enemy_ship.size[1]) > state.player.coord[1]
			if x_overlap && y_overlap {
				enemy_ship.life = 0
				if state.player.shield >= 0 do state.player.shield -= 1
				else do state.player.life -= 1
				fmt.println("ship-ennemy ship collision detected !!!")
			}
		}
	}

	if state.player.primary_weapon.waiting_time > 0 do state.player.primary_weapon.waiting_time -= 1
	else do state.player.primary_weapon.waiting_time = 0

	if state.player.alive &&
	   state.player.primary_weapon.firing &&
	   state.player.primary_weapon.waiting_time <= 0 {
		for i := 0; i < state.player.primary_weapon.number_canons; i += 1 {
			fmt.println("fire !")
			p := new(Projectile)
			p.name = state.player.primary_weapon.name
			p.velocity[1] = -state.player.primary_weapon.speed
			p.velocity[0] = state.player.primary_weapon.speed
			p.speed = int(state.player.primary_weapon.speed)
			p.acceleration = state.player.primary_weapon.acceleration
			p.life = state.player.primary_weapon.life
			p.alive = true
			p.dmg = &state.player.primary_weapon.dmg
			p.size = state.player.primary_weapon.size_projectiles
			p.follow_target = state.player.primary_weapon.follow_target
			p.player_friendly = true
			if state.player.primary_weapon.number_canons == 1 {
				p.coordinates = {
					state.player.coord[0] + (state.player.size[0] / 2.0),
					state.player.coord[1],
				}
			} else {
				p.coordinates = {
					state.player.coord[0] +
					f32(i) *
						(state.player.size[0] /
								(f32(state.player.primary_weapon.number_canons - 1))),
					state.player.coord[1],
				}

			}
			append(&list_projectiles, p)
		}
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
		p.max_speed = state.player.secondary_weapon.max_speed
		p.size = state.player.secondary_weapon.size_projectiles
		p.player_friendly = true
		p.coordinates = {state.player.coord[0] + state.player.size[0] / 2, state.player.coord[1]}
		p.target_follow_delta = &state.player.secondary_weapon.target_follow_delta
		p.target_lost = true
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

cleanup_list :: proc() {
	for i := len(list_projectiles) - 1; i >= 0; i -= 1 {
		projectile := list_projectiles[i]
		if !projectile.alive {
			free(projectile)
			unordered_remove(&list_projectiles, i)
			continue
		}
		if projectile.coordinates[1] < -100 || projectile.coordinates[1] > SCREEN_HEIGHT + 100 {
			free(projectile)
			unordered_remove(&list_projectiles, i)
		} else if projectile.coordinates[0] > SCREEN_WIDTH + 50 ||
		   projectile.coordinates[0] < -50 {
			free(projectile)
			unordered_remove(&list_projectiles, i)
		}
	}
	for i := 0; i < len(list_ennemy_ships); i += 1 {
		ennemy := list_ennemy_ships[i]
		if !ennemy.alive || ennemy.coordinates[1] > SCREEN_HEIGHT + 100 {
			fmt.println("Ennemy", ennemy.name, "destroyed !!!")
			free(ennemy)
			unordered_remove(&list_ennemy_ships, i)
			continue
		}
	}
}

aim_shortest_target :: proc(p: ^Projectile) {
	fmt.println("Acquiring closest target !")
	min_dist_sq: f32 = math.F64_MAX
	for enemy in list_ennemy_ships {
		if enemy.coordinates[0] < 0 || enemy.coordinates[0] > f32(SCREEN_WIDTH + enemy.size[0]) do continue
		if enemy.coordinates[1] < -f32(enemy.size[1]) || enemy.coordinates[1] > f32(SCREEN_HEIGHT) do continue

		dx := enemy.coordinates[0] - p.coordinates[0]
		dy := enemy.coordinates[1] - p.coordinates[1]
		dist_sq := dx * dx + dy * dy
		if dist_sq < min_dist_sq {
			min_dist_sq = dist_sq
			p.target_ship_id = enemy.id
			p.target_lost = false
		}
	}
}

projectile_deplacements :: proc(p: ^Projectile, state: ^Game_State) {
	if !p.follow_target do return
	if p.target_follow_delta == nil {
		fmt.println("Error initializing target_follow_delta for the projectile")
		return
	}

	target_vector: [2]f32
	buffer: f32 = 6.0

	if p.player_friendly {
		target_ship: ^Ennemy_ship = nil
		for i := 0; i < len(list_ennemy_ships); i += 1 {
			if list_ennemy_ships[i].id == p.target_ship_id {
				target_ship = list_ennemy_ships[i]
				break
			}
		}

		if target_ship == nil || !target_ship.alive || target_ship.life < 0 {
			p.target_lost = true
			fmt.println("target lost !")
			return
		}

		target_vector = target_ship.coordinates - p.coordinates

	} else {
		target_vector = state.player.coord - p.coordinates
	}
	dist := linalg.length(target_vector)
	if dist < 1.0 do return
	dir := linalg.normalize(target_vector)
	perfect_velocity := dir * f32(p.speed)
	p.velocity = linalg.lerp(p.velocity, perfect_velocity, f32(p.target_follow_delta^))

	if p.velocity[0] > p.max_speed do p.velocity[0] = p.max_speed
	if p.velocity[0] < -p.max_speed do p.velocity[0] = -p.max_speed
	if p.velocity[1] > p.max_speed do p.velocity[1] = p.max_speed
	if p.velocity[1] < -p.max_speed do p.velocity[1] = -p.max_speed
}
