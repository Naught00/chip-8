package chip

import "core:os"
import "core:fmt"
import "core:math/rand"
import "core:time"
import "vendor:sdl2"

print :: fmt.println

/* Operations */
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

//operations_determine :: proc(op_code: u8) -> operations {
//	switch op_code {
//	case 0xA0:
//		return operations.LD_I
//	}
//	return operations.LD_I
//}

Cpu :: struct {
	registers: [16]u8,
	I: u16,
	VF: u8,
	delay: u8,
	program_counter: u16,
	stack_pointer: u8,
}

cpu_set_register_I :: proc(using cpu: ^Cpu, val: u16) {
	I = val
}

get_value :: proc(pc: u16) -> u16 {
	next_byte := ram[pc + 1]

	low_bits: u8 = ram[pc] & 0b00001111
	fmt.printf("low: {:8b}\n", low_bits)
	fmt.printf("HEX: {:8b}\n", next_byte)

	value :u16 = u16(low_bits) << 8 | u16(next_byte)

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
	program, success := os.read_entire_file_from_filename("fizz.ch8")
	cpu: Cpu

	for x, i in program {
		if i % 2 == 0 {
		//	fmt.println()
		}

		//fmt.printf("{:X} ", x)
	}

	//prog := []u8{0x82, 0x03}
	load_program(program)
	load_sprites()
	print_ram()
	cpu.program_counter = 0x200

	renderer, window = display_init()
	display_sprite(5, 0x0, 10, 10)
	display_sprite(5, 0x0 + 5, 20, 10)
	display_sprite(5, 0x0 + 10, 30, 10)

	sdl2.RenderPresent(renderer)

	for ; cpu.program_counter < u16(len(program)) + 0x200; {

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

		print()
		print()
		print()

		fmt.printf("HEX: {:8b}\n", ram[cpu.program_counter])

		operation := ram[cpu.program_counter] & 0b11110000
		
		fmt.printf("HEX: {:X}\n", operation)
	

		switch operation {
		case LD_I_addr:
			value := get_value(cpu.program_counter)
			cpu_set_register_I(&cpu, value)
			print(cpu.I)

		case JP_addr:
			cpu.program_counter = get_value(cpu.program_counter)
			print("pc : ", cpu.program_counter)
			fmt.printf("pc {:X} ", cpu.program_counter)

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
				cpu.registers[low_bits] = cpu.registers[next_byte_high_bits]

			// OR Vx, Vy
			case 0x1:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				cpu.registers[low_bits] = cpu.registers[low_bits] | cpu.registers[next_byte_high_bits]
			case 0x2:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				cpu.registers[low_bits] = cpu.registers[low_bits] & cpu.registers[next_byte_high_bits]
			// XOR 
			case 0x3:
				print("XOR!")
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				cpu.registers[low_bits] = cpu.registers[low_bits] ~ cpu.registers[next_byte_high_bits]
			// ADD Vx, Vy, vf
			case 0x4:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				temp := cpu.registers[low_bits] + cpu.registers[next_byte_high_bits]
				if temp > 255 {
					cpu.VF = 1
				} else {
					cpu.VF = 0
				}

				cpu.registers[low_bits] = temp & 0b00001111

			case 0x5:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				if cpu.registers[low_bits] > cpu.registers[next_byte_high_bits] {
					cpu.VF = 1
				} else {
					cpu.VF = 0
				}

				cpu.registers[low_bits] -= cpu.registers[next_byte_high_bits] 
			case 0x6:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				if cpu.registers[low_bits] & 0b00000001 == 1 {
					cpu.VF = 1
				} else {
					cpu.VF = 0
				}

				cpu.registers[low_bits] /= 2
			case 0x7:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				if cpu.registers[next_byte_high_bits] > cpu.registers[low_bits] {
					cpu.VF = 1
				} else {
					cpu.VF = 0
				}

				cpu.registers[low_bits] = cpu.registers[next_byte_high_bits] - cpu.registers[low_bits]

			case 0xE:
				low_bits := ram[cpu.program_counter] & 0b00001111
				next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

				if cpu.registers[low_bits] & 0b10000000 == 128 {
					cpu.VF = 1
				} else {
					cpu.VF = 0
				}

				cpu.registers[low_bits] /= 2
			}
		case SNE_vx_vy:
			low_bits := ram[cpu.program_counter] & 0b00001111

			next_byte_high_bits := ram[cpu.program_counter + 1] & 0b11110000

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

		}
			

		cpu.program_counter += 2
			

		//operation := bits.bitfield_extract_u8(byte, 0, 8)
		//fmt.printf("HEX: {:8b}", operation)
	}


}

