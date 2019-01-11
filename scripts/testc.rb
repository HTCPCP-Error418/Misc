#!/usr/bin/env ruby

=begin
	This script is designed to augment GCC so I don't have to write the full command when
	compiling and testing C programs. Since I'm not a dev, this script does not really
	consider non-standard libraries or anything too advanced. That stuff will probably be
	added when/if I ever need it. Regardless, this script is probably useless to everyone
	else...

	TODO: Test passing runopts to compiled program

=end

require 'optparse'

#dumb stuff
class String
	#usage: puts "string".[color]
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

#PARSE OPTIONS
#if no options are given, print help
ARGV << '-h' if ARGV.empty?

#create options hash
options = {
	:infile => "",
	:path => "",
	:runopts => "",
	:outfile => "",
	:verbose => false,
}

parser = OptionParser.new do |opts|
	opts.version = 'v1.1'
	opts.release = 'r1'
	opts.set_program_name('testc')
	opts.banner = "Usage: #{$0} [options]".blue
	opts.separator "	Ex. #{$0} -f [file_name].c -o [outfile_name] -r \"[run_options]\"".blue
	opts.separator ""

	opts.separator "Required Options:".blue
	opts.on('-f', '--file [file_name].c', ':	Name of C file to be compiled and run') do |op|
		options[:infile] = op
		options[:path] = File.dirname(File.expand_path(op))
	end
	opts.separator ""

	opts.separator "Additional Test Options:".blue
	opts.on('-r', '--run_opts "[run_options]"', ':	Options to be passed when running C program') do |op|
		options[:runopts] = op
	end
	opts.on('-o', '--outfile [file_name]', ':	Overwrite default file name with "[file_name]"') do |op|
		options[:outfile] = op
	end
	opts.separator ""

	opts.separator "Other Options:".blue
	opts.on('-h', '--help', ':	Print this help dialogue and exit') do
		puts opts
		exit(0)
	end
	opts.on('-v', '--version', ':	Print version information and exit') do
		puts opts.ver()
		exit(0)
	end
	opts.on('-vv', '--verbose', ':	Print verbose status messages (debug messages)') do |op|
		options[:verbose] = true
	end
end
parser.parse!

#error checks
if options[:infile].empty?
	abort("[!]	Input file must be specified.".red)
end

#compile program
def compile(infile, outfile)
	`gcc -o #{outfile} #{infile}`

	if $?.exitstatus == 0
		puts "[+]	Program compiled successfully.".green
	else
		abort("[!]	Error compiling program.".red)
	end
end



######################################################
##---------------------- MAIN ----------------------##
######################################################

#if no outfile name specified, use default
if options[:outfile].empty?
	options[:outfile] = File.basename(options[:infile],File.extname(options[:infile]))
end

#expand file paths
options[:infile] = "#{options[:path]}/#{options[:infile]}"
options[:outfile] = "#{options[:path]}/#{options[:outfile]}"

#DEBUG
if options[:verbose]
	puts "File Name:	#{options[:infile]}".yellow
	puts "Outfile:  	#{options[:outfile]}".yellow
	puts "File Path:	#{options[:path]}".yellow
	puts "Run Opts: 	#{options[:runopts]}".yellow
	puts "Verbose:  	#{options[:verbose]}".yellow
end

compile(options[:infile], options[:outfile])

#run program
if options[:runopts].empty?
	`gnome-terminal -- bash -c "#{options[:outfile]}; bash;"`
else
	`gnome-terminal -- bash -c "#{options[:outfile]} #{options[:runopts]}; bash;"`
end
