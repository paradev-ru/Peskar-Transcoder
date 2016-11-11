#!/bin/bash

source "functions.sh"

user=emedvedev

queue_path=/home/$user/queue/
source_path=/home/$user/source/
end_path=/home/$user/end/
log_path=/home/$user/logs/

paradev_path=/home/user/films/
state_failed=0

while true; do
  job_id=$(job_ping)
  if [ $job_id == "null" ]; then
    exit 0
  fi

  job_state=$(job_get_state $job_id)
  if [ $job_state == "pending" ]; then
    let "state_failed=state_failed += 1"
    if [ "$state_failed" -gt 4 ]; then
      echo -e "job_state not change to requested" > $log_path$job_id.log
      job_set_failed $job_id "job_state not change to requested"
    fi
    continue
  elif [ $job_state == "requested" ]; then
    job_set_working $job_id "Add to working..."
  fi

  job_download_url=$(job_get_url $job_id)

  if [ $job_download_url == "null" ]; then
    job_set_failed $job_id "URL not found"
    exit 0
  fi

  file_name=`echo $job_download_url | awk -F/ '{print $NF}'`
  mkdir $queue_path$job_id

  job_log $job_id "Starting download..."
  curl -s -o $queue_path$job_id/$file_name $job_download_url & pid_curl=$!
  wait $pid_curl
  job_log $job_id "Successfully downloaded"

  end_name=`echo $file_name | awk -F. '{print $1}'`

  mkdir -p $source_path$job_id/
  mkdir -p $end_path$job_id/
  mkdir -p $log_path$job_id/

  job_log $job_id "Ensure FFmpeg is not running"
  sleep 1
  ps_status=`ps -e | grep ffmpeg | wc -l`
  while [ "$ps_status" -gt "0" ]; do
    job_log $job_id "FFmpeg is rinning, sleeping..."
    sleep 10
    ps_status=`ps -e | grep ffmpeg | wc -l`
  done
  job_log $job_id "FFmpeg is available"

  job_log $job_id "Starting transcoding..."
  ffmpeg \
        -i $queue_path$job_id/$file_name -c:v libx264 -preset veryfast -g 25 -keyint_min 4\
        -c:a aac -f mp4 $source_path$job_id/$end_name.mp4 > $log_path$job_id/$end_name.log 2>&1 & pid_ffmpeg=$!
  wait $pid_ffmpeg

  file_size=`wc -c $source_path$job_id/$end_name.mp4 | awk '{print $1}'`
  if [ $file_size -lt 1 ]; then
    job_set_failed $job_id "Transcoding error"

    tar -c -f $end_path$job_id/$end_name.tar $log_path$job_id/$end_name.log > /dev/null 2>&1
    rsync -e='ssh -p 3389' -r $end_path$job_id/$end_name.tar user@paradev.ru:$paradev_path
    rm -r -f queue_path$job_id && rm -r -f $source_path$job_id && rm -r -f $end_path$job_id > /dev/null 2>&1

    exit 0
  fi
  job_log $job_id "Transcoding finished"

  job_log $job_id "Starting segmenting..."
  ffmpeg \
        -i $source_path$job_id/$end_name.mp4 -map 0 -c copy -segment_time 3 \
        -segment_list $end_path$job_id/$end_name.m3u8 -f segment \
        $end_path$job_id/$end_name\_%08d.ts > $log_path$job_id/$end_name\_seg.log 2>&1 & pid_ffmpeg=$!
  wait $pid_ffmpeg
  job_log $job_id "Segmenting finished"

  job_log $job_id "Creating tarball..."
  tar -z -c -f $end_path$job_id/logs_$end_name.tar.gz $log_path$job_id/* > /dev/null 2>&1
  cp $end_path$job_id/logs_$end_name.tar.gz $end_path$job_id/
  tar -c -f $end_path$job_id/$end_name.tar $end_path$job_id/$end_name/* > /dev/null 2>&1
  job_log $job_id "Creating finished"

  job_log $job_id "Starting copying to remote server..."
  rsync -e='ssh -p 3389' -r $end_path$job_id/$end_name.tar user@paradev.ru:$paradev_path
  job_log $job_id "Copying finished"

  rm -r -f queue_path$job_id && rm -r -f $source_path$job_id && rm -r -f $end_path$job_id > /dev/null 2>&1

  job_set_finished $job_id "Done"
  break
done
