package main

import "core:fmt"
import sdl "vendor:sdl3"

//init_time := sdl.GetTicks()
wave_number: int = 0
basic_weapon := Weapon {
	name             = "small_laser",
	speed            = 400,
	acceleration     = 1.0,
	alive            = true,
	dmg_type         = "laser",
	dmg              = 1,
	fire_rate        = 50,
	size_projectiles = {5, 10},
	waiting_time     = 0,
	firing           = true,
	follow_target    = false,
}

init_level1 :: proc(state: ^Game_State) {
	//init_time = sdl.GetTicks()
	ennemy_ship_test := new(Ennemy_ship)
	ennemy_ship_test.name = "The basic one"
	ennemy_ship_test.coordinates = {SCREEN_WIDTH / 2, -50.0}
	ennemy_ship_test.velocity = {280, 80}
	ennemy_ship_test.max_speed = 80
	ennemy_ship_test.acceleration = 1
	ennemy_ship_test.life = 1
	ennemy_ship_test.pattern = "swipe"
	ennemy_ship_test.max_life = 1
	ennemy_ship_test.shield = 0
	ennemy_ship_test.alive = true
	ennemy_ship_test.size = {40, 70}
	ennemy_ship_test.primary_weapon = basic_weapon
	append(&list_ennemy_ships, ennemy_ship_test)
}

update_level1 :: proc(state: ^Game_State) {
	switch wave_number {
	case 0:
		if len(list_ennemy_ships) == 0 {
			for i := 0; i < 10; i += 1 {
				es := new(Ennemy_ship)
				es.name = "The basic one"
				es.coordinates = {SCREEN_WIDTH / 2, -70.0 - 150.0 * f32(i)}
				es.velocity = {80, 50}
				es.max_speed = 80
				es.acceleration = 1
				es.life = 1
				es.pattern = "swipe"
				es.max_life = 1
				es.shield = 0
				es.alive = true
				es.size = {40, 70}
				es.primary_weapon = basic_weapon
				append(&list_ennemy_ships, es)
			}
			wave_number += 1
		}
	}
}
