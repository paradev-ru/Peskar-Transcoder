#!/bin/bash

# JOB_ID="$1"

set -x

FILM="$1"

HOURS=$(($(ffprobe $FILM 2>&1 | grep Duration | awk '{print $2}' | awk -F: '{print $1}') * 60))
MINUTS=$(ffprobe $FILM 2>&1 | grep Duration | awk '{print $2}' | awk -F: '{print $2}')
DURATION=$(($HOURS + $MINUTS))

NAME="${FILM%.*}"
mkdir -p $NAME

_HH=00
_MM=01
MIN=01
NUM=$MIN

PLUS_ONE (){
  MIN=$(($MIN + 1))
  NUM=$(printf %02d $MIN)
}

while [ $MIN -le $DURATION ]; do
  ffmpeg -v warning -ss $_HH:$_MM:00.00 -t 1 -r 1 \
        -i $FILM -f image2 $NAME\/$NAME\_$NUM.png
  if [ $_MM -eq "59" ];then
    _MM=00
    _HH=$(printf %02d $(($_HH + 1)))
    PLUS_ONE
    continue
  fi
  _MM=$(($_MM + 1))
  PLUS_ONE
done

ffmpeg -i $NAME\/$NAME\_\%02d.png \
      -r 10 -f gif $NAME\.gif

