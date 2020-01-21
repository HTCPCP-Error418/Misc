#!/usr/bin/env ruby

=begin
	This Ruby script serves as a quick assembler for the HACK assembly language, allowing me to continue
	in the course while I don't have enough time to figure out the C version.

	This script takes one HACK assembly file as an input and outputs one binary, machine language file.

	Usage: ./assembler.rb [input file] [output file]

	TODO:
		- ignore comments
		- ignore blank lines
=end

#add color to strings
class String
	def colorize(color_code)
		"\e[01;#{color_code}m#{self}\e[0m"
	end
	def red
		colorize(31)
	end
	def green
		colorize(32)
	end
	def yellow
		colorize(33)
	end
	def blue
		colorize(34)
	end
end

#built-in symbols for the HACK assembly language
symbol_table = {
	:R0 => 0,
	:R1 => 1,
	:R2 => 2,
	:R3 => 3,
	:R4 => 4,
	:R5 => 5,
	:R6 => 6,
	:R7 => 7,
	:R8 => 8,
	:R9 => 9,
	:R10 => 10,
	:R11 => 11,
	:R12 => 12,
	:R13 => 13,
	:R14 => 14,
	:R15 => 15,
	:SCREEN => 16834,
	:KBD => 24576,
	:SP => 0,
	:LCL => 1,
	:ARG => 2,
	:THIS => 3,
	:THAT => 4
}

#HACK language definitions (binary representation converted to decimal)
dest_bits = {									#these can be replaced with just M, D, and A with a little more
	"M" => 8,									#math (just add the values together for multiple destinations)
	"D" => 16,
	"MD" => 24,
	"A" => 32,
	"AM" => 40,
	"AD" => 48,
	"AMD" => 56
}

cond_bits = {									#I hope the numbers and symbols dont cause problems
	"0" => 2688,
	"1" => 4032,
	"-1" => 3712,
	"D" => 768,
	"A" => 3072,
	"M" => 7168,
	"!D" => 4928,
	"!A" => 3136,
	"!M" => 7232,
	"-D" => 960,
	"-A" => 3264,
	"-M" => 7360,
	"D+1" => 1984,
	"A+1" => 3520,
	"M+1" => 7616,
	"D-1" => 896,
	"A-1" => 3200,
	"M-1" => 7296,
	"D+A" => 128,
	"D+M" => 4224,
	"D-A" => 1216,
	"D-M" => 5312,
	"A-D" => 448,
	"M-D" => 4544,
	"D&A" => 0,
	"D&M" => 4096,
	"D|A" => 1344,
	"D|M" => 5440
}

jump_bits = {
	"JGT" => 1,
	"JEQ" => 2,
	"JGE" => 3,
	"JLT" => 4,
	"JNE" => 5,
	"JLE" => 6,
	"JMP" => 7
}

def usage()
	puts "Usage: #{$0} [input file] [output file]".blue
	exit(0)
end

=begin
	To Binary:
	This function is used to translate a decimal number (from command value calculations in pass_two) into a
	16-bit binary value (the actual machine code) that can then be written to the outfile
=end
def to_bin(decimal, outfile)
	binary = Array.new(15)
	count = 15
	while count >= 0
		if decimal < 1
			binary[count] = 0
		else
			binary[count] = decimal % 2
			decimal /= 2
		end
		count -= 1
	end
	binary.collect!{|i| i.to_s}					#convert integer values to string values
#	puts binary.join.blue						#output full string of machine code
#	puts "-----\n"
	File.open(outfile, mode="a+") { |file|
		file.write("#{binary.join}\n")
	}
end

=begin
	Format:
	Doing all of this in memory turned into a long process, in the interest of saving time the format function
	will go through the input file and remove all comments, blank lines, and leading whitespace; outputting
	only the code. This will remove a lot of work from the parser (pass_one) and the assembler (pass_two)
=end
def format(infile, tmpfile)
	IO.foreach(infile) { |line|
		line.chomp!
		if line.match(/^\s/)					#if line starts with whitespace, flatten it
			line.gsub!(/^\s+/, "")				#select all leading whitespace, replace with ""
		end
		if line.match(/^\/{2}/)					#if line starts with "//" (comment), go to the next line
			next
		elsif line.empty?						#if line is blank, go to next line
			next
		end
		line.gsub!(/\s+\/{2}.+/, "")			#replace all inline comments with ""
		line.gsub!(/\s/, "")					#remove any other whitespace (such as M = D to M=D)

		#write line to tempfile
		File.open(tmpfile, mode="a+") { |file|
			file.write("#{line}\n")
		}
	}
end

=begin
	First Pass:
	For each line in the format "(NAME)", add the pair ":NAME => address" to the symbol table.
	Address will be the line number following the declaration of the name.
=end
def pass_one(tmpfile, symbol_table)
	line_num = 0
	IO.foreach(tmpfile).with_index { |line|
		line.chomp!
		if line.match(/^\(.+\)/)				#if line is in the format "(NAME)"
			symbol = line.gsub!(/(\(|\))/, "").to_sym
#			puts "	Found loop declaration: #{symbol} on line #{line_num}".yellow
			if !symbol_table.include? symbol	#if found symbol is not in symbol table already
				address = line_num
#				puts "Adding symbol: #{symbol} => #{address}".green
				symbol_table[symbol] = address
				line_num -= 1					#(NAME) lines aren't translated, so they don't count
			end
		end
		line_num += 1
	}
end

=begin
	Second Pass:
	Set counter to 16 and scan the program again.
	For each instruction:
		If the instruction is "@NAME", search for NAME in symbol table
			If ":NAME => value" is found, use "value" to translate the instruction
			If not found, add ":NAME => counter" to the symbol table, increment counter
				Use new ":NAME => value" entry to translate instruction
		If the instruction is "@value", translate as A-instruction
		If the instruction is a C-instruction, translate normally
		To translate the instruction, calculate the decimal value of the line and send to to_bin(), write
		the result to the outfile
=end
def pass_two(tmpfile, symbol_table, outfile, dest_bits, cond_bits, jump_bits)
	counter = 16
	c_header = 57344											#decimal value of standard C-inst bits
	line_num = 0
	IO.foreach(tmpfile) { |line|
		line.chomp!
#		puts "#{line_num} #{line}".blue
		if line.match(/^\(.+\)/)								#if line matches "(NAME)", skip
			next
		end
		if line.match(/^\@\d+/)									#if line matches "@NUMBER" (@10)
			decimal = line.gsub!(/\@/, "").to_i
#			puts "	Found Value: #{decimal}".yellow
			to_bin(decimal, outfile)							#translate to machine code
		elsif line.match(/^\@\D+/)								#if line matches "@NAME" (@sum)
			variable = line.gsub!(/\@/, "").to_sym
#			puts "	Found Variable: #{variable}".yellow
			if symbol_table.include? variable
#				puts "		Variable exists in symbol table".green
				to_bin(symbol_table[variable], outfile)			#translate to machine code
			else
#				puts "		Adding variable to symbol table".red
				address = counter
				symbol_table[variable] = address
				counter += 1
#				puts "		symbol_table[#{variable}] => #{symbol_table[variable]}".green
				to_bin(symbol_table[variable], outfile)			#translate to machine code
			end
		else													#line is C-instruction?
#			puts "		Found C-instruction".green
			if line.include? ";"								#is jump instruction (cond;jump)
				line = line.split(";")							#line[0]=cond, line[1]=jump
				val = cond_bits[line[0]] + jump_bits[line[1]] + c_header
#				puts "		Value calculated: cond = #{line[0]}, jump = #{line[1]}, c_header = #{c_header}".blue
#				puts "		Instruction value: #{val}".yellow
				#This method does not allow the command "JMP" without being written as "0;JMP"
				to_bin(val, outfile)
			else												#is not jump (dest=cond)
				line = line.split("=")							#line[0]=dest, line[1]=cond
				val = dest_bits[line[0]] + cond_bits[line[1]] + c_header
#				puts "		Value calculated: dest = #{line[0]}, cond = #{line[1]}".blue
#				puts "		Instruction value: #{val}".yellow
				to_bin(val, outfile)
			end
		end
		line_num += 1
	}
end



# MAIN
if ARGV.length != 2								#check for two CLAs
	puts "	[!] Invalid number of arguments".red
	usage()
elsif !File.exist?(ARGV[0])						#check that input file exists (negative check)
	puts "	[!] Unable to find input file".red
	usage()
else											#start translating
	infile = ARGV[0]
	outfile = ARGV[1]
	#tmpfile to write formatted code to
	#(hopefully this name isn't already a file... I should probably add stuff to plan for that...)
	tmpfile = "/tmp/assembler_tmpfile.tmp"

	format(infile, tmpfile)						#run format() to create tmpfile
	pass_one(tmpfile, symbol_table)				#do first pass
	pass_two(tmpfile, symbol_table, outfile, dest_bits, cond_bits, jump_bits)	#do second pass

#	puts symbol_table

	File.delete(tmpfile)
end
