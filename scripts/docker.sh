#!/usr/bin/env bash

# Command line output colors
NORMAL="\\033[0;39m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"
BOLD="\033[1m"

# Script variables
APP_CONTAINER="profiler_app"
APP_USER="hgprofiler"
PUB_CACHE="/pub-cache"

### START SCRIPT FUNCTIONS ###

# Echo statement in blue.
log() {
  echo -e "$BLUE > $1 $NORMAL"
}

# Echo statement in red.
error() {
  echo "" 
  echo -e "$RED >>> ERROR - $1$NORMAL"
}


# Run Flask dev server in debug mode.
serve() {
  docker exec -it ${APP_CONTAINER} su ${APP_USER} -c "python3 /hgprofiler/bin/run-server.py --ip 0.0.0.0 --debug"
}


# Open bash shell in container.
shell() {
  docker exec -it ${APP_CONTAINER} bin/bash
}


# Database commands.
db() {
  docker exec -it ${APP_CONTAINER} su ${APP_USER} -c "python3 /hgprofiler/bin/database.py $@"
}


# Restart supervisor applications.
supervisorctl() {
  docker exec ${APP_CONTAINER} supervisorctl "$@" 
}


# Tail logs.
tail() {
  # E.g. log_tail supervisor/*
  # E.g. log_tail supervisor/scrape*
  # E.g. log_tail supervisor/scrape*stderr*
  docker exec -it ${APP_CONTAINER} su -c "tail -f /var/log/$1"
}


# Fix pub permissions.
fixpub() {
  log "Fixing pub permissions."
  docker exec -it ${APP_CONTAINER} su -c "chown -R root:root $PUB_CACHE; find $PUB_CACHE -type f -exec chmod 644 {} \;"
}


# Perform pub command.
pub() {
  log "Running pub command."
  log "Fixpub is called automatically after any pub command."
  docker exec -it ${APP_CONTAINER} su -c "cd /hgprofiler/static/dart/; pub $1"
  fixpub
}


# Print help.
help() {
  echo "-----------------------------------------------------------------------"
  echo -e -n "$BOLD"
  echo -e "                      Available commands                               "
  echo -e -n "$NORMAL"
  echo "-----------------------------------------------------------------------"
  echo -e "   $BOLD db $NORMAL- Execute database command, e.g. 'build', 'drop'"
  echo -e "   $BOLD fixpub $NORMAL- Fix pub permissions"
  echo -e "   $BOLD help $NORMAL- Display this help"
  echo -e "   $BOLD pub $NORMAL- Execute pub command, e.g. 'get'"
  echo -e "   $BOLD serve $NORMAL- Run Flask dev server in debug mode"
  echo -e "   $BOLD shell $NORMAL- Open shell in profiler container"
  echo -e "   $BOLD supervisorctl $NORMAL- Execute supervisorctl command, e.g. 'restart all'"
  echo -e "   $BOLD tail $NORMAL- Tail logs, e.g. 'supervisor/*', 'supervisor/scrape*stderr*'"
  echo "-----------------------------------------------------------------------"
}

### END SCRIPT FUNCTIONS ###

# Command options.
COMMANDS=("serve" "shell" "db" "supervisorctl" "tail" "pub" "fixpub" "help")
COMMAND=$1

# Ensure command is supplied.
if [ -z $COMMAND ]
  then
    error "Missing command."
    help
fi


# Ensure command is recognised.
if [[ ! "${COMMANDS[@]}" =~ "${COMMAND}" ]]
  then
    error "Command not found."
    help
fi

$*
