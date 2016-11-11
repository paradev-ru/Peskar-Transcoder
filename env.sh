#!/bin/bash
#
# Perform setting vars

# Transcoder options
PESKAR_PETR_USER=${PESKAR_PETR_USER:-"emedvedev"}

# Rsync options
PESKAR_SYNC_TARGET=${PESKAR_STORE_USER:-"user@paradev.ru"}
PESKAR_SYNC_PATH=${PESKAR_SYBC_PATH:-"/home/user/films/"}
PESKAR_SYNC_OPTIONS=${PESKAR_STORE_PORT:-"ssh -p 3389"}

# API options
PESKAR_API_URL=${PESKAR_API_URL:-"http://api.peskar.paradev.ru"}
