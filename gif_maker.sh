#!/bin/bash
#
# Perform Peskar GIF maker

#######################################
# Ping server
# Globals:
#   PESKAR_PETR_JOBS_PATH
# Arguments:
#   None
# Returns:
#   Job ID
#######################################
gif_maker () {
  local JOB_ID="$1"
  local FILM="$2"
  local NAME="$3"
  local FPS=4
  local SUM_FRAME=15

  local HOURS=$(ffprobe $FILM 2>&1 | grep Duration | awk '{print $2}' | awk -F: '{print $1}')
  local MINUTS=$(ffprobe $FILM 2>&1 | grep Duration | awk '{print $2}' | awk -F: '{print $2}')
  local DURATION=$((($HOURS * 60 + $MINUTS) * 60 ))
  local STEP=$(($DURATION / $SUM_FRAME))

  mkdir -p $JOB_PATH\/PNG

  convertsecs() {
   ((h=${1}/3600))
   ((m=(${1}%3600)/60))
   ((s=${1}%60))
   _TIME=$(printf "%02d:%02d:%02d\n" $h $m $s)
  }

  plus_one (){
    FRAME=$(($FRAME + $STEP))
    SEQ=$(($SEQ + 1))
    NUM=$(printf %02d $SEQ)
  }

  local FRAME=1
  local SEQ=01
  local NUM=$SEQ
  local _TIME="00:00:01"

  while [ $FRAME -le $DURATION ]; do
    ffmpeg -v fatal -ss $_TIME\.00 -t 1 -r 1 \
          -i $FILM -f image2 $JOB_PATH\/PNG\/$NAME\_$NUM.png
    if [[ "$?" -ne 0 ]]; then
      job_set_failed $JOB_ID "Created png #$NUM failed"
    fi
    plus_one
    convertsecs $FRAME
  done

  ffmpeg -v fatal -r $FPS -i $JOB_PATH\/PNG\/$NAME\_%02d.png \
        -r $FPS -vf scale=300:-1 -gifflags +transdiff -y $END_PATH\/$NAME\.gif
  if [[ "$?" -ne 0 ]]; then
    job_set_failed $JOB_ID "Created GIF failed"
    return 1
  fi

}
