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
  while true; do
    can_work=$(is_work_time)
    if [ $can_work != "true" ]; then
      log_info "DND"
      sleep 30m
      continue
    fi
    log_info "Getting new job..."
    job_id=$(job_ping)
    if [ $job_id == "null" ]; then
      log_verbose "Nothing found, sleeping for a 5m..."
      sleep 5m
      continue
    fi
    log_info "Starting a job..."
    worker $job_id &
    sleep 1m
  done
}

main "$@"
