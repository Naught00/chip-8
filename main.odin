package chip

import "core:os"
import "core:fmt"
import "core:math/rand"
import "core:time"
import "vendor:sdl2"
import ma "vendor:miniaudio"

print :: fmt.println

/* Operations */
CLR         :: 0xE0 
RET         :: 0xEE
LD_I_addr   :: 0xA0
JP_addr     :: 0x10
CALL_addr   :: 0x20
SE_vx_byte  :: 0x30
SNE_vx_byte :: 0x40
SE_vx_vy    :: 0x50
LD_vx_byte  :: 0x60
ADD_vx_byte :: 0x70
SNE_vx_vy   :: 0x90
JP_v0_addr  :: 0xB0
RND_vx_byte :: 0xC0
DRW_vx_vy   :: 0xD0
LD_vx_delay :: 0xF0 
	

/* Sprites */
sprites: []u8 = {0xF0, 0x90, 0x90, 0x90, 0xF0,
		0x20, 0x60, 0x20, 0x20, 0x70,
		0xF0, 0x10, 0xF0, 0x80, 0xF0,
		0xF0, 0x10, 0xF0, 0x10, 0xF0,
		0x90, 0x90, 0xF0, 0x10, 0x10,
		0xF0, 0x80, 0xF0, 0x10, 0xF0,
		0xF0, 0x80, 0xF0, 0x90, 0xF0,
		0xF0, 0x10, 0x20, 0x40, 0x40,
		0xF0, 0x90, 0xF0, 0x90, 0xF0,
		0xF0, 0x90, 0xF0, 0x10, 0xF0,
		0xF0, 0x90, 0xF0, 0x90, 0x90,
		0xE0, 0x90, 0xE0, 0x90, 0xE0,
		0xF0, 0x80, 0x80, 0x80, 0xF0,
		0xE0, 0x90, 0x90, 0x90, 0xE0,
		0xF0, 0x80, 0xF0, 0x80, 0xF0,
		0xF0, 0x80, 0xF0, 0x80, 0x80}


stack: [16]u16
ram: [4096]u8

window: ^sdl2.Window
renderer: ^sdl2.Renderer

Cpu :: struct {
	registers: [16]u8,
	I: u16,
	VF: u8,
	delay: u8,
	program_counter: u16,
	stack_pointer: u8,
	sound: u8
}

cpu_set_register_I :: proc(using cpu: ^Cpu, val: u16) {
	I = val
}

get_value :: proc(pc: u16) -> u16 {
	next_byte := ram[pc + 1]

	low_bits: u8 = ram[pc] & 0b00001111
	fmt.printf("low: {:8b}\n", low_bits)
	fmt.printf("HEX: {:8b}\n", next_byte)

	value: u16 = u16(low_bits) << 8 | u16(next_byte)

	fmt.printf("HEX: {:X}\n", value)
	return value
}

load_program :: proc(program: []u8) {
	for byte, i in program {
		ram[0x200 + i] = byte
	}
}

load_sprites :: proc() {
	for byte, i in sprites {
		ram[i] = byte
	}
}

print_ram :: proc() {
	for x, i in ram do fmt.printf("ADDR: {:X}: {:8b}\n", i, x)
}

main :: proc() {
	filename: string
	if len(os.args) > 1 do filename = os.args[1]

	// @DEBUG
	filename = "programs/chip8-test-suite.ch8"
	program, success := os.read_entire_file_from_filename(filename)

	if !success {
		fmt.eprintln("Invalid filename") 
		os.exit(1)
	}

	engine: ma.engine
	ma.engine_init(nil, &engine)

	//ma.engine_play_sound(&engine, "sound.wav", nil)

	cpu: Cpu

	for x, i in program {
		if i % 2 == 0 {
			fmt.println()
		}

		fmt.printf("{:X} ", x)
	}

//	if true {
//		os.exit(1)
//	}

	// @DEBUG
	prog := []u8{0xF2, 0x29, 0xD0, 0x15, 0x00, 0xE0, 0xF2, 0x33, 0xF5, 0x55, 0xF2, 0x65}

	load_program(program)
	load_sprites()
	print_ram()

	/* CHIP-8 programs start at 0x200 */
	cpu.program_counter = 0x200

	renderer, window = display_init()
	defer {
		sdl2.DestroyWindow(window)
		sdl2.DestroyRenderer(renderer)
	}

	//i :u16 = 0
	//for _ in 0..<15 {
	//	display_sprite(5, 0x0 + i, 0 + u8(i), 10)
	//	i += 5
	//}


	i: int = 0
	for cpu.program_counter < u16(len(program)) + 0x200 {
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

		fmt.printf("HEX: {:8b}\n", ram[cpu.program_counter])

		operation := ram[cpu.program_counter] & 0b11110000
		
		fmt.printf("Operation HEX: {:X}\n", operation)

		switch operation {
		case LD_I_addr:
			value := get_value(cpu.program_counter)
			cpu_set_register_I(&cpu, value)
			print(cpu.I)

		case JP_addr:
			cpu.program_counter = get_value(cpu.program_counter)
			print("pc : ", cpu.program_counter)
			fmt.printf("pc {:X} ", cpu.program_counter)
			continue

			//@HACK
			//os.exit(0)

		case CALL_addr:
			cpu.stack_pointer += 1
			stack[cpu.stack_pointer] = cpu.program_counter

			cpu.program_counter = get_value(cpu.program_counter)
			continue

		case SE_vx_byte:
			print("SE")
			low_bits: u8 = ram[cpu.program_counter] & 0b00001111

			fmt.printf("low {:8b} ", low_bits)
			print(low_bits)

			// Not sure yet
			//low_bits = low_bits << 4
			//fmt.printf("low {:8b} ", low_bits)
			//print(low_bits)

			next_byte := ram[cpu.program_counter + 1]

			if cpu.registers[low_bits] == next_byte {
				cpu.program_counter += 2
			}

		case SNE_vx_byte:
			print("SNE")
			low_bits: u8 = ram[cpu.program_counter] & 0b00001111

			fmt.printf("low {:8b} ", low_bits)
			print(low_bits)

			next_byte := ram[cpu.program_counter + 1]

			if cpu.registers[low_bits] != next_byte {
				cpu.program_counter += 2
			}

		case SE_vx_vy:
			low_bits: u8 = ram[cpu.program_counter] & 0b00001111

			next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

			next_byte_high_bits = next_byte_high_bits >> 4

			if cpu.registers[low_bits] == cpu.registers[next_byte_high_bits] {
				cpu.program_counter += 2
			}

		case LD_vx_byte:
			low_bits: u8 = ram[cpu.program_counter] & 0b00001111
			cpu.registers[low_bits] = ram[cpu.program_counter + 1]

		case ADD_vx_byte:
			low_bits: u8 = ram[cpu.program_counter] & 0b00001111
			cpu.registers[low_bits] += ram[cpu.program_counter + 1]

		case 0x80:
			next_byte_low_bits := ram[cpu.program_counter + 1] & 0b00001111
			print("here")

			switch next_byte_low_bits {
			// LD_vx_vy
			case 0x0:
				low_bits := ram[cpu.program_counter] & 0b00001111

				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000
				next_byte_high_bits = next_byte_high_bits >> 4

				cpu.registers[low_bits] = cpu.registers[next_byte_high_bits]
			// OR Vx, Vy
			case 0x1:
				low_bits := ram[cpu.program_counter] & 0b00001111

				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000
				next_byte_high_bits = next_byte_high_bits >> 4

				cpu.registers[low_bits] = cpu.registers[low_bits] | cpu.registers[next_byte_high_bits]
			case 0x2:
				low_bits := ram[cpu.program_counter] & 0b00001111

				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000
				next_byte_high_bits = next_byte_high_bits >> 4

				cpu.registers[low_bits] = cpu.registers[low_bits] & cpu.registers[next_byte_high_bits]
			// XOR 
			case 0x3:
				print("XOR!")
				low_bits := ram[cpu.program_counter] & 0b00001111

				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000
				next_byte_high_bits = next_byte_high_bits >> 4

				cpu.registers[low_bits] = cpu.registers[low_bits] ~ cpu.registers[next_byte_high_bits]
			// ADD Vx, Vy, vf
			case 0x4:
				low_bits := ram[cpu.program_counter] & 0b00001111

				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000
				next_byte_high_bits = next_byte_high_bits >> 4

				temp :u16 = u16(cpu.registers[low_bits]) + u16(cpu.registers[next_byte_high_bits])
				if temp > 255 {
					cpu.registers[0xF] = 1
				} else {
					cpu.registers[0xF] = 0
				}

				//@TEST
				cpu.registers[low_bits] = u8(temp)

			case 0x5:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				next_byte_high_bits = next_byte_high_bits >> 4
				cpu.registers[low_bits] -= cpu.registers[next_byte_high_bits] 

				if cpu.registers[low_bits] > cpu.registers[next_byte_high_bits] {
					cpu.registers[0xF] = 1
				} else {
					cpu.registers[0xF] = 0
				}


			case 0x6:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				next_byte_high_bits = next_byte_high_bits >> 4


				if cpu.registers[low_bits] & 0b00000001 == 1 {
					cpu.registers[low_bits] /= 2
					cpu.registers[0xF] = 1
				} else {
					cpu.registers[0xF] = 0
					cpu.registers[low_bits] /= 2
				}



			case 0x7:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				next_byte_high_bits = next_byte_high_bits >> 4

				cpu.registers[low_bits] = cpu.registers[next_byte_high_bits] - cpu.registers[low_bits]

				if cpu.registers[next_byte_high_bits] > cpu.registers[low_bits] {
					cpu.registers[0xF] = 1
				} else {
					cpu.registers[0xF] = 0
				}


			case 0xE:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				next_byte_high_bits = next_byte_high_bits >> 4

				if cpu.registers[low_bits] & 0b10000000 == 128 {
					cpu.registers[low_bits] *= 2
					cpu.registers[0xF] = 1
				} else {
					cpu.registers[0xF] = 0
					cpu.registers[low_bits] *= 2
				}

			}

		case SNE_vx_vy:
			low_bits := ram[cpu.program_counter] & 0b00001111

			next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

			next_byte_high_bits = next_byte_high_bits >> 4

			if cpu.registers[low_bits] != cpu.registers[next_byte_high_bits] {
				cpu.program_counter += 2
			}
			
		case JP_v0_addr:
			cpu.program_counter = get_value(cpu.program_counter) + u16(cpu.registers[0])

		case RND_vx_byte:
			r := rand.create(u64(time.time_to_unix(time.now())))

			num := u8(rand.uint32(&r))

			low_bits := ram[cpu.program_counter] & 0b00001111

			cpu.registers[low_bits] = num & ram[cpu.program_counter + 1]

		//@TODO collision
		case DRW_vx_vy:
			cpu.registers[0xF] = 0
			x := ram[cpu.program_counter] & 0b00001111
			y := ram[cpu.program_counter + 1] & 0b11110000
			print("y", y)
			y = y >> 4
			print("y", y)

			n := ram[cpu.program_counter + 1] & 0b00001111

			vx := cpu.registers[x]
			vy := cpu.registers[y]
			

			if vx > 63 {
				vx %= 64
			}

			if vy > 31 {
				vy %= 32
			}


			fmt.println("CORDS")
			fmt.println(vx, vy, n)
			print(cpu.I)

			print("BEFORE:", cpu.VF)
			display_sprite(&cpu, n, cpu.I, vx, vy)
			print("AFTER", cpu.VF)

			fmt.print("here")

		case 0xE0:
			switch ram[cpu.program_counter + 1] {
			//SKP
			case 0x9E:

				keys := sdl2.GetKeyboardState(nil)
				low_bits := ram[cpu.program_counter] & 0b00001111

				key := cpu.registers[low_bits]

				print("key", key)


				scancode := get_scancode(key)
				if bool(keys[scancode]) {
					cpu.program_counter += 2
				}
				print("SCAN!")

			//SKNP
			case 0xA1:
				keys := sdl2.GetKeyboardState(nil)
				low_bits := ram[cpu.program_counter] & 0b00001111

				key := cpu.registers[low_bits]


				scancode := get_scancode(key)
				if !bool(keys[scancode]) {
					cpu.program_counter += 2
				}
			}


		case 0xF0:
			x := ram[cpu.program_counter] & 0b00001111
			print("0xF0")
			vx := u16(cpu.registers[x])

			switch ram[cpu.program_counter + 1] {
			case 0x07:
				cpu.registers[x] = cpu.delay

			case 0x0A:
				print("wait")
				time.sleep(1000 * 1000 * 1000)
				//event: sdl2.Event
				//for sdl2.WaitEvent(&event) {
				//	#partial switch event.type {
				//	case .QUIT:
				//	case .KEYDOWN:
				//		if event.key.keysym.scancode == sdl2.SCANCODE_F {
				//			break

				//		}
				//	}
				//}

			case 0x15:
				cpu.delay = cpu.registers[x]

			case 0x18:
				cpu.sound = cpu.registers[x]

			case 0x1E:
				cpu.I += vx

			case 0x29:
				print("0x29")

				addr: u16
				switch {
				case vx == 0:
					addr = 0
				case vx == 1:
					addr = 5
				case:
					addr = vx * 5 + 0
					print("*:::" ,addr)
				}

				print(addr)
				cpu.I = addr
			
			case 0x33:
				print("0x33")
				x := ram[cpu.program_counter] & 0b00001111

				vx := cpu.registers[x] 

				ram[cpu.I] = (vx - (vx % 100)) / 100
				ram[cpu.I + 1] = (vx % 100 - (vx % 10)) / 10
				ram[cpu.I + 2] = vx % 10

				print(vx)
				print(ram[cpu.I])
				print(ram[cpu.I + 1])
				print(ram[cpu.I + 2])


			case 0x55:
				x := ram[cpu.program_counter] & 0b00001111

				print("0x55")
				for i in 0..=x {
					ram[cpu.I + u16(i)] = cpu.registers[i]
				}

			case 0x65:
				x := ram[cpu.program_counter] & 0b00001111

				for i in 0..=x {
					cpu.registers[i] = ram[cpu.I + u16(i)]
				}

			}

		case 0x00:
			switch ram[cpu.program_counter + 1] {
			case CLR:
				print("CLR")
				sdl2.SetRenderDrawColor(renderer, 255, 255, 255, 255)
				sdl2.RenderClear(renderer)
				sdl2.SetRenderDrawColor(renderer, 0, 0, 0, 255)

			case RET:
				print("RET")
				cpu.program_counter = stack[cpu.stack_pointer]
				cpu.stack_pointer -= 1
			}
		}

		cpu.program_counter += 2
		sdl2.RenderPresent(renderer)

		if cpu.delay > 0 {
			cpu.delay -= 1
		}

		time.sleep(3 * 1000 * 1000)

	}
}
