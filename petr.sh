#!/bin/bash
#
# Peskar Transcoder

PESKAR_PETR_HOME_PATH=${PESKAR_PETR_HOME_PATH:-"/opt/peskar/peskar-transcoder"}

source "$PESKAR_PETR_HOME_PATH/env.sh"
source "$PESKAR_PETR_HOME_PATH/api.sh"
source "$PESKAR_PETR_HOME_PATH/worker.sh"

#######################################
# Entrypoint
# Globals:
#   PESKAR_PETR_HOME_PATH
# Arguments:
#   $@
# Returns:
#   None
#######################################
main() {
  if [ ! -d "$PESKAR_PETR_HOME_PATH" ]; then
    echo "Directory '$PESKAR_PETR_HOME_PATH' doesn't exist."
    exit 1
  fi
  while true; do
    job_id=$(job_ping)
    if [ $job_id == "null" ]; then
      sleep 5m
      continue
    fi

    worker $job_id &
    sleep 1m
  done
}

main "$@"
