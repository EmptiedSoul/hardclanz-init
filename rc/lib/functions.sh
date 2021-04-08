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

_echo(){
	echo -e "$*" 
	echo -e "$*" >> /run/bootlog
}

run_daemon(){
	exec runuser -u ${RUN_DAEMON_USER:-root} -- $*
}

msg_ok(){
	_echo "[ ${GREEN_COLOR}OK${CLEAR_COLOR} ] $*" 
}

msg_pending(){
	_echo "       $*"
}

msg_fail(){
	_echo "[${RED_COLOR}FAIL${CLEAR_COLOR}] $*"
}

msg_warn(){
	_echo "[${YELLOW_COLOR}WARN${CLEAR_COLOR}] $*"
}

msg_info(){
	_echo "[${BLUE_COLOR}INFO${CLEAR_COLOR}] $*"
}

eval_retval(){
	local retval=${?}
	case $retval in
		$SUCCESS) 	
			msg_ok   "$SUCCESS_MSG"
			[[ -n "$SUCCESS_ACT" ]] && eval "$SUCCESS_ACT"
		;;
		$WARN)	  
			msg_warn "$WARN_MSG"
			[[ -n "$WARN_ACT" ]] && eval "$WARN_ACT"
		;;
		$FAIL)    
			msg_fail "$FAIL_MSG"
			[[ -n "$FAIL_ACT" ]] && eval "$FAIL_ACT"
		;;	
	esac
	is_true "$EVAL_EXIT" && exit $retval
	return 0
}
