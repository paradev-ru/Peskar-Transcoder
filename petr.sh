#!/bin/bash
#
# Peskar Transcoder

PESKAR_PETR_HOME_PATH=${PESKAR_PETR_HOME_PATH:-"/opt/peskar/peskar-transcoder"}

source "$PESKAR_PETR_HOME_PATH/env.sh"
source "$PESKAR_PETR_HOME_PATH/functions.sh"
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
    log_fail "Directory '$PESKAR_PETR_HOME_PATH' doesn't exist."
  fi
  if ! installed ffmpeg; then
    log_fail "FFmpeg does not installed."
  fi
  mkdir -p $PESKAR_PETR_HOME_PATH/jobs/
  if [[ "$?" -ne 0 ]]; then
    log_fail "Unable create $PESKAR_PETR_HOME_PATH/jobs/ directory"
  fi
  while true; do
    can_work=$(is_work_time)
    if [ $can_work != "true" ]; then
      sleep 10m
      continue
    fi
    job_id=$(job_ping)
    if [ $job_id == "null" ]; then
      sleep 30s
      continue
    fi
    log_info "Starting a job '$job_id'..."
    worker $job_id &
    sleep 1m
  done
}

main "$@"
