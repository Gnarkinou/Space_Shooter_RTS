package main

import "core:fmt"
//import sdl "vendor:sdl3"

wave_number: int = 0
wave_trigger: int = 0

basic_boss_weapon := Weapon {
	name             = "boss_small_laser",
	speed            = 400,
	acceleration     = 1.0,
	dmg_type         = "laser",
	dmg              = 1,
	life             = 1,
	fire_rate        = 50,
	size_projectiles = {5, 10},
	waiting_time     = 0,
	number_canons    = 2,
	firing           = true,
	follow_target    = false,
}

basic_weapon := Weapon {
	name             = "small_laser",
	speed            = 400,
	acceleration     = 1.0,
	dmg_type         = "laser",
	dmg              = 1,
	life             = 1,
	number_canons    = 1,
	fire_rate        = 50,
	size_projectiles = {5, 10},
	waiting_time     = 0,
	firing           = true,
	follow_target    = false,
}

init_big_boss_level1 :: proc(state: ^Game_State) {
	boss_level_1 := new(Ennemy_ship)
	boss_level_1.name = "The basic one"
	boss_level_1.coordinates = {SCREEN_WIDTH / 2, -50.0}
	boss_level_1.velocity = {280, 80}
	boss_level_1.max_speed = {280, 80}
	boss_level_1.speed = 40
	boss_level_1.acceleration = 1
	boss_level_1.life = 20
	boss_level_1.pattern = "Trail Player"
	boss_level_1.max_life = 1
	boss_level_1.shield = 0
	boss_level_1.max_shield = 0
	boss_level_1.max_reload_shield = 0
	boss_level_1.alive = true
	boss_level_1.size = {120, 80}
	boss_level_1.primary_weapon = basic_boss_weapon
	boss_level_1.secondary_weapon = basic_boss_weapon
	boss_level_1.secondary_weapon.fire_rate = 70
	boss_level_1.secondary_weapon.firing = false
	append(&list_ennemy_ships, boss_level_1)
}

init_level1 :: proc(state: ^Game_State) {
	ennemy_ship_test := new(Ennemy_ship)
	ennemy_ship_test.name = "The basic one"
	ennemy_ship_test.coordinates = {SCREEN_WIDTH / 2, -50.0}
	ennemy_ship_test.velocity = {280, 80}
	ennemy_ship_test.max_speed = {280, 80}
	ennemy_ship_test.speed = 90
	ennemy_ship_test.acceleration = 1
	ennemy_ship_test.life = 1
	ennemy_ship_test.pattern = "swipe"
	ennemy_ship_test.max_life = 1
	ennemy_ship_test.shield = 0
	ennemy_ship_test.max_shield = 0
	ennemy_ship_test.max_reload_shield = 0
	ennemy_ship_test.alive = true
	ennemy_ship_test.size = {40, 70}
	ennemy_ship_test.primary_weapon = basic_weapon
	append(&list_ennemy_ships, ennemy_ship_test)
}

update_level1 :: proc(state: ^Game_State) {
	switch wave_number {
	case 0:
		fmt.println("First wave spawning")
		if len(list_ennemy_ships) == 0 {
			for i := 0; i < 2; i += 1 {
				es := new(Ennemy_ship)
				es.name = "The basic one"
				es.coordinates = {SCREEN_WIDTH / 2, -70.0 - 80.0 * f32(i)}
				es.velocity = {150, 150}
				es.max_speed = {180, 250}
				es.acceleration = 1
				es.life = 1
				es.pattern = "dance"
				es.max_life = 1
				es.shield = 0
				es.alive = true
				es.size = {40, 70}
				es.primary_weapon = basic_weapon
				append(&list_ennemy_ships, es)
			}
			for i := 0; i < 2; i += 1 {
				es := new(Ennemy_ship)
				es.name = "The basic one"
				es.coordinates = {(SCREEN_WIDTH / 2) - 100, -70.0 - 80.0 * f32(i)}
				es.velocity = {150, 150}
				es.max_speed = {180, 250}
				es.acceleration = 1
				es.life = 1
				es.pattern = "dance"
				es.max_life = 1
				es.shield = 0
				es.alive = true
				es.size = {40, 70}
				es.primary_weapon = basic_weapon
				append(&list_ennemy_ships, es)
			}
			for i := 0; i < 2; i += 1 {
				es := new(Ennemy_ship)
				es.name = "The basic one"
				es.coordinates = {(SCREEN_WIDTH / 2) - 200, -70.0 - 80.0 * f32(i)}
				es.velocity = {150, 150}
				es.max_speed = {180, 250}
				es.acceleration = 1
				es.life = 1
				es.pattern = "dance"
				es.max_life = 1
				es.shield = 0
				es.alive = true
				es.size = {40, 70}
				es.primary_weapon = basic_weapon
				append(&list_ennemy_ships, es)
			}

			for i := 0; i < 2; i += 1 {
				es := new(Ennemy_ship)
				es.name = "The basic one"
				es.coordinates = {SCREEN_WIDTH / 2, -500.0 - 80.0 * f32(i)}
				es.velocity = {150, 150}
				es.max_speed = {180, 250}
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
	case 1:
		if len(list_ennemy_ships) == 0 {
			fmt.println("Condition to end the first wave is met, GG !!")
			wave_number += 1
		}
	case 2:
		fmt.println("Second wave coming !")
		if wave_trigger == 1 && len(list_ennemy_ships) == 0 {
			fmt.println("Conditions to end wave 2 met ! GG !")
			wave_number += 1
			break
		}

		if len(list_ennemy_ships) == 0 {
			for i := 0; i < 3; i += 1 {
				es := new(Ennemy_ship)
				es.name = "The basic one"
				es.coordinates = {SCREEN_WIDTH / 2, -500.0 - 80.0 * f32(i)}
				es.velocity = {150, 150}
				es.max_speed = {180, 250}
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
		}

		if wave_trigger == 0 {
			for i := 0; i < 4; i += 1 {
				es := new(Ennemy_ship)
				es.name = "The basic one"
				es.coordinates = {SCREEN_WIDTH / 2, -70.0 - 80.0 * f32(i)}
				es.velocity = {150, 150}
				es.max_speed = {180, 250}
				es.acceleration = 1
				es.life = 1
				es.pattern = "dance"
				es.max_life = 1
				es.shield = 0
				es.alive = true
				es.size = {40, 70}
				es.primary_weapon = basic_weapon
				append(&list_ennemy_ships, es)
			}
			for i := 0; i < 3; i += 1 {
				es := new(Ennemy_ship)
				es.name = "The basic one"
				es.coordinates = {(SCREEN_WIDTH / 2) - 100, -70.0 - 80.0 * f32(i)}
				es.velocity = {150, 150}
				es.max_speed = {180, 250}
				es.acceleration = 1
				es.life = 1
				es.pattern = "dance"
				es.max_life = 1
				es.shield = 0
				es.alive = true
				es.size = {40, 70}
				es.primary_weapon = basic_weapon
				append(&list_ennemy_ships, es)
			}
			for i := 0; i < 2; i += 1 {
				es := new(Ennemy_ship)
				es.name = "The basic one"
				es.coordinates = {(SCREEN_WIDTH / 2) - 200, -70.0 - 80.0 * f32(i)}
				es.velocity = {150, 150}
				es.max_speed = {180, 250}
				es.acceleration = 1
				es.life = 1
				es.pattern = "dance"
				es.max_life = 1
				es.shield = 0
				es.alive = true
				es.size = {40, 70}
				es.primary_weapon = basic_weapon
				append(&list_ennemy_ships, es)
			}
			wave_trigger = 1
		}
	case 3:
		fmt.println("Spwaning the Big Boss now !")
	}
}
