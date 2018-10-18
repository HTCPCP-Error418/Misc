#!/usr/bin/env ruby

=begin
	This script is designed to utilize the 'speedtest-cli' program to log the current connection
	properties (ping, upload, download) every 15 minutes outputting the results to a log file and
	creating a graph.

	Required software:
		Ruby						apt install ruby-full
		Rubygems					https://rubygems.org/rubygems/rubygems-x.x.x.zip; rubygems-x.x.x/setup.rb
		Gruff						gem install gruff
			libmagickwand-dev		apt install libmagickwand-dev
			imagemagick				apt install imagemagick
		python						apt install python3.5
		Speedtest-cli				https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py

	Find Speedtest Server ID:
		https://www.speedtestserver.com/
=end

#required gems
require 'gruff'
require 'date'
require 'fileutils'

#config options
$LOG_DIR = "/opt/net_stat/logs"
$ULOG = "#{$LOG_DIR}/up.log"
$DLOG = "#{$LOG_DIR}/down.log"
$PLOG = "#{$LOG_DIR}/ping.log"
$interval = 900						#15 min == 900 sec
#server = "6421"									#document server ID (variable not used)
#speedtest = "/opt/netsat/speedtest-cli.py"			#document location of speedtest-cli.py (variable not used)


def error_check
	#check for log dir
	if Dir.exist?("#{$LOG_DIR}") == false
		puts "LOG_DIR not found, please create the directory path"
	end
end

def speedtest
	#create speedtest command -- selects ping | download | upload
	speedtest = '/opt/netstat/speedtest-cli.py --server 6421 --csv --csv-delimiter ";" | cut -d ";" -f 6,7,8'

	#test variables -- run test 3 times for good data
	test0 = ""
	test1 = ""
	test2 = ""

	#run 3 speed tests and get average
	counter = 0
	while counter < 3
		speed_results = `#{speedtest}`

		if counter == 0
			test0 = "#{speed_results}".split(';')
		elsif counter == 1
			test1 = "#{speed_results}".split(';')
		elsif counter == 2
			test2 = "#{speed_results}".split(';')
		end

		counter += 1
	end

	#get averages
	ping = (test0[0].to_f + test1[0].to_f + test2[0].to_f) / 3
	down = (test0[1].to_f + test1[1].to_f + test2[1].to_f) / 3
	up = (test0[2].to_f + test1[2].to_f + test2[2].to_f) / 3

	#write values to log files
	File.open("#{DLOG}", "a+") { |file|
		file.write(Time.now.strftime("%m-%d-%Y;%T;"))
		file.write(down)
	}
	File.open("#{ULOG}", "a+") { |file|
		file.write(Time.now.strftime("%m-%d-%Y;%T;"))
		file.write(up)
	}
	File.open("#{PLOG}", "a+") { |file|
		file.write(Time.now.strftime("%m-%d-%Y;%T"))
		file.write(ping)
	}

	#output results to terminal
	puts "Time:		#{Time.now.strftime("%m-%d-%Y  %T")}"
	puts "Ping:		#{ping}"
	puts "Down:		#{down}"
	puts "Up:		#{up}"
	puts ""
end

#make graphs
def graph
	ping = []
	down = []
	up = []

	#trim to only 14 days of entries in single log file (testing download logs)
	lines = `wc -l "#{DLOG}"`.strip.split(' ')[0].to_i

	#should only be 1344 lines for 2 weeks
	#FIGURE OUT HOW TO KEEP ARCHIVE LOGS
	if lines > 1344
		#trim download log
		File.rename("#{DLOG}", "download.old")
		last_lines = `tail -n 1344 "download.old"`
		File.open("#{DLOG}", "a+") { |file|
			file.write(last_lines)
		}
		File.delete("download.old")

		#trim upload log
		File.rename("#{ULOG}", "upload.old")
		last_lines = `tail -n 1344 "upload.old"`
		File.open("#{ULOG}", "a+") { |file|
			file.write(last_lines)
		}
		File.delete("upload.old")

		#trip ping log
		File.rename("#{PLOG}", "ping.old")
		last_lines = `tail -n 1344 "ping.old"`
		File.open("#{PLOG}", "a+") { |file|
			file.write(last_lines)
		}
		File.delete("ping.old")
	end

	#get information from logs, formatted for graphing
	#download logs
	IO.readlines("#{DLOG}", chomp: true).each { |line|
		#format: | date | time | speed (Mbps) |
		line = line.split(';')
		speed = line[2].to_f / 1000000		#bps to Mbps
		speed = speed.round(2)				#round to 2 decimal places
		down.push speed
	}

	#upload logs
	IO.readlines("#{ULOG}", chomp: true).each { |line|
		#format: | date | time | speed (Mbps) |
		line = line.split(';')
		speed = line[2].to_f / 1000000
		speed = speed.round(2)
		up.push speed
	}

	#ping logs
	IO.readlines("#{PLOG}", chomp: true).each { |line|
		#format: | date | time | speed (ms) |
		line = line.split(';')
		speed = line[2].to_f
		speed = speed.round(2)
		ping.push speed
	}

	#build graph
	g = Gruff::Line.new('1200x600')
		g.title = 'Last 2 Weeks'
		g.labels = {
			#line => day (96 lines/day)
			0 => 14,
			96 => 13,
			192 => 12,
			288 => 11,
			384 => 10,
			480 => 9,
			576 => 8,
			672 => 7,
			768 => 6,
			864 => 5,
			960 => 4,
			1056 => 3,
			1152 => 2,
			1248 => 1
		}
		g.y_axis_label = 'Speed (Mbps || ms)'
		g.x_axis_label = 'Days Ago'
		g.minimum_value = 0
		g.maximum_value = 130		#max out the graph at 130 Mbps
		g.baseline_value = 100		#expect 100 Mbps
		g.y_axis_increment = 10
		g.line_width = 2
		g.dot_radius = 1

		g.data('Download', down)
		g.data('Upload', up)
		g.data('Ping', ping)
		g.write("#{$LOG_DIR}/graph.png")
end


############# MAIN #############
error_check
while 1
	speedtest
	graph
	sleep $interval
end
