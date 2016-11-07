#!/bin/bash

queue_path=/home/torrent/queue-video-tmp/
source_path=/home/torrent/source-video-tmp/
end_path=/home/torrent/end-video-tmp/
log_dir=/home/torrent/logs/

paradev_path=/home/user/films/

tmp_video_size1=`du -s $queue_path | awk '{print $1}'`
sleep 10

if [ "$tmp_video_size1" -lt 1000 ]; then
  exit 0
else
  while true; do
    tmp_video_size1=`du -s $queue_path | awk '{print $1}'`
    sleep 10
    tmp_video_size2=`du -s $queue_path | awk '{print $1}'`

    if [ "$tmp_video_size1" -eq "$tmp_video_size2" ]; then
      break
    fi
  done
fi

next_file=`ls -t -r -1 $queue_path | sed -n -e 1p`

if [ -d $queue_path$next_file ];then
  next_file_n2=`find $queue_path$next_file -size +10M`
  mv $next_file_n2 $source_path
  rm -r -f $queue_path$next_file
else
  mv $queue_path$next_file $source_path
fi

source_file=`ls -1 $source_path`
end_file=`ls -1 $source_path | awk -F. '{print $1}'`
mkdir $end_path$end_file

sleep 1
ps_status=`ps -e | grep ffmpeg | wc -l`
while [ "$ps_status" -gt "0" ]; do
  sleep 2
  ps_status=`ps -e | grep ffmpeg | wc -l`
done

ffmpeg \
      -i $source_path$source_file -map 0 -c:v libx264 -preset veryfast -g 25 -keyint_min 4\
      -c:a aac -f mp4 $end_path$end_file/$end_file.mp4 > $log_dir$end_file.log 2>&1 &

sleep 1
ps_status=`ps -e | grep ffmpeg | wc -l`
while [ "$ps_status" -gt "0" ]; do
  sleep 2
  ps_status=`ps -e | grep ffmpeg | wc -l`
done

ffmpeg \
      -i $end_path$end_file/$end_file.mp4 -map 0 -c copy -segment_time 3 \
      -segment_list $end_path$end_file/$end_file.m3u8 -f segment \
      $end_path$end_file/$end_file\_%08d.ts > $log_dir$end_file\_seg.log 2>&1 &

sleep 1
ps_status=`ps -e | grep ffmpeg | wc -l`
while [ "$ps_status" -gt "0" ]; do
  sleep 2
  ps_status=`ps -e | grep ffmpeg | wc -l`
done

tar -c -f $end_path$end_file.tar $end_path$end_file/*

rsync -e='ssh -p 3389' -r $end_path$end_file.tar user@paradev.ru:$paradev_path
rm -r -f $source_path* && rm -r -f $end_path* > /dev/null 2>&1

exit 0
