package chip

import "core:os"
import "core:fmt"

print :: fmt.println

/* Operations */
LD_I :: 0xA0
JP :: 0x10
CALL :: 0x20
SE :: 0x30

stack : [16]u16
ram : [4096]u8


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
print_ram :: proc() {
	for x, i in ram do fmt.printf("ADDR: {:X}: %d\n", i, x)
}

main :: proc() {

	program, success := os.read_entire_file_from_filename("fizz.ch8")
	cpu: Cpu

	for x, i in program {
		if i % 2 == 0 {
			fmt.println()
		}

		fmt.printf("{:X} ", x)
	}

	load_program(program)
	cpu.program_counter = 0x200

	for ; cpu.program_counter < u16(len(program)) + 0x200 - 2; {

		print()
		print()
		print()

		fmt.printf("HEX: {:8b}\n", ram[cpu.program_counter])

		operation := ram[cpu.program_counter] & 0b11110000
		
		fmt.printf("HEX: {:X}\n", operation)
	

		switch operation {
		case LD_I:
			value := get_value(cpu.program_counter)
			cpu_set_register_I(&cpu, value)
			print(cpu.I)

		case JP:
			cpu.program_counter = get_value(cpu.program_counter)
			print("pc : ", cpu.program_counter)
			fmt.printf("pc {:X} ", cpu.program_counter)
			exit(0)
			continue


		case CALL:
			cpu.stack_pointer += 1
			stack[cpu.stack_pointer] = cpu.program_counter
		case SE:

		}

		cpu.program_counter += 2
			

		//operation := bits.bitfield_extract_u8(byte, 0, 8)
		//fmt.printf("HEX: {:8b}", operation)
	}


}

