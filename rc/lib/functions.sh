#!/bin/bash

GREEN_COLOR="\e[1;32m"
RED_COLOR="\e[1;31m"
YELLOW_COLOR="\e[1;33m"
BLUE_COLOR="\e[1;34m"
CLEAR_COLOR="\e[0m"

shopt -s extglob

abort(){
	kill -USR2 $(cat /run/service/${0##*/}/supervisor)
	exit $1
}

require(){
	while true
	do
		[[ -e $1 ]] && return
		sleep ${POLL_DELAY:-0.01}
	done
}

is_true(){
	case $1 in 
		Y*|y*|on|true|OK|ok|1)	return 0;;
		*)			return 1;;
	esac
}

cgroup_exist(){
	find /sys/fs/cgroup -type d |& grep "$1$" &>/dev/null
}

cgroup_setup(){
	cgcreate -g ${rc_cg_controllers}:/${rc_cgroup}
	for variable in "${rc_cg_variables[@]}"
	do
		cgset -r $variable /${rc_cgroup}	
	done
}

_echo(){
	echo -e "$*" > ${RC_DEV_CONSOLE:-/dev/console}
	{ is_true $rc_logger && ! is_true $rc_logger_disable; } && {
		[[ -e /run/.s_done ]] && {
			logger -p local7.notice -t ${0##*/} --id=$$ "${*//\\e\[*([0-9;])m}"
		} || {
			echo -e "$*" >> /run/bootlog 
		}
	}
	return 0
}

run_daemon(){
	[[ -n "$niceness"  ]] && renice -n $niceness $$	
	[[ -n "$rc_cgroup" ]] && {
		cgroup_exist $rc_cgroup || cgroup_setup
		_cgexec_="cgexec -g ${rc_cg_controllers}:/${rc_cgroup}"
	}
	exec ${_cgexec_} $*

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
[[ -e "/etc/conf.d/${0##*/}" ]] && \
	. /etc/conf.d/${0##*/}

PID=$$

{ is_true $rc_logger && ! is_true $rc_logger_disable; } && {
	[[ -e /run/.s_done ]] && {
		exec 1> >(exec logger -p local7.info -t ${0##*/} --id=$PID)
		exec 2> >(exec logger -p local7.err  -t ${0##*/} --id=$PID)
	} || {	
		exec 1>${RC_DEV_CONSOLE:-/dev/console}
		exec 2>${RC_DEV_CONSOLE:-/dev/console}
	} 
} || {
	exec 1>${RC_DEV_CONSOLE:-/dev/console}
	exec 2>${RC_DEV_CONSOLE:-/dev/console}
}
