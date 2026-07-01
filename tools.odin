package main

import "core:math"
import sdl "vendor:sdl3"

draw_circle :: proc(render: ^sdl.Renderer, center_x, center_y, radius: f32, segments: int = 32) {
	for i in 0 ..< segments {
		theta1 := (f32(i) / f32(segments)) * (2.0 * math.PI)
		theta2 := (f32(i + 1) / f32(segments)) * (2.0 * math.PI)
		x1 := center_x + radius * math.cos(theta1)
		y1 := center_y + radius * math.sin(theta1)
		x2 := center_x + radius * math.cos(theta2)
		y2 := center_y + radius * math.sin(theta2)
		sdl.RenderLine(render, x1, y1, x2, y2)
	}
}
