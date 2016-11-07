#!/bin/bash

queue_path=/home/torrent/queue-video-tmp/
source_path=/home/torrent/source-video-tmp/
end_path=/home/torrent/end-video-tmp/
log_dir=/home/torrent/logs/

paradev_path=/home/user/films/

tmp_video_size1=`du -s $queue_path | awk '{print $1}'`
sleep 10
  
if [ "$tmp_video_size1" -ne 1000 ]; then
  exit 0
else
  while true; do   # Проверям размер раталога
    tmp_video_size1=`du -s $queue_path | awk '{print $1}'`
    sleep 10
    tmp_video_size2=`du -s $queue_path | awk '{print $1}'`

    if [ "$tmp_video_size1" -eq "$tmp_video_size2" ]; then  # Убеждаемся, что временный каталог более не растет
      break
    fi
  done
fi

next_file=`ls -t -r -1 $queue_path | sed -n -e 1p`
mv $queue_path$next_file $source_path       # перемещаем из очереди в рабочий каталог
end_file_name=`ls -1 $source_path`
end_file_n2=`ls -1 $source_path | awk -F. '{print $1}'`
mkdir $end_path$end_file_n2

sleep 1
ps_status=`ps -e | grep ffmpeg | wc -l`
while [ "$ps_status" -gt "0" ]; do
  sleep 2
  ps_status=`ps -e | grep ffmpeg | wc -l`
done

ffmpeg \
      -i $source_path$end_file_name -map 0 -c:v libx264 -preset veryfast -g 25 -keyint_min 4\
      -c:a aac -f mp4 $end_path$end_file_n2/$end_file_n2.mp4 > $log_dir$end_file_n2.log 2>&1 &

sleep 1
ps_status=`ps -e | grep ffmpeg | wc -l`
while [ "$ps_status" -gt "0" ]; do
  sleep 2
  ps_status=`ps -e | grep ffmpeg | wc -l`
done

ffmpeg \
      -i $end_path$end_file_n2/$end_file_n2.mp4 -map 0 -c copy -segment_time 3 \
      -segment_list $end_path$end_file_n2/$end_file_n2.m3u8 -f segment \
      $end_path$end_file_n2/$end_file_n2\_%08d.ts > $log_dir$end_file_n2\_seg.log 2>&1 &
    
sleep 1
ps_status=`ps -e | grep ffmpeg | wc -l`
while [ "$ps_status" -gt "0" ]; do
  sleep 2
  ps_status=`ps -e | grep ffmpeg | wc -l`
done

rsync -e='ssh -p 3389' -r $end_path$end_file_n2 user@paradev.ru:$paradev_path
rm -r -f $source_path* && rm -r -f $end_path* && rm -r -f $end_path* > /dev/null 2>&1

exit 0
