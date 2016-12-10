#!/bin/bash
#
# Perform Peskar worker

#######################################
# Peskar transcored worker
# Globals:
#   PESKAR_PETR_JOBS_PATH
#   PESKAR_SYNC_TARGET
#   PESKAR_SYNC_PATH
#   PESKAR_SYNC_OPTIONS
# Arguments:
#   Job ID
# Returns:
#   None
#######################################
worker() {
  local JOB_ID="$1"

  local QUEUE_PATH="$PESKAR_PETR_JOBS_PATH/$JOB_ID/queue"
  local SOURCE_PATH="$PESKAR_PETR_JOBS_PATH/$JOB_ID/source"
  local END_PATH="$PESKAR_PETR_JOBS_PATH/$JOB_ID/end"
  local FINISH_PATH="$PESKAR_PETR_JOBS_PATH/$JOB_ID/finish"
  local LOG_PATH="$PESKAR_PETR_JOBS_PATH/$JOB_ID/logs"

  if [[ -z "$JOB_ID" ]]; then
    return
  fi

  job_set_working $JOB_ID "Add to working..."
  job_download_url=$(job_get_url $JOB_ID)
  if [ $job_download_url == "null" ]; then
    job_set_failed $JOB_ID "URL not found"
    return
  fi

  mkdir -p $QUEUE_PATH $SOURCE_PATH $END_PATH $FINISH_PATH $LOG_PATH

  file_name=$(echo $job_download_url | awk -F/ '{print $NF}')
  end_name="${file_name%.*}"

  job_log $JOB_ID "Starting downloading..."
  curl -sfo $QUEUE_PATH/$file_name $job_download_url & pid_curl=$!
  watcher $JOB_ID $pid_curl
  if [[ "$?" -ne 0 ]]; then
    job_log $JOB_ID "watcher kill pid"
    rm -rf $PESKAR_PETR_JOBS_PATH/$JOB_ID
    return
  fi
  wait $pid_curl
  if [[ "$?" -ne 0 ]]; then
    job_set_failed $JOB_ID "Downloading failed"
    rm -rf $PESKAR_PETR_JOBS_PATH/$JOB_ID
    return
  fi
  job_log $JOB_ID "Downloading finished"

  mapper $JOB_ID $QUEUE_PATH/$file_name
  if [[ "$?" -ne 0 ]]; then
    job_set_failed $JOB_ID "Mapping failed"
    rm -rf $PESKAR_PETR_JOBS_PATH/$JOB_ID
    return
  fi
  job_log $JOB_ID "Video stream: $m_video"
  job_log $JOB_ID "Audio stream: $m_audio"

  if [[ "$(is_work_time)" != "true" ]]; then
    sleep 10m
    continue
  fi

  job_log $JOB_ID "Ensure FFmpeg is not running"
  ps_status=$(ps -e | grep ffmpeg | wc -l)
  while [ "$ps_status" -gt "0" ]; do
    job_log $JOB_ID "FFmpeg is running, sleeping..."
    sleep 30
    ps_status=$(ps -e | grep ffmpeg | wc -l)
  done
  job_log $JOB_ID "FFmpeg is available"

  job_log $JOB_ID "Starting transcoding..."
  echo -e "ffmpeg \
    -i $QUEUE_PATH/$file_name -map $m_video -map $m_audio -c:v libx264 -preset veryfast \
    -g 25 -keyint_min 4 -c:a aac -f mp4 \
    $SOURCE_PATH/$end_name.mp4" > $LOG_PATH/$end_name.log

  ffmpeg \
    -i $QUEUE_PATH/$file_name -map $m_video -map $m_audio -c:v libx264 -preset veryfast \
    -g 25 -keyint_min 4 -c:a aac -f mp4 \
    $SOURCE_PATH/$end_name.mp4 >> $LOG_PATH/$end_name.log 2>&1 & pid_ffmpeg=$!
  watcher $JOB_ID $pid_ffmpeg
  if [[ "$?" -ne 0 ]]; then
    job_log $JOB_ID "watcher kill pid"
    rm -rf $PESKAR_PETR_JOBS_PATH/$JOB_ID
    return
  fi
  wait $pid_ffmpeg
  if [[ "$?" -ne 0 ]]; then
    job_set_failed $JOB_ID "Transcoding failed"
    tar -zcf $END_PATH/logs_$end_name.tar.gz $LOG_PATH/* > /dev/null 2>&1
    rsync \
      -e "$PESKAR_SYNC_OPTIONS" \
      -r $END_PATH/logs_$end_name.tar.gz \
      $PESKAR_SYNC_TARGET:$PESKAR_SYNC_PATH
    rm -rf $PESKAR_PETR_JOBS_PATH/$JOB_ID
    return
  fi
  job_log $JOB_ID "Transcoding finished"

  job_log $JOB_ID "Starting segmenting..."
  ffmpeg \
    -i $SOURCE_PATH/$end_name.mp4 -map 0 -c copy -segment_time 3 \
    -segment_list $END_PATH/$end_name.m3u8 -f segment \
    $END_PATH/$end_name\_%08d.ts > $LOG_PATH/$end_name\_seg.log 2>&1 & pid_ffmpeg=$!
  wait $pid_ffmpeg
  if [[ "$?" -ne 0 ]]; then
    job_set_failed $JOB_ID "Segmenting failed"
    rm -rf $PESKAR_PETR_JOBS_PATH/$JOB_ID
    return
  fi
  job_log $JOB_ID "Segmenting finished"

  job_log $JOB_ID "Creating tarball..."
  tar -zcf $END_PATH/logs_$end_name.tar.gz $LOG_PATH/* > /dev/null 2>&1
  tar -cf $FINISH_PATH/$end_name.tar $END_PATH/* > /dev/null 2>&1
  job_log $JOB_ID "Creating finished"

  job_log $JOB_ID "Starting copying to remote server..."
  rsync \
    -e "$PESKAR_SYNC_OPTIONS" \
    -r $FINISH_PATH/$end_name.tar \
    $PESKAR_SYNC_TARGET:$PESKAR_SYNC_PATH & pid_rsync=$!
  watcher $JOB_ID $pid_rsync
  if [[ "$?" -ne 0 ]]; then
    job_log $JOB_ID "watcher kill pid"
    rm -rf $PESKAR_PETR_JOBS_PATH/$JOB_ID
    return
  fi
  wait $pid_curl
  if [[ "$?" -ne 0 ]]; then
    job_set_failed $JOB_ID "Uploading failed"
    rm -rf $PESKAR_PETR_JOBS_PATH/$JOB_ID
    return
  fi
  job_log $JOB_ID "Copying finished"

  rm -rf $PESKAR_PETR_JOBS_PATH/$JOB_ID

  job_set_finished $JOB_ID "Done"
}
