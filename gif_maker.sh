#!/bin/bash

# JOB_ID="$1"

 set -x

FILM="$1"
FPS=4
SUM_FRAME=15

HOURS=$(($(ffprobe $FILM 2>&1 | grep Duration | awk '{print $2}' | awk -F: '{print $1}') * 60))
MINUTS=$(ffprobe $FILM 2>&1 | grep Duration | awk '{print $2}' | awk -F: '{print $2}')
DURATION=$((($HOURS + $MINUTS) * 60 ))
STEP=$(($DURATION / $SUM_FRAME))

NAME="${FILM%.*}"
mkdir -p $NAME

echo $DURATION
echo $STEP

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

FRAME=1
SEQ=01
_TIME="00:00:01"

while [ $FRAME -le $DURATION ]; do
  ffmpeg -v warning -ss $_TIME\.00 -t 1 -r 1 \
        -i $FILM -f image2 $NAME\/$NAME\_$NUM.png
  plus_one
  convertsecs $FRAME
done

ffmpeg -r $FPS -i $NAME\/$NAME\_%02d.png \
      -r $FPS -vf scale=300:-1 -gifflags +transdiff -y $NAME\.gif

