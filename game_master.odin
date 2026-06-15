package main

import "core:fmt"

list_player_projectiles: [dynamic]^Projectile
list_ennemy_projectiles: [dynamic]^Projectile
list_ennemy_ships: [dynamic]^Ennemy_ship

World :: struct {
	break_velocity: [2]f32,
}

Player :: struct {
	coord:                            [2]f32,
	velocity:                         [2]f32,
	max_speed:                        f32,
	increment_speed:                  f32,
	life:                             int,
	max_life:                         int,
	shield:                           int,
	alive:                            bool,
	primary_weapon, secondary_weapon: Weapon,
}

Weapon :: struct {
	name:                                 string,
	speed:                                f32,
	acceleration:                         f32,
	alive:                                bool,
	dmg_type:                             string,
	dmg:                                  int,
	fire_rate, waiting_time, number_ammo: int,
	coordinates:                          ^[2]f32,
	target:                               ^[2]f32,
	size:                                 [2]f32,
	size_projectiles:                     [2]f32,
	follow_target:                        bool,
	auto_fire:                            bool,
	firing, infinite_ammo:                bool,
}

Projectile :: struct {
	name:            string,
	speed:           f32,
	acceleration:    f32,
	alive:           bool,
	life:            int,
	dmg:             int,
	size:            [2]f32,
	coordinates:     [2]f32,
	target:          [2]f32,
	follow_target:   bool,
	player_friendly: bool,
}

Ennemy_ship :: struct {
	name:                             string,
	coordinates:                      [2]f32, // location of the ship x,y
	velocity:                         [2]int, // da speeeed
	max_speed:                        int, // da max speeeed
	acceleration:                     int,
	life:                             int,
	max_life:                         int,
	shield:                           int,
	alive:                            bool,
	primary_weapon, secondary_weapon: Weapon,
	width, height:                    int,
}
