// This test daemon is meant to be an example of a working daemon. It will generate a log
// entry every x seconds until stopped.

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <syslog.h>
#include <string.h>

//global variables (from configuration file)
char *logfile = NULL;
char *pidfile = NULL;
int interval = 15;		//defaults to 15 seconds

int read_configs(void);


int main(void) {
	pid_t pid, sid;

	//fork off parent process
	fprintf(stderr, "Forking from parent\n");
	pid = fork();
	if (pid < 0) {
		//child not created
		fprintf(stderr, "Failure creating child\n");
		exit(EXIT_FAILURE);
	}
	if (pid > 0) {
		fprintf(stderr, "Child created successfully\n");
		//child created
		exit(EXIT_SUCCESS);
	}

	//change the umask for the daemon
	umask(0);

	//open log file
	FILE *log = fopen(logfile, "a+");
	//make sure file opened correctly
	if (log == NULL) {
		fprintf(stderr, "Error opening logfile: %s\n", logfile);
		exit(EXIT_FAILURE);
	}

	//record Process ID
	FILE *pidlog = fopen(pidfile, "w+");
	if (pidlog == NULL) {
		fprintf(stderr, "Error opening pidfile: %s\n", pidfile);
		exit(EXIT_FAILURE);
	} else {			//if pidfile was opened successfully, write the PID and close the file
		fprintf(pidlog, "%d", pid);
		fclose(pidlog);
	}

	//create a new sid for the child process
	sid = setsid();
	if (sid < 0) {
		//log failure
		fprintf(log, "Error creating new sid\n");
		exit(EXIT_FAILURE);
	}

	//change the current working directory
	if ((chdir("/")) < 0) {
		//log failure
		fprintf(log, "Error changing directory\n");
		exit(EXIT_FAILURE);
	}

	//close standard file descriptors
	close(STDIN_FILENO);
	close(STDOUT_FILENO);
	close(STDERR_FILENO);


	//DAEMON CODE
	while (1) {
		fprintf(log, "my_daemon is running\n");
		sleep(15); //perform task again in 15 seconds
	}



	//close log file
	fclose(log);

	//daemon finished, exit gracefully
	exit(EXIT_SUCCESS);
}

int read_configs(void) {
	//open configuration file and check pointer
	FILE *confptr = fopen("/etc/my_daemon/my_daemon.conf", "r");
	if (confptr == NULL) {
		fprintf(stderr, "Error reading config file: /etc/my_daemon/my_daemon.conf\n");
		exit(EXIT_FAILURE);
	}

}
