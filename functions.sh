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
# Check if program is installed
# Globals:
#   None
# Arguments:
#   Program name
# Returns:
#   Boolean
#######################################
installed() {
  hash "$1" 2>/dev/null
}
