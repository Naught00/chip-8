package chip

import "core:os"
import "core:fmt"
import "core:bytes"

print :: fmt.println


stack : [16]u16
ram : [4096]u8

Cpu :: struct {
	registers: [16]u8,
	I: u8,
	VF: u8,
	delay: u8,
	program_counter: u16,
	stack_counter: u8,
}

set_register_I :: proc(using cpu: ^Cpu, val: u8) {
	I = val
}

main :: proc() {

	data, success := os.read_entire_file_from_filename("fizz.ch8")

	for x, i in data {
		if i % 2 == 0 {
			fmt.println()
		}

		fmt.printf("{:X} ", x)
	}

	reader: bytes.Reader
	bytes.reader_init(&reader, data)

	cpu: ^Cpu
	set_register_I(cpu, 11)

	print(cpu.I)
	print(cpu.I)
	print(cpu.I)
	print(cpu.I)
}
