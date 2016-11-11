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
  echo $(curl -sX GET $PESKAR_API_URL/ping/ | jq '.id' | tr -d \")
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
  local DATE=$(date +%Y-%m-%dT%T%Z)
  if [[ -z "$LOG" ]]; then
    return 0
  fi
  curl \
    -X PUT \
    -d "{\"log\": \"$DATE: $LOG\"}" \
    $PESKAR_API_URL/job/$JOB_ID/ > /dev/null 2>&1
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
  echo $(curl -sX GET $PESKAR_API_URL/job/$JOB_ID/ | jq '.state' | tr -d \")
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
  echo $(curl -sX GET $PESKAR_API_URL/job/$JOB_ID/ | jq '.download_url' | tr -d \")
}

#######################################
# Set job state
# Globals:
#   PESKAR_API_URL
# Arguments:
#   Job ID
#   State
#   Log message (optional)
# Returns:
#   None
#######################################
job_set_state() {
  local JOB_ID="$1"
  local STATE="$2"
  local LOG="$3"
  local DATE=$(date +%Y-%m-%dT%T%Z)
  if [[ -z "$STATE" ]]; then
    return 0
  fi
  if [[ -z "$LOG" ]]; then
    LOG="$DATE: Set state $STATE"
  fi
  curl \
    -X PUT \
    -d "{\"state\": \"$STATE\", \"log\": \"$LOG\"}" \
    $PESKAR_API_URL/job/$JOB_ID/ > /dev/null 2>&1
}

#######################################
# Set job state to "working"
# Globals:
#   PESKAR_API_URL
# Arguments:
#   Job ID
#   Log message (optional)
# Returns:
#   None
#######################################
job_set_working() {
  job_state $1 "working" $2
}

#######################################
# Set job state to "finished"
# Globals:
#   PESKAR_API_URL
# Arguments:
#   Job ID
#   Log message (optional)
# Returns:
#   None
#######################################
job_set_finished() {
  job_state $1 "finished" $2
}

#######################################
# Set job state to "failed"
# Globals:
#   PESKAR_API_URL
# Arguments:
#   Job ID
#   Log message (optional)
# Returns:
#   None
#######################################
job_set_failed() {
  job_state $1 "failed" $2
}
