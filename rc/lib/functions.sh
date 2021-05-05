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
	echo -e "$*" > ${RC_DEV_CONSOLE:-/dev/console}
	{ is_true $rc_logger && ! is_true $rc_logger_disable; } && {i
		[[ -e /run/.s_done ]] && {
			logger -p local7.notice -t ${0##*/} --id=$$ "$*"
		} || {
			echo -e "$*" >> /run/bootlog 
		}
	}
}

run_daemon(){
	[[ -n "$niceness" ]] && renice -n $niceness $$	
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

[[ -e "/etc/rc.conf" ]] && \
	. /etc/rc.conf
[[ -e "/etc/conf.d/${0##*/}.conf" ]] && \
	. /etc/conf.d/${0##*/}.conf

PID=$$

{ is_true $rc_logger && ! is_true $rc_logger_disable; } && {
	[[ -e /run/.s_done ]] && {
		exec 1> >(logger -p local7.info -t ${0##*/} --id=$PID)
		exec 2> >(logger -p local7.err  -t ${0##*/} --id=$PID)
	} || {	
		exec 1>${RC_DEV_CONSOLE:-/dev/console}
		exec 2>${RC_DEV_CONSOLE:-/dev/console}
	} 
} || {
	exec 1>${RC_DEV_CONSOLE:-/dev/console}
	exec 2>${RC_DEV_CONSOLE:-/dev/console}
}
