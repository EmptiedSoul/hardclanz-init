#!/bin/bash

GREEN_COLOR="\e[1;32m"
RED_COLOR="\e[1;31m"
YELLOW_COLOR="\e[1;33m"
BLUE_COLOR="\e[1;34m"
CLEAR_COLOR="\e[0m"

run_daemon(){
	exec runuser -u ${RUN_DAEMON_USER:-root} -- $*
}

msg_ok(){
	echo -e "[ ${GREEN_COLOR}OK${CLEAR_COLOR} ] $*"
}

msg_pending(){
	echo -e "       $*"
}

msg_fail(){
	echo -e "[${RED_COLOR}FAIL${CLEAR_COLOR}] $*"
}

msg_warn(){
	echo -e "[${YELLOW_COLOR}WARN${CLEAR_COLOR}] $*"
}

msg_info(){
	echo -e "[${BLUE_COLOR}INFO${CLEAR_COLOR}] $*"
}
