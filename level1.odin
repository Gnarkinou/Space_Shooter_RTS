package main

import "core:fmt"
import sdl "vendor:sdl3"

init_level1 :: proc(state: ^Game_State) {
	ennemy_ship_test := new(Ennemy_ship)
	ennemy_ship_test.name = "The basic one"
	ennemy_ship_test.coordinates = {SCREEN_WIDTH / 2, -200.0}
	ennemy_ship_test.velocity = {0, 20}
	ennemy_ship_test.max_speed = 30
	ennemy_ship_test.acceleration = 1
	ennemy_ship_test.life = 10
	ennemy_ship_test.max_life = 10
	ennemy_ship_test.shield = 0
	ennemy_ship_test.alive = true
	ennemy_ship_test.width = 20
	ennemy_ship_test.height = 50

	basic_weapon := Weapon {
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
		firing           = true,
		coordinates      = &ennemy_ship_test.coordinates,
		follow_target    = false,
	}

	ennemy_ship_test.primary_weapon = basic_weapon
	append(&list_ennemy_ships, ennemy_ship_test)
}

update_level1 :: proc(state: ^Game_State, dt: f32) {
	for ennemy in list_ennemy_ships {
		if ennemy.primary_weapon.firing && ennemy.primary_weapon.waiting_time <= 0 {
			p := new(Projectile)
			p.name = ennemy.primary_weapon.name
			p.speed = ennemy.primary_weapon.speed
			p.acceleration = ennemy.primary_weapon.acceleration
			p.alive = true
			p.life = 10
			p.dmg = 20
			p.size = ennemy.primary_weapon.size_projectiles
			if p.follow_target do p.target = ennemy.primary_weapon.target^
			else do p.target = ennemy.coordinates[0] + f32(ennemy.width) / 2
			p.coordinates = {
				ennemy.primary_weapon.coordinates[0] + f32(ennemy.width) / 2,
				ennemy.primary_weapon.coordinates[1],
			}
			ennemy.primary_weapon.waiting_time = ennemy.primary_weapon.fire_rate
			append(&list_ennemy_projectiles, p)
		}
		ennemy.coordinates[0] += f32(ennemy.velocity[0]) * dt
		ennemy.coordinates[1] += f32(ennemy.velocity[1]) * dt
	}

	for i := 0; i < len(list_ennemy_projectiles); {
		proj := list_ennemy_projectiles[i]
		if !proj.alive {
			free(proj)
			unordered_remove(&list_ennemy_projectiles, i)
			continue
		}
		if !proj.follow_target do proj.coordinates[0] += 0
		else {
			// Logic à implémenter pour le suivit de la cible
			// Peut etre intéresant d'avoir la target comme un pointer
			// On récupère ses coordonnées à chaque frame et on se déplace d'un delta en sa direction sur l'axe x
			// Qque chose comme ça:
			//projectile.coordinates[0]=(projectile.coordinates[0] - projectile.target[0]) * delta_déplacement
		}
		proj.coordinates[1] += proj.speed * dt
		proj.speed = proj.speed * proj.acceleration
		if proj.coordinates[1] > SCREEN_HEIGHT + 50 {
			free(proj)
			unordered_remove(&list_ennemy_projectiles, i)
		} else {
			i += 1
		}
	}
}

render_level1 :: proc(state: ^Game_State) {
	sdl.SetRenderDrawColorFloat(state.render, 1.0, 1.0, 0.0, 1.0)
	for proj in list_ennemy_projectiles {
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
