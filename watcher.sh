#!/bin/bash
#
# Perform Peskar watcher pid

#######################################
# Peskar watcher pid
# Globals:
#   None
# Arguments:
#   Job ID
#   pid
# Returns:
#   None
#######################################
watcher(){
  local JOB_ID="$1"
  local PID="$2"
  while kill -0 $PID; do
  	STATE=$(job_get_state $JOB_ID)
  	if [ "$STATE" == "canceled" ]; then
  		kill -9 $PID
  		job_log $JOB_ID "Administrative canceled !"
  		return 1
  	fi
  	sleep 20
  done
}
