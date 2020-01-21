# Ruby Daemons
Created while following post on https://codeincomplete.com/posts/ruby-daemons/

## Basic Daemon Tasks
When a daemon starts, it has to complete some low-level tasks to accommodate autonomy:
* Fork from the parent process twice, exiting the processes if successful
	* Record new Proccess ID (PID) to a PID file
* Change Session ID (SID)
* Change Current Working Directory to file system root ("/")
* Open/create log file
* Close standard file descriptors/redirect output

Forking from the parent process twice avoids issues with "zombie processes" where the parent process doesn't
receive the exit status from the child and never kills the process. By forking twice, the process is "adopted"
by `init` which will handle the exit status.

The new Process ID is recorded to allow a user to kill the process and prevent the daemon from becoming an
orphaned process. The normal location for PID files is `/var/run/`; however, writing to this location requires
root permissions. ~~To avoid requiring root permissions to run the program, an install script (running with root
permissions) can be used to create a folder in this directory (such as `/var/run/daemon/`) and set the folder
permissions to a level that will allow the daemon to write a PID file there.~~[NOTE](#notes-regarding-/var/run)

When the daemon process is killed, it should remove the PID file. Using this strategy also allows the daemon to
ensure that only one instance of the daemon is running at a time. To accomplish this, the daemon can check for
the existence of a PID file. If a PID file already exists, an instance of the daemon is already running and the
new instance can exit.

A new Session ID should be set to detach the process from the controlling terminal. This ensures that the
process remains running after the terminal session is terminated.

The Current Working Directory should be changed to a directory that is guaranteed to exist. The only directory
that is guaranteed to exist in all Unix systems is the file system root ("/"). For this reason, all file paths
provided by a user should be expanded and double-checked.

Utilizing log files allows the daemon to provide information to the user without needing a terminal session to
output messages. The normal location for log files is `/var/log/`; however, writing to this location requires
root permissions. This restriction can be overcome using the method mentioned for PID files above.

Additionally, using `/var/log/` to store the daemon's logs will also allow the use of `/etc/logrotate.d/` to
control automatic log rotation and retention.

Closing standard file descriptors prevents issues when the daemon attempts to output messages to a terminal.
The standard file descriptors can be opened to direct all output to the log file(s).

---
## Writing the Daemon
When creating a daemon, the code to execute must be contained in an infinite loop. This will allow the program
to run continuously. The example below will print a message every two seconds until the process is killed.

```rb
while true
	puts "Daemon is running"
	sleep(2)
end
```

When creating the daemon, it is best practice to separate the daemon controls from the main code that will be
executing. The daemon code is normally placed in the `/usr/local/lib/` directory, while the daemon control
script is normally placed in the `/usr/local/bin/` directory. In Ruby, a `class` containing the daemon code can
be created, simplifying the control script.

The two files that will be used in this example are:

| File             | Description                                                                             |
| :--------------: | :-------------------------------------------------------------------------------------- |
| `daemon.rb`      | File defining the `Daemon` class. Contains the main daemon code.                        |
| `daemon_ctrl.rb` | Control script for the daemon. Processes options and creates an instance of the daemon. |

### daemon.rb
```rb
class Daemon

	attr_reader :options				#read options passed from control script

	def initialize(options)				#initialize options
		@options = options
	end

	def run!							#define function that executes the code
		while true						#infinite worker loop from beginning
			puts "Daemon is running"
			sleep(2)					
		end
	end

end
```

### daemon_ctrl.rb
```rb
require 'daemon'						#require file containing main code

options = {}							#hash table to store options (we don't have any, yet)

Daemon.new(options).run!				#Start daemon
```
To run the daemon at this point, the $LOAD_PATH option with the directory of `daemon.rb` will need to be passed
to the Ruby interpreter. This option gives the interpreter the location to search in for the `require 'daemon'`
statement.

##### Example (both `daemon` and `daemon_ctrl` in `work_dir`):
```bash
.../work_dir$ ruby -I. daemon_ctrl.rb
Daemon is running
Daemon is running
	...
```
##### Example (`daemon` in `work_dir/lib`, `daemon_ctrl` in `work_dir/bin`):
```bash
.../work_dir$ ruby -Ilib bin/daemon_ctrl.rb
Daemon is running
Daemon is running
	...
```
---

## Adding Options
By using two separate files for the daemon, options can be parsed by the control script and passed to the
daemon code.

```rb
#!/usr/bin/env ruby

require 'optparse'				#option parser
require 'fileutils'

options = {
	:interval => 600,
	:logfile => "/var/log/daemon/daemon.log",
	:pidfile => "/var/run/daemon/daemon.pid",
}

parser = OptionParser.new do |opts|
	opts.version = 'v1.0'
	opts.release = 'r1'
	opts.set_program_name('Daemon')
	opts.banner = "Usage: #{opts.program_name} [options]"
	opts.separator ""

	opts.on('-i', '--interval [NUM]', ': Time (in minutes) between each iteration of the daemon',
		'	(Default: 10 minutes)') do |op|
		options[:interval] = (op.to_i * 60)
	end
	opts.on('-l', '--logfile [PATH/FILE]', ': File name and path for log file',
		'   (Default: /var/log/daemon/daemon.log)') do |op|
		options[:logfile] = op
	end
	opts.on('-p', '--pidfile [PATH/FILE]', ': File name and path for PID file',
		'   (Default: /var/run/daemon/daemon.pid)') do |op|
		options[:pidfile] = op
	end
	opts.on('--quit', ': Gracefully shutdown daemon, if running (REQUIRES PIDFILE)') do
		if File.exists?(options[:pidfile])			#make sure PID file exists before reading
			pid = File.read(options[:pidfile]).to_i	#read PID from PID file
			Process.kill(3,pid)						#send "QUIT" signal to daemon
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

require 'daemon'		#file containing main code

Daemon.new(options).run!
```
Notes:
* Listing the options and their default values when declaring the hash table is not required; however, I like
to have a list of all options somewhere to ensure that I don't forget any later.
* `--interval` can as for seconds and avoid the calculation; however, minutes will be easier for the user to
to enter (especially if the interval is particularly long).
* The `--include` option has been added to simplify running the script. The $LOAD_PATH for the daemon code can
now be specified as an argument to the control script, as opposed to providing it directly to the Ruby
interpreter.
	* When using this method `require 'daemon'` must be moved lower in the script to allow `optparse` to parse
	any provided load paths and provide them to the Ruby interpreter.
* A `--quit` option has been added to the control script (requiring `fileutils`). When implementing the options
in the daemon code, the "QUIT" signal will be trapped to allow a graceful shutdown of the daemon this option
will provide an easy way for the user to send the "QUIT" signal and shutdown the daemon. This code can also
be moved to the daemon class, if desired.

#### Example (both `daemon` and `daemon_ctrl` in `work_dir`):
```bash
.../work_dir$ ./run_class.rb -I.
Daemon is running
Daemon is running
	...
```
#### Example (`daemon` in `work_dir/lib`, `daemon_ctrl` in `work_dir/bin`):
```bash
work_dir$ ./run_class.rb -Ilib
Daemon is running
Daemon is running
	...
```
## Implementing Daemon Options
Now that the control script has the daemon options, the daemon code needs to implement these options, as well
as the rest of the general daemon requirements. The following functions need to be implemented in the Daemon
class:
* Expand any user-provided file paths/double-check files
* Process `--interval`
* Fork from parent process twice
* Record new PID
* Change SID
* Chance Current Working Directory
* Open/create log file
* Close standard file descriptors/redirect output
* Trap QUIT signal

```rb
require 'fileutils'

class Daemon

	def self.run!(options)
		Daemon.new(options).run!
	end

	attr_reader :options, :quit

	def initialize(options)
		@options = options

		#daemonizing script will change the working directory, so full paths should be used
		options[:logfile] = File.expand_path(options[:logfile])
		options[:pidfile] = File.expand_path(options[:pidfile])
	end

	#create main function to run daemon
	def run!
		puts "Starting Daemon..."		#signal to user that code is running before redirecting output
		check_pid
		daemonize
		write_pid
		trap_signals
		redirect_output

		#infinite loop
		while !quit							#we will provide "quit" later
			log "Daemon is running"			#replace with deamon's purpose
			sleep(options[:interval])		#run every [interval] seconds
		end
		log "Daemon is stopped"				#log that the daemon has stopped successfully
	end

	#create function to handle log format
	def log(msg)
		puts "[#{Process.pid}] [#{Time.now}] #{msg}"
	end

	#create function to check for existing PID file
	def pid_status(pidfile)
		return :exited unless File.exists?(pidfile)	#if PID file doesn't exist, daemon not running
		pid = File.read(pidfile).to_i				#if PID file exists, read the PID (cast to integer)
		return :dead if pid == 0					#if PID is 0, process is dead
		Process.kill(0, pid)						#throw error if process is owned by another user
		:running									#if no errors so far, process is running
	rescue Errno::ESRCH								#no such process
		:dead
	rescue Errno::EPERM								#operation not permitted (owned by another user)
		:not_owned
	end

	#create function to check if daemon is already running
	def check_pid
		case pid_status(options[:pidfile])
		when :running, :not_owned						#if process is running, inform user and exit
			puts "An instance is already running, Check #{options[:pidfile]}"
			exit(1)
		when :dead
			File.delete(options[:pidfile])				#if process is dead, remove PID file
		end
	end

	#create function to write PID file
	def write_pid
		begin			#create writable-only file, raise error if file exists
			File.open(options[:pidfile], ::File::CREAT | ::File::EXCL | ::File::WRONLY) { |f|
				f.write("#{Process.pid}")
			}
			at_exit { 	#delete PID file just before exiting the daemon  
				File.delete(options[:pidfile]) if File.exists?(options[:pidfile])
			}
		rescue Errno::EEXIST		#if file exists
			check_pid
			retry
		end
	end

	#create function to fork the process
	def daemonize
		exit if fork			#fork once
		Process.setsid			#set new SID
		exit if fork			#fork twice
		Dir.chdir "/"			#change working directory
	end

	#create function to catch QUIT signal and allow a graceful shutdown on next iteration
	def trap_signals
		trap(:QUIT) do			#when QUIT is received, make next loop evaluate to false
			@quit = true
		end
	end

	#create function to redirect output to log file
	def redirect_output
		#check if file/directory exist, make it if they do not
		if !File.directory?(File.dirname(options[:logfile]))
			FileUtils.mkdir_p(File.dirname(options[:logfile], :mode => 0755))
		end
		if !File.exists?(options[:logfile])
			FileUtils.touch options[:logfile]
			File.chmod(0644, options[:logfile])
		end

		#redirect stdout and stderr to log file
		$stderr.reopen(options[:logfile], 'a')		#redirect stderr to logfile in 'append' mode
		$stdout.reopen($stderr)						#redirect stdout to stderr
		$stdout.sync = $stderr.sync = true			#immediately write to file, no buffering
	end
end
```
---
The daemon should now be complete and ready to run.

---
## Notes Regarding /var/run
In some Linux distributions (seemingly any ones using `systemd`), some high-level directories are now `tmpfs`
and created at run time according to `.conf` files located in `/ect/tmpfiles.d/`, `/run/tmpfiles.d/`, and
`/usr/lib/tmpfiles.d/`. There are two ways to utilize `systemd` to create a directory for the PID file:

1. Use the install script to place `daemon.conf` (containing the directory to create)
in `/usr/lib/tmpfiles.d/` [(More info on tmpfiles.d here)](http://manpages.ubuntu.com/manpages/xenial/en/man5/tmpfiles.d.5.html)
2. Create a `systemd` service file to control the daemon (Which I will hopefully have in the C daemon example
at some point)
