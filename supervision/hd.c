/*
 * Copyright (c) 2021 Arseniy "emptiedsoul" Lesin
 * 
 * This file is part of hardclanz-init
 * hardclanz-init, and all of its parts, excluding SysVInit
 * are published under terms of GNU GPLv3 or newer
 * 
 * See COPYING file or <https://gnu.org/license>
 */
#include <stdlib.h>
#include <errno.h>
#include <syslog.h>
#include <stdio.h>
#include <sys/signal.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <stdbool.h>
typedef enum _Mode {
	KEEP_ALIVE,
	ONCE,
	ON_FAIL,
	UNKNOWN
} Mode;
Mode mode 			= UNKNOWN;
int times 			= -1;
int waitsec 			= 0;
int status;
bool no_fork			= false;
char command[1024]		= "";
char service_dir[1024]		= "";
char hd_pidfile[1024]		= "";
char service_pidfile[1024]	= "";
char service_statfile[1024]	= "";
int opt;	
pid_t pid;
#define PRINT_USAGE() \
	puts("hd -k|-o|-f [-n] -w <seconds> -t <times> -s <script>");
void on_sig_hup(int sig){
	signal(sig, on_sig_hup);
	kill(pid, SIGHUP);
}
void on_sig_term(int sig){
	signal(sig, on_sig_term);
	waitsec = 0;
	times	= 0;		
	kill(pid, SIGTERM);	
}
void on_sig_usr1(int sig){
	signal(sig, on_sig_usr1);
	_exit(0);
}
void on_sig_usr2(int sig){	
	signal(sig, on_sig_usr2);
	waitsec = 0;
	times	= 0;
}
int main(int argc, char* argv[], char* envp[]){
	signal(SIGTERM, on_sig_term); 
	signal(SIGHUP, on_sig_hup);
	signal(SIGUSR1, on_sig_usr1);
	signal(SIGUSR2, on_sig_usr2);
	while((opt = getopt(argc, argv, "koft:w:s:n")) != -1){
		switch(opt){
			case 'k':
				mode = KEEP_ALIVE;
				break;
			case 'o':
				mode = ONCE;
				break;
			case 'f':
				mode = ON_FAIL;
				break;
			case 't':
				times = atoi(optarg);
				break;
			case 'w':
				waitsec = atoi(optarg);
				break;
			case 's':
				strncpy(command, optarg, 1024);
				break;
			case 'n':
				no_fork = true;
				break;
			default:
				PRINT_USAGE();
				exit(1);
				break;
		}
	}
	if (command[0] == '\0'){
		puts("hd: missing command");
		PRINT_USAGE();
		exit(1);
	}
	if (mode == UNKNOWN){
		puts("hd: missing mode");
		PRINT_USAGE();
		exit(1);
	}
	if (no_fork) goto supervising;
	switch(pid = fork()){
		case -1:
			perror("hd: fork");
			exit(1);
			break;
		case 0:
			setsid(); 
			supervising:
			openlog(NULL, LOG_PID, LOG_DAEMON); 
			syslog(LOG_INFO, "Started supervisor, pid=%d", getpid());
			snprintf(service_dir, 1024, "/run/service/%s", command);
			snprintf(hd_pidfile, 1024, "/run/service/%s/supervisor", command);
			snprintf(service_pidfile, 1024, "/run/service/%s/pid", command);
			snprintf(service_statfile, 1024, "/run/service/%s/status", command);
			mkdir(service_dir, 0755);
			FILE* hd_pidfile_fd 		= fopen(hd_pidfile, "w"); 
			FILE* service_pidfile_fd	= fopen(service_pidfile, "w"); 
			FILE* service_statfile_fd	= fopen(service_statfile, "w"); 
			restart: 
			switch(pid = fork()){
				case -1:
					syslog(LOG_ERR, "Failed to fork: %s", strerror(errno));
					closelog();
					exit(1);
					break;
				case 0:
					openlog(NULL, LOG_PID, LOG_DAEMON);
					syslog(LOG_INFO, "Executing: %s, pid=%d", command, getpid());
					closelog();
					FILE* hd_pidfile_fd 		= fopen(hd_pidfile, "w");
					FILE* service_pidfile_fd	= fopen(service_pidfile, "w");
					FILE* service_statfile_fd	= fopen(service_statfile, "w");
					fprintf(hd_pidfile_fd, "%d    ", getppid());
					fprintf(service_pidfile_fd, "%d    ", getpid());
					fprintf(service_statfile_fd, "%s    ", "running");
					fclose(hd_pidfile_fd);
					fclose(service_pidfile_fd);
					fclose(service_statfile_fd);
					if (execle(command, command, NULL, envp) == -1){
						openlog(NULL, LOG_PID, LOG_DAEMON);
						syslog(LOG_ERR, "Failed to execute %s: %s", command, strerror(errno));
						closelog();
						remove(hd_pidfile);
						remove(service_pidfile);
						service_statfile_fd = fopen(service_statfile, "w");
						fprintf(service_statfile_fd, "%s", "failed=exec");
						fclose(service_statfile_fd);
						exit(1);
					}
					break;
			}
			wait(&status);
			switch(mode){
				case ONCE:
					if (WIFEXITED(status)){
						fprintf(service_statfile_fd, "exited=%d ", WEXITSTATUS(status));
					}else{
						fprintf(service_statfile_fd, "killed      ");
					}
					syslog(LOG_INFO, "%s exited", command);
					closelog();
					fclose(hd_pidfile_fd);
					fclose(service_pidfile_fd);
					fclose(service_statfile_fd);
					remove(hd_pidfile);
					remove(service_pidfile);
					exit(0);
					break;
				case ON_FAIL:
					if (WIFEXITED(status)){
						if (WEXITSTATUS(status) == 0){
							fprintf(service_statfile_fd, "exited=0   ");
							syslog(LOG_INFO, "%s exited with 0 exit code", command);
							closelog();
							fclose(hd_pidfile_fd);
							fclose(service_pidfile_fd);
							fclose(service_statfile_fd);
							remove(hd_pidfile);
							remove(service_pidfile);
							exit(0);
						}
					}
					break;
			}
			if (times != 0) {
				times--;
				sleep(waitsec);
				goto restart;
			}else{
				if (WIFEXITED(status)){
					fprintf(service_statfile_fd, "exited=%d", WEXITSTATUS(status));
				}else{
					fprintf(service_statfile_fd, "killed       ");
				}
				syslog(LOG_INFO, "%s exited", command);
				closelog();
				fclose(hd_pidfile_fd);
				fclose(service_pidfile_fd);
				fclose(service_statfile_fd);
				remove(hd_pidfile);
				remove(service_pidfile);
				exit(0);
			}
			break;
	}
	return 0;
}
