#!/bin/bash

GREEN_COLOR="\e[1;32m"
RED_COLOR="\e[1;31m"
YELLOW_COLOR="\e[1;33m"
BLUE_COLOR="\e[1;34m"
CLEAR_COLOR="\e[0m"

is_true(){
	case $1 in 
		Y*|y*|on|true|OK|ok|1)	return 0;;
		*)			return 1;;
	esac
}

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

eval_retval(){
	local retval=${?}
	case $retval in
		$SUCCESS) msg_ok   "$SUCCESS_MSG";;
		$WARN)	  msg_warn "$WARN_MSG";;
		$FAIL)    msg_fail "$FAIL_MSG";;
	esac
	is_true "$EVAL_EXIT" && exit $retval
	return 0
}
