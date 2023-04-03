package chip

import "vendor:sdl2"
import "core:fmt"

display_init :: proc() -> (^sdl2.Renderer, ^sdl2.Window) {
	assert(sdl2.Init(sdl2.INIT_VIDEO) == 0, sdl2.GetErrorString())

	window := sdl2.CreateWindow(
		"chip-8",
		sdl2.WINDOWPOS_CENTERED,
		sdl2.WINDOWPOS_CENTERED,
		640,
		320,
		sdl2.WINDOW_SHOWN,
	)

	renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)

	sdl2.SetRenderDrawColor(renderer, 255, 255, 255, 255)
	sdl2.RenderClear(renderer)
	sdl2.SetRenderDrawColor(renderer, 0, 0, 0, 255)

	sdl2.RenderPresent(renderer)
	return renderer, window
}



display_draw :: proc(x: i32, y: i32) {
	x := x
	y := y

	x *= 10
	y *= 10
	for i in x..<(x + 9) {
		for j in y..<(y + 9) {
			sdl2.RenderDrawPoint(renderer, i, j)
		}
	}
}

display_sprite :: proc(n: u16, I: u16, x, y:u8) {
	for i, j in I..<I+n {
		byte := ram[i]

		mask: u8 = 1
		for i in 0..=7 {
			if bool(byte & mask) { 
				fmt.print("here")
				display_draw(i32(x + u8(i)), i32(y + u8(j)))
			}
			mask *= 2 
		}
	}
}
