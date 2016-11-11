#!/bin/bash
#
# Perform helpers

#######################################
# Print info message
# Globals:
#   None
# Arguments:
#   Text
# Returns:
#   None
#######################################
log_info() {
  echo "----> $*"
}

#######################################
# Print verbose message
# Globals:
#   None
# Arguments:
#   Text
# Returns:
#   None
#######################################
log_verbose() {
  echo "      $*"
}

#######################################
# Print warning message
# Globals:
#   None
# Arguments:
#   Text
# Returns:
#   None
#######################################
log_warn() {
  echo " !    $*"
}

#######################################
# Print fail message and exit
# Globals:
#   None
# Arguments:
#   Text
# Returns:
#   None
#######################################
log_fail() {
  echo "$@" 1>&2
  exit 1
}

#######################################
# Print arguments and execute curl
# Globals:
#   None
# Arguments:
#   Curl arguments
# Returns:
#   None
#######################################
curl_exec() {
  local ARGS="$@"
  log_info "curl $ARGS"
  curl $ARGS
  log_verbose "done"
}

#######################################
# Print arguments and execute rsync
# Globals:
#   None
# Arguments:
#   Rsync arguments
# Returns:
#   None
#######################################
rsync_exec() {
  local ARGS="$@"
  log_info "rsync $ARGS"
  rsync $ARGS
  log_verbose "done"
}

#######################################
# Print arguments and execute ffmpeg
# Globals:
#   None
# Arguments:
#   FFmpeg arguments
# Returns:
#   None
#######################################
ffmpeg_exec() {
  local ARGS="$@"
  log_info "ffmpeg $ARGS"
  ffmpeg $ARGS
  log_verbose "done"
}
