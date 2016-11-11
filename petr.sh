#!/bin/bash
#
# Peskar Transcoder

source "env.sh"
source "api.sh"

base_path=/home/$PESKAR_PETR_USER
queue_path/=$base_path/queue/
source_path=$base_path/source/
end_path=$base_path/end/
finish_path=$base_path/finish/
log_path=$base_path/logs/

pre_work_hook() {
  local JOB_ID="$1"

  mkdir -p $queue_path/$JOB_ID \
    $source_path/$JOB_ID \
    $end_path/$JOB_ID \
    $finish_path/$JOB_ID \
    $log_path/$JOB_ID \
}

post_work_hook() {
  local JOB_ID="$1"

  rm -rf $queue_path/$JOB_ID \
    $source_path/$JOB_ID \
    $end_path/$JOB_ID \
    $finish_path/$JOB_ID \
    $log_path/$JOB_ID \
    > /dev/null 2>&1
}

worker() {
  local JOB_ID="$1"

  job_set_working $JOB_ID "Add to working..."
  job_download_url=$(job_get_url $JOB_ID)
  if [ $job_download_url == "null" ]; then
    job_set_failed $JOB_ID "URL not found"
    return
  fi

  pre_work_hook $JOB_ID

  file_name=$(echo $job_download_url | awk -F/ '{print $NF}')
  end_name=$(echo $file_name | awk -F. '{print $1}')

  job_log $JOB_ID "Starting downloading..."
  curl -s -o $queue_path/$JOB_ID/$file_name $job_download_url & pid_curl=$!
  wait $pid_curl
  job_log $JOB_ID "Downloading finished"

  job_log $JOB_ID "Ensure FFmpeg is not running"
  ps_status=$(ps -e | grep ffmpeg | wc -l)
  while [ "$ps_status" -gt "0" ]; do
    job_log $JOB_ID "FFmpeg is running, sleeping..."
    sleep 30
    ps_status=$(ps -e | grep ffmpeg | wc -l)
  done
  job_log $JOB_ID "FFmpeg is available"

  job_log $JOB_ID "Starting transcoding..."
  ffmpeg \
    -i $queue_path/$JOB_ID/$file_name -c:v libx264 -preset veryfast -g 25 -keyint_min 4\
    -c:a aac -f mp4 $source_path/$JOB_ID/$end_name.mp4 > $log_path/$JOB_ID/$end_name.log 2>&1 & pid_ffmpeg=$!
  wait $pid_ffmpeg

  file_size=$(wc -c $source_path/$JOB_ID/$end_name.mp4 | awk '{print $1}')
  if [ $file_size -lt 1 ]; then
    job_set_failed $JOB_ID "Transcoding error"
    tar -zcf $end_path/$JOB_ID/logs_$end_name.tar.gz $log_path/$JOB_ID/* > /dev/null 2>&1
    rsync \
      -e "\"$PESKAR_SYNC_OPTIONS\"" \
      -r $end_path/$JOB_ID/logs_$end_name.tar.gz \
      $PESKAR_SYNC_TARGET:$PESKAR_SYNC_PATH
    post_work_hook $JOB_ID
    return
  fi
  job_log $JOB_ID "Transcoding finished"

  job_log $JOB_ID "Starting segmenting..."
  ffmpeg \
    -i $source_path/$JOB_ID/$end_name.mp4 -map 0 -c copy -segment_time 3 \
    -segment_list $end_path/$JOB_ID/$end_name.m3u8 -f segment \
    $end_path/$JOB_ID/$end_name\_%08d.ts > $log_path/$JOB_ID/$end_name\_seg.log 2>&1 & pid_ffmpeg=$!
  wait $pid_ffmpeg
  job_log $JOB_ID "Segmenting finished"

  job_log $JOB_ID "Creating tarball..."
  tar -zcf $end_path/$JOB_ID/logs_$end_name.tar.gz $log_path/$JOB_ID/* > /dev/null 2>&1
  tar -cf $finish_path/$JOB_ID/$end_name.tar $end_path/$JOB_ID/* > /dev/null 2>&1
  job_log $JOB_ID "Creating finished"

  job_log $JOB_ID "Starting copying to remote server..."
  rsync \
    -e "\"$PESKAR_SYNC_OPTIONS\"" \
    -r $finish_path/$JOB_ID/$end_name.tar \
    $PESKAR_SYNC_TARGET:$PESKAR_SYNC_PATH
  job_log $JOB_ID "Copying finished"

  post_work_hook $JOB_ID

  job_set_finished $JOB_ID "Done"
}

main() {
  while true; do
    job_id=$(job_ping)
    if [ $job_id == "null" ]; then
      sleep 5m
      continue
    fi

    worker $job_id &
    sleep 1m
  done
}

main_test "$@"
