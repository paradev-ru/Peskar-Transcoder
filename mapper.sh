#!/bin/bash
#
# Perform Peskar mapper stream

#######################################
# Peskar mapper stream
# Globals:
#   None
# Arguments:
#   Job ID
#   Video file
# Returns:
#   None
#######################################
mapper() {
  local JOB_ID="$1"
  local FILENAME="$2"
  m_video=$(ffprobe $FILENAME 2>&1 | grep Video | awk '{print $2}' | sed -ne 1p | cut -c 2-4)
  if [[ "$?" -ne 0 ]]; then
    job_set_failed $JOB_ID "Failed to execute FFprobe (Video)"
    return 1
  elif [[ -z "$m_video" ]]; then
    job_set_failed $JOB_ID "Video stream not found"
    return 2
  fi
  m_audio=$(ffprobe $FILENAME 2>&1 | grep rus | grep Audio | sed -ne 1p | awk '{print $2}' | cut -c 2-4)
  if [[ "$?" -ne 0 ]]; then
    job_set_failed $JOB_ID "Failed to execute FFprobe (Audio/Rus)"
    return 1
  elif [[ -z "$m_audio" ]]; then
    job_log $JOB_ID "Russian audio stream not found"
    m_audio=$(ffprobe $FILENAME 2>&1 | grep Audio | awk '{print $2}' | sed -ne 1p | cut -c 2-4)
    if [[ "$?" -ne 0 ]]; then
      job_set_failed $JOB_ID "Failed to execute FFprobe (Audio)"
      return 1
    elif [[ -z "$m_audio" ]]; then
      job_set_failed $JOB_ID "Audio stream not found"
      return 2
    fi
  fi
}
