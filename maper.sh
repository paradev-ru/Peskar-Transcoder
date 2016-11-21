#!/bin/bash
#
# Perform Peskar maper stream

#######################################
# Peskar maper stream
# Globals:
#   None
# Arguments:
#   Job ID
#   Video file
# Returns:
#   None
#######################################
maper() {
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
  m_audio_rus=$(ffprobe $FILENAME 2>&1 | grep rus | grep Audio | awk '{print $2}' | cut -c 2-4)
  if [[ "$?" -ne 0 ]]; then
    job_set_failed $JOB_ID "Failed to execute FFprobe (Audio/Rus)"
    return 1
  elif [[ -z "$m_audio_rus" ]]; then
    job_log $JOB_ID "Russian audio stream not found"
    m_audio_any=$(ffprobe $FILENAME 2>&1 | grep Audio | awk '{print $2}' | sed -ne 1p | cut -c 2-4)
    if [[ "$?" -ne 0 ]]; then
      job_set_failed $JOB_ID "Failed to execute FFprobe (Audio)"
      return 1
    elif [[ -z "$m_audio_eng" ]]; then
      job_set_failed $JOB_ID "Audio stream not found"
      return 2
    fi
    m_audio="$m_audio_any"
    return
  fi
  m_audio="$m_audio_rus"
}
