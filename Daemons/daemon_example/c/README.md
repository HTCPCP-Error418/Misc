# Creating Daemons

## Table of Contents
* [Basic Structure](#basic-daemon-structure)
   * [Forking from the Parent Process](#forking-from-the-parent-process)
   * [Changing the File Mode Mask](#changing-the-file-mode-mask)
   * [Opening Logs and Files](#opening-logs-and-files)
   * [Creating a Unique Session ID](#creating-a-unique-session-id-(sid))
   * [Changing the Working Directory](#changing-the-working-directory)
   * [Closing Standard File Descriptors](#closing-standard-file-descriptors)
   * [Execute Daemon Code](#execute-daemon-code)
   * [Additional Links](#additional-links)
* [Daemon Files](#daemon-files)
   * [File Descriptions](#file-descriptions)
   * [File Locations](#file-locations)

## Basic Daemon Structure

When a daemon starts, it has to complete some low-level tasks to accommodate autonomy:
* Fork from the parent process
   * Kill the parent process
   * Record the new Process ID (PID)
* Change the file mode mask (umask 0)
* Open any logs and files
* Create a unique Session ID (SID)
* Change the current working directory
* Close standard file descriptors
* Execute daemon code

When writing a daemon all code must be written as defensively as possible. Any code that can be error checked should be error checked.
Additionally, error messages should be relatively verbose, as troubleshooting a malfunctioning daemon can be very intensive.

The libraries needed for the skeleton daemon are:
* unistd.h
* stdlib.h
* stdio.h
* sys/stat.h

The full code for this example daemon is available in this repository. Please note that the code in the full example may have changed from
the code written in this guide. I will get around to updating it eventually...

### Forking from the Parent Process

```c
pid_t pid;

pid = fork();			//fork() returns the new PID on success or -1 on failure
if (pid < 0) {
	fprintf(stderr, "Error forking from parent process\n");
	exit(EXIT_FAILURE);
}
if (pid > 0) {			//if the fork is successful, the parent process should exit gracefully
	exit(EXIT_SUCCESS);	//we will write the new PID to a file later
}
```

### Changing the File Mode Mask (umask)

```c
pid_t pid;

pid = fork();            //fork() returns the new PID on success or -1 on failure
if (pid < 0) {                                                       
     fprintf(stderr, "Error forking from parent process\n");
     exit(EXIT_FAILURE);
}
if (pid > 0) {           //if the fork is successful, the parent process should exit gracefully
     exit(EXIT_SUCCESS); //we will write the new PID to a file later
}

umask(0);				//setting the umask to 0 will remove all restrictions from created logs and directories
```

### Opening Logs and Files

If writing daemon code in C, do not forget to check the pointer and close the file at the end of your code

```c
pid_t pid;

pid = fork();            //fork() returns the new PID on success or -1 on failure
if (pid < 0) {                                                       
     fprintf(stderr, "Error forking from parent process\n");
     exit(EXIT_FAILURE);
}
if (pid > 0) {           //if the fork is successful, the parent process should exit gracefully
     exit(EXIT_SUCCESS); //we will write the new PID to a file later
}

umask(0);                //setting the umask to 0 will remove all restrictions from created logs and directories

char *logfile = "log.txt";			//set the logfile
FILE *log = fopen(logfile, "a+");		//"a+" opens the log file in "append" mode and creates the file if it doesn't exist
if (log == NULL) {					//file pointer will be NULL if the file was unable to be opened
	fprintf(stderr, "Error opening logfile: %s\n", logfile);
	exit(EXIT_FAILURE);
}
char *pidlog = "daemon.pid";			//set the file to save the PID
FILE *pidfile = fopen(pidlog, "w+");	//since we only need to write the newest PID to the file, we can overwrite anything there
if (pidfile == NULL) {
	fprintf(stderr, "Error opening pidfile: %s\n", pidlog);
	exit(EXIT_FAILURE);
} else {							//if the file was opened successfully, write the PID and close the file
	fprintf(pidfile, "%d", pid);
	fclose(pidfile);
}
```

### Creating a Unique Session ID (SID)

Without a unique Session ID, the child process will become an orphan in the system. The SID can also use the "pid_t" data type.

```c
pid_t pid, sid;		//sid is declared here

pid = fork();            //fork() returns the new PID on success or -1 on failure
if (pid < 0) {
     fprintf(stderr, "Error forking from parent process\n");
     exit(EXIT_FAILURE);
}
if (pid > 0) {           //if the fork is successful, the parent process should exit gracefully
     exit(EXIT_SUCCESS); //we will write the new PID to a file later
}

umask(0);                //setting the umask to 0 will remove all restrictions from created logs and directories

char *logfile = "log.txt";	          //set the logfile
FILE *log = fopen(logfile, "a+");	     //"a+" opens the log file in "append" mode and creates the file if it doesn't exist
if (log == NULL) {	                    //file pointer will be NULL if the file was unable to be opened
     fprintf(stderr, "Error opening logfile: %s\n", logfile);
     exit(EXIT_FAILURE);
} else {                                //if the file was opened successfully, write the PID and close the file
     fprintf(pidfile, "%d", pid);
     fclose(pidfile);
}

sid = setsid();		//setsid() returns the new SID on success or -1 on failure
if (sid < 0) {
	fputs("Error creating new SID\n", log);
	exit(EXIT_FAILURE);
}
```

### Changing the Working Directory

The current working directory for the daemon should be changed to a location that is guaranteed to exist. The only directory that is
guaranteed in all Linux distributions is root ("/"); however, service installation and startup scripts can be used to check for and
create required directories. This example will use the file system root.

```c
pid_t pid, sid;          //sid is declared here

pid = fork();            //fork() returns the new PID on success or -1 on failure
if (pid < 0) {
     fprintf(stderr, "Error forking from parent process\n");
     exit(EXIT_FAILURE);
}
if (pid > 0) {           //if the fork is successful, the parent process should exit gracefully
     exit(EXIT_SUCCESS); //we will write the new PID to a file later
}

umask(0);                //setting the umask to 0 will remove all restrictions from created logs and directories

char *logfile = "log.txt";		     //set the logfile
FILE *log = fopen(logfile, "a+");	     //"a+" opens the log file in "append" mode and creates the file if it doesn't exist
if (log == NULL) {	                    //file pointer will be NULL if the file was unable to be opened
     fprintf(stderr, "Error opening logfile: %s\n", logfile);
     exit(EXIT_FAILURE);
} else {                                //if the file was opened successfully, write the PID and close the file
     fprintf(pidfile, "%d", pid);
     fclose(pidfile);
}

sid = setsid();	          //setsid() returns the new SID on success or -1 on failure
if (sid < 0) {
     fputs("Error creating new SID\n", log);
     exit(EXIT_FAILURE);
}

if ((chdir("/")) < 0 ){		//chdir will return -1 on failure
	fputs("Error changing directory to system root\n", log);
	exit(EXIT_FAILURE);
}
```

### Closing Standard File Descriptors

Since a daemon cannot use the terminal, standard file descriptors are redundant and may pose a security issue.
`close()` can be used to close these descriptors.

```c
pid_t pid, sid;          //sid is declared here

pid = fork();            //fork() returns the new PID on success or -1 on failure
if (pid < 0) {
     fprintf(stderr, "Error forking from parent process\n");
     exit(EXIT_FAILURE);
}
if (pid > 0) {           //if the fork is successful, the parent process should exit gracefully
     exit(EXIT_SUCCESS); //we will write the new PID to a file later
}

umask(0);                //setting the umask to 0 will remove all restrictions from created logs and directories

char *logfile = "log.txt";              //set the logfile
FILE *log = fopen(logfile, "a+");       //"a+" opens the log file in "append" mode and creates the file if it doesn't exist
if (log == NULL) {                      //file pointer will be NULL if the file was unable to be opened
     fprintf(stderr, "Error opening logfile: %s\n", logfile);
     exit(EXIT_FAILURE);
} else {                                //if the file was opened successfully, write the PID and close the file
     fprintf(pidfile, "%d", pid);
     fclose(pidfile);
}

sid = setsid();               //setsid() returns the new SID on success or -1 on failure
if (sid < 0) {
     fputs("Error creating new SID\n", log);
     exit(EXIT_FAILURE);
}

if ((chdir("/")) < 0 ){       //chdir will return -1 on failure
     fputs("Error changing directory to system root\n", log);
     exit(EXIT_FAILURE);
}

close(STDIN_FILENO);
close(STDOUT_FILENO);
close(STDERR_FILENO);
```

### Execute Daemon Code

Daemon code is written in an infinite `while()` loop. The control script created for the daemon will read the
Process ID from the pidfile we created and use `kill` to stop the daemon when it is requested by the user.

```c
pid_t pid, sid;          //sid is declared here

pid = fork();            //fork() returns the new PID on success or -1 on failure
if (pid < 0) {
     fprintf(stderr, "Error forking from parent process\n");
     exit(EXIT_FAILURE);
}
if (pid > 0) {           //if the fork is successful, the parent process should exit gracefully
     exit(EXIT_SUCCESS); //we will write the new PID to a file later
}

umask(0);                //setting the umask to 0 will remove all restrictions from created logs and directories

char *logfile = "log.txt";              //set the logfile
FILE *log = fopen(logfile, "a+");       //"a+" opens the log file in "append" mode and creates the file if it doesn't exist
if (log == NULL) {                      //file pointer will be NULL if the file was unable to be opened
     fprintf(stderr, "Error opening logfile: %s\n", logfile);
     exit(EXIT_FAILURE);
} else {                                //if the file was opened successfully, write the PID and close the file
     fprintf(pidfile, "%d", pid);
     fclose(pidfile);
}

sid = setsid();               //setsid() returns the new SID on success or -1 on failure
if (sid < 0) {
     fputs("Error creating new SID\n", log);
     exit(EXIT_FAILURE);
}

if ((chdir("/")) < 0 ){       //chdir will return -1 on failure
     fputs("Error changing directory to system root\n", log);
     exit(EXIT_FAILURE);
}

close(STDIN_FILENO);
close(STDOUT_FILENO);
close(STDERR_FILENO);

while (1) {
	//DAEMON CODE
	sleep(15);			//execute the daemon code every 15 seconds
}
```

### Additional Links
* [Linux Daemon How To](http://www.netzmafia.de/skripten/unix/linux-daemon-howto.html)
* [Systemd Unit Files](https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files)
* [Creating Systemd Services (With Control Script Example)](https://www.ubuntudoc.com/how-to-create-new-service-with-systemd/)


# Daemon Files

## File Descriptions

Depending on the purpose of the daemon and the way it is coded, different files may be needed. The files below are general files that can be used when creating a daemon.
Examples of all files are available in this repo.

| File                   | Description                                                                                                       |
| :--------------------: | :---------------------------------------------------------------------------------------------------------------- |
| `my_daemon`            | Actual daemon code (compiled C code in this example)                                                              |
| `install.sh`           | Install script used to created the needed directories and check for/install dependencies                          |
| `my_daemon.service`    | The Unit file for `systemd`, providing the description and requirements for the service                           |
| `my_daemon_control.sh` | The script that is used to interact with the daemon, providing `start`, `stop`, `restart`, and `status` functions |
| `my_daemon.conf`       | The configuration file for the script, allowing users to customize the daemon                                     |
| `my_daemon.lock`       | The lockfile for the daemon, preventing the daemon from executing if the instance before it has not completed     |
| `my_daemon.pid`        | The PID file contains the Process ID for the daemon, allowing the control script to read the file and kill it     |

## File Locations

```
   /
   |-- /var/
   |    |-- /lock/
   |    |    |-- my_daemon.lock
   |    |-- /run/
   |    |    |-- /my_daemon/
   |    |    |    |-- my_daemon.pid
   |
   |-- /usr/
   |    |-- /local/
   |    |    |-- /bin/
   |    |    |    |-- my_daemon
   |
   |-- /etc/
   |    |-- /my_daemon/
   |    |    |-- my_daemon.conf
   |    |-- /init.d/
   |    |    |-- my_daemon_control.sh
   |    |-- /systemd/
   |    |    |-- /system/
   |    |    |    |-- my_daemon.service
```
