#!/usr/bin/env ruby

require 'optparse'		#option parser
require 'fileutils'

options = {				#hash table for options and default values. Placing options here isn't required
	:interval => 600,	#but I like to have a list of all of my options somewhere so I don't forget any.
	:logfile => "/var/log/daemon.log",
	:pidfile => "/var/run/daemon.pid"
}

parser = OptionParser.new do |opts|
	opts.version = 'v1.0'
	opts.release = 'r1'
	opts.set_program_name('Daemon')
	opts.banner = "Usage: #{opts.program_name} [options]"
	opts.separator ""

	opts.on('-i', '--interval [NUM]', ': Time (in minutes) between each iteration of the daemon') do |op|
		options[:interval] = (op.to_i * 60)	#minutes to seconds for sleep()
	end
	opts.on('-l', '--logfile [PATH/FILE]', ': File name and path for log file',
		'	(Default: /var/log/daemon/daemon.log)') do |op|
		options[:logfile] = op
	end
	opts.on('-p', '--pidfile [PATH/FILE]', ': File name and path for PID file',
		'	(Default: /var/run/daemon/daemon.pid)') do |op|
		options[:pidfile] = op
	end
	opts.on('--quit', ': Gracefully shutdown daemon, if running (REQUIRES PIDFILE)') do
		if File.exists?(options[:pidfile])
			pid = File.read(options[:pidfile]).to_i
			Process.kill(3,pid)
		else
			puts "Unable to locate PID file. Please kill the process manually."
		end
		exit(0)
	end

	opts.on('-I', '--include [DIR]', ': Additional $LOAD_PATH directory (if required)') do |op|
		$LOAD_PATH.unshift(*op.split(":").map{|v| File.expand_path(v)})
	end
	opts.on('-h', '--help', ': Print this help dialogue and exit') do
		puts opts
		exit(0)
	end
	opts.on('-v', '--version', ': Print version information and exit') do
		puts opts.ver()
		exit(0)
	end
end
parser.parse!

require 'daemon'			#file containing main code

Daemon.new(options).run!
