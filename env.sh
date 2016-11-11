#!/bin/bash
#
# Perform setting vars

# Transcoder options
PESKAR_PETR_HOME_PATH=${PESKAR_PETR_HOME_PATH:-"/home/emedvedev/peskar-transcoder"}

# Rsync options
PESKAR_SYNC_TARGET=${PESKAR_SYNC_TARGET:-"user@paradev.ru"}
PESKAR_SYNC_PATH=${PESKAR_SYNC_PATH:-"/home/user/films/"}
PESKAR_SYNC_OPTIONS=${PESKAR_SYNC_OPTIONS:-"ssh -p 3389"}

# API options
PESKAR_API_URL=${PESKAR_API_URL:-"http://api.peskar.paradev.ru"}
