package main

import "core:fmt"
import sdl "vendor:sdl3"

init_level1 :: proc(state: ^Game_State) {
	ennemy_ship_test := new(Ennemy_ship)
	ennemy_ship_test.name = "The basic one"
	ennemy_ship_test.coordinates = {SCREEN_WIDTH / 2, -50.0}
	ennemy_ship_test.velocity = {0, 80}
	ennemy_ship_test.max_speed = 80
	ennemy_ship_test.acceleration = 1
	ennemy_ship_test.life = 1
	ennemy_ship_test.max_life = 1
	ennemy_ship_test.shield = 0
	ennemy_ship_test.alive = true
	ennemy_ship_test.size = {40, 70}

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
