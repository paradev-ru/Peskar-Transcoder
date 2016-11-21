#!/bin/bash
#
# Perform Peskar maper stream

#######################################
# Peskar maper stream
# Globals:
#   PESKAR_PETR_JOBS_PATH
#   PESKAR_SYNC_TARGET
#   PESKAR_SYNC_PATH
#   PESKAR_SYNC_OPTIONS
# Arguments:
#   Job ID
#   file_name
# Returns:
#   None
#######################################
maper(){
  while true ;do
    m_video="${ffprobe $file_name 2>&1 | grep Video | awk '{print $2}' | cut -c 2-4}"
      if [[ "$?" -ne 0 ]]; then
        job_set_failed $JOB_ID "err found video stream"
        return 1
      elif [[ -z "$m_video" ]]; then
        job_set_failed $JOB_ID "not found video stream"
        return 2
      fi

    m_audio_rus="${ffprobe $file_name 2>&1 | grep rus | grep Audio | awk '{print $2}' | cut -c 2-4 }"
      if [[ "$?" -ne 0 ]]; then
        job_set_failed $JOB_ID "err found rus audio stream"
        return 1
      elif [[ -z "$m_audio_rus" ]]; then
        job_set_failed $JOB_ID "not found rus audio stream"

        m_audio_any="${ffprobe $file_name 2>&1 | grep Audio | awk '{print $2}' | sed -ne 1p | cut -c 2-4 }"
        if [[ "$?" -ne 0 ]]; then
          job_set_failed $JOB_ID "err found any audio stream"
          return 1
        elif [[ -z "$m_audio_eng" ]]; then
          job_set_failed $JOB_ID "not found any audio stream"
          return 2
        fi
        m_audio="${$m_audio_any}"
        break
      fi
    m_audio="${$m_audio_rus}"
    break
  done
}


