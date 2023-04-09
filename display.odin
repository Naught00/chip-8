package chip

import "vendor:sdl2"
import "vendor:miniaudio"
import "core:fmt"

pixels: [32][64]bool

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

	renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_SOFTWARE)

	sdl2.SetRenderDrawColor(renderer, 255, 255, 255, 255)
	sdl2.RenderClear(renderer)
	sdl2.SetRenderDrawColor(renderer, 0, 0, 0, 255)

	sdl2.RenderPresent(renderer)
	return renderer, window
}



display_draw :: proc(cpu: ^Cpu, x: i32, y: i32) {

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

display_sprite :: proc(cpu: ^Cpu, n: u8, I: u16, x, y:u8) {
	if pixels[y][x] {
		sdl2.SetRenderDrawColor(renderer, 255, 255, 255, 255)
		pixels[y][x] = false
		cpu.VF = 1
	} else {
		pixels[y][x] = true
		sdl2.SetRenderDrawColor(renderer, 0, 0, 0, 255)
		cpu.VF = 0
	}
	for i, j in I..<I+u16(n) {
		byte := ram[i]

		mask: u8 = 128
		for i in 0..=7 {
			if bool(byte & mask) { 
				display_draw(cpu, i32(x + u8(i)), i32(y + u8(j)))
			}
			mask /= 2 
		}
	}
}

get_scancode :: proc(key: u8) -> sdl2.Scancode {
	switch key {
		case 1:
			return sdl2.SCANCODE_1
		case 2:
			return sdl2.SCANCODE_2
		case 3:
			return sdl2.SCANCODE_3
		case 0xC:
			return sdl2.SCANCODE_W
		case 4:
			return sdl2.SCANCODE_4
		case 5:
			return sdl2.SCANCODE_5
		case 6:
			return sdl2.SCANCODE_6
		case 0xD:
			return sdl2.SCANCODE_E
		case 7:
			return sdl2.SCANCODE_7
		case 8:
			return sdl2.SCANCODE_8
		case 9:
			return sdl2.SCANCODE_9
		case 0xE:
			return sdl2.SCANCODE_F
		case 0xA:
			return sdl2.SCANCODE_A
		case 0:
			return sdl2.SCANCODE_0
		case 0xB:
			return sdl2.SCANCODE_B
		case 0xF:
			return sdl2.SCANCODE_F
	}

	return sdl2.SCANCODE_0
}
