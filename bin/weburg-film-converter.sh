#!/bin/bash

queue_path=/home/emedvedev/queue-video-tmp/
source_path=/home/emedvedev/source-video-tmp/
end_path=/home/emedvedev/end-video-tmp/
trans_source_path=/home/emedvedev/trans-video-tmp/
log_dir=/home/emedvedev/logs/

video_search="Обнаружен материал объемом"
wait_video="Ожидается пауза при копировании в папку с очередью"

while true; do
  tmp_video_size1=`du -s $queue_path | awk '{print $1}'`
  # echo -e '\n' "\e[0;32m $tmp_video_size1 \e[0m" '\n'
  sleep 2
  while [ "$tmp_video_size1" -gt 1000 ]; do   # Проверям размер раталога
    tmp_video_size1=`du -s $queue_path | awk '{print $1}'`
    sleep 2
    tmp_video_size2=`du -s $queue_path | awk '{print $1}'`
    tmp_video_size_hum=`du -s -h $queue_path | awk '{print $1}'`

    if [ "$tmp_video_size1" -ne "$tmp_video_size2" ]; then  # Убеждаемся, что временный каталог более не растет
      continue
    fi

    date_time=`date +%H:%M_%d-%m-%Y`
    next_file=`ls -t -r -1 $queue_path | sed -n -e 1p`
    mv $queue_path$next_file $source_path       # перемещаем из очереди в рабочий каталог
    end_file_name=`ls -1 $source_path`

    sleep 1
    ps_status=`ps -e | grep ffmpeg | wc -l`
    while [ "$ps_status" -gt "0" ]; do
      sleep 2
      ps_status=`ps -e | grep ffmpeg | wc -l`
    done

    ffmpeg \
          -i $source_path$end_file_name -map 0 -c:v libx264 -preset veryfast \
          -c:a aac -f mp4 $trans_source_path$end_file_name.mp4 > $log_dir$end_file_name.log 2>&1 &

    sleep 1
    ps_status=`ps -e | grep ffmpeg | wc -l`
    while [ "$ps_status" -gt "0" ]; do
      sleep 2
      ps_status=`ps -e | grep ffmpeg | wc -l`
    done

    cp $trans_source_path$end_file_name.mp4 $end_path

    full_time=`ffprobe $trans_source_path$end_file_name.mp4 2>&1 | grep Duration | awk '{print $2}' | sed s'/,//g'`
    echo -e $full_time
    # while [  ]; do

    mkdir $end_path$end_file_name\chunks
    ss_chunk="00:00:00"
    t_chunk="00:00:05"
    chunk_size=10
    name_num=10000001

      while [ "$t_chunk" \< "$full_time" ]; do

        ffmpeg \
              -i $trans_source_path$end_file_name.mp4 -map 0-ss $ss_chunk -t $t_chunk \
              -c copy -f mpegts $end_path$end_file_name\chunks/$end_file_name\_$name_num.ts > $log_dir$end_file_name\_$name_num.log 2>&1 &

      let "name_num=name_num += 1"
      ss_chunk=$t_chunk
      t_chunk=`date -d "$t_chunk $chunk_size sec" +"%H:%M:%S"`

      echo -e $ss_chunk
      echo -e $t_chunk
      echo -e $name_num

      done

    exit 0
    break
  done
done
