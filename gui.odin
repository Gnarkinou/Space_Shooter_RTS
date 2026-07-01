package main

import "core:fmt"
import "core:math"
import sdl "vendor:sdl3"

bg_rect := sdl.FRect {
	x = 20,
	y = 20,
	w = 200,
	h = 20,
}

shield_rect := sdl.FRect {
	x = bg_rect.x,
	y = bg_rect.y + 10 + bg_rect.h,
	w = bg_rect.w,
	h = bg_rect.h,
}

render_gui :: proc(state: ^Game_State) {
	display_life(state)
	display_shield_gui(state)
}

display_shield_gui :: proc(state: ^Game_State) {
	sdl.SetRenderDrawBlendMode(state.render, {.BLEND})
	sdl.SetRenderDrawColor(state.render, 10, 10, 100, 140)
	sdl.RenderFillRect(state.render, &shield_rect)
	shield_percentage: f32 = 0.0
	if state.player.shield > 0 do shield_percentage = f32(state.player.shield) / f32(state.player.max_shield)
	else do shield_percentage = 0.0
	shield_percentage = clamp(shield_percentage, 0.0, 1.0)
	blue_rect := sdl.FRect {
		x = shield_rect.x,
		y = shield_rect.y,
		w = shield_rect.w * shield_percentage,
		h = shield_rect.h,
	}
	sdl.SetRenderDrawColor(state.render, 0, 130, 255, 200)
	sdl.RenderFillRect(state.render, &blue_rect)

	if state.player.shield <= state.player.max_shield {
		reload_progress: f32 = 0.0
		reload_progress =
			1.0 - f32(state.player.reload_shield) / f32(state.player.max_reload_shield)
		reload_progress = clamp(reload_progress, 0.0, 1.0)
		green_rect := sdl.FRect {
			x = shield_rect.x,
			y = shield_rect.y,
			w = shield_rect.w * reload_progress,
			h = shield_rect.h,
		}
		sdl.SetRenderDrawColor(state.render, 50, 220, 100, 100)
		sdl.RenderFillRect(state.render, &green_rect)
	}

	sdl.SetRenderDrawColor(state.render, 50, 180, 255, 255)
	sdl.RenderRect(state.render, &shield_rect)
}

display_shield :: proc(state: ^Game_State) {
	center_x := state.player.coord.x + (state.player.size.x / 2.0)
	center_y := state.player.coord.y + (state.player.size.y / 2.0)
	half_w := state.player.size.x / 2.0
	half_h := state.player.size.y / 2.0
	radius := math.sqrt(half_w * half_w + half_h * half_h) + 6.0
	sdl.SetRenderDrawBlendMode(state.render, {.BLEND})
	sdl.SetRenderDrawColor(state.render, 0, 150, 255, 200)
	draw_circle(state.render, center_x, center_y, radius, 36)
}

display_ennemy_life :: proc(render: ^sdl.Renderer, enemy: ^Ennemy_ship) {
	// I can improve this by having an init_ennemy_rect or something
	// and initialized it with pointers of the coord of the ennemy
	enemy_life_rect := sdl.FRect {
		w = f32(enemy.size[0]),
		h = 20,
		x = enemy.coordinates[0],
		y = enemy.coordinates[1] - 30,
	}
	sdl.SetRenderDrawBlendMode(render, {.BLEND})
	sdl.SetRenderDrawColor(render, 100, 10, 10, 140)
	sdl.RenderFillRect(render, &enemy_life_rect)
	life_percentage: f32 = 0.0
	if enemy.life > 0 do life_percentage = f32(enemy.life) / f32(enemy.max_life)
	else do life_percentage = 0.0
	life_percentage = clamp(life_percentage, 0.0, 1.0)
	fg_rect := sdl.FRect {
		x = enemy_life_rect.x,
		y = enemy_life_rect.y,
		w = enemy_life_rect.w * life_percentage,
		h = enemy_life_rect.h,
	}
	sdl.SetRenderDrawColor(render, 230, 30, 30, 220)
	sdl.RenderFillRect(render, &fg_rect)

	sdl.SetRenderDrawColor(render, 255, 255, 255, 200)
	sdl.RenderRect(render, &enemy_life_rect)
}

display_life :: proc(state: ^Game_State) {
	sdl.SetRenderDrawBlendMode(state.render, {.BLEND})
	sdl.SetRenderDrawColor(state.render, 100, 10, 10, 140)
	sdl.RenderFillRect(state.render, &bg_rect)

	life_percentage: f32 = 0.0
	if state.player.life > 0 do life_percentage = f32(state.player.life) / f32(state.player.max_life)
	else do life_percentage = 0.0
	life_percentage = clamp(life_percentage, 0.0, 1.0)
	fg_rect := sdl.FRect {
		x = bg_rect.x,
		y = bg_rect.y,
		w = bg_rect.w * life_percentage,
		h = bg_rect.h,
	}
	sdl.SetRenderDrawColor(state.render, 230, 30, 30, 220)
	sdl.RenderFillRect(state.render, &fg_rect)

	sdl.SetRenderDrawColor(state.render, 255, 255, 255, 200)
	sdl.RenderRect(state.render, &bg_rect)
}
