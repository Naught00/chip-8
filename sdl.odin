package sdl

import "core:fmt"
import "vendor:sdl2"


main :: proc() {
	assert(sdl2.Init(sdl2.INIT_VIDEO) == 0, sdl2.GetErrorString())

	window: ^sdl2.Window
	renderer: ^sdl2.Renderer


	//= sdl2.CreateWindow(
	//	"chip-8",
	//	sdl2.WINDOWPOS_CENTERED,
	//	sdl2.WINDOWPOS_CENTERED,
	//	64,
	//	32,
	//	sdl2.WINDOW_SHOWN,
	//)

	sdl2.CreateWindowAndRenderer(64, 32, nil, &window, &renderer)
	defer sdl2.DestroyWindow(window)
	window_surface := sdl2.GetWindowSurface(window);

	pixels: [2048]u8
	for x, i in pixels {
		pixels[i] = 0
	}

	p := rawptr(&pixels)

	fmt.print(pixels)

	surface := sdl2.CreateRGBSurfaceFrom(p, 64, 32, 8, 64, 0, 0, 0, 0)

	sdl2.BlitSurface(surface, nil, window_surface, nil)
	sdl2.UpdateWindowSurface(window);

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
