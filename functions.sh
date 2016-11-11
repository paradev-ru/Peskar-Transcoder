#!/bin/bash

PESKAR_API_URL=${PESKAR_API_URL:-"http://api.peskar.paradev.ru"}

job_log() {
  local JOBID="$1"
  local LOG="$2"
  local DATE=$(date +%Y-%m-%dT%T%Z)
  if [[ ! -n "$LOG" ]]; then
    return 0
  fi
  curl \
    -X PUT \
    -d "{\"log\": \"$DATE: $LOG\"}" \
    $PESKAR_API_URL/job/$JOBID/ > /dev/null 2>&1
}

job_get_state() {
  local JOBID="$1"
  echo $(curl -sX GET $PESKAR_API_URL/job/$JOBID/ | jq '.state' | tr -d \")
}

job_get_url() {
  local JOBID="$1"
  echo $(curl -sX GET $PESKAR_API_URL/job/$JOBID/ | jq '.download_url' | tr -d \")
}

job_set_state() {
  local JOBID="$1"
  local STATE="$2"
  local LOG="$3"
  local DATE=$(date +%Y-%m-%dT%T%Z)
  if [[ ! -n "$STATE" ]]; then
    return 0
  fi
  if [[ -n "$LOG" ]]; then
    LOG="$DATE: $LOG"
  fi
  curl \
    -X PUT \
    -d "{\"state\": \"$STATE\", \"log\": \"$LOG\"}" \
    $PESKAR_API_URL/job/$JOBID/ > /dev/null 2>&1
}

job_set_working() {
  job_state $1 "working"
}

job_set_finished() {
  job_state $1 "finished"
}

job_set_failed() {
  job_state $1 "failed"
}
