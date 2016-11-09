#!/bin/bash

user=emedvedev
api_url="http://api.peskar.paradev.ru"

queue_path=/home/$user/queue/
source_path=/home/$user/source/
end_path=/home/$user/end/
log_dir=/home/$user/logs/

paradev_path=/home/user/films/
state_failed=0

while true;do

  date_time=`date +%Y-%m-%dT%T%Z`
  job_id=`curl -s $api_url/ping/ | jq '.id' | tr -d \"`

  if [ $job_id == "null" ]; then
    exit 0
  fi

  job_state=`curl -s $api_url/job/$job_id/ | jq '.state' | tr -d \"`

  if [ $job_state == "pending" ]; then
    let "state_failed=state_failed += 1"
    if [ "$state_failed" -gt 4 ]; then
      echo -e "job_state not change to requested" > $log_dir$job_id.log
      curl -X PUT -d '{"state": "failed", "log": "job_state not change to requested"}' http://api.peskar.paradev.ru/job/$job_id/
    fi
    continue
  elif [ $job_state == "requested" ]; then
    curl -X PUT -d '{"state": "working"}' http://api.peskar.paradev.ru/job/$job_id/
  fi

  job_download_url=`curl -s $api_url/job/$job_id/ | jq '.download_url' | tr -d \"`
  job_name=`curl -s $api_url/job/$job_id/ | jq '.name' | tr -d \"`


  file_name=`echo $job_download_url | awk -F/ '{print $NF}'`
  mkdir $queue_path$job_id
  curl -s -o $queue_path$job_id/$file_name $job_download_url &
  curl -X PUT -d '{"state": "working", "log": "$date_time Starting download..."}' http://api.peskar.paradev.ru/job/$job_id/

  sleep 1
  ps_status=`ps -e | grep curl | wc -l`
  while [ "$ps_status" -gt "0" ]; do
    sleep 2
    ps_status=`ps -e | grep curl | wc -l`
  done

  curl -X PUT -d '{"state": "working", "log": "$date_time Downloaded, sending to transcoder..."}' http://api.peskar.paradev.ru/job/$job_id/

  echo "download done"

  tmp_video_size1=`du -s $queue_path | awk '{print $1}'`
  sleep 5
  while true; do
    tmp_video_size1=`du -s $queue_path | awk '{print $1}'`
    sleep 5
    tmp_video_size2=`du -s $queue_path | awk '{print $1}'`

    if [ "$tmp_video_size1" -eq "$tmp_video_size2" ]; then
      break
    fi
  done

  mkdir -p $source_path$job_id/
  mkdir -p $end_path$job_id/

  sleep 1
  ps_status=`ps -e | grep ffmpeg | wc -l`
  while [ "$ps_status" -gt "0" ]; do
    sleep 2
    ps_status=`ps -e | grep ffmpeg | wc -l`
  done

  ffmpeg \
        -i $source_path$job_id/$file_name -c:v libx264 -preset veryfast -g 25 -keyint_min 4\
        -c:a aac -f mp4 $end_path$job_id/$file_name.mp4 > $log_dir$file_name.log 2>&1 &

  sleep 1
  ps_status=`ps -e | grep ffmpeg | wc -l`
  while [ "$ps_status" -gt "0" ]; do
    sleep 2
    ps_status=`ps -e | grep ffmpeg | wc -l`
  done

  ffmpeg \
        -i $end_path$job_id/$file_name.mp4 -map 0 -c copy -segment_time 3 \
        -segment_list $end_path$job_id/$file_name/$file_name.m3u8 -f segment \
        $end_path$job_id/$end_file/$end_file\_%08d.ts > $log_dir$end_file\_seg.log 2>&1 &

  sleep 1
  ps_status=`ps -e | grep ffmpeg | wc -l`
  while [ "$ps_status" -gt "0" ]; do
    sleep 2
    ps_status=`ps -e | grep ffmpeg | wc -l`
  done

  tar -c -f $end_path$job_id/$end_file.tar $end_path$job_id/$end_file/*  > /dev/null 2>&1

  rsync -e='ssh -p 3389' -r $end_path$job_id/$end_file.tar user@paradev.ru:$paradev_path
  rm -r -f $source_path$job_id && rm -r -f $end_path$job_id > /dev/null 2>&1

done




# next_file=`ls -t -r -1 $queue_path | sed -n -e 1p`

# mkdir $source_path$job_id
# mkdir $end_path$job_id

# exit 0
