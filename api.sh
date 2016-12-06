#!/bin/bash
#
# Perform Peskar API server calls

#######################################
# Ping server
# Globals:
#   PESKAR_API_URL
# Arguments:
#   None
# Returns:
#   Job ID
#######################################
job_ping() {
  echo $(curl -sX GET "${PESKAR_API_URL}/ping/" | jq '.id' | tr -d \")
}

#######################################
# Send log
# Globals:
#   PESKAR_API_URL
# Arguments:
#   Job ID
#   Log message
# Returns:
#   None
#######################################
job_log() {
  local JOB_ID="$1"
  local LOG="$2"
  if [[ -z "$LOG" ]]; then
    return 0
  fi
  log_verbose "${JOB_ID}: ${LOG}"
  curl \
    -X POST \
    -d "{\"message\": \"${LOG}\"}" \
    "${PESKAR_API_URL}/job/${JOB_ID}/log/" > /dev/null 2>&1
}

#######################################
# Get job state
# Globals:
#   PESKAR_API_URL
# Arguments:
#   Job ID
# Returns:
#   State
#######################################
job_get_state() {
  local JOB_ID="$1"
  echo $(curl -sX GET "${PESKAR_API_URL}/job/${JOB_ID}/" | jq '.state' | tr -d \")
}

#######################################
# Get job download url
# Globals:
#   PESKAR_API_URL
# Arguments:
#   Job ID
# Returns:
#   Download url
#######################################
job_get_url() {
  local JOB_ID="$1"
  echo $(curl -sX GET "${PESKAR_API_URL}/job/${JOB_ID}/" | jq '.download_url' | tr -d \")
}

#######################################
# Set job state
# Globals:
#   PESKAR_API_URL
# Arguments:
#   Job ID
#   State
# Returns:
#   None
#######################################
job_state() {
  local JOB_ID="$1"
  local STATE="$2"
  if [[ -z "$STATE" ]]; then
    return 0
  fi
  log_verbose "${JOB_ID}: Set job state to ${STATE}"
  curl \
    -X PUT \
    -d "{\"state\": \"${STATE}\"}" \
    "${PESKAR_API_URL}/job/${JOB_ID}/" > /dev/null 2>&1
}

#######################################
# Set job state to "working"
# Globals:
#   None
# Arguments:
#   Job ID
#   Log message (optional)
# Returns:
#   None
#######################################
job_set_working() {
  local JOB_ID="$1"
  local LOG="$2"
  job_log "${JOB_ID}" "${LOG}"
  job_state "${JOB_ID}" "working"
}

#######################################
# Set job state to "finished"
# Globals:
#   None
# Arguments:
#   Job ID
#   Log message (optional)
# Returns:
#   None
#######################################
job_set_finished() {
  local JOB_ID="$1"
  local LOG="$2"
  job_log "${JOB_ID}" "${LOG}"
  job_state "${JOB_ID}" "finished"
}

#######################################
# Set job state to "failed"
# Globals:
#   None
# Arguments:
#   Job ID
#   Log message (optional)
# Returns:
#   None
#######################################
job_set_failed() {
  local JOB_ID="$1"
  local LOG="$2"
  job_log "${JOB_ID}" "${LOG}"
  job_state "${JOB_ID}" "failed"
}

#######################################
# Get work time state
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   State
#######################################
is_work_time() {
  echo $(curl -sX GET "${PESKAR_API_URL}/work_time/" | jq '.is_work_time' | tr -d \")
}
