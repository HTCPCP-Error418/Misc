#!/usr/bin/env ruby

=begin
	This script will take all inputted files, extract all text (with Tika) and
	put the content into the JSON file.

	NOTE: I have not had time to implement much error checking. I will try to put
	all of the critical stuff as a global variable so it is easy to verify.
=end

#required gems
require 'json'
require 'optparse'
require 'find'
require 'progress_bar'
require 'rubygems'
require 'zip'

#global variables
$tika = "java -jar /opt/tika-1.18/tika-app/target/tika-app-1.18.jar -t"


$error = ""		#error.log file pointer
$skip = ""		#skipped.log file pointer
$out = ""			#out.json file pointer
$tree = []		#array of all objects in directory tree
$tree_len = 0		#number of entries in directory tree
$zip_file_count = 0	#number of entries in zip file
$extensions = []	#array to hold found extensions

#file extension whitelist
$whitelist = [
	"pdf",
	"txt",
	"rtf",
	"html",
	"msg",
	"xls",
	"xlsx",
	"xlsx",
	"xlsm",
	"doc",
	"docx",
	"docm"
]

#json structure
$json_struct = {
	:original_source => "",
	:date => "",
	:body => ""
}

#command line arguments
$options = {
	:index => 0,
	:dir => "",
	:zip => "",
	:verbose => false,
	:error_path => "./error.log",
	:skip_path => "./skipped.log",
	:json_path => "./out.json",
	:ext_path => "./extensions.txt"
}

#basic housekeeping stuff, you can ignore everything between here and the functions
ARGV << '-h' if ARGV.empty?

#parse options
parser = OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} [ -d [directory] | -z [file] ] [options]"
	opts.separator ""
	opts.separator "Options:"
	opts.on('-d', '--dir [DIRECTORY]', ': Target directory') { |dir|
		$options[:dir] = dir
	}
	opts.on('-z', '--zip [FILE]', ': Target zip file [EXPERIMENTAL]') { |zip|
		$options[:zip] = zip
	}
	opts.on('-i', '--index-start [NUMBER]', ': Start value for index numbers (Default: 0)') { |num|
		$options[:index] = num.to_i
	}
	opts.on('--error-path [PATH/TO/FILE]', ': File to write errors to') { |err|
		$options[:error_path] = err
	}
	opts.on('--skip-path [PATH/TO/FILE]', ': File to write skipped file names to') { |skip|
		$options[:skip_path] = skip
	}
	opts.on('--json-path [PATH/TO/FILE]', ': File to write JSON to') { |json|
		$options[:json_path] = json
	}
	opts.on('--ext-path [PATH/TO/FILE]', ': File to write all found extensions to') { |ext|
		$options[:ext_path] = ext
	}
	opts.on('--print-whitelist', ': Print file types currently in the whitelist') {
		count = 0
		while count < ($whitelist.length - 1)
			print "#{$whitelist[count]}, "
			count += 1
		end
		puts $whitelist[count]
		exit(0)
	}
	opts.on('--clean', ': Remove error, json, and extension files generated in previous runs') {
		clean
		exit(0)
	}
	opts.on('-v', '--verbose', ': Display verbose (debug) messages') {
		$options[:verbose] = true
	}
	opts.on('-h', '--help', ': Display this help dialogue and exit') {
		puts opts
		exit(0)
	}
	opts.separator ""
end
parser.parse!

class String
	def colorize(color_code)
		"\e[01;#{color_code}m#{self}\e[0m"
	end
	def red				#errors
		colorize(31)
	end
	def green				#debug messages
		colorize(32)
	end
end


########### FUNCTIONS ###########

#clean option
def clean
	#create array to make randomly changing confirmation words
	confirm_array = ["DESTROY", "DELETE", "YES", "PURGE", "REMOVE", "CONFIRM"]

	puts "                          [!] WARNING [!]".red
	puts "--------------------------===============----------------------------".red
	puts "[!]          ALL DATA FROM PREVIOUS RUNS WILL BE DELETED          [!]".red
	puts "[!] PLEASE CONFIRM THAT THIS IS THE ACTION YOU WOULD LIKE TO TAKE [!]".red
	puts ""
	confirm_word = confirm_array[rand(6)]
	puts "[!] TO CONFIRM, PLEASE TYPE: #{confirm_word}".red
	confirm_input = gets.chomp.upcase

	if confirm_input == confirm_word
		puts "[!] REMOVING FILES".red
		`rm #{$options[:error_path]}`
		`rm #{$options[:skip_path]}`
		`rm #{$options[:json_path]}`
		`rm #{$options[:ext_path]}`
	end

	puts "[!] FILES REMOVED, EXITING".red
end

#dry run option
def dry_run
	#TODO
end

#fatal error (exit script)
def fatal_error(error)
	puts "[!] ERROR -- #{error}".red
	exit(1)
end

#very basic error checks
def error_checks
	#make sure user specified a zip or directory
	if ($options[:zip] == nil) && ($options[:dir] == nil)
		fatal_error("No directory or zip file specified")
	end
	if ($options[:zip] != "") && ($options[:dir] != "")
		fatal_error("Only one target (dir or zip) can be specified")
	end

#	#check if tika path is correct
#	if File.file?($tika) == false
#		fatal_error("Unable to find Tika, please edit the script variable")
#	end
end

def display_options
	puts ""
	puts "Starting index:	#{$options[:index]}".green
	puts "Zip file:	#{$options[:zip]}".green if $options[:zip] != nil
	puts "Directory:	#{$options[:dir]}".green if $options[:dir] != nil
	puts "Error log:	#{$options[:error_path]}".green
	puts "Skipped log:	#{$options[:skip_path]}".green
	puts "JSON file:	#{$options[:json_path]}".green
	puts "Ext list:	#{$options[:ext_path]}".green
	puts ""
	puts "Whitelisted file types:".green
	count = 0
	while count < $whitelist.length
		puts "  #{$whitelist[count]}".green
		count += 1
	end
	puts ""
end

def open_files
	#open error log
	$error = File.open("#{$options[:error_path]}", "a+")
	#open skipped log
	$skip = File.open("#{$options[:skip_path]}", "a+")
	#open json file
	$out = File.open("#{$options[:json_path]}", "a+")
end

#get full directory tree
def get_tree
	count = 0
	Find.find("#{$options[:dir]}") { |obj|
		$tree[count] = obj
		count += 1
	}
	$tree_len = count
	$progress = ProgressBar.new(count) if $options[:verbose] == true
	puts "#{count} files found".green if $options[:verbose] == true
end

#get number of entries in zip file
def get_zip_count
	count = 0
	Zip::File.open($options[:zip]) { |zip_file|
		zip_file.each { |file|
			count += 1
		}
	}
	$zip_file_count = count
end

#get file info
def get_info(file)
	$json_struct[:original_source] = file
	$json_struct[:date] = File.stat("#{$json_struct[:original_source]}").ctime
end

def get_body(file)
	#escape special characters (to hopefully stop problems...)
	escaped_file = file.gsub(/ /, '\ ').gsub(/[\(]/, '\(').gsub(/[\)]/, '\)')
	$json_struct[:body] = `#{$tika} #{escaped_file} 2> /dev/null`
end

#function for writing the path of skipped files
def write_skip(file)
	$skip.write("#{file}\n")
end

#write the current index to out.json
def write_index
	$out.write("\{\"index\"\:\{\"_id\"\:#{$options[:index]}\}\}\n")
	$options[:index] += 1
end

#write everything to out.json
def write_json
	write_index
	$out.puts $json_struct.to_json
end

def display_metrics
	puts "Last index:	#{$options[:index] - 1}".green
	skipped = `wc -l "#{$options[:skip_path]}"`.strip.split(' ')[0].to_i
	puts "Files skipped:	#{skipped}".green
end

#write found extensions to a file (allowing you to expand the whitelist)
def write_ext_list
	list = File.open("#{$options[:ext_path]}", "w+")
	list.puts $extensions
	list.close
end

def close_files
	#close error log
	$error.close
	#close skipped log
	$skip.close
	#close json file
	$out.close
end


########## MAIN ##########
error_checks
display_options if $options[:verbose] == true
open_files

#dir magic
if $options[:dir] != ""
	get_tree
	for file in $tree
		if File.file?(file)										#this is the best line of code i've ever written (gets rid of directories)
			path_string = file.to_s

			#skip files that don't have extensions
			if path_string.include? '.'
				path_string = path_string.split('.')
				len = path_string.length
				extension = path_string[len - 1].downcase			#extension for the file

				if extension.length <= 4							#most extensions are under 5 characters, you get a lot of garbage without this
					#build array of found extensions
					if (($extensions.include? extension) == false)
						$extensions.push(extension)
					end

					#if extension is in the whitelist, magic it
					if $whitelist.include? extension
						file = File.absolute_path(file)
						get_info(file)
						get_body(file)
						write_json
					else
						#skip the file and log the full path
						write_skip(file)
					end
				else
					#something is wrong with the extension, skip it and log the path
					write_skip(file)
				end
			else
				#file doesn't have extension, skip it and log the path
				write_skip(file)
			end
		end
		$progress.increment! if $options[:verbose] == true
	end
end

#zip magic
if $options[:zip] != ""
	Zip::File.open($options[:zip]) do |zip_file|
		#for each file in zip
		zip_file.each do |file|
			if file.file?
				#get file path?
				path_string = file.to_s

				#skip files that don't have extensions
				if path_string.include? '.'
					#get the extension
					path_string = path_string.split('.')
					len = path_string.length
					extension = path_string[len - 1].downcase

					if extension.length <= 4
						#build array of found extensions
						if ($extensions.include? extension) == false
							$extensions.push(extension)
						end

						#if extension is in the whitelist, magic it
						if $whitelist.include? extension
							file = File.absolute_path(file)		#can I get the filepath of a file inside a zip?
							get_info(file)
							get_body(file)
							write_json
						else
							#extension is not in whitelist, skip and log it
							write_skip(file)
						end
					else
						#something is wrong with the extension, skip it and log the path
						write_skip(file)
					end
				else
					#file doesn't have an extension, skip and log it
					write_skip(file)
				end
			elsif file.directory?
				#do nothing
			else
				#write error
				write_error(file)
			end
			$progress.increment! if $options[:verbose] == true
		end
	end
end

write_ext_list
close_files
display_metrics if $options[:verbose] == true
exit(0)
