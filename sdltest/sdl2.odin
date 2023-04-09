package sdl

import "core:fmt"
import "vendor:sdl2"


main :: proc() {
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
	defer sdl2.DestroyWindow(window)
	defer sdl2.DestroyRenderer(renderer)

	sdl2.SetRenderDrawColor(renderer, 255, 255, 255, 255)
	sdl2.RenderClear(renderer)
	sdl2.SetRenderDrawColor(renderer, 0, 0, 0, 255)

	display_draw(63, 31, renderer)
	sdl2.RenderPresent(renderer)

	for {
		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				return
			case .KEYDOWN:
				if event.key.keysym.scancode == sdl2.SCANCODE_Q {
					return
				}
			}

		}
	}

}

display_draw :: proc(x: i32, y: i32, renderer: ^sdl2.Renderer) {
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
