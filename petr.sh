#!/bin/bash

source "functions.sh"

user=emedvedev
api_url="http://api.peskar.paradev.ru"

queue_path=/home/$user/queue/
source_path=/home/$user/source/
end_path=/home/$user/end/
log_path=/home/$user/logs/

paradev_path=/home/user/films/
state_failed=0

date_time_up () {
  date_time=`date +%Y-%m-%dT%T%Z`
}

while true;do

  date_time_up
  job_id=`curl -s $api_url/ping/ | jq '.id' | tr -d \"`

  if [ $job_id == "null" ]; then
    exit 0
  fi

  job_state=`curl -s $api_url/job/$job_id/ | jq '.state' | tr -d \"`

  if [ $job_state == "pending" ]; then
    let "state_failed=state_failed += 1"
    if [ "$state_failed" -gt 4 ]; then
      echo -e "job_state not change to requested" > $log_path$job_id.log
      curl -X PUT -d '{"state": "failed", "log": "job_state not change to requested"}' $api_url/job/$job_id/ > /dev/null 2>&1
    fi
    continue
  elif [ $job_state == "requested" ]; then
    date_time_up
    curl -X PUT -d '{"state": "working", "log": "'$date_time' add to working..."}' $api_url/job/$job_id/ > /dev/null 2>&1
  fi

  job_download_url=`curl -s $api_url/job/$job_id/ | jq '.download_url' | tr -d \"`
  # job_name=`curl -s $api_url/job/$job_id/ | jq '.name' | tr -d \"`

  if [ $job_download_url == "null" ]; then
    date_time_up
    curl -X PUT -d '{"state": "failed", "log": "'$date_time' download_url not found"}' $api_url/job/$job_id/ > /dev/null 2>&1
    exit 0
  fi

  file_name=`echo $job_download_url | awk -F/ '{print $NF}'`
  mkdir $queue_path$job_id
  curl -s -o $queue_path$job_id/$file_name $job_download_url & pid_curl=$!
  date_time_up
  curl -X PUT -d '{"state": "working", "log": "'$date_time' Starting download..."}' $api_url/job/$job_id/ > /dev/null 2>&1

  wait $pid_curl

  date_time_up
  curl -X PUT -d '{"state": "working", "log": "'$date_time' Downloaded, sending to transcoder..."}' $api_url/job/$job_id/ > /dev/null 2>&1

  end_name=`echo $file_name | awk -F. '{print $1}'`

  mkdir -p $source_path$job_id/
  mkdir -p $end_path$job_id/
  mkdir -p $log_path$job_id/

  sleep 1
  ps_status=`ps -e | grep ffmpeg | wc -l`
  while [ "$ps_status" -gt "0" ]; do
    sleep 10
    ps_status=`ps -e | grep ffmpeg | wc -l`
  done

  ffmpeg \
        -i $queue_path$job_id/$file_name -c:v libx264 -preset veryfast -g 25 -keyint_min 4\
        -c:a aac -f mp4 $source_path$job_id/$end_name.mp4 > $log_path$job_id/$end_name.log 2>&1 & pid_ffmpeg=$!

  date_time_up
  curl -X PUT -d '{"state": "working", "log": "'$date_time' Starting transcoding..."}' $api_url/job/$job_id/ > /dev/null 2>&1

  wait $pid_ffmpeg

  file_size=`wc -c $source_path$job_id/$end_name.mp4 | awk '{print $1}'`
  if [ $file_size -lt 1 ]; then
    curl -X PUT -d '{"state": "failed", "log": "'$date_time' Transcoding error "}' $api_url/job/$job_id/ > /dev/null 2>&1

    tar -c -f $end_path$job_id/$end_name.tar $log_path$job_id/$end_name.log > /dev/null 2>&1
    rsync -e='ssh -p 3389' -r $end_path$job_id/$end_name.tar user@paradev.ru:$paradev_path
    rm -r -f queue_path$job_id && rm -r -f $source_path$job_id && rm -r -f $end_path$job_id > /dev/null 2>&1

    exit 0
  fi

  date_time_up
  curl -X PUT -d '{"state": "working", "log": "'$date_time' Transcoding finished, sending to copying..."}' $api_url/job/$job_id/ > /dev/null 2>&1

  ffmpeg \
        -i $source_path$job_id/$end_name.mp4 -map 0 -c copy -segment_time 3 \
        -segment_list $end_path$job_id/$end_name.m3u8 -f segment \
        $end_path$job_id/$end_name\_%08d.ts > $log_path$job_id/$end_name\_seg.log 2>&1 & pid_ffmpeg=$!

  wait $pid_ffmpeg

  tar -z -c -f $end_path$job_id/logs_$end_name.tar.gz $log_path$job_id/* > /dev/null 2>&1
  cp $end_path$job_id/logs_$end_name.tar.gz $end_path$job_id/
  tar -c -f $end_path$job_id/$end_name.tar $end_path$job_id/$end_name/* > /dev/null 2>&1

  date_time_up
  curl -X PUT -d '{"state": "working", "log": "'$date_time' Starting copying..."}' $api_url/job/$job_id/ > /dev/null 2>&1

  rsync -e='ssh -p 3389' -r $end_path$job_id/$end_name.tar user@paradev.ru:$paradev_path

  date_time_up
  curl -X PUT -d '{"state": "working", "log": "'$date_time' Copying finished."}' $api_url/job/$job_id/ > /dev/null 2>&1
  curl -X PUT -d '{"state": "finished", "log": "'$date_time' Done"}' $api_url/job/$job_id/ > /dev/null 2>&1

  rm -r -f queue_path$job_id && rm -r -f $source_path$job_id && rm -r -f $end_path$job_id > /dev/null 2>&1
  break
done
