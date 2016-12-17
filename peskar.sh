#!/bin/bash
#
# Peskar Transcoder

PESKAR_PETR_VERSION="0.1.3-dev"
PESKAR_PETR_HOME_PATH=${PESKAR_PETR_HOME_PATH:-"/opt/peskar/peskar-transcoder"}
# PESKAR_PETR_HOME_PATH=${PESKAR_PETR_HOME_PATH:-"/home/emedvedev/petr-test"}  # DEV PATH
PESKAR_PETR_JOBS_PATH=${PESKAR_PETR_JOBS_PATH:-"$PESKAR_PETR_HOME_PATH/jobs"}

source "${PESKAR_PETR_HOME_PATH}/env.sh"
source "${PESKAR_PETR_HOME_PATH}/functions.sh"
source "${PESKAR_PETR_HOME_PATH}/api.sh"
source "${PESKAR_PETR_HOME_PATH}/mapper.sh"
source "${PESKAR_PETR_HOME_PATH}/watcher.sh"
source "${PESKAR_PETR_HOME_PATH}/worker.sh"
source "${PESKAR_PETR_HOME_PATH}/gif_maker.sh"

#######################################
# Init function
# Globals:
#   PESKAR_PETR_HOME_PATH
#   PESKAR_PETR_JOBS_PATH
# Arguments:
#   None
# Returns:
#   None
#######################################
init() {
  if [ ! -d "${PESKAR_PETR_HOME_PATH}" ]; then
    log_fail "Directory ${PESKAR_PETR_HOME_PATH} doesn't exist."
  fi
  if ! installed ffmpeg; then
    log_fail "FFmpeg does not installed."
  fi
  mkdir -p "${PESKAR_PETR_JOBS_PATH}"
  if [[ "$?" -ne 0 ]]; then
    log_fail "Unable create ${PESKAR_PETR_JOBS_PATH} directory"
  fi
}

#######################################
# Entrypoint
# Globals:
#   PESKAR_PETR_HOME_PATH
# Arguments:
#   Command (optional)
# Returns:
#   None
#######################################
main() {
  local COMMAND="$1"
  case "${COMMAND}" in
    -v|--version|version)
    echo "peskar-transcoder ${PESKAR_PETR_VERSION}"
    exit 0
    ;;
  esac
  log_info "Starting peskar-transcoder"
  init
  while true; do
    job_id=$(job_ping)
    if [[ "${job_id}" == "null" ]]; then
      sleep 10s
      continue
    fi
    log_info "Starting a job ${job_id}..."
    worker "${job_id}" &
    sleep 1m
  done
}

main "$@"
