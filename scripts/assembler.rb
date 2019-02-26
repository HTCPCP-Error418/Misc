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

def usage()
	puts "Usage: #{$0} [input file] [output file]".blue
	exit(0)
end

=begin
	First Pass:
	For each line in the format "(NAME)", add the pair ":NAME => address" to the symbol table.
	Address will be the line number following the declaration of the name.
=end
def pass_one(infile)
	File.foreach(infile).with_index do |line, line_num|
		line.chomp!
		if line.start_with? '//'
			puts "COMMENT".blue
		else
			puts line
		end
	end
end

=begin
	Second Pass:
	Set counter to 16 and scan the program again. For each instruction:
		If the instruction is "@NAME", search for NAME in symbol table
			If ":NAME => value" is found, use "value" to translate the instruction
			If not found, add ":NAME => counter" to the symbol table, increment counter
				Use new ":NAME => value" entry to translate instruction
		If the instruction is "@value", translate as A-instruction
		If the instruction is a C-instruction, translate normally
		Write translated instruction to file
=end
def pass_two(infile)

end

# MAIN
if ARGV.length != 2								#check for two CLAs
	puts "	[!] Invalid number of arguments".red
	usage()
elsif !File.exist?(ARGV[0])					#check that input file exists (negative check)
	puts "	[!] Unable to find input file".red
	usage()
else										#start translating
	infile = ARGV[0]
	#do first pass
	pass_one(infile)

	#do second pass

end


#do first pass
#do second pass
	#if error creating file, abort
