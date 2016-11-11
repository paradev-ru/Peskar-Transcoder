#!/bin/bash

PESKAR_API_URL=${PESKAR_API_URL:-"http://api.peskar.paradev.ru"}

# job_ping
job_ping() {
  echo $(curl -sX GET $PESKAR_API_URL/ping/ | jq '.id' | tr -d \")
}

# job_log JOB_ID "Log message"
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

# job_get_state JOB_ID
job_get_state() {
  local JOB_ID="$1"
  echo $(curl -sX GET $PESKAR_API_URL/job/$JOB_ID/ | jq '.state' | tr -d \")
}

# job_get_url JOB_ID
job_get_url() {
  local JOB_ID="$1"
  echo $(curl -sX GET $PESKAR_API_URL/job/$JOB_ID/ | jq '.download_url' | tr -d \")
}

# job_set_state JOB_ID "working" "Log message"
# job_set_state JOB_ID "working"
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

# job_set_working JOB_ID "Log message"
# job_set_working JOB_ID
job_set_working() {
  job_state $1 "working" $2
}

# job_set_finished JOB_ID "Log message"
# job_set_finished JOB_ID
job_set_finished() {
  job_state $1 "finished" $2
}

# job_set_failed JOB_ID "Log message"
# job_set_failed JOB_ID
job_set_failed() {
  job_state $1 "failed" $2
}
